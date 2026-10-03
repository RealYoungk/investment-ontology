import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_conflict_cache.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exhausted exact conflict evidence', (builder, endpoints) {
    final receipts = {
      for (final p in KnownAnnualConflictCache.profiles) p['receipt'] as String,
    };
    for (final receipt in receipts) {
      final p = KnownAnnualConflictCache.profiles.firstWhere(
        (p) => p['receipt'] == receipt,
      );
      final expected = KnownAnnualConflictCache.profiles
          .where((p) => p['receipt'] == receipt)
          .length;
      for (final superseded in [false, true]) {
        test(
          '$receipt normal API0 worker immutable failure evidence; superseded=$superseded',
          () async {
            final session = builder.asAdmin.build(),
                now = DateTime.utc(2026, 10, 3);
            await ApiCallUsage.db.insertRow(
              session,
              ApiCallUsage(
                provider: ApiProvider.dart,
                day: '2026-10-03',
                calls: 20000,
              ),
            );
            await DartFilingScan.db.insertRow(
              session,
              DartFilingScan(
                scannedFrom: DateTime.utc(2021),
                scannedThrough: now,
                updatedAt: now,
              ),
            );
            final company = await Company.db.insertRow(
              session,
              Company(
                corpCode: p['corpCode'] as String,
                name: 'exact source owner',
                stockCode: '123456',
                market: Market.konex,
                fiscalMonth: 12,
              ),
            );
            final filing = await DartFiling.db.insertRow(
              session,
              DartFiling(
                companyId: company.id,
                corpCode: company.corpCode,
                rceptNo: receipt,
                reportName: '사업보고서 (${p['year']}.12)',
                bsnsYear: p['year'] as int,
                reportCode: FinancialReportCode.annual,
                discoveredAt: now,
                attempts: 3,
                consolidatedStatus: FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.failed,
                lastError: 'immutable earlier generic failure',
              ),
            );
            if (superseded) {
              await DartFiling.db.insertRow(
                session,
                filing.copyWith(id: null, rceptNo: '20260401000001'),
              );
            }
            final client = SourceClient();
            List<Map<String, dynamic>>? auditBefore;
            for (var replay = 0; replay < 2; replay++) {
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
              final after = (await DartFiling.db.findById(
                session,
                filing.id!,
              ))!;
              expect(after.attempts, 3);
              expect(after.consolidatedStatus, FilingFetchStatus.failed);
              expect(after.separateStatus, FilingFetchStatus.failed);
              expect(await FinancialReport.db.count(session), 0);
              expect(await FinancialFact.db.count(session), 0);
              final audits = await Source.db.find(
                session,
                where: (t) => t.reference.like('financial-source-conflict:%'),
                orderBy: (t) => t.id,
              );
              expect(audits, hasLength(superseded ? 0 : expected));
              if (!superseded) {
                expect(
                  after.lastError,
                  contains('primarySourceConflict'),
                );
                expect(after.lastError, contains(filing.lastError!));
                for (final audit in audits) {
                  final data = jsonDecode(audit.title);
                  expect(
                    data['action'],
                    'verified-primary-source-conflict',
                  );
                  expect(data['status'], 'failed');
                  expect(data['evidence']['collectionComplete'], false);
                  expect(data['evidence']['noData'], false);
                  expect(data['evidence']['networkRequests'], 0);
                  expect(data['evidence']['apiCalls'], 0);
                  expect(
                    data['evidence']['readFromPinnedCache'],
                    true,
                  );
                }
                if (replay == 0) {
                  auditBefore = [for (final a in audits) a.toJson()];
                } else {
                  expect([for (final a in audits) a.toJson()], auditBefore);
                }
              } else {
                expect(after.lastError, filing.lastError);
              }
              final view = await endpoints.financial.summary(
                builder,
                company.corpCode,
              );
              expect(
                view!.statementAvailabilitySources,
                hasLength(superseded ? 0 : expected),
              );
              expect(view.periods, isEmpty);
              expect(view.pendingFilingCount, 1);
              if (!superseded) {
                expect(
                  view.statementAvailabilitySources!.map((s) => s.id).toSet(),
                  audits.map((s) => s.id).toSet(),
                );
              }
              final done = (await IngestJob.db.findById(session, job.id!))!;
              expect(done.updated, 0);
              expect(done.status, IngestStatus.failed);
              if (!superseded && replay == 0) {
                expect(done.message, contains('원문 불일치 실패 근거 $expected건'));
              }
            }
            expect(client.calls, 0);
            expect((await ApiCallUsage.db.findFirstRow(session))!.calls, 20000);
          },
        );
      }
    }
  });
}
