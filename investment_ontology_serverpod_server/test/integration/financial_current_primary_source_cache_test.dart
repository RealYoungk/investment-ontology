import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Current exact historical primary sources', (
    builder,
    endpoints,
  ) {
    test('current bothfailed public3 registered bases recover once without API or counter reset', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      final receipts = [
        "20220316000897",
        "20220318000943",
        "20220322000542",
        "20220323001368",
        "20220429000083",
        "20221026000437",
        "20230314000624",
        "20230321000275",
        "20230728000135",
        "20240319000167",
        "20241227000654",
        "20250319000137",
      ];
      final entries = VerifiedAnnualSourceRegistry.entries
          .where((x) => receipts.contains(x.receipt))
          .toList();
      final companies = <String, Company>{};
      for (final r in receipts) {
        final e = entries.firstWhere((x) => x.receipt == r);
        final c =
            companies[e.corpCode] ??
            await Company.db.insertRow(
              s,
              Company(
                corpCode: e.corpCode,
                name: e.companyName,
                stockCode: '000001',
                fiscalMonth: 12,
                market: Market.kosdaq,
              ),
            );
        companies[e.corpCode] = c;
        await DartFiling.db.insertRow(
          s,
          DartFiling(
            companyId: c.id,
            corpCode: c.corpCode,
            rceptNo: r,
            reportName: '사업보고서 (${e.year}.12)',
            bsnsYear: e.year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'api-noData-annual-public:attempt=3; Exact annual legal issuer corroboration failed',
            discoveredAt: now,
          ),
        );
      }
      Future<void> run() async {
        final j = await IngestJob.db.insertRow(
          s,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await FinancialFactsSync(
          s,
          SourceClient(),
          j.id!,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
      }

      for (var i = 0; i < 4; i++) {
        await run();
      }
      for (final e in entries) {
        final ledger = (await DartFiling.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt),
        )).single;
        expect(ledger.attempts, 3);
        expect(ledger.lastError, contains('attempt=3'));
        expect(
          e.basis == FsDiv.separate
              ? ledger.separateStatus
              : ledger.consolidatedStatus,
          FilingFetchStatus.stored,
        );
        final report = (await FinancialReport.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt) & t.fsDiv.equals(e.basis),
        )).single;
        expect(report.bsnsYear, e.year);
        final source = (await Source.db.findById(s, report.sourceId))!;
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        );
        final stmt = (manifest['sources'] as List).singleWhere(
          (x) => x['label'] == e.statementLabel,
        );
        expect(source.reference, e.receipt);
        expect(source.url, stmt['url']);
        final facts = await FinancialFact.db.find(
          s,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts.length, inInclusiveRange(7, 8));
        expect(facts.every((x) => x.sourceId == source.id), isTrue);
        expect(
          await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          ),
          hasLength(1),
        );
      }
      for (final r in receipts) {
        if (!entries.any(
          (x) => x.receipt == r && x.basis == FsDiv.consolidated,
        )) {
          final f = (await DartFiling.db.find(
            s,
            where: (t) => t.rceptNo.equals(r),
          )).single;
          expect(f.consolidatedStatus, FilingFetchStatus.failed);
          expect(
            await FinancialReport.db.find(
              s,
              where: (t) =>
                  t.rceptNo.equals(r) & t.fsDiv.equals(FsDiv.consolidated),
            ),
            isEmpty,
          );
        }
      }
      final before = [
        for (final x in await FinancialReport.db.find(s)) x.toJson(),
        for (final x in await FinancialFact.db.find(s)) x.toJson(),
      ];
      await run();
      expect([
        for (final x in await FinancialReport.db.find(s)) x.toJson(),
        for (final x in await FinancialFact.db.find(s)) x.toJson(),
      ], before);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
