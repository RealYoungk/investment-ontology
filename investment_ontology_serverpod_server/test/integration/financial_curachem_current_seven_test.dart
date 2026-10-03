import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Curachem own current seven exact storage', (
    builder,
    endpoints,
  ) {
    test(
      'normal API0 queue stores seven, summary PPE null and replay zero',
      () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 3);
        final e = VerifiedAnnualSourceRegistry.find(
          '20250305000164',
          FsDiv.separate,
        )!;
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
        final f = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id!,
            corpCode: c.corpCode,
            rceptNo: e.receipt,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2024.12)',
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
          ).run();
          expect(client.calls, 0);
          final result = (await IngestJob.db.findById(session, j.id!))!;
          expect(result.status, IngestStatus.succeeded);
          return result;
        }

        expect((await run()).updated, 1);
        final after = (await DartFiling.db.findById(session, f.id!))!;
        expect(after.separateStatus, FilingFetchStatus.stored);
        expect(after.consolidatedStatus, FilingFetchStatus.failed);
        expect(after.attempts, 7);
        final reports = await FinancialReport.db.find(
          session,
          where: (t) => t.companyId.equals(c.id!),
        );
        expect(reports, hasLength(1));
        final detail = (await endpoints.financial.report(
          builder,
          reports.single.id!,
        ))!;
        expect(detail.facts, hasLength(7));
        expect(
          detail.facts.every(
            (f) => f.sourceId == detail.source!.id && f.accountId == null,
          ),
          true,
        );
        final summary = (await endpoints.financial.summary(
          builder,
          c.corpCode,
          fsDiv: FsDiv.separate,
        ))!;
        final expected = {
          'assets': '15425583523',
          'liabilities': '8124107688',
          'equity': '7301475835',
          'revenue': '5356867177',
          'operatingIncome': '-406123410',
          'netIncome': '-266546846',
          'operatingCashFlow': '-487952845',
        };
        for (final v in expected.entries) {
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == v.key)
                .amount,
            BigInt.parse(v.value),
          );
        }
        expect(summary.periods.single.lines, hasLength(7));
        expect(
          summary.periods.single.lines.where((l) => l.key == 'capex'),
          isEmpty,
        );
        final proof = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${e.receipt}:separate',
          ),
        );
        final payload = jsonDecode(proof!.title) as Map;
        expect(payload['coreRows'], 7);
        for (final p in payload['coreRowProvenance'] as List) {
          expect(p['partialCore7'], true);
          expect(p['fullStatementCollected'], false);
          expect(p['detailHierarchyComplete'], false);
          expect(p['notesVerified'], false);
          expect(p['uncollectedOptionalAccounts'], ['capex']);
        }
        expect((await run()).updated, 0);
        expect(
          await FinancialFact.db.count(
            session,
            where: (t) => t.reportId.equals(reports.single.id!),
          ),
          7,
        );
      },
    );
  });
}
