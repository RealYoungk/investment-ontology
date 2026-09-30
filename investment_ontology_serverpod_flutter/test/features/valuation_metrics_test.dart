import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/metric_profile.dart';

import 'financial_metrics_test.dart' as f;

Map<String, DerivedMetric> calculate(List<FinancialPeriod> periods) => {
  for (final m in FinancialView(
    f.financials(periods, cap: BigInt.from(10000)),
  ).metrics())
    m.key: m,
};
void main() {
  test('conflicted source balances are masked and retain the exact reason', () {
    const reason = '자산·부채·자본 합계 불일치 · 원천 공시 확인 필요';
    final raw = f.line('assets', 0).copyWith(unavailableReason: reason);
    final period = f.period(2025, FinancialReportCode.annual, [
      raw,
      f.line('netIncome', 100),
      f.line('operatingIncome', 150),
    ]);
    final safe = FinancialView.line(period, 'assets')!;
    expect(safe.amount, isNull);
    expect(safe.cumulativeAmount, isNull);
    expect(safe.unavailableReason, reason);
    expect(raw.amount, BigInt.zero);
    final m = calculate([period]);
    for (final key in ['per', 'por', 'fcfYield']) {
      expect(m[key]!.derived.value, isNull);
      expect(m[key]!.derived.missing, reason);
    }
  });
  test(
    'foreign currency ratios retain units and never mix with won market cap',
    () {
      final data = f.financials([
        f.period(2025, FinancialReportCode.annual, [
          for (final item in {
            'assets': 1000000000,
            'equity': 1000,
            'netIncome': 100,
            'cash': 500,
          }.entries)
            f.line(item.key, item.value).copyWith(currency: 'USD'),
        ]),
      ], cap: BigInt.from(10000));
      final m = {for (final v in FinancialView(data).metrics()) v.key: v};
      expect(m['roe']!.derived.value, .1);
      expect(m['per']!.derived.value, isNull);
      expect(m['per']!.derived.missing, contains('통화 불일치'));
      expect(m['cash']!.display, '500 USD');
      expect(m['cash']!.derived.inputs.single.currency, 'USD');
    },
  );
  test('TTM refuses mixed reporting currencies', () {
    final data = f.financials([
      f.period(2024, FinancialReportCode.halfYear, [
        f.line('revenue', 10, cumulative: 10).copyWith(currency: 'USD'),
      ]),
      f.period(2024, FinancialReportCode.annual, [
        f.line('revenue', 100).copyWith(currency: 'KRW'),
      ]),
      f.period(2025, FinancialReportCode.halfYear, [
        f.line('revenue', 30, cumulative: 30).copyWith(currency: 'USD'),
      ]),
    ]);
    final value = FinancialView(data).trailing('revenue', '매출');
    expect(value.value, isNull);
    expect(value.missing, contains('통화 불일치'));
  });

  test('capex TTM normalizes each filing sign before subtraction', () {
    final view = FinancialView(
      f.financials([
        f.period(2024, FinancialReportCode.halfYear, [
          f.line('capex', 30, cumulative: 30),
        ]),
        f.period(2024, FinancialReportCode.annual, [f.line('capex', -100)]),
        f.period(2025, FinancialReportCode.halfYear, [
          f.line('capex', 40, cumulative: 40),
        ]),
      ]),
    );
    expect(view.trailing('capex', '유형자산 취득').value, 110);
    expect(view.trailing('capex', '유형자산 취득').formula, contains('절댓값'));
    final invalid = FinancialView(
      f.financials([
        f.period(2024, FinancialReportCode.halfYear, [
          f.line('capex', 30, cumulative: 30),
        ]),
        f.period(2024, FinancialReportCode.annual, [f.line('capex', 20)]),
        f.period(2025, FinancialReportCode.halfYear, [
          f.line('capex', 0, cumulative: 0),
        ]),
      ]),
    ).trailing('capex', '유형자산 취득');
    expect(invalid.value, isNull);
    expect(invalid.missing, contains('기간별 금액 불일치'));
  });

  test('invalid market cap and absent financials have explicit reasons', () {
    final zero = FinancialView(
      f.financials([
        f.period(2025, FinancialReportCode.annual, [f.line('netIncome', 10)]),
      ], cap: BigInt.zero),
    ).metrics();
    for (final key in ['marketCap', 'per', 'psr', 'fcfYield']) {
      final metric = zero.singleWhere((m) => m.key == key);
      expect(metric.derived.value, isNull);
      expect(metric.derived.missing, isNotEmpty);
      expect(metric.display, '—');
    }
    final absent = FinancialView(f.financials([])).metrics();
    expect(
      absent.singleWhere((m) => m.key == 'per').derived.missing,
      '재무 자료 없음',
    );
  });

  test('price, cash and returns have different denominators; no invented EV or PEG', () {
    final m = calculate([
      f.period(2025, FinancialReportCode.annual, [
        f.line('revenue', 1000),
        f.line('operatingIncome', 100),
        f.line('netIncome', 50),
        f.line('operatingCashFlow', 200),
        f.line('capex', -80),
        f.line('cash', 500),
      ]),
    ]);
    expect(m['psr']!.derived.value, 10);
    expect(m['por']!.derived.value, 100);
    expect(m['pcf']!.derived.value, 50);
    expect(m['capexRatio']!.derived.value, .08);
    expect(m['ocfMargin']!.derived.value, .2);
    expect(m['evEbitda']!.derived.value, isNull);
    expect(m['evEbitda']!.derived.missing, contains('차입금'));
    expect(m['peg']!.derived.value, isNull);
  });
  test('TTM growth aligns prior interim rather than using earlier annual or quarter', () {
    final m = calculate([
      f.period(2023, FinancialReportCode.annual, [f.line('revenue', 800)]),
      f.period(2024, FinancialReportCode.halfYear, [
        f.line('revenue', 10, cumulative: 400),
      ]),
      f.period(2024, FinancialReportCode.annual, [f.line('revenue', 1000)]),
      f.period(2025, FinancialReportCode.halfYear, [
        f.line('revenue', 20, cumulative: 600),
      ]),
    ]);
    // 2025 TTM 1200 vs 2024 TTM 800 +400 - missing 2023 H1.
    expect(m['revenueGrowth']!.derived.value, isNull);
    expect(m['revenueGrowth']!.derived.missing, contains('2023 반기'));
  });
  test('annual growth 20%, loss/zero bases are not growth, incomplete data not loss', () {
    final m = calculate([
      f.period(2024, FinancialReportCode.annual, [
        f.line('revenue', 100),
        f.line('netIncome', -20),
      ]),
      f.period(2025, FinancialReportCode.annual, [
        f.line('revenue', 120),
        f.line('netIncome', 20),
      ]),
    ]);
    expect(m['revenueGrowth']!.derived.value, closeTo(.2, 1e-9));
    expect(m['profitGrowth']!.derived.value, isNull);
    expect(
      MetricProfile.forCompany('62010', '소프트웨어', m.values.toList()).title,
      contains('사업 성장'),
    );
  });
  test('DA combined total wins, does not double count components; EV requires debt scope', () {
    final m = calculate([
      f.period(2025, FinancialReportCode.annual, [
        f.line('operatingIncome', 100),
        f.line('depreciationAmortisation', 50),
        f.line('depreciation', 40),
        f.line('amortisation', 10),
        f.line('interestDebtIncludingLeases', 200),
        f.line('noncontrollingInterest', 30),
        f.line('cash', 300),
      ]),
    ]);
    expect(m['ebitda']!.derived.value, 150);
    expect(
      m['evEbitda']!.derived.value,
      closeTo((10000 + 200 + 30 - 300) / 150, 1e-9),
    );
    expect(m['evOperating']!.derived.value, 99.3);
  });
  test(
    'missing amortisation is not zero; negative EBITDA cannot yield a multiple',
    () {
      var m = calculate([
        f.period(2025, FinancialReportCode.annual, [
          f.line('operatingIncome', 100),
          f.line('depreciation', 50),
        ]),
      ]);
      expect(m['ebitda']!.derived.value, isNull);
      m = calculate([
        f.period(2025, FinancialReportCode.annual, [
          f.line('operatingIncome', -100),
          f.line('depreciationAmortisation', 50),
          f.line('interestDebtIncludingLeases', 0),
          f.line('noncontrollingInterest', 0),
          f.line('cash', 10),
        ]),
      ]);
      expect(m['evEbitda']!.derived.value, isNull);
      expect(m['evEbitda']!.derived.missing, 'EBITDA 0 이하');
    },
  );
  test('industry selects readable relevant metrics, loss selection requires actual loss', () {
    final empty = calculate([]).values.toList();
    expect(
      MetricProfile.forCompany('64121', '은행', empty).keys,
      containsAll(['pbr', 'roe']),
    );
    expect(
      MetricProfile.forCompany('64121', '은행', empty).keys,
      isNot(contains('evEbitda')),
    );
    expect(
      MetricProfile.forCompany('26299', '제조업', empty).keys,
      contains('capexRatio'),
    );
    expect(
      MetricProfile.forCompany('62010', '기업', empty).title,
      isNot(contains('적자')),
    );
    final loss = calculate([
      f.period(2025, FinancialReportCode.annual, [f.line('netIncome', -10)]),
    ]).values.toList();
    expect(
      MetricProfile.forCompany('21101', '바이오', loss).keys,
      containsAll(['psr', 'cash']),
    );
    expect(
      MetricProfile.forCompany('68112', '테스트리츠', loss).title,
      contains('자산 운용'),
    );
  });
}
