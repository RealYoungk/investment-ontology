import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Historical primary immutable normal queue', (
    builder,
    endpoints,
  ) {
    for (final receipt in ['20230714000217', '20240319000287']) {
      test(
        '$receipt actual both-failed cap3 stores independently proven CFS and OFS once',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final entry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.separate,
          )!;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: entry.corpCode,
              name: entry.companyName,
              stockCode: '123456',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final reportName =
              '${receipt == '20230714000217' ? '[기재정정]' : ''}사업보고서 (${entry.year}.12)';
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: entry.corpCode,
              rceptNo: receipt,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              reportName: reportName,
              discoveredAt: now,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=3; Exact annual legal issuer corroboration failed',
            ),
          );
          Future<void> run(int expectedUpdated) async {
            final client = SourceClient();
            final job = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            await FinancialFactsSync(
              session,
              client,
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(client.calls, 0);
            expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
            expect(
              (await IngestJob.db.findById(session, job.id!))!.updated,
              expectedUpdated,
            );
          }

          await run(2);
          final actual = (await DartFiling.db.findById(session, filing.id!))!;
          expect(actual.separateStatus, FilingFetchStatus.stored);
          expect(actual.consolidatedStatus, FilingFetchStatus.stored);
          expect(actual.attempts, 3);
          expect(actual.lastError, filing.lastError);
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(company.id!),
          );
          expect(reports, hasLength(2));
          final report = reports.singleWhere((r) => r.fsDiv == FsDiv.separate);
          expect(report.fsDiv, FsDiv.separate);
          expect(report.rceptNo, receipt);
          final source = (await Source.db.findById(session, report.sourceId))!;
          final cases = jsonDecode(
            File(
              'test/fixtures/financial_html/primary-historical-issuer/cases.json',
            ).readAsStringSync(),
          ) as List;
          final proof = cases.singleWhere((c) => c['receipt'] == receipt);
          expect(source.url, proof['urls']['ofs']);
          expect(source.reference, receipt);
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(report.id!),
          );
          final expected = proof['expectedRows'] as List;
          expect(facts, hasLength(7));
          for (final pair in expected) {
            final fact = facts.singleWhere((f) => f.accountName == pair[0]);
            expect(fact.amount, BigInt.parse(pair[1]));
            expect(fact.accountId, isNull);
            expect(fact.sourceId, source.id);
          }
          final summary = await endpoints.financial.summary(
            builder,
            entry.corpCode,
            fsDiv: FsDiv.separate,
          );
          const keys = [
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
          ];
          for (var i = 0; i < keys.length; i++) {
            expect(
              summary!.periods.single.lines
                  .singleWhere((l) => l.key == keys[i])
                  .amount,
              BigInt.parse(expected[i][1]),
            );
          }
          final audit = (await Source.db.find(
            session,
            where: (t) => t.reference.equals(entry.auditReference),
          )).single;
          final payload = jsonDecode(audit.title);
          expect(payload['status'], 'completed-source-numeric');
          expect(payload['publicAttemptPreserved'], 3);
          expect(payload['networkRequests'], 0);
          expect(payload['apiCalls'], 0);
          final before = [
            report.toJson(),
            source.toJson(),
            for (final fact in facts) fact.toJson(),
            audit.toJson(),
          ];
          await run(0);
          final againReports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(company.id!),
          );
          final againSource = (await Source.db.findById(session, source.id!))!;
          final againFacts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(report.id!),
            orderBy: (t) => t.id,
          );
          final againAudit = (await Source.db.find(
            session,
            where: (t) => t.reference.equals(entry.auditReference),
          )).single;
          expect([
            againReports.singleWhere((r) => r.fsDiv == FsDiv.separate).toJson(),
            againSource.toJson(),
            for (final fact in againFacts) fact.toJson(),
            againAudit.toJson(),
          ], before);
        },
      );
    }
  });
}
