import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';

import '../unit/public_financial_html_optional_capex_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class CapexClient extends SourceClient {
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
      throw const FormatException(
        'CFS not included in this OFS fixture regression',
      );
    }
    return actual.fetchAngio();
  }
}

void main() {
  withServerpod('Optional capex source recovery', (builder, endpoints) {
    test('seven core amounts stored; summary and screen keep capex unavailable and audit raw dash', () async {
      final session = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 2);
      final c = await Company.db.insertRow(
        session,
        Company(
          corpCode: '01115044',
          name: '(주)안지오랩',
          stockCode: '251280',
          fiscalMonth: 12,
          market: Market.konex,
        ),
      );
      final f = await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: c.id,
          corpCode: c.corpCode,
          rceptNo: '20260318000962',
          reportName: '사업보고서 (2025.12)',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          discoveredAt: now,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.noData,
        ),
      );
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = CapexClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        corpCode: c.corpCode,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(
        (await DartFiling.db.findById(session, f.id!))!.separateStatus,
        FilingFetchStatus.stored,
      );
      final facts = await FinancialFact.db.find(session);
      expect(facts.length, 7);
      expect(facts.any((x) => x.accountName.contains('유형자산')), false);
      final summary = (await FinancialEndpoint().summary(
        session,
        c.corpCode,
        fsDiv: FsDiv.separate,
      ))!;
      expect(summary.periods.single.lines.any((x) => x.key == 'capex'), false);
      expect(
        summary.periods.single.lines
            .singleWhere((x) => x.key == 'revenue')
            .amount,
        BigInt.from(2264605060),
      );
      final sources = await Source.db.find(session);
      expect(
        sources.any(
          (x) =>
              x.title.contains('unavailableOptionalAccounts') &&
              x.title.contains('Printed optional amount unavailable'),
        ),
        true,
      );
      final source = (await FinancialReport.db.find(session)).single.sourceId;
      final s = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR251280',
          shortCode: '251280',
          name: c.name,
          companyId: c.id,
          lastSeenDate: now,
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: s.id!,
          baseDate: now,
          marketCap: BigInt.from(100000000000),
          sourceId: source,
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(baseDate: now, rowCount: 1, fetchedAt: now),
      );
      final page = await ScreenEndpoint().list(
        session,
        corpCodes: [c.corpCode],
      );
      expect(page.items.single.revenue, BigInt.from(2264605060));
      expect(page.items.single.freeCashFlow, isNull);
      expect(reader.calls, 0);
    });
  });
}
