import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/public_issuer_five_first_declarations_test.dart' as fixtures;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class FiveDirectIssuerSourceClient extends SourceClient {
  final requested = <String>[];
  @override
  Future<PublicFinancialHtmlSource> fetchAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    requested.add('$receipt:${consolidated ? 'CFS' : 'OFS'}');
    if (consolidated || !fixtures.positives.contains(receipt)) {
      throw const FormatException('Unverified basis/source');
    }
    final dir = '${fixtures.root}/$receipt';
    final proof = jsonDecode(File('$dir/proof.json').readAsStringSync());
    Uri uri(String label) => Uri.parse(
      (proof['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final cover = File('$dir/cover.html').readAsStringSync();
    final body = File('$dir/ofs.html').readAsStringSync();
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: cover,
      statementHtml: body,
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      periodStart: DateTime.utc(bsnsYear),
      periodEnd: periodEnd,
      issuerProof: fixtures.evidence(receipt),
      rows: PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: body,
        coverSource: uri('cover'),
        statementSource: uri('ofs'),
        receipt: receipt,
        corpCode: corpCode,
        companyName: companyName,
        periodStart: DateTime.utc(bsnsYear),
        periodEnd: periodEnd,
        consolidated: false,
        issuerProof: fixtures.evidence(receipt),
      ),
    );
  }
}

void main() {
  withServerpod('Five first direct naming OFS queue', (builder, endpoints) {
    test('five verified direct naming sources precede generic ten and store actual source and summary', () async {
      final session = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 2);
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-02',
          calls: 20000,
        ),
      );
      for (var i = 0; i < 15; i++) {
        final actual = i >= 10;
        final receipt = actual
            ? fixtures.positives[i - 10]
            : '20260930${i.toString().padLeft(6, '0')}';
        final corp = actual
            ? fixtures.meta(receipt)['corpCode'] as String
            : '8${i.toString().padLeft(7, '0')}';
        final year = actual ? fixtures.meta(receipt)['bsnsYear'] as int : 2025;
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: actual
                ? fixtures.meta(receipt)['companyName'] as String
                : 'Generic $i',
            stockCode: i.toString().padLeft(6, '0'),
            market: Market.konex,
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id,
            corpCode: corp,
            rceptNo: receipt,
            reportName: '사업보고서 ($year.12)',
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: actual
                ? FilingFetchStatus.noData
                : FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            discoveredAt: now,
            attempts: 1,
            lastError: 'api-noData-annual-public:attempt=1; previous failure',
          ),
        );
      }
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = FiveDirectIssuerSourceClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.take(10).toSet(), {
        for (final receipt in fixtures.positives) '$receipt:CFS',
        for (final receipt in fixtures.positives) '$receipt:OFS',
      });
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(5));
      for (final report in reports) {
        expect(report.fsDiv, FsDiv.separate);
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.kind, SourceKind.dartReport);
        expect(source.reference, report.rceptNo);
        expect(source.url, contains('rcpNo=${report.rceptNo}'));
        final reviewed = jsonDecode(
          File('${fixtures.root}/${report.rceptNo}/reviewed-core.json')
              .readAsStringSync(),
        ) as Map;
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts.length, (reviewed['rows'] as List).length);
        for (final row in reviewed['rows'] as List) {
          final fact = facts.singleWhere(
            (f) => f.amount == BigInt.parse(row['amount']),
          );
          expect(fact.amount, BigInt.parse(row['amount']));
          expect(
            fact.accountName.replaceAll(RegExp(r'\s+'), ''),
            (row['label'] as String).replaceAll(RegExp(r'\s+'), ''),
          );
          expect(fact.accountId, isNull);
          expect(fact.sourceId, source.id);
        }
        final audits = await Source.db.find(
          session,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${report.rceptNo}:separate',
          ),
        );
        expect(audits, hasLength(1));
        final payload = jsonDecode(audits.single.title);
        final provenance = payload['coreRowProvenance'] as List;
        for (final row in provenance) {
          final identity = row['html_provenance']['historicalCompanyIdentity'];
          expect(identity['receipt'], report.rceptNo);
          expect(
            identity['corpCode'],
            fixtures.meta(report.rceptNo)['corpCode'],
          );
          expect(
            identity['legalNameEvidenceSource'],
            fixtures.uri(report.rceptNo, 'overview').toString(),
          );
        }
        final company = (await Company.db.findById(session, report.companyId))!;
        final summary = (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: FsDiv.separate,
        ))!;
        final revenue = (reviewed['rows'] as List)[3]['amount'];
        expect(
          summary.periods.single.lines
              .singleWhere((l) => l.key == 'revenue')
              .amount,
          BigInt.parse(revenue),
        );
        final mapped = await session.db.unsafeQuery(
          'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
        );
        expect(mapped.where((r) => r[0] != null).length, facts.length);
      }
      expect(reader.calls, 0);
    });
  });
}
