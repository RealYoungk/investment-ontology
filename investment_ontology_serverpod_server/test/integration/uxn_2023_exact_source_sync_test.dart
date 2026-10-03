import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/uxn_2023_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('UXN exact current annual8', (builder, endpoints) {
    test('normal worker recovers exact FY2023 current8; no prior numeric/API/replay writes', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      final e = VerifiedAnnualSourceRegistry.find(
        '20240320001200',
        FsDiv.separate,
      )!;
      final company = await Company.db.insertRow(
        s,
        Company(
          corpCode: e.corpCode,
          name: e.companyName,
          stockCode: '337840',
          fiscalMonth: 12,
          market: Market.konex,
        ),
      );
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      final oldError =
          'api-noData-annual-public:attempt=3; public annual source verification failed: Ambiguous annual current header';
      await DartFiling.db.insertRow(
        s,
        DartFiling(
          companyId: company.id,
          corpCode: e.corpCode,
          rceptNo: e.receipt,
          reportName: '사업보고서 (2023.12)',
          bsnsYear: 2023,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: oldError,
          discoveredAt: now,
        ),
      );
      Future<void> run() async {
        final job = await IngestJob.db.insertRow(
          s,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        final client = SourceClient();
        await FinancialFactsSync(
          s,
          client,
          job.id!,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
        expect(client.calls, 0);
      }

      await run();
      final filing = (await DartFiling.db.find(s)).single;
      expect(filing.consolidatedStatus, FilingFetchStatus.noData);
      expect(filing.separateStatus, FilingFetchStatus.stored);
      expect(filing.attempts, 3);
      expect(filing.lastError, contains('attempt=3'));
      final report = (await FinancialReport.db.find(s)).single;
      expect(report.bsnsYear, 2023);
      expect(report.fsDiv, FsDiv.separate);
      expect(report.rceptNo, e.receipt);
      final source = (await Source.db.findById(s, report.sourceId))!;
      expect(source.url, Uxn2023ExactSource.sources['ofs']!.$1);
      expect(source.reference, e.receipt);
      expect(source.kind, SourceKind.dartReport);
      final facts = await FinancialFact.db.find(s);
      expect(facts, hasLength(8));
      expect(
        facts.every(
          (v) =>
              v.sourceId == source.id &&
              v.reportId == report.id &&
              v.bsnsYear == 2023 &&
              v.fsDiv == FsDiv.separate,
        ),
        true,
      );
      expect(facts.map((v) => v.amount.toString()).toSet(), {
        '33395980981',
        '52781999366',
        '-19386018385',
        '336490000',
        '-6807802596',
        '-14009326289',
        '-4456714416',
        '1197626910',
      });
      expect(FinancialAccounts.pick(facts).map((v) => v.key).toSet(), {
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
        'capex',
      });
      final audit = jsonDecode(
        (await Source.db.find(
          s,
          where: (t) => t.reference.equals(e.auditReference),
        )).single.title,
      ) as Map;
      expect(audit['status'], 'completed-source-numeric');
      expect(audit['manifestDigest'], e.manifestDigest);
      expect(audit['numericCoreRows'], 8);
      expect(audit['apiCalls'], 0);
      expect(audit['networkRequests'], 0);
      final proof = jsonDecode(
        (await Source.db.find(
          s,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${e.receipt}:${e.basis.name}',
          ),
        )).single.title,
      ) as Map;
      expect(proof['corpCode'], e.corpCode);
      expect(proof['targetReceipt'], e.receipt);
      expect(proof['fsDiv'], e.basis.name);
      final rows = proof['coreRowProvenance'] as List;
      expect(rows, hasLength(8));
      for (final row in rows) {
        final p = row['html_provenance'] as Map;
        expect(p['printedPLPeriodTitle'], '제12(당)기 2023년 12월 31일 현재');
        expect(p['priorNumericPeriodsCollected'], false);
        expect(p['fullStatementVerified'], false);
        expect(p['numericCellCorrection'], false);
        expect(p['genericRoundingTolerance'], false);
        expect(p['sourceSha256'], Uxn2023ExactSource.sources['ofs']!.$2);
      }
      final beforeFacts = [for (final v in facts) v.toJson()];
      final beforeSources = [
        for (final v in await Source.db.find(s)) v.toJson(),
      ];
      final beforeFilings = [filing.toJson()];
      await run();
      expect([
        for (final v in await FinancialFact.db.find(s)) v.toJson(),
      ], beforeFacts);
      expect([
        for (final v in await Source.db.find(s)) v.toJson(),
      ], beforeSources);
      expect([
        for (final v in await DartFiling.db.find(s)) v.toJson(),
      ], beforeFilings);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
      expect(await FinancialReport.db.find(s), hasLength(1));
    });
  });
}
