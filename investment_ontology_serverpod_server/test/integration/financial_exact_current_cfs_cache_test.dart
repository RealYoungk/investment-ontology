import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;

import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_current_cfs_source.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

final exactCfsValues = <String, Map<String, String>>{
  '20220317000713': {
    'assets': '4236298193122',
    'liabilities': '3148923131403',
    'equity': '1087375061719',
    'revenue': '2192007504681',
    'operatingIncome': '188406599612',
    'netIncome': '67355184309',
    'operatingCashFlow': '608989211710',
    'capex': '-135128052057',
  },
  for (final p in ExactCurrentCfsSource.profiles)
    p['receipt'] as String: {
      for (final c in p['core'] as List)
        c['role'] as String: c['amountKRW'] as String,
    },
};

List<String> rowsNames(String receipt) {
  final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.consolidated)!;
  if (receipt == '20220317000713') {
    return (jsonDecode(
      File('${entry.assetDirectory}/expected-rows.json').readAsStringSync(),
    ) as List).map((r) => r[0] as String).toList();
  }
  return (jsonDecode(
            File('${entry.assetDirectory}/current-cell-evidence.json')
                .readAsStringSync(),
          )['rows']
          as List)
      .map((r) => r['printedLabel'] as String)
      .toList();
}

void main() {
  for (final receipt in exactCfsValues.keys) {
    withServerpod('Exact CFS seven $receipt source cache', (
      builder,
      endpoints,
    ) {
      test(
        'API0 independently restores both approved bases and preserves counters',
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
          Source? existingCorrection;
          if (receipt == '20250424000405') {
            existingCorrection = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference: 'isolated-existing-correction:$receipt',
                url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
                title: 'Isolated test fixture: pre-existing same-receipt correction audit',
                retrievedAt: now,
              ),
            );
          }
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

          expect((await run()).updated, 2);
          if (existingCorrection != null) {
            expect(
              (await Source.db.findById(
                session,
                existingCorrection.id!,
              ))!.toJson(),
              existingCorrection.toJson(),
            );
          }

          final after = (await DartFiling.db.findById(session, f.id!))!;
          expect(after.consolidatedStatus, FilingFetchStatus.stored);
          expect(after.separateStatus, FilingFetchStatus.stored);
          expect(after.attempts, 7);
          expect(after.lastError, contains('attempt=3'));
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(c.id!),
          );
          expect(reports, hasLength(2));
          final report = reports.singleWhere(
            (r) => r.fsDiv == FsDiv.consolidated,
          );
          expect(report.fsDiv, FsDiv.consolidated);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(exactCfsValues[receipt]!.length));
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
          for (final e in exactCfsValues[receipt]!.entries) {
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
          expect(
            mapped.where((r) => r[0] != null),
            hasLength(exactCfsValues[receipt]!.length),
          );
          if (receipt != '20220317000713') {
            expect(
              summary.periods.single.lines
                  .where((l) => l.key == 'capex')
                  .every((l) => l.amount == null),
              true,
            );
          }
          expect(
            detail.facts.map((f) => f.accountName),
            unorderedEquals(rowsNames(receipt)),
          );
          final ofsReport = reports.singleWhere(
            (r) => r.fsDiv == FsDiv.separate,
          );
          final ofsDetail = (await endpoints.financial.report(
            builder,
            ofsReport.id!,
          ))!;
          final ofsEntry = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.separate,
          )!;
          final ofsManifest = jsonDecode(
            File('${ofsEntry.assetDirectory}/manifest.json').readAsStringSync(),
          );
          final ofsUri = (ofsManifest['sources'] as List).singleWhere(
            (s) => s['label'] == 'ofs',
          )['url'];
          expect(ofsDetail.source!.url, ofsUri);
          expect(ofsDetail.source!.url, isNot(detail.source!.url));
          expect(ofsDetail.source!.id, isNot(detail.source!.id));
          expect(
            ofsDetail.facts.every(
              (f) =>
                  f.fsDiv == FsDiv.separate &&
                  f.sourceId == ofsDetail.source!.id,
            ),
            true,
          );
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${entry.receipt}:consolidated',
            ),
          );
          final amountPayload = jsonDecode(amountSource!.title);
          expect(amountPayload['coreRows'], exactCfsValues[receipt]!.length);
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
          if (receipt != '20220317000713') {
            expect(
              amountPayload['coreRowProvenance'].every(
                (dynamic x) =>
                    x['html_provenance']['uncollectedOptionalAccounts']
                        .single ==
                    'capex',
              ),
              true,
            );
          }
          final coverage = await endpoints.ingest.coverage(builder.asAdmin);
          expect(
            coverage.financialFailedFilings,
            0,
          ); // Both approved bases restored independently; all statement rows remain partial.
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
    });
  }
}
