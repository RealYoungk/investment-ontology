import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exhausted exact nonpresented evidence', (builder, endpoints) {
    for (final superseded in [false, true]) {
      test(
        'normal API0 worker immutable failure evidence; superseded=$superseded',
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
              corpCode: '00442455',
              name: '(주)코스나인',
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
              rceptNo: '20260324000091',
              reportName: '사업보고서 (2025.12)',
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              discoveredAt: now,
              attempts: 3,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              lastError: 'storedCurrentAmountsMissing: 20260324000091; immutable earlier failure',
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
            final after = (await DartFiling.db.findById(session, filing.id!))!;
            expect(after.attempts, 3);
            expect(after.consolidatedStatus, FilingFetchStatus.failed);
            expect(after.separateStatus, FilingFetchStatus.failed);
            expect(await FinancialReport.db.count(session), 0);
            expect(await FinancialFact.db.count(session), 0);
            final audits = await Source.db.find(
              session,
              where: (t) =>
                  t.reference.like('financial-source-not-presented:%'),
              orderBy: (t) => t.id,
            );
            expect(audits, hasLength(superseded ? 0 : 2));
            if (!superseded) {
              expect(
                after.lastError,
                contains('primaryStatementsNotPresented'),
              );
              for (final audit in audits) {
                final data = jsonDecode(audit.title);
                expect(
                  data['action'],
                  'verified-primary-statements-not-presented',
                );
                expect(data['status'], 'failed');
                expect(data['evidence']['collectionComplete'], false);
                expect(data['evidence']['basisNotApplicable'], false);
                expect(data['evidence']['currentNumericCells'], 0);
                expect(
                  data['evidence']['auditAttachmentReadFromPinnedCache'],
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
            final done = (await IngestJob.db.findById(session, job.id!))!;
            expect(done.updated, 0);
            expect(done.status, IngestStatus.failed);
            if (!superseded && replay == 0) {
              expect(done.message, contains('당기 원문 미제시 실패 근거 2건'));
            }
          }
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.findFirstRow(session))!.calls, 20000);
        },
      );
    }
  });
}
