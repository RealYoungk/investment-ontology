import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Immutable official raw cache normal job', (
    builder,
    endpoints,
  ) {
    for (final scenario in [
      'success-and-rerun',
      'failed-and-rerun',
      'cancel-during-read',
      'final-receipt-superseded',
    ]) {
      test(scenario, () async {
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
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: VerifiedAnnualSourceCache.corpCode,
            name: '(주) 탈로스',
            stockCode: '231090',
            fiscalMonth: 12,
            market: Market.konex,
          ),
        );
        final dto = jsonDecode(
          File(
            'test/fixtures/financial_html/talos-current/stored-ofs-public-dto.json',
          ).readAsStringSync(),
        ) as Map<String, dynamic>;
        // Public report/source/facts DTO snapshot. Only isolated foreign keys and IDs change.
        final oldSource = await Source.db.insertRow(
          session,
          Source.fromJson(Map<String, dynamic>.from(dto['source']))
              .copyWith(id: null),
        );
        final oldReport = await FinancialReport.db.insertRow(
          session,
          FinancialReport.fromJson(
            Map<String, dynamic>.from(dto['report']),
          ).copyWith(id: null, companyId: company.id!, sourceId: oldSource.id!),
        );
        final oldFacts = await FinancialFact.db.insert(
          session,
          (dto['facts'] as List)
              .map(
                (row) =>
                    FinancialFact.fromJson(Map<String, dynamic>.from(row))
                        .copyWith(
                          id: null,
                          companyId: company.id!,
                          reportId: oldReport.id!,
                          sourceId: oldSource.id!,
                        ),
              )
              .toList(),
        );
        final beforeSource = oldSource.toJson(),
            beforeReport = oldReport.toJson(),
            beforeFacts = [for (final f in oldFacts) f.toJson()];
        final target = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id,
            corpCode: company.corpCode,
            rceptNo: VerifiedAnnualSourceCache.receipt,
            reportName: '사업보고서 (2025.12)',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.stored,
            attempts: 7,
            lastError:
                'api-noData-annual-public:attempt=3; old current title error',
            discoveredAt: now,
          ),
        );
        if (scenario == 'final-receipt-superseded') {
          await DartFiling.db.insertRow(
            session,
            target.copyWith(
              id: null,
              rceptNo: '20260324000001',
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
            ),
          );
        }
        var reads = 0;
        Future<void> run() async {
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final client = SourceClient();
          final cache = VerifiedAnnualSourceCache(
            readAsset: (path) async {
              reads++;
              if (scenario == 'cancel-during-read' && reads == 1) {
                await IngestJob.db.updateRow(
                  session,
                  job.copyWith(status: IngestStatus.cancelled),
                );
              }
              final raw = await File(path).readAsBytes();
              return scenario == 'failed-and-rerun' &&
                      path.endsWith('manifest.json')
                  ? [...raw, 32]
                  : raw;
            },
          );
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            sourceCache: cache,
          ).run();
          final finished = (await IngestJob.db.findById(session, job.id!))!;
          final expectedStored = 0;
          expect(finished.updated, expectedStored);
          if (scenario != 'cancel-during-read') {
            expect(finished.message, contains('저장한 재무제표 $expectedStored벌'));
          } else {
            expect(finished.status, IngestStatus.cancelled);
          }
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
        }

        await run();
        final firstReads = reads;
        final ledger = (await DartFiling.db.findById(session, target.id!))!;
        expect(ledger.attempts, 7);
        expect(
          ledger.lastError,
          contains('api-noData-annual-public:attempt=3;'),
        );
        expect(ledger.separateStatus, FilingFetchStatus.stored);
        final attempt = await Source.db.find(
          session,
          where: (t) =>
              t.reference.equals(VerifiedAnnualSourceCache.auditReference),
        );
        if (scenario == 'success-and-rerun' || scenario == 'failed-and-rerun') {
          expect(attempt.length, 1);
          final a = jsonDecode(attempt.single.title);
          expect(a['manifestDigest'], VerifiedAnnualSourceCache.manifestDigest);
          expect(a['ruleVersion'], VerifiedAnnualSourceCache.ruleVersion);
          expect(a['publicAttemptPreserved'], 3);
          expect(a['generalAttemptPreserved'], 7);
          expect(a['networkRequests'], 0);
          expect(
            a['status'],
            scenario == 'success-and-rerun'
                ? 'completed-source-not-applicable'
                : 'failed',
          );
          expect(
            ledger.consolidatedStatus,
            scenario == 'success-and-rerun'
                ? FilingFetchStatus.noData
                : FilingFetchStatus.failed,
          );
          await run();
          expect(reads, firstReads);
          expect(
            (await Source.db.find(
              session,
              where: (t) =>
                  t.reference.equals(VerifiedAnnualSourceCache.auditReference),
            )).length,
            1,
          );
        } else {
          expect(attempt, isEmpty);
          expect(ledger.consolidatedStatus, FilingFetchStatus.failed);
          if (scenario == 'final-receipt-superseded') expect(reads, 0);
        }
        final basisAudit = await Source.db.find(
          session,
          where: (t) => t.reference.equals(
            'financial-public-basis-not-applicable:${target.rceptNo}:consolidated',
          ),
        );
        if (scenario == 'success-and-rerun') {
          expect(basisAudit.length, 1);
          final payload = jsonDecode(basisAudit.single.title);
          expect(payload['evidence'].replaceAll(' ', ''), '해당사항없음');
          expect(payload['receipt'], target.rceptNo);
          expect(payload['corpCode'], company.corpCode);
          expect(payload['periodStart'], '2025-01-01T00:00:00.000Z');
          expect(payload['periodEnd'], '2025-12-31T00:00:00.000Z');
          expect(payload['statementSource'], contains('eleId=19'));
        } else {
          expect(basisAudit, isEmpty);
        }
        expect(
          (await Source.db.findById(session, oldSource.id!))!.toJson(),
          beforeSource,
        );
        expect(
          (await FinancialReport.db.findById(session, oldReport.id!))!.toJson(),
          beforeReport,
        );
        for (var i = 0; i < oldFacts.length; i++) {
          expect(
            (await FinancialFact.db.findById(
              session,
              oldFacts[i].id!,
            ))!.toJson(),
            beforeFacts[i],
          );
        }
        expect(
          await FinancialReport.db.find(
            session,
            where: (t) =>
                t.companyId.equals(company.id!) &
                t.fsDiv.equals(FsDiv.consolidated),
          ),
          isEmpty,
        );
      });
    }
  });
}
