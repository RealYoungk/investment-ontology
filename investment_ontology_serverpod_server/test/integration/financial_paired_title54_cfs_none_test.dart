import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Paired original CFS absence with independent OFS', (
    builder,
    endpoints,
  ) {
    for (final scenario in [
      for (final r in [
        '20220321001162',
        '20220322000589',
        '20220329000316',
        '20220330000929',
        '20220624000490',
        '20230323001068',
        '20230327000728',
        '20240321000503',
        '20240321001467',
        '20250318000656',
        '20250320000656',
        '20250321000943',
        '20250321001385',
        '20260323000673',
        '20260323001028',
      ])
        (r, false),
      ('20220321001162', true),
    ]) {
      final receipt = scenario.$1;
      final rejectOfs = scenario.$2;
      test(
        '$receipt rejectOfs=$rejectOfs API0 resolves typed CFS none and direct OFS whole amounts',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final entry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.separate,
          )!;
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: entry.corpCode,
              name: entry.companyName,
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
              rceptNo: entry.receipt,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (${entry.year}.12)',
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 7,
              lastError: 'api-noData-annual-public:attempt=3; original failure',
              discoveredAt: now,
            ),
          );
          var reads = 0;
          final cache = VerifiedAnnualSourceCache(
            readAsset: (path) async {
              reads++;
              final bytes = await File(path).readAsBytes();
              return rejectOfs &&
                      path.contains('$receipt-ofs/') &&
                      path.endsWith('ofs.html')
                  ? [...bytes, 32]
                  : bytes;
            },
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
              sourceCache: cache,
            ).run();
            expect(client.calls, 0);
            expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
            return (await IngestJob.db.findById(session, j.id!))!;
          }

          if (rejectOfs) {
            expect((await run()).updated, 0);
            final state = (await DartFiling.db.findById(session, f.id!))!;
            expect(state.consolidatedStatus, FilingFetchStatus.noData);
            expect(state.separateStatus, FilingFetchStatus.failed);
            expect(state.attempts, 7);
            expect(await FinancialReport.db.find(session), isEmpty);
            expect(await FinancialFact.db.find(session), isEmpty);
            final source = await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:$receipt:consolidated',
              ),
            );
            expect(source, isNotNull);
            final proof = jsonDecode(source!.title);
            expect(proof['corpCode'], entry.corpCode);
            expect(
              proof['evidence'],
              VerifiedAnnualSourceRegistry.find(
                receipt,
                FsDiv.consolidated,
              )!.absenceLiteral,
            );
            expect(
              (await endpoints.ingest.coverage(builder.asAdmin))
                  .financialFailedFilings,
              1,
            );
            return;
          }
          expect((await run()).updated, 1);
          final after = (await DartFiling.db.findById(session, f.id!))!;
          expect(after.consolidatedStatus, FilingFetchStatus.noData);
          expect(after.separateStatus, FilingFetchStatus.stored);
          expect(after.attempts, 7);
          expect(after.lastError, contains('attempt=3'));
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(c.id!),
          );
          expect(reports, hasLength(1));
          final noneEntry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.consolidated,
          )!;
          final noneManifest = jsonDecode(
            File('${noneEntry.assetDirectory}/manifest.json')
                .readAsStringSync(),
          );
          final noneUri = (noneManifest['sources'] as List).singleWhere(
            (x) => x['label'] == 'cfs',
          )['url'];
          final noneSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:$receipt:consolidated',
            ),
          );
          expect(noneSource!.kind, SourceKind.dartReport);
          expect(noneSource.url, noneUri);
          final noneProof = jsonDecode(noneSource.title);
          expect(noneProof['receipt'], receipt);
          expect(noneProof['corpCode'], entry.corpCode);
          expect(noneProof['periodStart'], '${entry.year}-01-01T00:00:00.000Z');
          expect(noneProof['periodEnd'], '${entry.year}-12-31T00:00:00.000Z');
          expect(noneProof['evidence'], noneEntry.absenceLiteral);

          final report = reports.single;
          expect(report.fsDiv, FsDiv.separate);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts.length, inInclusiveRange(7, 8));
          expect(
            detail.facts.every(
              (x) => x.accountId == null && x.sourceId == detail.source!.id,
            ),
            true,
          );
          final manifest = jsonDecode(
            File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
          );
          final expectedUri = (manifest['sources'] as List).singleWhere(
            (x) => x['label'] == 'ofs',
          )['url'];
          expect(detail.source!.url, expectedUri);
          final summary = (await endpoints.financial.summary(
            builder,
            c.corpCode,
            fsDiv: FsDiv.separate,
          ))!;
          final pinnedRows = jsonDecode(
            File('${entry.assetDirectory}/expected-rows.json')
                .readAsStringSync(),
          ) as List;
          expect(detail.facts.length, pinnedRows.length);
          expect(
            detail.facts
                .map(
                  (x) => [
                    x.accountName,
                    x.amount.toString(),
                    x.accountId,
                    x.statement.name,
                    x.currency,
                    x.bsnsYear,
                    x.reportCode.name,
                    x.fsDiv.name,
                    x.periodName,
                  ],
                )
                .toList(),
            unorderedEquals([
              for (var i = 0; i < pinnedRows.length; i++)
                [
                  pinnedRows[i][0],
                  pinnedRows[i][1],
                  null,
                  i < 3
                      ? 'balanceSheet'
                      : i < 6
                      ? 'comprehensiveIncome'
                      : 'cashFlow',
                  'KRW',
                  entry.year,
                  'annual',
                  'separate',
                  i < 3
                      ? '${entry.year}-12-31'
                      : '${entry.year}-01-01~${entry.year}-12-31',
                ],
            ]),
          );
          // The independently pinned current source's whole rows remain verbatim.
          expect(
            summary.periods.single.lines
                .singleWhere((x) => x.key == 'assets')
                .amount,
            isNotNull,
          );
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${entry.receipt}:separate',
            ),
          );
          final amountPayload = jsonDecode(amountSource!.title);
          expect(amountPayload['coreRows'], detail.facts.length);
          for (final row in amountPayload['coreRowProvenance']) {
            final proof = row['html_provenance'];
            expect(proof['periodStart'], '${entry.year}-01-01');
            expect(proof['periodEnd'], '${entry.year}-12-31');
            expect(proof['basis'], 'OFS');
            expect(proof['unit'], anyOf('원', '천원', '백만원'));
            expect(row['currency'], 'KRW');
            expect(row['account_id'], isNull);
          }

          expect(
            amountPayload['coreRowProvenance'].every(
              (dynamic x) => x['html_provenance']['source'] == expectedUri,
            ),
            true,
          );
          final coverage = await endpoints.ingest.coverage(builder.asAdmin);
          expect(
            coverage.financialFailedFilings,
            0,
          ); // CFS source explicitly none; only own OFS facts count numeric.
          final sourceBefore = (await Source.db.find(session))
              .map((x) => x.toJson())
              .toList();
          final reportsBefore = reports.map((x) => x.toJson()).toList();
          final factsBefore = (await FinancialFact.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList();
          final ledgerBefore = after.toJson();
          final firstReads = reads;
          expect((await run()).updated, 0);
          expect(reads, firstReads);
          expect(
            (await Source.db.find(session)).map((x) => x.toJson()).toList(),
            sourceBefore,
          );
          expect(
            (await FinancialReport.db.find(session))
                .map((x) => x.toJson())
                .toList(),
            reportsBefore,
          );
          expect(
            (await FinancialFact.db.find(
              session,
              orderBy: (t) => t.id,
            )).map((x) => x.toJson()).toList(),
            factsBefore,
          );
          expect(
            (await DartFiling.db.findById(session, f.id!))!.toJson(),
            ledgerBefore,
          );
        },
      );
    }
  });
}
