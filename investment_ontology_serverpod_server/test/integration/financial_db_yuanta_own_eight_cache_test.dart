import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

const exactSevenValues = {
  '20220316001241': {
    'assets': '9583673039437',
    'liabilities': '8535236408583',
    'equity': '1048436630854',
    'revenue': '1410732861048',
    'operatingIncome': '169597211231',
    'netIncome': '126818163372',
    'operatingCashFlow': '-197242734468',
    'capex': '6841895429',
  },
  '20230314000094': {
    'assets': '13419879837000',
    'liabilities': '11862753297000',
    'equity': '1557126540000',
    'revenue': '2479008315000',
    'operatingIncome': '43311171000',
    'netIncome': '45073044000',
    'operatingCashFlow': '517965843000',
    'capex': '7626293000',
  },
};

List<String> rowsNames(String receipt) {
  final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.consolidated)!;
  return (jsonDecode(
    File('${entry.assetDirectory}/current-cell-evidence.json')
        .readAsStringSync(),
  ) as Map)['core'].map<String>((r) => r['printedLabel'] as String).toList();
}

void main() {
  for (final receipt in exactSevenValues.keys) {
    withServerpod('Exact CFS eight $receipt source cache', (
      builder,
      endpoints,
    ) {
      test(
        'API0 stores exact CFS eight; approved DB OFS recovers independently; replay preserves original Source and counters',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final entry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.consolidated,
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
          final sourceManifest = jsonDecode(
            File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
          );
          final ownCover = (sourceManifest['sources'] as List).singleWhere(
            (v) => v['label'] == 'cover',
          );
          final correctionSource = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title:
                  'Existing same-receipt correction cover SHA256:${ownCover['sha256']}',
              reference: entry.receipt,
              url: ownCover['url'],
              retrievedAt: now.subtract(const Duration(days: 1)),
            ),
          );
          final correctionBefore = correctionSource.toJson();
          final f = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: c.id!,
              corpCode: c.corpCode,
              rceptNo: entry.receipt,
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
          var reads = 0;
          final cache = VerifiedAnnualSourceCache(
            readAsset: (path) async {
              reads++;
              return File(path).readAsBytes();
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

          final first = await run();
          // The opposite basis remains exhausted and incomplete.
          expect(
            first.status,
            receipt == '20220316001241'
                ? IngestStatus.succeeded
                : IngestStatus.failed,
          );
          expect(first.failed, 0);
          if (receipt != '20220316001241') {
            expect(first.message, contains('재시도 한도에 도달한 미완료 1건'));
          }
          expect(first.updated, receipt == '20220316001241' ? 2 : 1);
          final after = (await DartFiling.db.findById(session, f.id!))!;
          expect(after.consolidatedStatus, FilingFetchStatus.stored);
          expect(
            after.separateStatus,
            receipt == '20220316001241'
                ? FilingFetchStatus.stored
                : FilingFetchStatus.failed,
          );
          expect(after.attempts, 7);
          if (receipt != '20220316001241') {
            expect(after.lastError, contains('attempt=3'));
          }
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(c.id!),
          );
          expect(reports, hasLength(receipt == '20220316001241' ? 2 : 1));
          final report = reports.singleWhere(
            (r) => r.fsDiv == FsDiv.consolidated,
          );
          expect(reports.every((r) => r.factCount >= 7), true);
          expect(report.fsDiv, FsDiv.consolidated);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(8));
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
            (x) => x['label'] == 'cfs',
          )['url'];
          expect(detail.source!.url, expectedUri);
          final summary = (await endpoints.financial.summary(
            builder,
            c.corpCode,
            fsDiv: FsDiv.consolidated,
          ))!;
          for (final e in exactSevenValues[receipt]!.entries) {
            expect(
              summary.periods.single.lines
                  .singleWhere((l) => l.key == e.key)
                  .amount,
              BigInt.parse(e.value),
            );
          }
          final mapped = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
          );
          expect(mapped.where((r) => r[0] != null), hasLength(8));
          expect(
            detail.facts.map((f) => f.accountName),
            unorderedEquals(rowsNames(receipt)),
          );
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${entry.receipt}:consolidated',
            ),
          );
          final amountPayload = jsonDecode(amountSource!.title);
          expect(amountPayload['coreRows'], 8);
          final proof =
              amountPayload['coreRowProvenance'][0]['html_provenance']['supportingPeriodEvidence'];
          expect(proof['currentEquationWitnesses'], hasLength(8));
          expect(detail.report.factCount, 8);
          expect(
            amountPayload['coreRowProvenance'].every(
              (dynamic x) => x['html_provenance']['source'] == expectedUri,
            ),
            true,
          );
          expect(
            amountPayload['coreRowProvenance'].every(
              (dynamic x) =>
                  x['html_provenance']['fullStatementCollected'] == false,
            ),
            true,
          );
          expect(
            (await Source.db.findById(session, correctionSource.id!))!.toJson(),
            correctionBefore,
          );
          final coverage = await endpoints.ingest.coverage(builder.asAdmin);
          expect(
            coverage.financialFailedFilings,
            receipt == '20220316001241' ? 0 : 1,
          ); // OFS conflicting title remains unresolved: no filing-complete claim.
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
          final replay = await run();
          // The opposite basis remains exhausted and incomplete.
          expect(
            replay.status,
            receipt == '20220316001241'
                ? IngestStatus.succeeded
                : IngestStatus.failed,
          );
          expect(replay.failed, 0);
          if (receipt != '20220316001241') {
            expect(replay.message, contains('재시도 한도에 도달한 미완료 1건'));
          }
          expect(replay.updated, 0);
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
    });
  }
}
