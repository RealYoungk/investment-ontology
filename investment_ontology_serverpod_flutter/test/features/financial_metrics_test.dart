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
  lines: [
    if (!lines.any((l) => l.key == 'assets')) line('assets', 1000000000),
    ...lines,
  ],
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
  test('latest uses actual closing month rather than FY or later correction receipt', () {
    final march = period(2026, FinancialReportCode.annual, [
      line('revenue', 300),
    ])..reportName = '사업보고서 (2026.03)';
    final june = period(2026, FinancialReportCode.halfYear, [
      line('revenue', 600),
    ])..reportName = '반기보고서 (2026.06)';
    final correction =
        period(2026, FinancialReportCode.annual, [line('revenue', 301)])
          ..reportName = '[기재정정]사업보고서 (2026.03)'
          ..rceptNo = '20261231000001';
    final metrics = FinancialView(financials([june, march, correction]));
    expect(metrics.latest, same(june));
    expect(metrics.latestInterim(), same(june));
    final december = period(2026, FinancialReportCode.annual, [
      line('revenue', 1200),
    ])..reportName = '사업보고서 (2026.12)';
    expect(
      FinancialView(financials([december, june, correction])).latest,
      same(december),
    );
  });

  test(
    'known 364 and 367 day annual ranges cannot represent twelve months',
    () {
      for (final name in [
        '2026.01.02 ~ 2026.12.31 (364일)',
        '2025.12.30 ~ 2026.12.31 (367일)',
      ]) {
        final annual = period(2026, FinancialReportCode.annual, [
          line('revenue', 1200),
        ])..periodName = name;
        expect(
          FinancialView(financials([annual])).trailing('revenue', '매출').missing,
          contains('12개월 기간 아님'),
        );
      }
    },
  );

  test('verified 90-day annual and unknown partial periods block TTM, growth and Q4 but preserve reported balances', () {
    for (final name in ['2026.01.01 ~ 2026.03.31 (90일)', '원문 보고기간 확인 필요']) {
      final annual = period(2026, FinancialReportCode.annual, [
        line('revenue', 90),
        line('netIncome', 9),
        line('operatingIncome', 18),
      ]).copyWith(periodName: name);
      final view = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [
            line('revenue', 365),
            line('netIncome', 36),
          ]),
          period(2026, FinancialReportCode.q3, [
            line('revenue', 60, cumulative: 60),
          ]),
          annual,
        ]),
      );
      expect(view.trailing('revenue', '매출액').value, isNull);
      expect(
        view.trailing('revenue', '매출액').missing,
        contains(name.contains('90일') ? '90일' : '기간 확인 필요'),
      );
      expect(
        view
            .trailingSeries('revenue')
            .where(
              (p) => p.year == 2026 && p.code == FinancialReportCode.annual,
            ),
        isEmpty,
      );
      final q4 = view.quarterly().singleWhere((p) => p.label == '26.4분기');
      expect(q4.revenue.value, isNull);
      expect(q4.revenue.missing, contains('4분기'));
      expect(
        view
            .metrics()
            .singleWhere((m) => m.key == 'revenueGrowth')
            .derived
            .value,
        isNull,
      );
      expect(
        view
            .metrics()
            .singleWhere((m) => m.key == 'revenueGrowth')
            .derived
            .missing,
        contains('계산 불가'),
      );
      expect(FinancialView.line(annual, 'revenue')!.amount, BigInt.from(90));
      expect(view.latestBalance('assets', '자산').value, 1000000000);
    }
  });
  test('verified full 365 or 366 day annual preserves TTM; short prior annual cannot seed interim TTM', () {
    for (final p in [
      period(2026, FinancialReportCode.annual, [
        line('revenue', 365),
      ]).copyWith(periodName: '2026.01.01 ~ 2026.12.31 (365일)'),
      period(2024, FinancialReportCode.annual, [
        line('revenue', 366),
      ]).copyWith(periodName: '2024.01.01 ~ 2024.12.31 (366일)'),
    ]) {
      expect(
        FinancialView(financials([p])).trailing('revenue', '매출액').value,
        FinancialView.line(p, 'revenue')!.amount!.toDouble(),
      );
    }
    final view = FinancialView(
      financials([
        period(2025, FinancialReportCode.annual, [
          line('revenue', 90),
        ]).copyWith(periodName: '2025.01.01 ~ 2025.03.31 (90일)'),
        period(2025, FinancialReportCode.halfYear, [
          line('revenue', 20, cumulative: 40),
        ]),
        period(2026, FinancialReportCode.halfYear, [
          line('revenue', 30, cumulative: 60),
        ]),
      ]),
    );
    expect(view.trailing('revenue', '매출액').value, isNull);
    expect(view.trailing('revenue', '매출액').missing, contains('90일'));
  });

  test(
    'IPO TTM uses filed prior comparison without inventing an old report',
    () {
      final half = line('revenue', 55, cumulative: 120)
        ..priorSameCumulativeAmount = BigInt.from(48);
      final view = FinancialView(
        financials([
          period(2025, FinancialReportCode.annual, [line('revenue', 133)]),
          period(2026, FinancialReportCode.halfYear, [half]),
        ]),
      );
      expect(view.trailing('revenue', '매출액').value, 205);
      expect(
        view.trailing('revenue', '매출액').inputs.last.basis,
        contains('전년 동기 비교열'),
      );
      expect(view.trailingSeries('revenue').last.value, 205);
      expect(view.period(2025, FinancialReportCode.halfYear), isNull);
    },
  );

  test('own-period filing wins over the later comparison column', () {
    final half = line('revenue', 55, cumulative: 120)
      ..priorSameCumulativeAmount = BigInt.from(48);
    final view = FinancialView(
      financials([
        period(2025, FinancialReportCode.halfYear, [
          line('revenue', 30, cumulative: 50),
        ]),
        period(2025, FinancialReportCode.annual, [line('revenue', 133)]),
        period(2026, FinancialReportCode.halfYear, [half]),
      ]),
    );
    expect(view.trailing('revenue', '매출액').value, 203);
  });

  test('comparison fallback still rejects mixed currencies', () {
    final half = line('revenue', 55, cumulative: 120)
      ..priorSameCumulativeAmount = BigInt.from(48)
      ..currency = 'USD';
    final view = FinancialView(
      financials([
        period(2025, FinancialReportCode.annual, [
          line('revenue', 133)..currency = 'KRW',
        ]),
        period(2026, FinancialReportCode.halfYear, [half]),
      ]),
    );
    expect(view.trailing('revenue', '매출액').value, isNull);
    expect(view.trailing('revenue', '매출액').missing, contains('통화 불일치'));
  });

  test(
    'summary amounts compact verified KRW units and retain source precision',
    () {
      expect(formatUnitAmountCompact(41216512, '백만원'), '41.2조원');
      expect(formatUnitAmountCompact(41216512000000, '원'), '41.2조원');
      expect(formatUnitAmountCompact(41.216512, '조원'), '41.2조원');
      expect(formatUnitAmountCompact(-123450, '백만원'), '-1234.5억원');
      expect(formatUnitAmountCompact(0, '원'), '0원');
      expect(formatUnitAmountCompact(4500, '원'), '4,500원');
      expect(formatUnitAmountCompact(84.6, '%'), '84.6%');
      expect(formatUnitAmountCompact(123, '백만 달러'), '123백만 달러');
      expect(formatUnitAmountCompact(double.nan, '원'), '—');
      expect(formatSourceAmount(41216512.123, '백만원'), '41,216,512.123 백만원');
    },
  );
  FinancialLine cashLine(String key, int amount, {String currency = 'KRW'}) =>
      line(key, amount)
        ..statement = FinancialStatementKind.cashFlow
        ..currency = currency;

  group('분기 현금흐름', () {
    test('누적 공시를 3개월로 차감하고 취득액 부호는 차감 전에 정규화한다', () {
      final view = FinancialView(
        financials([
          period(2025, FinancialReportCode.q1, [
            cashLine('operatingCashFlow', 10),
            cashLine('capex', 0),
          ]),
          period(2025, FinancialReportCode.halfYear, [
            cashLine('operatingCashFlow', -10),
            cashLine('capex', -30),
          ]),
          period(2025, FinancialReportCode.q3, [
            cashLine('operatingCashFlow', 20),
            cashLine('capex', 50),
          ]),
          period(2025, FinancialReportCode.annual, [
            cashLine('operatingCashFlow', 5),
            cashLine('capex', -80),
          ]),
          period(2026, FinancialReportCode.q1, [
            cashLine('operatingCashFlow', 8),
            cashLine('capex', -3),
          ]),
        ]),
      );
      final points = view.cashFlowQuarterly();
      expect(points.map((p) => p.label), [
        '25.1분기',
        '25.2분기',
        '25.3분기',
        '25.4분기',
        '26.1분기',
      ]);
      expect(points.map((p) => p.operating), [10, -20, 30, -15, 8]);
      expect(points.map((p) => p.capex), [0, 30, 20, 30, 3]);
      expect(points.map((p) => p.free), [10, -50, 10, -45, 5]);
      expect(points.every((p) => p.missing == null), isTrue);
      expect(points.take(4).fold<double>(0, (sum, p) => sum + p.free!), -75);
    });

    test('직전 보고서·계정이 없으면 누적값을 분기로 쓰거나 0으로 채우지 않는다', () {
      final data = financials([
        period(2025, FinancialReportCode.halfYear, [
          cashLine('operatingCashFlow', 100),
        ]),
        period(2025, FinancialReportCode.q3, [
          cashLine('operatingCashFlow', 120),
          cashLine('capex', 30),
        ]),
      ])..fsDiv = FsDiv.separate;
      final points = FinancialView(data).cashFlowQuarterly();
      expect(points.first.operating, isNull);
      expect(points.first.free, isNull);
      expect(points.first.missing, contains('2025 1분기 영업현금 누적값 없음'));
      expect(points.last.operating, 20);
      expect(points.last.capex, isNull);
      expect(points.last.free, isNull);
      expect(points.last.missing, contains('2025 반기 유형자산 취득 누적값 없음'));
      final annualOnly = FinancialView(
        financials([
          period(2024, FinancialReportCode.annual, [
            cashLine('operatingCashFlow', 120),
            cashLine('capex', 30),
          ]),
        ]),
      ).cashFlowQuarterly().single;
      expect(annualOnly.operating, isNull);
      expect(annualOnly.missing, contains('2024 3분기'));
    });

    test('통화 변경·취득 누적액 감소·원천 충돌은 계산하지 않고 이유를 남긴다', () {
      final points = FinancialView(
        financials([
          period(2025, FinancialReportCode.q1, [
            cashLine('operatingCashFlow', 10, currency: 'USD'),
            cashLine('capex', 30),
          ]),
          period(2025, FinancialReportCode.halfYear, [
            cashLine('operatingCashFlow', 100),
            cashLine('capex', 20),
          ]),
          period(2025, FinancialReportCode.q3, [
            cashLine('operatingCashFlow', 150)
              ..unavailableReason = '영업현금 계정 충돌',
            cashLine('capex', 50),
          ]),
        ]),
      ).cashFlowQuarterly();
      expect(points[1].operating, isNull);
      expect(points[1].capex, isNull);
      expect(points[1].free, isNull);
      expect(points[1].missing, contains('표시 통화가 다름'));
      expect(points[1].missing, contains('누적액이 이전 기간보다 작음'));
      expect(points[2].operating, isNull);
      expect(points[2].capex, 30);
      expect(points[2].free, isNull);
      expect(points[2].missing, '영업현금 계정 충돌');
    });
  });

  test('순이익률은 연간·누적·분기·4분기에서 같은 기간 전체 당기순이익을 사용한다', () {
    final view = FinancialView(
      financials([
        period(2025, FinancialReportCode.q1, [
          line('revenue', 100),
          line('netIncome', -10),
        ]),
        period(2025, FinancialReportCode.halfYear, [
          line('revenue', 150, cumulative: 250),
          line('netIncome', 30, cumulative: 20),
        ]),
        period(2025, FinancialReportCode.q3, [
          line('revenue', 100, cumulative: 350),
          line('netIncome', 10, cumulative: 30),
        ]),
        period(2025, FinancialReportCode.annual, [
          line('revenue', 500),
          line('netIncome', 80),
          line('netIncomeOwners', 20),
        ]),
        period(2026, FinancialReportCode.halfYear, [
          line('revenue', 200, cumulative: 400),
          line('netIncome', -20, cumulative: -40),
        ]),
      ]),
    );
    final annual = view.annual(now: DateTime(2026, 9, 30));
    expect(annual.first.netMargin, .16);
    expect(annual.last.netMargin, -.1);
    final quarters = view.quarterly();
    expect(quarters.first.netMargin, -.1);
    expect(quarters[1].netMargin, .2);
    expect(quarters[3].netIncome?.value, 50);
    expect(quarters[3].netMargin, closeTo(50 / 150, .000001));
    expect(view.trailingSeries('netIncome').last.value, 20);
    expect(view.trailingSeries('revenue').last.value, 650);
    final missing = PeriodPoint(
      label: '없음',
      revenue: annual.first.revenue,
      operatingIncome: annual.first.operatingIncome,
    );
    expect(missing.netMargin, isNull);
  });

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

  group('누락 사유와 별도 재무', () {
    test('전년 동기 누락을 정확히 표시하고 연간 값으로 대체하지 않는다', () {
      final data = financials([
        period(2025, FinancialReportCode.annual, [
          line('netIncomeOwners', 100),
        ]),
        period(2026, FinancialReportCode.halfYear, [
          line('netIncomeOwners', 40, cumulative: 70),
        ]),
      ], cap: BigInt.from(1000));
      final per = FinancialView(data)
          .metrics()
          .firstWhere((m) => m.key == 'per');
      expect(per.derived.value, isNull);
      expect(per.derived.missing, '2025 반기 누적 지배주주 순이익 자료 부족');
    });

    test('보고서가 있어도 누적 계정 값이 없으면 해당 기간을 표시한다', () {
      final view = FinancialView(
        financials([
          period(2025, FinancialReportCode.halfYear, [
            line('revenue', 10, cumulative: 30),
          ]),
          period(2025, FinancialReportCode.annual, [line('revenue', 100)]),
          period(2026, FinancialReportCode.halfYear, [line('revenue', 20)]),
        ]),
      );
      expect(view.trailing('revenue', '매출액').missing, '2026 반기 누적 매출액 자료 부족');
    });

    test('별도 순이익으로 TTM을 계산하고 0인 전년 동기는 누락으로 보지 않는다', () {
      final data = financials([
        period(2025, FinancialReportCode.halfYear, [
          line('netIncome', 0, cumulative: 0),
        ]),
        period(2025, FinancialReportCode.annual, [line('netIncome', 100)]),
        period(2026, FinancialReportCode.halfYear, [
          line('netIncome', 40, cumulative: 50),
        ]),
      ], cap: BigInt.from(1500));
      data.fsDiv = FsDiv.separate;
      final per = FinancialView(data)
          .metrics()
          .firstWhere((m) => m.key == 'per');
      expect(per.derived.value, 10);
      expect(per.derived.missing, isNull);
      expect(per.derived.formula, isNot(contains('지배주주')));
    });
  });

  group('계산 불가 상태', () {
    test('자본 0 이하와 순이익 적자를 구분하고 적자 ROE는 보존한다', () {
      final data = financials([
        period(2025, FinancialReportCode.annual, [
          line('netIncomeOwners', -10),
          line('equityOwners', 100),
          line('equity', 100),
          line('liabilities', 200),
        ]),
      ], cap: BigInt.from(1000));
      var metrics = {for (final m in FinancialView(data).metrics()) m.key: m};
      expect(metrics['per']!.derived.missing, contains('순이익 0 이하'));
      expect(metrics['roe']!.derived.value, -.1);
      data.periods.single.lines = [
        line('assets', 1000000000),
        line('netIncomeOwners', 10),
        line('equityOwners', 0),
        line('equity', 0),
      ];
      metrics = {for (final m in FinancialView(data).metrics()) m.key: m};
      expect(metrics['pbr']!.derived.missing, contains('자본 0 이하'));
      expect(metrics['roe']!.derived.missing, contains('자본 0 이하'));
    });
    test('ROE는 전체 순이익과 지배주주 자본을 섞지 않는다', () {
      final data = financials([
        period(2025, FinancialReportCode.annual, [
          line('netIncome', 20),
          line('equityOwners', 50),
          line('equity', 100),
        ]),
      ], cap: BigInt.from(1000));
      final roe = FinancialView(data)
          .metrics()
          .firstWhere((m) => m.key == 'roe');
      expect(roe.derived.value, .2);
      expect(FinancialView(data).trailingRatios().single.roe, 20);
      expect(roe.derived.formula, contains('자본총계'));
      expect(roe.derived.formula, isNot(contains('지배주주')));
    });
    test('금액 단위 확인에 필요한 자산이 없으면 PER을 계산하지 않는다', () {
      final data = financials([
        period(2025, FinancialReportCode.annual, [line('netIncome', 10)]),
      ], cap: BigInt.from(1000));
      data.periods.single.lines.removeWhere((l) => l.key == 'assets');
      final per = FinancialView(data)
          .metrics()
          .firstWhere((m) => m.key == 'per');
      expect(per.derived.value, isNull);
      expect(per.derived.missing, contains('자산총계 누락'));
    });
    test('지배주주 값 누락 시 연결 전체 값으로 계산하고 근거에 표시한다', () {
      final data = financials([
        period(2025, FinancialReportCode.annual, [
          line('netIncome', 100),
          line('equity', 500),
        ]),
      ], cap: BigInt.from(1000));
      final metrics = {for (final m in FinancialView(data).metrics()) m.key: m};
      expect(metrics['per']!.derived.value, 10);
      expect(metrics['pbr']!.derived.value, 2);
      expect(metrics['per']!.derived.formula, contains('당기순이익'));
      expect(metrics['pbr']!.derived.formula, contains('자본총계'));
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
