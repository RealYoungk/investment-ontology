import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

/// 스크리너: 지표를 저장하지 않고 조회할 때 계산한다. 기업 화면과 같은 기준
/// (손익·현금흐름은 최근 12개월, 재무상태표는 최근 보고서 기말)인지 확인한다.
void main() {
  withServerpod('Given 스크리닝할 재무·시세', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asReader;
    late Session session;
    late Source source;
    late Company big;
    late Company small;

    // Financial and market amounts share a 1,000만원 fixture unit.
    // The explicit thousand-won scenario below intentionally stays unscaled.
    const moneyUnit = 10000000;
    BigInt money(int value) => BigInt.from(value * moneyUnit);
    int scale(Company c) => c.corpCode == '00000009' ? 1 : moneyUnit;

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
      final receipt = '$year${code.name}${c.id}';
      final month = switch (code) {
        FinancialReportCode.annual => '12',
        FinancialReportCode.q3 => '09',
        FinancialReportCode.halfYear => '06',
        FinancialReportCode.q1 => '03',
      };
      final reportName = '정기보고서 ($year.$month)';
      final financialSource = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'bound financial fixture',
          reference: receipt,
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: receipt,
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: reportName,
          bsnsYear: year,
          reportCode: code,
          consolidatedStatus: FilingFetchStatus.stored,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      final r = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: c.id!,
          rceptNo: receipt,
          fsDiv: FsDiv.consolidated,
          bsnsYear: year,
          reportCode: code,
          reportName: reportName,
          factCount: amounts.length,
          sourceId: financialSource.id!,
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
            amount: BigInt.from(e.value.$1 * scale(c)),
            cumulativeAmount: e.value.$2 == null
                ? null
                : BigInt.from(e.value.$2! * scale(c)),
            sourceId: financialSource.id!,
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
          marketCap: BigInt.from(cap * scale(c)),
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
        // 자산 = 자본 + 부채. 금액 단위와 재무상태표 검산을 모두 통과한다.
        'ifrs-full_Assets': (750, null),
      });

      // 작은회사: 최근 보고서가 사업보고서 → 그 값이 곧 최근 12개월.
      await report(small, 2025, FinancialReportCode.annual, {
        'ifrs-full_Revenue': (100, null),
        'dart_OperatingIncomeLoss': (5, null),
        'ifrs-full_ProfitLoss': (4, null),
        'ifrs-full_Equity': (50, null),
        'ifrs-full_Liabilities': (150, null),
        'ifrs-full_Assets': (200, null),
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
          // 200백만원 = 20 fixture units.
          current: 200,
        ),
      );
    });

    Future<void> volumeHistory({
      int days = 20,
      int amount = 100,
      bool split = false,
      bool missing = false,
    }) async {
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final current = (await MarketSnapshot.db.find(
        session,
        where: (t) => t.securityId.equals(security.id!),
      )).single;
      current.volume = BigInt.from(200);
      await MarketSnapshot.db.updateRow(session, current);
      for (var i = 1; i <= days; i++) {
        final date = current.baseDate.subtract(Duration(days: i));
        await MarketSnapshotDay.db.insertRow(
          session,
          MarketSnapshotDay(
            baseDate: date,
            rowCount: 1,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: security.id!,
            baseDate: date,
            volume: missing && i == 5 ? null : BigInt.from(amount),
            listedShares: BigInt.from(split && i == 5 ? 2000 : 1000),
            closePrice: BigInt.from(1000),
            sourceId: source.id!,
          ),
        );
      }
      ScreenEndpoint.clearCache();
    }

    test('거래량은 당일을 제외한 직전 20거래일과 비교하고 모든 조건을 함께 적용한다', () async {
      await volumeHistory();
      final page = await endpoints.screen.list(
        sessionBuilder,
        volumeRatioMin: 2,
        volumeMin: BigInt.from(200),
        marketCapMin: money(1000),
      );
      expect(page.items.map((r) => r.company.name), ['큰회사']);
      expect(page.items.single.volumeRatio, 2);
      expect(page.items.single.volume, BigInt.from(200));
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          volumeRatioMin: 2.01,
        )).items,
        isEmpty,
      );
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          volumeMin: BigInt.from(201),
        )).items,
        isEmpty,
      );
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          marketCapMin: money(1001),
        )).items,
        isEmpty,
      );
    });

    test('twenty global observed dates do not fill a missing security row from the twenty-first date', () async {
      await volumeHistory(days: 21);
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final latest = DateTime.utc(2026, 9, 16);
      final missing = (await MarketSnapshot.db.find(
        session,
        where: (t) =>
            t.securityId.equals(security.id!) &
            t.baseDate.equals(latest.subtract(const Duration(days: 5))),
      )).single;
      await MarketSnapshot.db.deleteRow(session, missing);
      final page = await endpoints.screen.list(sessionBuilder);
      expect(
        page.items.firstWhere((r) => r.company.name == '큰회사').volumeRatio,
        isNull,
      );
    });

    test('holiday ledger rows and a second security cannot alter the representative twenty-session volume', () async {
      await volumeHistory(days: 21);
      final holiday = (await MarketSnapshotDay.db.find(
        session,
        where: (t) => t.baseDate.equals(DateTime.utc(2026, 9, 15)),
      )).single;
      holiday.rowCount = 0;
      await MarketSnapshotDay.db.updateRow(session, holiday);
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final holidayQuote = (await MarketSnapshot.db.find(
        session,
        where: (t) =>
            t.securityId.equals(security.id!) &
            t.baseDate.equals(holiday.baseDate),
      )).single;
      holidayQuote.volume = BigInt.from(999999);
      await MarketSnapshot.db.updateRow(session, holidayQuote);
      final other = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR_OTHER',
          shortCode: '999998',
          name: 'another security',
          companyId: big.id,
          lastSeenDate: DateTime.utc(2026, 9, 16),
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: other.id!,
          baseDate: DateTime.utc(2026, 9, 16),
          marketCap: BigInt.one,
          volume: BigInt.from(999999),
          listedShares: BigInt.one,
          sourceId: source.id!,
        ),
      );
      final page = await endpoints.screen.list(sessionBuilder);
      expect(
        page.items.firstWhere((r) => r.company.name == '큰회사').volumeRatio,
        2,
      );
    });

    for (final scenario in ['short', 'zero', 'split', 'missing']) {
      test('거래량 배수에서 $scenario 자료를 0이나 정상 값으로 대체하지 않는다', () async {
        await volumeHistory(
          days: scenario == 'short' ? 19 : 20,
          amount: scenario == 'zero' ? 0 : 100,
          split: scenario == 'split',
          missing: scenario == 'missing',
        );
        final page = await endpoints.screen.list(sessionBuilder);
        expect(
          page.items.firstWhere((r) => r.company.name == '큰회사').volumeRatio,
          isNull,
        );
        expect(
          (await endpoints.screen.list(
            sessionBuilder,
            volumeRatioMin: 0,
          )).items,
          isEmpty,
        );
      });
    }

    test('20일보다 오래된 거래량은 평균에 섞지 않는다', () async {
      await volumeHistory(days: 21);
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final oldest = (await MarketSnapshot.db.find(
        session,
        where: (t) => t.securityId.equals(security.id!),
        orderBy: (t) => t.baseDate,
      )).first;
      oldest.volume = BigInt.from(10000000);
      await MarketSnapshot.db.updateRow(session, oldest);
      ScreenEndpoint.clearCache();
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          volumeRatioMin: 2,
        )).items.single.volumeRatio,
        2,
      );
    });

    test('배당성향은 공시값을 쓰고 누락·무배당을 연속 배당으로 세지 않는다', () async {
      final dividend = (await DividendEntry.db.find(session)).single;
      dividend.prior = 1;
      dividend.beforePrior = 1;
      await DividendEntry.db.updateRow(session, dividend);
      await DividendEntry.db.insertRow(
        session,
        DividendEntry(
          reportId: dividend.reportId,
          companyId: big.id!,
          bsnsYear: 2025,
          ord: 1,
          item: '현금배당성향(%)',
          unit: '%',
          current: 40,
        ),
      );
      final page = await endpoints.screen.list(
        sessionBuilder,
        dividendPayoutMax: 40,
        dividendYearsMin: 3,
      );
      expect(page.items.map((r) => r.company.name), ['큰회사']);
      expect(page.items.single.dividendYear, 2025);
      expect(page.items.single.dividendPayout, 40);
      expect(page.items.single.dividendYears, 3);
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          dividendPayoutMax: 39,
        )).items,
        isEmpty,
      );
      for (final prior in [null, 0.0]) {
        dividend.prior = prior;
        await DividendEntry.db.updateRow(session, dividend);
        ScreenEndpoint.clearCache();
        expect(
          (await endpoints.screen.list(
            sessionBuilder,
            dividendYearsMin: 3,
          )).items,
          isEmpty,
        );
        expect(
          (await endpoints.screen.list(sessionBuilder))
              .items
              .first
              .dividendYears,
          1,
        );
      }
    });

    test('최신 연간 배당이 비어도 과거 배당으로 돌아가지 않는다', () async {
      await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: big.id!,
          rceptNo: 'd2',
          bsnsYear: 2026,
          section: DartSection.dividend,
          reportCode: FinancialReportCode.annual,
          rowCount: 0,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      ScreenEndpoint.clearCache();
      final row = (await endpoints.screen.list(sessionBuilder)).items.first;
      expect(row.dividendYear, 2026);
      expect(row.dividendYield, isNull);
      expect(row.dividendYears, isNull);
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          dividendYieldMin: 0,
        )).items,
        isEmpty,
      );
    });

    test('새 필터는 부정확한 숫자와 범위를 거부한다', () async {
      for (final request in [
        () => endpoints.screen.list(sessionBuilder, volumeRatioMin: double.nan),
        () => endpoints.screen.list(sessionBuilder, dividendYearsMin: 4),
        () => endpoints.screen.list(sessionBuilder, bandPositionMin: 101),
        () => endpoints.screen.list(sessionBuilder, return3mMin: -101),
      ]) {
        await expectLater(request(), throwsA(anything));
      }
    });

    test('최근 12개월과 최근 기말 값으로 지표를 만든다', () async {
      final page = await endpoints.screen.list(sessionBuilder);
      final rows = {for (final r in page.items) r.company.name: r};
      expect(page.universe, 2);
      expect(page.baseDate, DateTime.utc(2026, 9, 16));

      final b = rows['큰회사']!;
      // 매출 250 + 150 − 120 = 280, 영업이익 25 + 18 − 12 = 31,
      // 지배주주 순이익 20 + 16 − 10 = 26.
      expect(b.revenue, money(280));
      expect(b.operatingIncome, money(31));
      expect(b.netIncome, money(26));
      // 자본·부채는 최근 보고서(2026 반기) 기말 값.
      expect(b.equity, money(480));
      expect(b.liabilities, money(250));
      expect(b.totalEquity, money(500));
      expect(b.per, closeTo(1000 / 26, 1e-9));
      expect(b.pbr, closeTo(1000 / 480, 1e-9));
      expect(b.roe, closeTo(100 * 26 / 480, 1e-9));
      expect(b.operatingMargin, closeTo(100 * 31 / 280, 1e-9));
      expect(b.debtRatio, closeTo(100 * 250 / 500, 1e-9));
      // 영업활동 현금흐름 70 + 45 − 30 = 85, 유형자산 취득 20 + 15 − 10 = 25.
      expect(b.freeCashFlow, money(60));
      expect(b.fcfYield, closeTo(100 * 60 / 1000, 1e-9));
      // 성장률은 같은 기간끼리: 매출 (150 − 120) / 120.
      expect(b.revenueGrowth, closeTo(100 * 30 / 120, 1e-9));
      expect(b.operatingIncomeGrowth, closeTo(100 * 6 / 12, 1e-9));
      expect(b.dividendTotal, money(20));
      expect(b.dividendYield, closeTo(100 * 20 / 1000, 1e-9));

      final s = rows['작은회사']!;
      // 사업보고서가 최근이면 그 값 그대로. 지배주주 값이 없으면 전체 값을 쓴다.
      expect(s.revenue, money(100));
      expect(s.netIncome, money(4));
      expect(s.equity, money(50));
      expect(s.per, closeTo(40 / 4, 1e-9));
      // 전년 자료가 없으면 성장률·FCF는 계산하지 않는다.
      expect(s.revenueGrowth, isNull);
      expect(s.bandPosition, isNull, reason: '상장 이력 1년 미만은 52주 위치를 단정하지 않는다');
      expect(s.freeCashFlow, isNull);
    });

    test('선택 기업만 계산하고 전체 스크리너 캐시와 값을 유지한다', () async {
      ScreenEndpoint.clearCache();
      final selected = await endpoints.screen.list(
        sessionBuilder,
        corpCodes: [big.corpCode],
      );
      expect(selected.items.map((r) => r.company.corpCode), [big.corpCode]);
      expect(selected.universe, 1);
      final full = await endpoints.screen.list(sessionBuilder);
      expect(full.universe, 2, reason: '부분 조회가 전체 캐시를 채우면 안 된다');
      final reference = full.items.singleWhere(
        (r) => r.company.corpCode == big.corpCode,
      );
      expect(selected.items.single.toJson(), reference.toJson());
      expect(selected.baseDate, full.baseDate);
      final empty = await endpoints.screen.list(sessionBuilder, corpCodes: []);
      final unknown = await endpoints.screen.list(
        sessionBuilder,
        corpCodes: ["' OR true --"],
      );
      expect(empty.items, isEmpty);
      expect(unknown.items, isEmpty);
      expect((await endpoints.screen.list(sessionBuilder)).universe, 2);
    });

    test('자산과 부채·자본이 맞지 않으면 해당 재무상태 지표를 비운다', () async {
      final asset = (await FinancialFact.db.find(
        session,
        where: (t) =>
            t.companyId.equals(big.id!) &
            t.bsnsYear.equals(2026) &
            t.accountId.equals('ifrs-full_Assets'),
      )).single;
      asset.amount = money(900); // liabilities 250 + equity 500 != assets 900.
      await FinancialFact.db.updateRow(session, asset);
      final row = (await endpoints.screen.list(
        sessionBuilder,
        corpCodes: [big.corpCode],
      )).items.single;
      expect(row.equity, isNull);
      expect(row.totalEquity, isNull);
      expect(row.liabilities, isNull);
      expect(row.pbr, isNull);
      expect(row.roe, isNull);
      expect(row.debtRatio, isNull);
      expect(row.revenue, money(280));
      expect(row.operatingMargin, closeTo(100 * 31 / 280, 1e-9));
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
          'ifrs-full_Liabilities': (0, null),
          'ifrs-full_Assets': (100, null),
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
      // 큰회사: 370일 전 500원 → 300일 전 600원 → 95일 전 800원 → 지금 1,000원.
      // 52주 밴드는 1년 안의 값만 본다 (370일 전 500원은 밖이다).
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      final source = (await Source.db.find(session)).first;
      for (final (days, price) in [(370, 500), (300, 600), (95, 800)]) {
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
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          return3mMin: 25,
          return12mMin: 100,
          bandPositionMin: 100,
        )).items.map((r) => r.company.name),
        ['큰회사'],
      );
      expect(
        (await endpoints.screen.list(sessionBuilder, return3mMin: 25.1)).items,
        isEmpty,
      );
      expect(
        (await endpoints.screen.list(
          sessionBuilder,
          return12mMin: 100.1,
        )).items,
        isEmpty,
      );
    });

    test('가격 비교일보다 오래된 시세를 가까운 기준일 값처럼 쓰지 않는다', () async {
      final security = (await Security.db.find(
        session,
        where: (t) => t.shortCode.equals('000001'),
      )).single;
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: DateTime.utc(2025, 1, 1),
          closePrice: BigInt.from(500),
          listedShares: BigInt.from(1000),
          sourceId: source.id!,
        ),
      );
      ScreenEndpoint.clearCache();
      final row = (await endpoints.screen.list(sessionBuilder)).items.first;
      expect(row.return3m, isNull);
      expect(row.return12m, isNull);
      expect(row.bandPosition, isNull);
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
          ).subtract(const Duration(days: 370)),
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

    test('뒤에서 도는 계산이 실패해도 지난 계산을 주고, 다음 요청이 다시 시도한다', () async {
      var calls = 0;
      var closed = 0;
      var fail = true;
      ScreenEndpoint.serveStaleWhileRefreshing = true;
      ScreenEndpoint.refreshOverride = (s, key) async {
        calls++;
        s.addWillCloseListener((_) => closed++);
        if (fail) throw StateError('db down');
      };
      try {
        expect((await endpoints.screen.list(sessionBuilder)).universe, 2);
        final c = await company('00000003', '새회사', '264');
        await quote(c, '000003', 500);

        // 실패: 요청은 지난 계산을 받고, 실패는 밖으로 새지 않는다
        // (새면 기다리는 곳에서 던지거나 테스트 존의 처리되지 않은 오류가 된다).
        final stale = await endpoints.screen.list(sessionBuilder);
        expect(stale.universe, 2, reason: '지난 계산을 계속 준다');
        await ScreenEndpoint.awaitRefresh();
        expect(calls, 1);
        expect(closed, 1, reason: '따로 연 세션은 실패해도 닫는다');

        // 다시 시도: 실패한 계산이 자리를 비워 두어 다음 요청이 새로 돌린다.
        fail = false;
        final retry = await endpoints.screen.list(sessionBuilder);
        expect(retry.universe, 2, reason: '다시 계산하는 동안에도 지난 계산을 준다');
        await ScreenEndpoint.awaitRefresh();
        expect(calls, 2, reason: '실패 뒤 다음 요청이 다시 계산한다');
        expect(closed, 2);
      } finally {
        ScreenEndpoint.serveStaleWhileRefreshing = false;
        await ScreenEndpoint.awaitRefresh();
        ScreenEndpoint.refreshOverride = null;
        ScreenEndpoint.clearCache();
      }
    });
  });
}
