import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 스크리너: 지표를 저장하지 않고 조회할 때 계산한다. 기업 화면과 같은 기준
/// (손익·현금흐름은 최근 12개월, 재무상태표는 최근 보고서 기말)인지 확인한다.
void main() {
  withServerpod('Given 스크리닝할 재무·시세', (sessionBuilder, endpoints) {
    late Session session;
    late Source source;
    late Company big;
    late Company small;

    Future<Company> company(String corpCode, String name, String industry) {
      final cls = KsicSeeder.classify(industry);
      return Company.db.insertRow(
        session,
        Company(
          corpCode: corpCode,
          name: name,
          market: Market.kospi,
          industryCode: industry,
          sectionCode: cls.section,
          divisionCode: cls.division,
        ),
      );
    }

    /// 보고서 하나와 그 안의 계정들. 값은 `계정 → (amount, cumulative)`.
    Future<void> report(
      Company c,
      int year,
      FinancialReportCode code,
      Map<String, (int, int?)> amounts,
    ) async {
      final r = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: c.id!,
          rceptNo: '$year${code.name}${c.id}',
          fsDiv: FsDiv.consolidated,
          bsnsYear: year,
          reportCode: code,
          reportName: '$year $code',
          factCount: amounts.length,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      FinancialStatementKind kind(String account) => switch (account) {
        'ifrs-full_Equity' ||
        'ifrs-full_EquityAttributableToOwnersOfParent' ||
        'ifrs-full_Liabilities' ||
        'ifrs-full_Assets' => FinancialStatementKind.balanceSheet,
        'ifrs-full_CashFlowsFromUsedInOperatingActivities' ||
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities' =>
          FinancialStatementKind.cashFlow,
        _ => FinancialStatementKind.incomeStatement,
      };
      await FinancialFact.db.insert(session, [
        for (final e in amounts.entries)
          FinancialFact(
            reportId: r.id!,
            companyId: c.id!,
            bsnsYear: year,
            reportCode: code,
            fsDiv: FsDiv.consolidated,
            statement: kind(e.key),
            accountId: e.key,
            accountName: e.key,
            periodName: '제 $year 기',
            amount: BigInt.from(e.value.$1),
            cumulativeAmount: e.value.$2 == null
                ? null
                : BigInt.from(e.value.$2!),
            sourceId: source.id!,
          ),
      ]);
    }

    Future<void> quote(Company c, String code, int cap) async {
      final s = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR$code',
          shortCode: code,
          name: c.name,
          market: Market.kospi,
          companyId: c.id,
          lastSeenDate: DateTime.utc(2026, 9, 16),
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: s.id!,
          baseDate: DateTime.utc(2026, 9, 16),
          closePrice: BigInt.from(1000),
          marketCap: BigInt.from(cap),
          listedShares: BigInt.from(1000),
          tradingValue: BigInt.from(5000),
          sourceId: source.id!,
        ),
      );
    }

    setUp(() async {
      session = sessionBuilder.build();
      ScreenEndpoint.clearCache();
      // 테스트는 바뀐 값을 바로 본다 (지난 계산을 먼저 주는 동작은 따로 확인).
      ScreenEndpoint.serveStaleWhileRefreshing = false;
      await KsicSeeder.seed(session);
      source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.manual,
          title: 'test',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(
          baseDate: DateTime.utc(2026, 9, 16),
          rowCount: 2,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );

      big = await company('00000001', '큰회사', '264');
      small = await company('00000002', '작은회사', '264');

      // 큰회사: 최근 보고서가 반기 → 최근 12개월 = 전년 연간 + 올해 누적 − 전년 같은 기간 누적.
      await report(big, 2025, FinancialReportCode.halfYear, {
        'ifrs-full_Revenue': (60, 120),
        'dart_OperatingIncomeLoss': (6, 12),
        'ifrs-full_ProfitLossAttributableToOwnersOfParent': (5, 10),
        // 현금흐름표는 3개월 값이 없고 amount가 곧 누적이다.
        'ifrs-full_CashFlowsFromUsedInOperatingActivities': (30, null),
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities':
            (10, null),
      });
      await report(big, 2025, FinancialReportCode.annual, {
        'ifrs-full_Revenue': (250, null),
        'dart_OperatingIncomeLoss': (25, null),
        'ifrs-full_ProfitLossAttributableToOwnersOfParent': (20, null),
        'ifrs-full_CashFlowsFromUsedInOperatingActivities': (70, null),
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities':
            (20, null),
        'ifrs-full_Equity': (400, null),
        'ifrs-full_EquityAttributableToOwnersOfParent': (380, null),
        'ifrs-full_Liabilities': (200, null),
      });
      await report(big, 2026, FinancialReportCode.halfYear, {
        'ifrs-full_Revenue': (80, 150),
        'dart_OperatingIncomeLoss': (9, 18),
        'ifrs-full_ProfitLossAttributableToOwnersOfParent': (8, 16),
        'ifrs-full_CashFlowsFromUsedInOperatingActivities': (45, null),
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities':
            (15, null),
        'ifrs-full_Equity': (500, null),
        'ifrs-full_EquityAttributableToOwnersOfParent': (480, null),
        'ifrs-full_Liabilities': (250, null),
        // 자산총계로 재무제표가 원 단위임을 확인한다 (천원으로 적는 회사가 있어,
        // 1억원을 넘는 자산총계를 본 뒤에만 시가총액과 섞는 지표를 낸다).
        'ifrs-full_Assets': (1000000000, null),
      });

      // 작은회사: 최근 보고서가 사업보고서 → 그 값이 곧 최근 12개월.
      await report(small, 2025, FinancialReportCode.annual, {
        'ifrs-full_Revenue': (100, null),
        'dart_OperatingIncomeLoss': (5, null),
        'ifrs-full_ProfitLoss': (4, null),
        'ifrs-full_Equity': (50, null),
        'ifrs-full_Liabilities': (150, null),
        'ifrs-full_Assets': (1000000000, null),
      });

      await quote(big, '000001', 1000);
      await quote(small, '000002', 40);

      await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: big.id!,
          rceptNo: 'd1',
          bsnsYear: 2025,
          section: DartSection.dividend,
          reportCode: FinancialReportCode.annual,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      final dividendReport = (await DisclosureReport.db.findFirstRow(session))!;
      await DividendEntry.db.insertRow(
        session,
        DividendEntry(
          reportId: dividendReport.id!,
          companyId: big.id!,
          bsnsYear: 2025,
          ord: 0,
          item: '현금배당금총액(백만원)',
          unit: '백만원',
          // 원으로는 2,000만원. 시가총액 1,000 대비로는 아주 큰 값이지만
          // 계산이 맞는지만 본다.
          current: 0.00002,
        ),
      );
    });

    test('최근 12개월과 최근 기말 값으로 지표를 만든다', () async {
      final page = await endpoints.screen.list(sessionBuilder);
      final rows = {for (final r in page.items) r.company.name: r};
      expect(page.universe, 2);
      expect(page.baseDate, DateTime.utc(2026, 9, 16));

      final b = rows['큰회사']!;
      // 매출 250 + 150 − 120 = 280, 영업이익 25 + 18 − 12 = 31,
      // 지배주주 순이익 20 + 16 − 10 = 26.
      expect(b.revenue, BigInt.from(280));
      expect(b.operatingIncome, BigInt.from(31));
      expect(b.netIncome, BigInt.from(26));
      // 자본·부채는 최근 보고서(2026 반기) 기말 값.
      expect(b.equity, BigInt.from(480));
      expect(b.liabilities, BigInt.from(250));
      expect(b.totalEquity, BigInt.from(500));
      expect(b.per, closeTo(1000 / 26, 1e-9));
      expect(b.pbr, closeTo(1000 / 480, 1e-9));
      expect(b.roe, closeTo(100 * 26 / 480, 1e-9));
      expect(b.operatingMargin, closeTo(100 * 31 / 280, 1e-9));
      expect(b.debtRatio, closeTo(100 * 250 / 500, 1e-9));
      // 영업활동 현금흐름 70 + 45 − 30 = 85, 유형자산 취득 20 + 15 − 10 = 25.
      expect(b.freeCashFlow, BigInt.from(60));
      expect(b.fcfYield, closeTo(100 * 60 / 1000, 1e-9));
      // 성장률은 같은 기간끼리: 매출 (150 − 120) / 120.
      expect(b.revenueGrowth, closeTo(100 * 30 / 120, 1e-9));
      expect(b.operatingIncomeGrowth, closeTo(100 * 6 / 12, 1e-9));
      expect(b.dividendTotal, BigInt.from(20));
      expect(b.dividendYield, closeTo(100 * 20 / 1000, 1e-9));

      final s = rows['작은회사']!;
      // 사업보고서가 최근이면 그 값 그대로. 지배주주 값이 없으면 전체 값을 쓴다.
      expect(s.revenue, BigInt.from(100));
      expect(s.netIncome, BigInt.from(4));
      expect(s.equity, BigInt.from(50));
      expect(s.per, closeTo(40 / 4, 1e-9));
      // 전년 자료가 없으면 성장률·FCF는 계산하지 않는다.
      expect(s.revenueGrowth, isNull);
      expect(s.freeCashFlow, isNull);
    });

    test('조건에 맞는 기업만 남기고, 정렬은 값이 없는 기업을 뒤로 보낸다', () async {
      final cheap = await endpoints.screen.list(sessionBuilder, perMax: 15);
      expect([for (final r in cheap.items) r.company.name], ['작은회사']);

      final byMargin = await endpoints.screen.list(
        sessionBuilder,
        sort: ScreenSort.operatingMargin,
      );
      expect(
        [for (final r in byMargin.items) r.company.name],
        [
          '큰회사',
          '작은회사',
        ],
      );

      final byFcf = await endpoints.screen.list(
        sessionBuilder,
        sort: ScreenSort.fcfYield,
      );
      // 작은회사는 FCF가 없어 뒤로 간다.
      expect(byFcf.items.last.company.name, '작은회사');

      final debt = await endpoints.screen.list(
        sessionBuilder,
        debtRatioMax: 100,
      );
      expect([for (final r in debt.items) r.company.name], ['큰회사']);
    });

    test('재무제표가 원 단위가 아니면 시가총액과 섞는 지표를 주지 않는다', () async {
      // 자산총계 1억 미만은 상장사일 수 없다 (천원 단위로 낸 공시).
      final tiny = await company('00000009', '천원회사', '264');
      await report(tiny, 2025, FinancialReportCode.annual, {
        'ifrs-full_Revenue': (1000, null),
        'ifrs-full_ProfitLoss': (100, null),
        'ifrs-full_Equity': (500, null),
        'ifrs-full_Assets': (800, null),
      });
      await quote(tiny, '000009', 1000000);
      final page = await endpoints.screen.list(
        sessionBuilder,
        corpCodes: ['00000009'],
      );
      final row = page.items.single;
      expect(row.per, isNull, reason: '시가총액과 단위가 달라 계산하지 않는다');
      expect(row.pbr, isNull);
      // 재무제표 안에서만 계산하는 지표는 그대로 준다.
      expect(row.revenue, BigInt.from(1000));
      expect(row.netIncome, BigInt.from(100));
    });

    test('비교는 조건을 무시하고 준 기업만 준다', () async {
      final page = await endpoints.screen.list(
        sessionBuilder,
        corpCodes: ['00000002'],
        perMax: 1,
      );
      expect([for (final r in page.items) r.company.name], ['작은회사']);
    });

    test('업종 비교는 중앙값과 순위를 준다', () async {
      // 같은 업종에 값이 있는 기업이 다섯 곳은 되어야 비교한다.
      for (final i in [4, 5, 6]) {
        final c = await company('0000000$i', '기업$i', '264');
        await report(c, 2025, FinancialReportCode.annual, {
          'ifrs-full_Revenue': (100, null),
          'dart_OperatingIncomeLoss': (20, null),
          'ifrs-full_ProfitLoss': (10, null),
          'ifrs-full_Equity': (100, null),
          'ifrs-full_Assets': (1000000000, null),
        });
        await quote(c, '00000$i', 500);
      }
      final peers = await endpoints.screen.peers(sessionBuilder, '00000001');
      expect(peers, isNotNull);
      expect(peers!.peerCount, 5);
      expect(peers.code, '264');
      final byKey = {for (final m in peers.metrics) m.key: m};
      // PER을 줄 세우면 10 · 38.46 · 50 · 50 · 50 → 가운데는 50, 큰회사는 2위.
      expect(byKey['per']!.ranked, 5);
      expect(byKey['per']!.median, closeTo(50, 1e-9));
      expect(byKey['per']!.rank, 2);
      expect(byKey['per']!.lowerIsBetter, isTrue);
      // ROE: 큰회사 5.4%, 기업4·5·6 10%, 작은회사 8% → 큰회사가 꼴찌.
      expect(byKey['roe']!.rank, 5);
      // 값이 하나뿐인 지표도 중앙값은 그 값이다.
      expect(byKey['fcfYield']!.ranked, 1);
      expect(byKey['fcfYield']!.median, closeTo(6, 1e-9));
    });

    test('재무나 시세가 바뀌면 다시 계산한다', () async {
      final before = await endpoints.screen.list(sessionBuilder);
      expect(before.universe, 2);
      await company('00000003', '새회사', '264');
      await report(
        await Company.db
            .findFirstRow(
              session,
              where: (t) => t.corpCode.equals('00000003'),
            )
            .then((c) => c!),
        2025,
        FinancialReportCode.annual,
        {'ifrs-full_Revenue': (10, null)},
      );
      final third = (await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals('00000003'),
      ))!;
      await quote(third, '000003', 5);
      final after = await endpoints.screen.list(sessionBuilder);
      expect(after.universe, 3);
    });

    test('시세에서 등락률과 52주 자리를 낸다', () async {
      // 큰회사: 400일 전 500원 → 300일 전 600원 → 100일 전 800원 → 지금 1,000원.
      // 52주 밴드는 1년 안의 값만 본다 (400일 전 500원은 밖이다).
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final source = (await Source.db.find(session)).first;
      for (final (days, price) in [(400, 500), (300, 600), (100, 800)]) {
        final date = DateTime.utc(2026, 9, 16).subtract(Duration(days: days));
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: security.id!,
            baseDate: date,
            closePrice: BigInt.from(price),
            marketCap: BigInt.from(price),
            listedShares: BigInt.from(1000),
            tradingValue: BigInt.from(price * 10),
            sourceId: source.id!,
          ),
        );
      }
      ScreenEndpoint.clearCache();

      final rows = {
        for (final r in (await endpoints.screen.list(sessionBuilder)).items)
          r.company.name: r,
      };
      final b = rows['큰회사']!;
      expect(b.closePrice, 1000);
      expect(b.return3m, closeTo(25, 1e-9), reason: '800 → 1,000');
      expect(b.return12m, closeTo(100, 1e-9), reason: '500 → 1,000');
      expect(b.high52w, 1000);
      expect(b.low52w, 600, reason: '1년 안의 최저');
      expect(b.bandPosition, closeTo(100, 1e-9), reason: '최고가에 있다');
    });

    test('주식수가 크게 바뀐 기업(액면병합 등)은 등락률을 내지 않는다', () async {
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final source = (await Source.db.find(session)).first;
      // 1년 전에는 주식수가 100배였다 (그때 종가 10원 = 지금 1,000원과 같은 값).
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: DateTime.utc(
            2026,
            9,
            16,
          ).subtract(const Duration(days: 400)),
          closePrice: BigInt.from(10),
          marketCap: BigInt.from(1000),
          listedShares: BigInt.from(100000),
          sourceId: source.id!,
        ),
      );
      ScreenEndpoint.clearCache();

      final rows = {
        for (final r in (await endpoints.screen.list(sessionBuilder)).items)
          r.company.name: r,
      };
      expect(rows['큰회사']!.return12m, isNull, reason: '10원 → 1,000원은 허수다');
    });

    test('거래대금이 적은 기업은 걸러낸다', () async {
      final all = await endpoints.screen.list(sessionBuilder);
      expect(
        all.items.map((r) => r.avgTradingValue),
        everyElement(isNotNull),
        reason: '하루 평균 거래대금',
      );
      final liquid = await endpoints.screen.list(
        sessionBuilder,
        avgTradingValueMin: BigInt.from(6000),
      );
      expect(liquid.items, isEmpty, reason: '둘 다 5,000원어치뿐이다');
    });

    test('데이터가 바뀐 뒤 첫 요청은 지난 계산을 먼저 준다', () async {
      // 뒤에서 도는 계산은 따로 연 세션이라 테스트 트랜잭션 안의 데이터를 보지 못한다.
      // 여기서는 "먼저 지난 값을 준다"만 확인하고, 계산이 끝나기를 기다린 뒤 지운다.
      ScreenEndpoint.serveStaleWhileRefreshing = true;
      try {
        final before = await endpoints.screen.list(sessionBuilder);
        expect(before.universe, 2);
        final c = await company('00000003', '새회사', '264');
        await report(c, 2025, FinancialReportCode.annual, {
          'ifrs-full_Revenue': (100, null),
          'ifrs-full_Assets': (1000000000, null),
        });
        await quote(c, '000003', 500);

        final stale = await endpoints.screen.list(sessionBuilder);
        expect(stale.universe, 2, reason: '지난 계산을 먼저 준다');
      } finally {
        ScreenEndpoint.serveStaleWhileRefreshing = false;
        await ScreenEndpoint.awaitRefresh();
        ScreenEndpoint.clearCache();
      }
    });
  });
}
