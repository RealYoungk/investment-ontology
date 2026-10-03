import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  for (final receipt in ['20220321001531', '20220321000965']) {
    final basis = receipt == '20220321001531'
        ? FsDiv.consolidated
        : FsDiv.separate;
    withServerpod('Exact own2021 $receipt normal recovery', (
      builder,
      endpoints,
    ) {
      test('API0 resolves only approved basis, preserves correction and replay; opposite exhausted failure remains', () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 3);
        final e = VerifiedAnnualSourceRegistry.find(receipt, basis)!;
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: e.corpCode,
            name: e.companyName,
            stockCode: '123456',
            fiscalMonth: 12,
            market: Market.konex,
          ),
        );
        await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-03',
            calls: 20000,
          ),
        );
        final original = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: 'Existing same-receipt correction witness',
            reference: receipt,
            retrievedAt: now,
          ),
        );
        final before = original.toJson();
        final f = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id!,
            corpCode: e.corpCode,
            rceptNo: receipt,
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
            sourceCache: VerifiedAnnualSourceCache(
              readAsset: (p) => File(p).readAsBytes(),
            ),
          ).run();
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          return (await IngestJob.db.findById(session, j.id!))!;
        }

        final approvedOppositeAbsence = receipt == '20220321000965';
        final expectedJobStatus = approvedOppositeAbsence
            ? IngestStatus.succeeded
            : IngestStatus.failed;
        final first = await run();
        expect(first.status, expectedJobStatus);
        expect(first.updated, 1);
        final after = (await DartFiling.db.findById(session, f.id!))!;
        expect(after.attempts, 7);
        expect(
          basis == FsDiv.separate
              ? after.separateStatus
              : after.consolidatedStatus,
          FilingFetchStatus.stored,
        );
        expect(
          basis == FsDiv.separate
              ? after.consolidatedStatus
              : after.separateStatus,
          approvedOppositeAbsence
              ? FilingFetchStatus.noData
              : FilingFetchStatus.failed,
        );
        if (approvedOppositeAbsence) {
          final absence = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:$receipt:consolidated',
            ),
          );
          expect(absence, isNotNull);
          expect(
            jsonDecode(absence!.title)['evidence'],
            contains('연결대상 종속회사가 존재하지 않으므로'),
          );
        }
        final reports = await FinancialReport.db.find(session);
        expect(reports, hasLength(1));
        {
          final detail = (await endpoints.financial.report(
            builder,
            reports.single.id!,
          ))!;
          expect(detail.facts, hasLength(8));
          expect(
            detail.facts.every(
              (x) => x.accountId == null && x.sourceId == detail.source!.id,
            ),
            true,
          );
          expect(
            detail.facts.map((x) => x.amount.toString()),
            unorderedEquals(
              receipt == '20220321001531'
                  ? [
                      '8387016308',
                      '16001740077',
                      '-7614723769',
                      '776151780',
                      '-2712686801',
                      '-5927862041',
                      '-1846980891',
                      '405214346',
                    ]
                  : [
                      '16231577744',
                      '1706431782',
                      '14525145962',
                      '5934446253',
                      '651728876',
                      '-771791959',
                      '1030287321',
                      '190134090',
                    ],
            ),
          );
          expect(detail.report.fsDiv, basis);
          final audit = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:$receipt:${basis.name}',
            ),
          );
          final payload = jsonDecode(audit!.title) as Map;
          expect(payload['coreRows'], 8);
          for (final row in payload['coreRowProvenance'] as List) {
            final provenance = row['html_provenance'] as Map;
            expect(
              provenance['filingSeriesIdentity']['identityScope'],
              'official-DART-filing-series-only',
            );
            expect(
              provenance['filingSeriesIdentity']['jurirContinuityVerified'],
              false,
            );
            expect(
              provenance['filingSeriesIdentity']['operatingHistoryContinuityVerified'],
              false,
            );
            expect(provenance['fullStatementCollected'], false);
          }
          final summary = (await endpoints.financial.summary(
            builder,
            c.corpCode,
            fsDiv: basis,
          ))!;
          expect(
            summary.periods.single.lines.where((x) => x.amount != null),
            hasLength(8),
          );
        }
        expect(
          (await Source.db.findById(session, original.id!))!.toJson(),
          before,
        );
        expect(
          (await endpoints.ingest.coverage(builder.asAdmin))
              .financialFailedFilings,
          approvedOppositeAbsence ? 0 : 1,
        );
        final sources = (await Source.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList();
        final facts = (await FinancialFact.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList();
        final replay = await run();
        expect(replay.updated, 0);
        expect(replay.status, expectedJobStatus);
        expect(
          (await Source.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          sources,
        );
        expect(
          (await FinancialFact.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          facts,
        );
        expect(
          (await DartFiling.db.findById(session, f.id!))!.toJson(),
          after.toJson(),
        );
      });
    });
  }
}
