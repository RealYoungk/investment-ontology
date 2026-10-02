import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_facts_sync_test.dart' show AnnualNoDataClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Annual keyless stored progress resume', (builder, endpoints) {
    for (final mode in ['stored', 'failed', 'cancelled']) {
      test('$mode uses one earliest reservation without changing bounds', () async {
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
        final targets = <DartFiling>[];
        for (var i = 1; i <= 11; i++) {
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: '8${i.toString().padLeft(7, '0')}',
              name: '주식회사 폴레드',
              stockCode: i.toString().padLeft(6, '0'),
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          targets.add(
            await DartFiling.db.insertRow(
              session,
              DartFiling(
                companyId: c.id,
                corpCode: c.corpCode,
                rceptNo: '20260330${i.toString().padLeft(6, '0')}',
                reportName: '사업보고서 (2025.12)',
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                consolidatedStatus: FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.failed,
                lastError:
                    'api-noData-annual-public:attempt=1; prior guarded failure',
                discoveredAt: now,
              ),
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
        final resumes = <DateTime>[];
        // Queue identities are synthetic; core monetary tables use the existing
        // official Polred fixture. Independent fetcher tests bind actual shell IDs.
        final client = AnnualNoDataClient(
          failAll: mode == 'failed',
          syntheticQueueIdentity: true,
          onHtml: mode == 'cancelled'
              ? (cfs) async {
                  if (cfs) {
                    await IngestJob.db.updateRow(
                      session,
                      (await IngestJob.db.findById(
                        session,
                        job.id!,
                      ))!.copyWith(status: IngestStatus.cancelled),
                    );
                  }
                }
              : null,
        );
        Future<void> run(int id) => FinancialFactsSync(
          session,
          client,
          id,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
          scheduleResume: (at) async {
            resumes.add(at);
          },
        ).run();
        await run(job.id!);
        final current = (await IngestJob.db.findById(session, job.id!))!;
        if (mode == 'stored') {
          expect(await FinancialReport.db.count(session), 20);
          expect(current.updated, 20);
          expect(current.processed, 10);
          expect(resumes, [now.add(const Duration(seconds: 30))]);
          final untouched = await DartFiling.db.find(
            session,
            where: (t) =>
                t.lastError.like('api-noData-annual-public:attempt=1;%'),
          );
          expect(untouched, hasLength(1)); // leftover isn't fresh attempt0
        } else if (mode == 'failed') {
          expect(await FinancialReport.db.count(session), 0);
          expect(current.updated, 0);
          expect(current.processed, 6); // circuit unchanged
          expect(resumes, [now.add(const Duration(minutes: 15))]);
          for (var round = 0; round < 4; round++) {
            resumes.clear();
            final j = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            await run(j.id!);
          }
          final before = client.htmlRequests;
          final capped = await DartFiling.db.find(session);
          expect(
            capped.every(
              (f) =>
                  f.lastError?.startsWith(
                    'api-noData-annual-public:attempt=3',
                  ) ==
                  true,
            ),
            isTrue,
          );
          resumes.clear();
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          await run(j.id!);
          expect(client.htmlRequests, before);
          // Existing API-budget next-day schedule is independent of capped
          // public retries and must not become a fast retry loop.
          expect(resumes, [DateTime.utc(2026, 10, 2, 15, 10)]);
        } else {
          expect(current.status, IngestStatus.cancelled);
          expect(resumes, isEmpty);
          expect(
            (await DartFiling.db.findById(
              session,
              targets.last.id!,
            ))!.lastError,
            contains('attempt=1'),
          );
        }
        expect(client.financialRequests, 0);
        expect(current.apiCalls, 0);
        expect(
          (await ApiCallUsage.db.find(session)).every((u) => u.calls == 20000),
          isTrue,
        );
        expect(resumes.length, lessThanOrEqualTo(1));
      });
    }
  });
}
