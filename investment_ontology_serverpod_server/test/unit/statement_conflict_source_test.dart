import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_conflict_cache.dart';

void main() {
  for (final p in KnownAnnualConflictCache.profiles) {
    test(
      '${p['receipt']} ${p['consolidated']} public exact evidence and mutations',
      () async {
        final div = p['consolidated'] == true
            ? FsDiv.consolidated
            : FsDiv.separate;
        final c = Company(
          id: 17,
          corpCode: p['corpCode'] as String,
          name: 'actual own source',
        );
        final f = DartFiling(
          id: 23,
          companyId: 17,
          corpCode: c.corpCode,
          rceptNo: p['receipt'] as String,
          bsnsYear: p['year'] as int,
          reportName: '사업보고서 (${p['year']}.12)',
          reportCode: FinancialReportCode.annual,
          discoveredAt: DateTime.utc(2026),
          attempts: 3,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
        );
        final e = (await KnownAnnualConflictCache().verify(f, c, div)).evidence;
        final j = {
          'action': 'verified-primary-source-conflict',
          'targetReceipt': f.rceptNo,
          'reportName': f.reportName,
          'corpCode': c.corpCode,
          'fsDiv': div.name,
          'status': 'failed',
          'financialFactsStored': false,
          'evidence': e,
        };
        final s = Source(
          id: 987,
          kind: SourceKind.dartReport,
          reference: 'financial-source-conflict:${f.rceptNo}:${div.name}',
          url: e['statementSource'] as String,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode(j),
        );
        bool valid(Source s, {DartFiling? filing}) =>
            KnownAnnualConflictCache.validFailureSource(s, filing ?? f, c, div);
        expect(valid(s), true);
        expect(
          valid(
            s,
            filing: f.copyWith(
              attempts: 1,
              lastError: 'api-noData-annual-public:attempt=1',
            ),
          ),
          true,
          reason: 'known proof does not wait for retry exhaustion to display',
        );
        for (final other in [
          s.copyWith(kind: SourceKind.manual),
          s.copyWith(id: null),
          s.copyWith(reference: 'foreign'),
          s.copyWith(url: 'https://example.com'),
        ]) {
          expect(valid(other), false);
        }
        for (final entry in {
          'targetReceipt': '20260101000000',
          'corpCode': '00000000',
          'fsDiv': div == FsDiv.consolidated ? 'separate' : 'consolidated',
          'action': 'unknown',
          'status': 'stored',
          'financialFactsStored': true,
        }.entries) {
          final m = jsonDecode(s.title) as Map;
          m[entry.key] = entry.value;
          expect(valid(s.copyWith(title: jsonEncode(m))), false);
        }
        for (final entry in {
          'statementSha256': 'foreign',
          'statementSource': 'https://example.com',
          'periodEnd': '2020-12-31',
          'fullStatementCollected': true,
          'notesVerified': true,
          'collectionComplete': true,
          'noData': true,
          'financialFactsStored': true,
          'negativeCacheManifestSha256': 'foreign',
          'reason': 'corrected source without conflict',
        }.entries) {
          final m = jsonDecode(s.title) as Map;
          (m['evidence'] as Map)[entry.key] = entry.value;
          expect(
            valid(s.copyWith(title: jsonEncode(m))),
            false,
            reason: entry.key,
          );
        }
        final m = jsonDecode(s.title) as Map;
        (m['evidence'] as Map)['consolidated'] = !(p['consolidated'] as bool);
        expect(valid(s.copyWith(title: jsonEncode(m))), false);
        expect(valid(s, filing: f.copyWith(companyId: 18)), false);
        expect(
          valid(
            s,
            filing: f.copyWith(
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.noData,
            ),
          ),
          false,
        );
        for (final sources in [
          <Source>[s],
          <Source>[],
          null,
        ]) {
          final dto = CompanyFinancials(
            corpCode: c.corpCode,
            fsDiv: div,
            availableFsDivs: [],
            periods: [],
            filingCount: 1,
            pendingFilingCount: 1,
            statementAvailabilitySources: sources,
          );
          final restored = Protocol().deserialize<CompanyFinancials>(
            jsonDecode(jsonEncode(dto.toJson())),
          );
          expect(
            restored.statementAvailabilitySources
                ?.map((x) => x.toJson())
                .toList(),
            sources?.map((x) => x.toJson()).toList(),
          );
        }
      },
    );
  }
}
