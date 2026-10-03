import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  for (final numeric in [true, false]) {
    final receipt = numeric ? '20220322000964' : '20220308000292';
    final basis = numeric ? FsDiv.separate : FsDiv.consolidated;
    withServerpod('Exact own2021 $receipt normal recovery', (
      builder,
      endpoints,
    ) {
      test('API0 resolves only approved basis, preserves correction and replay; opposite exhausted failure remains', () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 3);
        final e = VerifiedAnnualSourceRegistry.find(receipt, basis)!;
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: e.corpCode,
            name: e.companyName,
            stockCode: '123456',
            fiscalMonth: 12,
            market: Market.konex,
          ),
        );
        await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-03',
            calls: 20000,
          ),
        );
        final original = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: 'Existing same-receipt correction witness',
            reference: receipt,
            retrievedAt: now,
          ),
        );
        final before = original.toJson();
        final f = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id!,
            corpCode: e.corpCode,
            rceptNo: receipt,
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: '[기재정정]사업보고서 (2021.12)',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 7,
            lastError: 'api-noData-annual-public:attempt=3; original failure',
            discoveredAt: now,
          ),
        );
        Future<IngestJob> run() async {
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final client = SourceClient();
          await FinancialFactsSync(
            session,
            client,
            j.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            sourceCache: VerifiedAnnualSourceCache(
              readAsset: (p) => File(p).readAsBytes(),
            ),
          ).run();
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          return (await IngestJob.db.findById(session, j.id!))!;
        }

        final first = await run();
        expect(first.status, IngestStatus.failed);
        expect(first.updated, numeric ? 1 : 0);
        final after = (await DartFiling.db.findById(session, f.id!))!;
        expect(after.attempts, 7);
        expect(
          numeric ? after.separateStatus : after.consolidatedStatus,
          numeric ? FilingFetchStatus.stored : FilingFetchStatus.noData,
        );
        expect(
          numeric ? after.consolidatedStatus : after.separateStatus,
          FilingFetchStatus.failed,
        );
        final reports = await FinancialReport.db.find(session);
        expect(reports, hasLength(numeric ? 1 : 0));
        if (numeric) {
          final detail = (await endpoints.financial.report(
            builder,
            reports.single.id!,
          ))!;
          expect(detail.facts, hasLength(8));
          expect(
            detail.facts.every(
              (x) => x.accountId == null && x.sourceId == detail.source!.id,
            ),
            true,
          );
          expect(
            detail.facts.map((x) => x.amount.toString()),
            unorderedEquals([
              '8448897501',
              '1160419459',
              '7288478042',
              '1000000000',
              '-6499482742',
              '-12891378384',
              '-6358670875',
              '139758582',
            ]),
          );
          expect(detail.report.fsDiv, FsDiv.separate);
        } else {
          expect(await FinancialFact.db.count(session), 0);
        }
        expect(
          (await Source.db.findById(session, original.id!))!.toJson(),
          before,
        );
        expect(
          (await endpoints.ingest.coverage(builder.asAdmin))
              .financialFailedFilings,
          1,
        );
        final sources = (await Source.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList();
        final facts = (await FinancialFact.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList();
        final replay = await run();
        expect(replay.updated, 0);
        expect(replay.status, IngestStatus.failed);
        expect(
          (await Source.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          sources,
        );
        expect(
          (await FinancialFact.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          facts,
        );
        expect(
          (await DartFiling.db.findById(session, f.id!))!.toJson(),
          after.toJson(),
        );
      });
    });
  }
}
