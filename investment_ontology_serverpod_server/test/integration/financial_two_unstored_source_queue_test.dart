import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class TwoSourceClient extends SourceClient {
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
    if (consolidated ||
        !{'20230321001265', '20220819000262'}.contains(receipt)) {
      throw const FormatException('Unverified basis/source');
    }
    final dir = 'test/fixtures/financial_html/two-unstored-priority/$receipt';
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
      ),
    );
  }
}

void main() {
  withServerpod('Two unstored actual OFS queue', (builder, endpoints) {
    test('two verified old OFS periods precede ten generic newer failures and store source-bound amounts', () async {
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
      for (var i = 0; i < 12; i++) {
        final actual = i >= 10;
        final receipt = i == 10
            ? '20230321001265'
            : i == 11
            ? '20220819000262'
            : '20260930${i.toString().padLeft(6, '0')}';
        final corp = i == 10
            ? '01344363'
            : i == 11
            ? '00450931'
            : '8${i.toString().padLeft(7, '0')}';
        final year = i == 10
            ? 2022
            : i == 11
            ? 2021
            : 2025;
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: i == 10
                ? '(주)다원넥스뷰'
                : i == 11
                ? '우양에이치씨(주)'
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
      final reader = TwoSourceClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.take(4).toSet(), {
        '20230321001265:CFS',
        '20230321001265:OFS',
        '20220819000262:CFS',
        '20220819000262:OFS',
      });
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(2));
      for (final report in reports) {
        expect(report.fsDiv, FsDiv.separate);
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.kind, SourceKind.dartReport);
        expect(source.reference, report.rceptNo);
        expect(source.url, contains('rcpNo=${report.rceptNo}'));
        final reviewed = jsonDecode(
          File(
            'test/fixtures/financial_html/two-unstored-priority/${report.rceptNo}/reviewed-core.json',
          ).readAsStringSync(),
        ) as Map;
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts.length, (reviewed['rows'] as List).length);
        for (final row in reviewed['rows'] as List) {
          final fact = facts.singleWhere((f) => f.accountName == row['label']);
          expect(fact.amount, BigInt.parse(row['amount']));
          expect(fact.accountId, isNull);
          expect(fact.sourceId, source.id);
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
