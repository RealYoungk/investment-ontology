import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

FinancialLine line(String key, int amount, {int? cumulative}) => FinancialLine(
  key: key,
  factId: 1,
  statement: FinancialStatementKind.incomeStatement,
  accountName: key,
  amount: BigInt.from(amount),
  cumulativeAmount: cumulative == null ? null : BigInt.from(cumulative),
);

FinancialPeriod period(
  int year,
  FinancialReportCode code,
  List<FinancialLine> lines,
) => FinancialPeriod(
  bsnsYear: year,
  reportCode: code,
  reportId: year * 10 + code.index,
  rceptNo: '${year}0000000000',
  reportName: '$year $code',
  supersededCount: 0,
  lines: lines,
);

CompanyFinancials financials(List<FinancialPeriod> periods, {BigInt? cap}) =>
    CompanyFinancials(
      corpCode: '00126380',
      fsDiv: FsDiv.consolidated,
      availableFsDivs: [FsDiv.consolidated],
      periods: periods,
      market: cap == null
          ? null
          : CompanyMarketCap(
              baseDate: DateTime.utc(2026, 9, 16),
              marketCap: cap,
              securities: [
                SecurityQuote(
                  securityId: 1,
                  shortCode: '005930',
                  name: '삼성전자',
                  marketCap: cap,
                ),
              ],
            ),
      filingCount: periods.length,
      pendingFilingCount: 0,
    );

void main() {
  group('formatKrw', () {
    test('조·억 단위', () {
      expect(formatKrw(BigInt.parse('566942110000000')), '566조 9,421억');
      expect(formatKrw(BigInt.parse('-43600000000')), '-436억');
      expect(formatKrw(BigInt.from(2000000000000)), '2조');
      expect(formatKrw(BigInt.from(12345)), '12,345원');
      expect(formatKrw(null), '—');
    });
  });

  group('formatKrwLong', () {
    test('조·억·만원까지 끝까지 적는다', () {
      expect(formatKrwLong(234903423455000), '234조 9,034억 2,345만원');
      expect(formatKrwLong(1133577000000), '1조 1,335억 7,700만원');
      expect(formatKrwLong(4500), '4,500원');
      expect(formatUnitAmount(1133577, '백만원'), '1조 1,335억 7,700만원');
      expect(formatUnitAmount(84.6, '%'), '84.6%');
    });
  });

  group('annual()의 올해 칸', () {
    test('사업보고서가 없는 해는 최근 분기·반기 누적으로, 그것도 없으면 없음', () {
      final view = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [line('revenue', 250)]),
          period(2026, FinancialReportCode.q1, [line('revenue', 60)]),
          period(2026, FinancialReportCode.halfYear, [
            line('revenue', 70, cumulative: 130),
          ]),
        ]),
      );
      final points = view.annual(now: DateTime(2026, 9, 21));
      expect(points.map((p) => p.label), ['2025', '2026 반기 누적']);
      expect(points.last.revenue.value, 130, reason: '반기 누적');

      final only = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [line('revenue', 250)]),
        ]),
      ).annual(now: DateTime(2026, 9, 21));
      expect(only.map((p) => p.label), ['2025', '2026 없음']);
      expect(only.last.revenue.value, isNull);
    });
  });

  group('FinancialView', () {
    final view = FinancialView(
      financials(
        [
          period(2024, FinancialReportCode.annual, [
            line('revenue', 1000),
            line('operatingIncome', 100),
            line('netIncomeOwners', 80),
          ]),
          period(2025, FinancialReportCode.q1, [
            line('revenue', 200),
            line('operatingIncome', 20),
            line('netIncomeOwners', 15),
            line('operatingCashFlow', 35),
            line('capex', 12),
          ]),
          period(2025, FinancialReportCode.q3, [
            line('revenue', 300, cumulative: 800),
            line('operatingIncome', 30, cumulative: 90),
          ]),
          period(2025, FinancialReportCode.annual, [
            line('revenue', 1200),
            line('operatingIncome', 110),
            line('netIncomeOwners', 90),
            line('operatingCashFlow', 150),
            line('capex', 60),
            line('equityOwners', 900),
            line('liabilities', 450),
            line('equity', 1000),
          ]),
          period(2026, FinancialReportCode.q1, [
            line('revenue', 260),
            line('operatingIncome', 40),
            line('netIncomeOwners', 30),
            line('operatingCashFlow', 40),
            line('capex', 18),
            line('equityOwners', 1000),
            line('liabilities', 500),
            line('equity', 1100),
          ]),
        ],
        cap: BigInt.from(1400),
      ),
    );

    test('분기: 1분기는 당기, 3분기는 3개월, 4분기는 연간 − 3분기 누적', () {
      final q = view.quarterly();
      expect(q.map((p) => p.label), ['25.1분기', '25.3분기', '25.4분기', '26.1분기']);
      expect(q[1].revenue.value, 300);
      expect(q[2].revenue.value, 400);
      expect(q[2].operatingIncome.value, 20);
      expect(q[2].derivedNote, contains('3분기보고서 누적'));
      expect(q[3].operatingMargin, closeTo(40 / 260, 1e-9));
    });

    test('최근 12개월: 전년 연간 + 올해 누적 − 전년 같은 기간 누적', () {
      final ttm = view.trailing('netIncomeOwners', '지배주주 순이익');
      expect(ttm.value, 90 + 30 - 15);
      expect(ttm.inputs, hasLength(3));
      expect(ttm.formula, contains('2025 사업보고서 + 2026 1분기 누적 − 2025 1분기 누적'));
    });

    test('파생 지표는 계산식과 입력값을 함께 준다', () {
      final m = {for (final x in view.metrics()) x.key: x};
      expect(m['per']!.derived.value, closeTo(1400 / 105, 1e-9));
      expect(m['per']!.derived.formula, startsWith('PER = 시가총액 ÷'));
      expect(m['pbr']!.derived.value, closeTo(1.4, 1e-9));
      expect(
        m['operatingMargin']!.derived.value,
        closeTo((110 + 40 - 20) / (1200 + 260 - 200), 1e-9),
      );
      expect(m['debtRatio']!.derived.value, closeTo(500 / 1100, 1e-9));
      expect(m['roe']!.derived.value, closeTo(105 / 1000, 1e-9));
    });

    test('잉여현금흐름은 취득액을 절댓값으로 빼고, 수익률은 시가총액으로 나눈다', () {
      final m = {for (final x in view.metrics()) x.key: x};
      // 영업활동 현금흐름 150 + 40 − 35 = 155, 유형자산 취득 60 + 18 − 12 = 66.
      expect(m['freeCashFlow']!.derived.value, closeTo(155 - 66, 1e-9));
      expect(m['fcfYield']!.derived.value, closeTo(89 / 1400, 1e-9));
      expect(
        m['freeCashFlow']!.derived.formula,
        contains('영업활동 현금흐름 − 유형자산의 취득'),
      );
    });

    test('취득액을 음수로 적는 회사도 같은 값이 나온다', () {
      final v = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [
            line('operatingCashFlow', 150),
            line('capex', -60),
          ]),
        ]),
      );
      final fcf = v.metrics().firstWhere((x) => x.key == 'freeCashFlow');
      expect(fcf.derived.value, closeTo(90, 1e-9));
    });

    test('적자면 PER을 계산하지 않고 이유를 남긴다', () {
      final loss = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [
            line('netIncomeOwners', -10),
          ]),
        ], cap: BigInt.from(100)),
      );
      final per = loss.metrics().firstWhere((x) => x.key == 'per');
      expect(per.derived.value, isNull);
      expect(per.derived.missing, contains('0 이하'));
      expect(per.display, '—');
    });

    test('3개월 금액이 따로 없으면 추측하지 않는다', () {
      final v = FinancialView(
        financials([
          period(2025, FinancialReportCode.halfYear, [line('revenue', 600)]),
        ]),
      );
      final half = v.quarterly().single;
      expect(half.revenue.value, isNull);
      expect(half.revenue.missing, contains('3개월'));
    });
  });
}
