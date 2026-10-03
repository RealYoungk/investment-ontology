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
  '20220715000446': {
    'assets': '919280938907',
    'liabilities': '191490588322',
    'equity': '727790350585',
    'revenue': '811879819525',
    'operatingIncome': '793507225421',
    'netIncome': '620087515295',
    'operatingCashFlow': '2577554687',
  },
};

List<String> rowsNames(String receipt) {
  final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
  return (jsonDecode(
    File('${entry.assetDirectory}/expected-rows.json').readAsStringSync(),
  ) as List).map((r) => r['account_nm'] as String).toList();
}

void main() {
  for (final receipt in exactSevenValues.keys) {
    withServerpod('Exact OFS seven $receipt source cache', (
      builder,
      endpoints,
    ) {
      test(
        'API0 stores OFS seven and preserves failed CFS and counters',
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
              bsnsYear: 2021,
              reportCode: FinancialReportCode.annual,
              reportName: '[기재정정]사업보고서 (2021.12)',
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

          expect((await run()).updated, 1);
          final after = (await DartFiling.db.findById(session, f.id!))!;
          expect(after.separateStatus, FilingFetchStatus.stored);
          expect(after.consolidatedStatus, FilingFetchStatus.failed);
          expect(after.attempts, 7);
          expect(after.lastError, contains('attempt=3'));
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(c.id!),
          );
          expect(reports, hasLength(1));
          final report = reports.single;
          expect(report.fsDiv, FsDiv.separate);
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
            (x) => x['label'] == 'ofs',
          )['url'];
          expect(detail.source!.url, expectedUri);
          final summary = (await endpoints.financial.summary(
            builder,
            c.corpCode,
            fsDiv: FsDiv.separate,
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
          expect(mapped.where((r) => r[0] != null), hasLength(7));
          expect(
            summary.periods.single.lines
                .where((l) => l.key == 'capex')
                .every((l) => l.amount == null),
            true,
          );
          expect(
            detail.facts.map((f) => f.accountName),
            unorderedEquals(rowsNames(receipt)),
          );
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${entry.receipt}:separate',
            ),
          );
          final amountPayload = jsonDecode(amountSource!.title);
          expect(amountPayload['coreRows'], 7);
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
            amountPayload['coreRowProvenance'].every(
              (dynamic x) =>
                  x['html_provenance']['uncollectedOptionalAccounts'].single ==
                  'capex',
            ),
            true,
          );
          final coverage = await endpoints.ingest.coverage(builder.asAdmin);
          expect(
            coverage.financialFailedFilings,
            1,
          ); // CFS remains unresolved: no filing-complete claim.
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

  withServerpod('Woori OFS immutable failure audit', (builder, endpoints) {
    test(
      'SHA mismatch writes one failure audit and replay performs no raw reads',
      () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 2);
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00231664',
            name: '우리기술투자(주)',
            stockCode: '041190',
            fiscalMonth: 12,
            market: Market.kosdaq,
          ),
        );
        final f = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id!,
            corpCode: c.corpCode,
            rceptNo: '20220715000446',
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: '[기재정정]사업보고서 (2021.12)',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 7,
            lastError: 'api-noData-annual-public:attempt=3; original failure',
            discoveredAt: now,
          ),
        );
        await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-02',
            calls: 20000,
          ),
        );
        var reads = 0;
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            reads++;
            final bytes = File(path).readAsBytesSync();
            return path.endsWith('ofs.html') ? [...bytes, 32] : bytes;
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
          return (await IngestJob.db.findById(session, j.id!))!;
        }

        expect((await run()).updated, 0);
        expect(await FinancialReport.db.find(session), isEmpty);
        expect(await FinancialFact.db.find(session), isEmpty);
        final after = (await DartFiling.db.findById(session, f.id!))!;
        expect(after.consolidatedStatus, FilingFetchStatus.failed);
        expect(after.separateStatus, FilingFetchStatus.failed);
        expect(after.attempts, 7);
        expect(after.lastError, contains('attempt=3'));
        final entry = VerifiedAnnualSourceRegistry.find(
          '20220715000446',
          FsDiv.separate,
        )!;
        final audits = await Source.db.find(
          session,
          where: (t) => t.reference.equals(entry.auditReference),
        );
        expect(audits, hasLength(1));
        expect(audits.single.title, contains('failed'));
        final firstReads = reads;
        expect((await run()).updated, 0);
        expect(reads, firstReads);
        expect(
          await Source.db.find(
            session,
            where: (t) => t.reference.equals(entry.auditReference),
          ),
          hasLength(1),
        );
        expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
      },
    );
  });
}
