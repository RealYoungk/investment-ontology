import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import '../unit/novmeta2021_cfs_source_cache_test.dart' show novmetaValues;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Novmeta2021 actual both-failed source cache', (
    builder,
    endpoints,
  ) {
    test(
      'API0 stores CFS whole8 once and preserves unavailable OFS and attempts',
      () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 2);
        final entry = VerifiedAnnualSourceRegistry.find(
          '20220318000715',
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
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2021.12)',
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
        expect(after.consolidatedStatus, FilingFetchStatus.stored);
        expect(after.separateStatus, FilingFetchStatus.failed);
        expect(after.attempts, 7);
        expect(after.lastError, contains('attempt=3'));
        final reports = await FinancialReport.db.find(
          session,
          where: (t) => t.companyId.equals(c.id!),
        );
        expect(reports, hasLength(1));
        final report = reports.single;
        expect(report.fsDiv, FsDiv.consolidated);
        final detail = (await endpoints.financial.report(builder, report.id!))!;
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
        for (final e in novmetaValues.entries) {
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == e.key)
                .amount,
            BigInt.parse(e.value),
          );
        }
        final amountSource = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${entry.receipt}:consolidated',
          ),
        );
        final amountPayload = jsonDecode(amountSource!.title);
        expect(amountPayload['coreRows'], 8);
        expect(
          amountPayload['coreRowProvenance'].every(
            (dynamic x) => x['html_provenance']['source'] == expectedUri,
          ),
          true,
        );
        final coverage = await endpoints.ingest.coverage(builder.asAdmin);
        expect(
          coverage.financialFailedFilings,
          1,
        ); // OFS remains unresolved: no filing-complete claim.
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
