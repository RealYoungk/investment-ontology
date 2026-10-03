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
  '20230323000123': {
    'assets': '27658110009',
    'liabilities': '15434598306',
    'equity': '12223511703',
    'revenue': '13829208123',
    'operatingIncome': '-903947084',
    'netIncome': '-1637586127',
    'operatingCashFlow': '2390809230',
  },
  '20240321000294': {
    'assets': '32828392275',
    'liabilities': '20359744746',
    'equity': '12468647529',
    'revenue': '16466985397',
    'operatingIncome': '-1076026348',
    'netIncome': '-1509318876',
    'operatingCashFlow': '-1646702373',
  },
};

List<String> rowsNames(String receipt) {
  final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.consolidated)!;
  return (jsonDecode(
            File('${entry.assetDirectory}/current-evidence.json')
                .readAsStringSync(),
          )['core']
          as List)
      .map((r) => r['label'] as String)
      .toList();
}

void main() {
  for (final receipt in exactSevenValues.keys) {
    withServerpod('Exact CFS seven $receipt source cache', (
      builder,
      endpoints,
    ) {
      test(
        'API0 restores own CFS seven and independent approved OFS without replacing either source',
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
          // Both exact original bases preserve their own independent rows.
          expect(first.status, IngestStatus.succeeded);
          expect(first.failed, 0);

          expect(first.updated, 2);
          final after = (await DartFiling.db.findById(session, f.id!))!;
          expect(after.separateStatus, FilingFetchStatus.stored);
          expect(after.consolidatedStatus, FilingFetchStatus.stored);
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
          expect(report.bsnsYear, entry.year);
          expect(report.rceptNo, entry.receipt);
          expect(report.reportCode, FinancialReportCode.annual);
          expect(report.invalidAmountCount, 0);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(7));
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
          final audit = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:$receipt:consolidated',
            ),
          );
          expect(audit, isNotNull);
          expect(audit!.url, expectedUri);
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
          expect(
            summary.periods.single.lines.where((l) => l.key == 'capex'),
            isEmpty,
          );
          final mapped = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
          );
          expect(mapped.where((r) => r[0] != null), hasLength(7));
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
          expect(amountPayload['coreRows'], 7);
          final evidence = jsonDecode(
            File('${entry.assetDirectory}/current-evidence.json')
                .readAsStringSync(),
          );
          expect(amountPayload['sha256'], evidence['sourceDigest']);
          final niRow = (amountPayload['coreRowProvenance'] as List)
              .singleWhere(
                (r) => (r['account_nm'] as String).contains('연결당기순손실'),
              );
          expect(niRow['sj_div'], entry.year == 2022 ? 'CIS' : 'IS');
          expect(
            niRow['html_provenance']['currentCell'],
            entry.year == 2022 ? '(1,637,586,127)' : '1,509,318,876',
          );
          expect(niRow['html_provenance']['sourceCellRewritten'], false);
          final proof =
              amountPayload['coreRowProvenance'][0]['html_provenance']['supportingPeriodEvidence']['scopeProof'];
          expect(proof['partialCore7'], true);
          expect(
            proof['checkedPrintedEquationCount'],
            entry.year == 2022 ? 16 : 15,
          );
          expect(proof['notesVerified'], false);
          expect(proof['optionalAccountsNotCollected'], ['capex']);
          expect(proof['fullStatementCollected'], false);
          expect(proof['FCFSupported'], false);
          expect(proof['allStatementRowsVerified'], false);
          expect(proof['fullStatementVerified'], false);
          expect(proof['priorNumericPeriodsCollected'], false);
          expect(detail.report.factCount, 7);
          expect(detail.facts.every((f) => f.ord != null), true);
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
            0,
          ); // Both independently approved own bases stored.
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
          // Both exact original bases preserve their own independent rows.
          expect(replay.status, IngestStatus.succeeded);
          expect(replay.failed, 0);

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
