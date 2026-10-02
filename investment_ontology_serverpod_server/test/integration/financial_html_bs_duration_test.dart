import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';

import '../unit/public_financial_html_bs_duration_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class DurationClient extends SourceClient {
  DurationClient(this.index);
  final int index;
  @override
  Future<PublicFinancialHtmlSource> fetchAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    if (consolidated) {
      throw const FormatException('CFS excluded from OFS source regression');
    }
    return actual.actualSource(index);
  }
}

void main() {
  withServerpod('BS annual duration source recovery', (
    builder,
    endpoints,
  ) {
    for (var i = 0; i < 2; i++) {
      final index = i;
      final a = index == 0
          ? ('20250318000596', '01352575', '바이오텐(주)', 2024)
          : ('20260320001385', '00925967', '(주)이엠티', 2025);
      test(
        '${a.$1} normal ingest stores exact OFS rows and audit API0',
        () async {
          final session = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 2);
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: a.$2,
              name: a.$3,
              stockCode: '000001',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          final f = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: c.id,
              corpCode: a.$2,
              rceptNo: a.$1,
              reportName: '사업보고서 (${a.$4}.12)',
              bsnsYear: a.$4,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
              discoveredAt: now,
            ),
          );
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final reader = DurationClient(index);
          await FinancialFactsSync(
            session,
            reader,
            j.id!,
            dailyBudget: 0,
            corpCode: c.corpCode,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(
            (await DartFiling.db.findById(session, f.id!))!.separateStatus,
            FilingFetchStatus.stored,
          );
          final expected = actual.actualSource(index).rows;
          final facts = await FinancialFact.db.find(session);
          expect(facts.length, expected.length);
          for (final row in expected) {
            final fact = facts.singleWhere(
              (v) => v.accountName == row['account_nm'],
            );
            expect(fact.amount, BigInt.parse(row['thstrm_amount'] as String));
            expect(fact.accountId, isNull);
          }
          final summary = (await FinancialEndpoint().summary(
            session,
            c.corpCode,
            fsDiv: FsDiv.separate,
          ))!;
          expect(summary.periods.single.lines.length, greaterThanOrEqualTo(7));
          expect(
            (await Source.db.find(session))
                .any((s) => s.title.contains('printedCurrentCells')),
            true,
          );
          final mapped = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} AS account FROM financial_fact f WHERE f."companyId"=${c.id}',
          );
          expect(mapped.where((r) => r[0] != null).length, expected.length);
          final reports = await FinancialReport.db.find(session);
          final priceSource = (await Source.db.findById(
            session,
            reports.single.sourceId,
          ))!;
          final security = await Security.db.insertRow(
            session,
            Security(
              isinCode: 'KR7000000009',
              lastSeenDate: now,
              shortCode: '000001',
              name: c.name,
              market: Market.konex,
              companyId: c.id,
            ),
          );
          await MarketSnapshot.db.insertRow(
            session,
            MarketSnapshot(
              securityId: security.id!,
              baseDate: now,
              marketCap: BigInt.from(1000000000000),
              sourceId: priceSource.id!,
            ),
          );
          await MarketSnapshotDay.db.insertRow(
            session,
            MarketSnapshotDay(baseDate: now, rowCount: 1, fetchedAt: now),
          );
          final screen = await ScreenEndpoint().list(
            session,
            corpCodes: [c.corpCode],
          );
          expect(
            screen.items.single.revenue,
            BigInt.from(index == 0 ? 5487917430 : 36396610263),
          );
          expect(
            screen.items.single.operatingIncome,
            BigInt.from(index == 0 ? -915886780 : 4871967882),
          );
          expect(
            screen.items.single.netIncome,
            BigInt.from(index == 0 ? -1203958296 : 2683100337),
          );
          expect(reader.calls, 0);
        },
      );
    }
  });
}
