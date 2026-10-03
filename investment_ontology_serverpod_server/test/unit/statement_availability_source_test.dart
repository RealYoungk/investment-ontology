import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_not_presented.dart';

void main() {
  final company = Company(id: 1, corpCode: '00442455', name: '코스나인');
  final filing = DartFiling(
    id: 1,
    companyId: 1,
    corpCode: company.corpCode,
    rceptNo: '20260324000091',
    reportName: '사업보고서 (2025.12)',
    bsnsYear: 2025,
    reportCode: FinancialReportCode.annual,
    discoveredAt: DateTime.utc(2026),
    attempts: 3,
    consolidatedStatus: FilingFetchStatus.failed,
    separateStatus: FilingFetchStatus.failed,
  );
  for (final div in FsDiv.values) {
    test(
      'public failed source exact owner/basis/period/proof validation: $div',
      () async {
        final evidence = (await KnownAnnualNotPresentedCache().verify(
          filing,
          company,
          div,
        )).evidence;
        final data = {
          'action': 'verified-primary-statements-not-presented',
          'targetReceipt': filing.rceptNo,
          'reportName': filing.reportName,
          'corpCode': company.corpCode,
          'fsDiv': div.name,
          'evidence': evidence,
          'status': 'failed',
          'financialFactsStored': false,
        };
        final source = Source(
          id: 123,
          kind: SourceKind.dartReport,
          reference:
              'financial-source-not-presented:${filing.rceptNo}:${div.name}',
          url: evidence['statementSource'] as String,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode(data),
        );
        bool valid(Source s) =>
            KnownAnnualSourcesNotPresented.validFailureSource(
              s,
              filing,
              company,
              div,
            );
        expect(valid(source), true);
        for (final entry in {
          'action': 'verified-primary-source-conflict',
          'targetReceipt': '20250324000091',
          'corpCode': '00000000',
          'fsDiv': div == FsDiv.consolidated ? 'separate' : 'consolidated',
          'reportName': '사업보고서 (2024.12)',
          'status': 'stored',
          'financialFactsStored': true,
        }.entries) {
          final changed = jsonDecode(source.title) as Map;
          changed[entry.key] = entry.value;
          expect(
            valid(source.copyWith(title: jsonEncode(changed))),
            false,
            reason: entry.key,
          );
        }
        for (final entry in {
          'receipt': '20250324000091',
          'year': 2024,
          'periodStart': '2024-01-01',
          'periodEnd': '2024-12-31',
          'statementSha256': 'foreign',
          'coverSha256': 'foreign',
          'statementSource': 'https://example.com',
          'currentColumn': 2,
          'printedUnit': '천원',
          'currentNumericCells': 1,
          'basisNotApplicable': true,
          'collectionComplete': true,
          'notesVerified': true,
          'fullStatementCollected': true,
          'auditAttachmentFetchedThisRun': true,
          'financialFactsStored': true,
          'negativeCacheManifestSha256': 'foreign',
        }.entries) {
          final changed = jsonDecode(source.title) as Map;
          (changed['evidence'] as Map)[entry.key] = entry.value;
          expect(
            valid(source.copyWith(title: jsonEncode(changed))),
            false,
            reason: entry.key,
          );
        }
        for (final entry in {
          'source': 'https://example.com',
          'sha256': 'foreign',
          'reviewedAheadOfTime': false,
          'printedEvidence': 'foreign',
        }.entries) {
          final changed = jsonDecode(source.title) as Map;
          ((changed['evidence'] as Map)['independentAuditEvidence']
                  as Map)[entry.key] =
              entry.value;
          expect(
            valid(source.copyWith(title: jsonEncode(changed))),
            false,
            reason: 'audit ${entry.key}',
          );
        }
        expect(valid(source.copyWith(kind: SourceKind.manual)), false);
        expect(valid(source.copyWith(reference: 'foreign')), false);
        expect(valid(source.copyWith(url: 'https://example.com')), false);
        for (final sources in <List<Source>?>[
          null,
          [],
          [source],
        ]) {
          final dto = CompanyFinancials(
            corpCode: company.corpCode,
            availableFsDivs: [],
            periods: [],
            filingCount: 1,
            pendingFilingCount: 1,
            statementAvailabilitySources: sources,
          );
          final wire =
              jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>;
          final server = CompanyFinancials.fromJson(wire);
          expect(server.statementAvailabilitySources?.length, sources?.length);
          if (sources?.isNotEmpty ?? false) {
            expect(
              server.statementAvailabilitySources!.single.reference,
              source.reference,
            );
          }
        }
      },
    );
  }
}
