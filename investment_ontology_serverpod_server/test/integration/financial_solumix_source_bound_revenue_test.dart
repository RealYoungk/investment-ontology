import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/solumix_own_revenue_scope.dart';

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
  for (final receipt in ['20220329001197']) {
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

        final first = await run();
        expect(first.status, IngestStatus.succeeded);
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
          FilingFetchStatus.noData,
        );
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
              [
                '7196246873',
                '487642114',
                '6708604759',
                '90552276',
                '-1462706911',
                '-1469436487',
                '-847433956',
                '173072000',
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
          0,
        );
        final basisAudit = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'financial-public-basis-not-applicable:$receipt:consolidated',
          ),
        );
        expect(basisAudit, isNotNull);
        expect(jsonDecode(basisAudit!.title)['fsDiv'], 'consolidated');
        final report = reports.single;
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(
          source.title,
          SolumixOwnRevenueScope.sourceTitle(report.reportName),
        );
        final originalSourceJson = source.toJson();
        final revenue = (await FinancialFact.db.find(
          session,
          where: (t) =>
              t.reportId.equals(report.id!) &
              t.accountName.equals(SolumixOwnRevenueScope.label),
        )).single;
        final security = await Security.db.insertRow(
          session,
          Security(
            isinCode: 'KR7123456000',
            shortCode: '123456',
            name: c.name,
            market: Market.konex,
            companyId: c.id,
            lastSeenDate: now,
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: security.id!,
            baseDate: now,
            marketCap: BigInt.from(1000000000),
            closePrice: BigInt.from(10000),
            sourceId: original.id!,
          ),
        );
        await MarketSnapshotDay.db.insertRow(
          session,
          MarketSnapshotDay(
            baseDate: now,
            rowCount: 1,
            sourceId: original.id,
            fetchedAt: now,
          ),
        );
        Future<void> parity(
          bool accepted, {
          bool sourceLedgerIneligible = false,
        }) async {
          final summary = (await endpoints.financial.summary(
            builder,
            c.corpCode,
            fsDiv: FsDiv.separate,
          ))!;
          final lines = summary.periods
              .expand((p) => p.lines)
              .where((l) => l.key == 'revenue')
              .toList();
          expect(lines.length, accepted ? 1 : 0);
          if (accepted) {
            expect(lines.single.amount, SolumixOwnRevenueScope.amount);
            expect(lines.single.accountName, SolumixOwnRevenueScope.label);
            expect(lines.single.accountId, isNull);
          }
          final sql = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f.id=@id',
            parameters: QueryParameters.named({'id': revenue.id!}),
          );
          expect(sql.single.first, accepted ? 'ifrs-full_Revenue' : null);
          final page = await endpoints.screen.list(
            builder,
            corpCodes: [c.corpCode],
          );
          if (sourceLedgerIneligible) {
            // FinancialBasis requires a dartReport source with this receipt.
            // With this sole report excluded, the company has no screen row.
            expect(accepted, isFalse);
            expect(page.items, isEmpty);
          } else {
            expect(page.items, hasLength(1));
            expect(
              page.items.single.revenue,
              accepted ? SolumixOwnRevenueScope.amount : null,
            );
          }
        }

        await parity(true);
        for (final drift in ['title', 'reference', 'url', 'kind']) {
          final bad = source.copyWith();
          switch (drift) {
            case 'title':
              bad.title += ' ';
            case 'reference':
              bad.reference = '20220329001198';
            case 'url':
              bad.url = 'https://dart.fss.or.kr/foreign';
            case 'kind':
              bad.kind = SourceKind.manual;
          }
          await Source.db.updateRow(session, bad);
          await parity(
            false,
            sourceLedgerIneligible: drift == 'reference' || drift == 'kind',
          );
          await Source.db.updateRow(session, source);
        }
        final originalCompany = c.copyWith();
        c.corpCode = '00000000';
        await Company.db.updateRow(session, c);
        final wrong = await session.db.unsafeQuery(
          'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f.id=@id',
          parameters: QueryParameters.named({'id': revenue.id!}),
        );
        expect(wrong.single.first, isNull);
        await Company.db.updateRow(session, originalCompany);
        c.corpCode = originalCompany.corpCode;
        for (final drift in [
          'amount',
          'label',
          'genericRevenueLabel',
          'year',
          'basis',
          'statement',
          'owner',
          'source',
        ]) {
          final bad = revenue.copyWith();
          switch (drift) {
            case 'amount':
              bad.amount = BigInt.from(90552277);
            case 'label':
              bad.accountName = '제품매출액';
            case 'genericRevenueLabel':
              bad.accountName = '매출액';
            case 'year':
              bad.bsnsYear = 2022;
            case 'basis':
              bad.fsDiv = FsDiv.consolidated;
            case 'statement':
              bad.statement = FinancialStatementKind.cashFlow;
            case 'owner':
              bad.companyId = c.id! + 999;
            case 'source':
              bad.sourceId = original.id!;
          }
          await FinancialFact.db.updateRow(session, bad);
          await parity(false);
          await FinancialFact.db.updateRow(session, revenue);
        }
        for (final drift in ['year', 'basis', 'receipt', 'name']) {
          final bad = report.copyWith();
          switch (drift) {
            case 'year':
              bad.bsnsYear = 2022;
            case 'basis':
              bad.fsDiv = FsDiv.consolidated;
            case 'receipt':
              bad.rceptNo = '20220329001198';
            case 'name':
              bad.reportName = '사업보고서 (2022.12)';
          }
          await FinancialReport.db.updateRow(session, bad);
          await parity(
            false,
            sourceLedgerIneligible: {'year', 'receipt', 'name'}.contains(drift),
          );
          await FinancialReport.db.updateRow(session, report);
        }
        final duplicate = await FinancialFact.db.insertRow(
          session,
          revenue.copyWith(id: null),
        );
        await parity(false);
        await FinancialFact.db.deleteRow(session, duplicate);
        await parity(true);
        expect(
          (await Source.db.findById(session, source.id!))!.toJson(),
          originalSourceJson,
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
        expect(replay.status, IngestStatus.succeeded);
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
