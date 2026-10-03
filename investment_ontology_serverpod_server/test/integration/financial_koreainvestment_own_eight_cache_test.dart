import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/koreainvestment_own_eight_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('KoreaInvestment exact own current8', (builder, endpoints) {
    for (final receipt in ['20250320000814', '20250320000804']) {
      test(
        '$receipt normal queue storage correction opposite and replay API0',
        () async {
          final session = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 3);
          final entry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.consolidated,
          )!;
          final profile =
              KoreaInvestmentOwnEightSource.profiles[receipt] as Map;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: entry.corpCode,
              name: entry.companyName,
              stockCode: '071050',
              fiscalMonth: 12,
              market: Market.kospi,
            ),
          );
          // The worker reserves the latest-filing feed independently of financial
          // dailyBudget. Pin an exhausted synthetic total budget for the API0
          // cache-recovery contract; no production usage record is modified.
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-03',
              calls: 20000,
            ),
          );
          final manifest = jsonDecode(
            File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
          );
          final cover = (manifest['sources'] as List).singleWhere(
            (s) => s['label'] == 'cover',
          );
          final correction = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'Own correction cover SHA256:${cover['sha256']}',
              reference: receipt,
              url: cover['url'],
              retrievedAt: now,
            ),
          );
          final originalCorrection = correction.toJson();
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id!,
              corpCode: company.corpCode,
              rceptNo: receipt,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              reportName: '[기재정정]사업보고서 (${entry.year}.12)',
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 7,
              lastError: 'api-noData-annual-public:attempt=3; original failure',
              discoveredAt: now,
            ),
          );
          final cache = VerifiedAnnualSourceCache(
            readAsset: (p) => File(p).readAsBytes(),
          );
          Future<IngestJob> run() async {
            final job = await IngestJob.db.insertRow(
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
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
              sourceCache: cache,
            ).run();
            expect(client.calls, 0);
            expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
            return (await IngestJob.db.findById(session, job.id!))!;
          }

          final first = await run();
          expect(first.updated, 1);
          expect(first.status, IngestStatus.failed);
          final actual = (await DartFiling.db.findById(session, filing.id!))!;
          expect(actual.consolidatedStatus, FilingFetchStatus.stored);
          expect(actual.separateStatus, FilingFetchStatus.failed);
          final report = (await FinancialReport.db.find(session)).single;
          expect(report.fsDiv, FsDiv.consolidated);
          expect(report.factCount, 8);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(8));
          for (final c in profile['core'] as List) {
            final fact = detail.facts.singleWhere(
              (f) => f.ord == c['physicalOrd'],
            );
            expect(fact.amount, BigInt.parse(c['value']));
            expect(fact.accountName, c['label']);
            expect(fact.sourceId, report.sourceId);
            expect(fact.fsDiv, FsDiv.consolidated);
            expect(fact.accountId, isNull);
          }
          final summary = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: FsDiv.consolidated,
          ))!;
          expect(summary.periods.single.lines, hasLength(8));
          for (final c in profile['core'] as List) {
            expect(
              summary.periods.single.lines
                  .singleWhere((l) => l.key == c['key'])
                  .amount,
              BigInt.parse(c['value']),
            );
          }
          final oldSource = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'Superseded own fixture',
              reference: 'superseded-$receipt',
              retrievedAt: now,
            ),
          );
          final old = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: '20220310000000',
              fsDiv: FsDiv.consolidated,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              reportName: 'Superseded own fixture',
              factCount: 1,
              sourceId: oldSource.id!,
              supersededById: report.id!,
              fetchedAt: now,
            ),
          );
          final currentNI = detail.facts.singleWhere(
            (f) => f.ord == profile['core'][5]['physicalOrd'],
          );
          await FinancialFact.db.insertRow(
            session,
            FinancialFact(
              reportId: old.id!,
              companyId: company.id!,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              fsDiv: FsDiv.consolidated,
              statement: currentNI.statement,
              accountName: currentNI.accountName,
              ord: currentNI.ord,
              amount: BigInt.one,
              sourceId: oldSource.id!,
              supersededById: currentNI.id,
            ),
          );
          final active = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: FsDiv.consolidated,
          ))!;
          expect(
            active.periods.single.lines
                .singleWhere((l) => l.key == 'netIncome')
                .amount,
            BigInt.parse(profile['core'][5]['value']),
          );
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:$receipt:consolidated',
            ),
          );
          final payload = jsonDecode(amountSource!.title);
          expect(payload['coreRows'], 8);
          final provenanceRows = payload['coreRowProvenance'] as List;
          expect(provenanceRows, hasLength(8));
          for (final core in profile['core'] as List) {
            final rawRow = provenanceRows.singleWhere(
              (p) => p['account_nm'] == core['label'],
            ) as Map;
            expect(rawRow['thstrm_amount'], core['value']);
            expect(rawRow['currency'], 'KRW');
            final p = rawRow['html_provenance'] as Map;
            expect(p['printedUnit'], '원');
            expect(p['unitMultiplier'], '1');
            expect(p['precisionUnit'], '1');
            expect(p['fullStatementCollected'], false);
            expect(p['allStatementRowsVerified'], false);
            expect(p['notesVerified'], false);
            expect(p['notesReadScopeComplete'], false);
            expect(p['crossPrecisionEqualityClaim'], false);
            expect(p['roundingCauseClaim'], false);
            expect(p['cashScopePrimaryOwnWon'], true);
            expect(p['cashScopeOwnNotePrintedMillion'], true);
            expect(p['sourceReceipt'], receipt);
            expect(p['basis'], 'CFS');
            expect(p['ruleVersion'], KoreaInvestmentOwnEightSource.rule);
            expect(p['periodStart'], '${entry.year}-01-01');
            expect(p['periodEnd'], '${entry.year}-12-31');
            expect(p['literalFlowMonth'], '012');
            expect(p['sourceBoundDecimalMonth'], 12);
            expect(p['tableIndex'], core['table']);
            expect(p['rowIndex'], core['row']);
            expect(p['column'], core['column']);
            expect(p['physicalOrd'], core['physicalOrd']);
            expect(p['printedLabel'], core['label']);
            expect(p['currentCell'], core['printed']);
            final primary = (profile['sources'] as List).singleWhere(
              (v) => v['label'] == 'cfs',
            );
            expect(p['source'], primary['url']);
            expect(p['sourceSha256'], primary['sha256']);
            final note = p['cashNoteScopeWitness'] as Map;
            expect(note['noteSumResidualPrintedMillion'], 0);
            expect(note['precisionNotice'], contains('No exact equality'));
            final supporting = p['supportingPeriodEvidence'] as Map;
            expect(supporting['currentEquationWitnesses'], profile['checks']);
          }
          expect(
            (await Source.db.findById(session, correction.id!))!.toJson(),
            originalCorrection,
          );
          final replay = await run();
          expect(replay.updated, 0);
          expect(replay.status, IngestStatus.failed);
          expect(await FinancialFact.db.count(session), 9);
          expect(await FinancialReport.db.count(session), 2);
        },
      );
    }
  });
}
