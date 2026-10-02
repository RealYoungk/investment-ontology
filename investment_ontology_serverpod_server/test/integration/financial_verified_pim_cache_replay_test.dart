import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart' show QueryParameters;
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('PIM immutable numeric cache normal job', (
    builder,
    endpoints,
  ) {
    for (final scenario in [
      'success-and-rerun',
      'existing-period-audit-conflict',
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
            corpCode: VerifiedAnnualSourceCache.pimCorpCode,
            name: '한국피아이엠',
            stockCode: '231090',
            fiscalMonth: 12,
            market: Market.konex,
          ),
        );
        final dto = jsonDecode(
          File(
            'test/fixtures/financial_html/pim-cfs-whole-ce/stored-ofs-public-dto.json',
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
            rceptNo: VerifiedAnnualSourceCache.pimReceipt,
            reportName: '사업보고서 (2024.12)',
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.stored,
            attempts: 7,
            lastError:
                'api-noData-annual-public:attempt=3; old current title error',
            discoveredAt: now,
          ),
        );
        if (scenario == 'existing-period-audit-conflict') {
          await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference:
                  'financial-api-noData-source:${target.rceptNo}:consolidated',
              title: 'conflicting historical evidence',
              url:
                  'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${target.rceptNo}',
              retrievedAt: now,
            ),
          );
        }
        if (scenario == 'final-receipt-superseded') {
          await DartFiling.db.insertRow(
            session,
            target.copyWith(
              id: null,
              rceptNo: '20250322000001',
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
          where: (t) => t.reference.equals(
            VerifiedAnnualSourceCache.referenceFor(target),
          ),
        );
        if (scenario.startsWith('success') ||
            scenario == 'failed-and-rerun' ||
            scenario == 'existing-period-audit-conflict') {
          expect(attempt.length, 1);
          final a = jsonDecode(attempt.single.title);
          expect(
            a['manifestDigest'],
            VerifiedAnnualSourceCache.pimManifestDigest,
          );
          expect(a['ruleVersion'], VerifiedAnnualSourceCache.pimRuleVersion);
          expect(a['publicAttemptPreserved'], 3);
          expect(a['generalAttemptPreserved'], 7);
          expect(a['networkRequests'], 0);
          expect(
            a['status'],
            scenario.startsWith('success')
                ? 'completed-source-numeric'
                : 'failed',
          );
          expect(
            ledger.consolidatedStatus,
            scenario.startsWith('success')
                ? FilingFetchStatus.stored
                : FilingFetchStatus.failed,
          );
          await run();
          expect(reads, firstReads);
          expect(
            (await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                VerifiedAnnualSourceCache.referenceFor(target),
              ),
            )).length,
            1,
          );
        } else {
          expect(attempt, isEmpty);
          expect(ledger.consolidatedStatus, FilingFetchStatus.failed);
          if (scenario == 'final-receipt-superseded') expect(reads, 0);
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
        final reports = await FinancialReport.db.find(
          session,
          where: (t) =>
              t.companyId.equals(company.id!) &
              t.fsDiv.equals(FsDiv.consolidated),
        );
        if (scenario.startsWith('success')) {
          expect(reports.length, 1);
          final report = reports.single;
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(source.reference, target.rceptNo);
          expect(source.title, contains('DART 원문 HTML 부분 핵심계정'));
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(report.id!),
          );
          expect(facts.length, greaterThanOrEqualTo(7));
          expect(
            facts.every((f) => f.accountId == null && f.sourceId == source.id),
            true,
          );
          final expected = [
            '76459309100',
            '32807209849',
            '43652099251',
            '37447247186',
            '3606809251',
            '2777596031',
            '3548256433',
          ];
          expect(
            facts.take(7).map((f) => f.amount.toString()).toList(),
            expected,
          );
          final summary = await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: FsDiv.consolidated,
          );
          final lines = summary!.periods.single.lines;
          expect(
            lines.singleWhere((l) => l.key == 'netIncome').amount,
            BigInt.parse('2777596031'),
          );
          expect(
            lines.singleWhere((l) => l.key == 'equity').amount,
            BigInt.parse('43652099251'),
          );
          final sql = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} AS account, amount FROM financial_fact f WHERE "reportId"=@report',
            parameters: QueryParameters.named({'report': report.id!}),
          );
          expect(
            sql.any(
              (r) =>
                  r[0] == 'ifrs-full_ProfitLoss' &&
                  r[1].toString() == '2777596031',
            ),
            true,
          );
          expect(
            sql.any(
              (r) =>
                  r[0] == 'ifrs-full_Equity' &&
                  r[1].toString() == '43652099251',
            ),
            true,
          );
          expect(
            jsonDecode(attempt.single.title)['sha256'],
            contains(RegExp(r'^[0-9a-f]{64}$')),
          );
        } else {
          expect(reports, isEmpty);
        }
      });
    }
  });
}
