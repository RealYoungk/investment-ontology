import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../company_ledger/formatters.dart';

/// 원 단위 금액 → "566조 9,421억". 1억 미만은 원 단위.
String formatKrw(BigInt? v) {
  if (v == null) return '—';
  final sign = v.isNegative ? '-' : '';
  final a = v.abs();
  final joUnit = BigInt.from(10).pow(12);
  final eokUnit = BigInt.from(10).pow(8);
  final jo = (a ~/ joUnit).toInt();
  final eok = ((a % joUnit) ~/ eokUnit).toInt();
  if (jo > 0) {
    return '$sign${formatCount(jo)}조${eok > 0 ? ' ${formatCount(eok)}억' : ''}';
  }
  if (eok > 0) return '$sign${formatCount(eok)}억';
  return '$sign${formatCount(a.toInt())}원';
}

/// 차트 눈금용 짧은 금액: 1.2조, 3,400억.
String formatKrwShort(double v) {
  final a = v.abs();
  final sign = v < 0 ? '-' : '';
  if (a >= 1e12) {
    final jo = a / 1e12;
    return '$sign${jo >= 10 ? formatCount(jo.round()) : jo.toStringAsFixed(1)}조';
  }
  if (a >= 1e8) return '$sign${formatCount((a / 1e8).round())}억';
  if (a == 0) return '0';
  return '$sign${formatCount(a.round())}원';
}

String formatPercent(double? ratio) =>
    ratio == null ? '—' : '${(ratio * 100).toStringAsFixed(1)}%';

String formatTimes(double? ratio) =>
    ratio == null ? '—' : '${ratio.toStringAsFixed(2)}배';

/// 보고서 코드 → 짧은 이름.
String reportCodeLabel(FinancialReportCode code) => switch (code) {
  FinancialReportCode.q1 => '1분기',
  FinancialReportCode.halfYear => '반기',
  FinancialReportCode.q3 => '3분기',
  FinancialReportCode.annual => '사업보고서',
};

String fsDivLabel(FsDiv div) => switch (div) {
  FsDiv.consolidated => '연결',
  FsDiv.separate => '별도',
};

/// 계산에 들어간 원천 값 하나.
class MetricInput {
  const MetricInput(this.label, this.amount, this.basis);

  final String label;
  final BigInt? amount;

  /// 어디서 온 값인지 (보고서·기준일).
  final String basis;
}

/// 화면에서 계산하는 값. 저장하지 않고 원천 값과 계산식을 함께 보여준다.
class DerivedValue {
  const DerivedValue({
    required this.value,
    required this.formula,
    required this.inputs,
    this.missing,
  });

  final double? value;
  final String formula;
  final List<MetricInput> inputs;

  /// 계산하지 못한 이유.
  final String? missing;
}

class DerivedMetric {
  const DerivedMetric({
    required this.key,
    required this.label,
    required this.display,
    required this.derived,
  });

  final String key;
  final String label;
  final String display;
  final DerivedValue derived;
}

/// 차트 한 칸: 기간 이름과 값 (원 단위, 없으면 null).
class PeriodPoint {
  const PeriodPoint({
    required this.label,
    required this.revenue,
    required this.operatingIncome,
    this.derivedNote,
  });

  final String label;
  final DerivedValue revenue;
  final DerivedValue operatingIncome;

  /// 원천 값을 그대로 쓰지 않고 계산한 칸이면 그 설명 (예: 4분기).
  final String? derivedNote;

  /// 영업이익률 = 영업이익 ÷ 매출액.
  double? get operatingMargin {
    final r = revenue.value, o = operatingIncome.value;
    if (r == null || o == null || r <= 0) return null;
    return o / r;
  }
}

/// [CompanyFinancials]의 원천 값으로 기간별 값과 파생 지표를 계산한다.
class FinancialView {
  FinancialView(this.data);

  final CompanyFinancials data;

  bool get isConsolidated => data.fsDiv == FsDiv.consolidated;

  late final Map<(int, FinancialReportCode), FinancialPeriod> _byPeriod = {
    for (final p in data.periods) (p.bsnsYear, p.reportCode): p,
  };

  FinancialPeriod? period(int year, FinancialReportCode code) =>
      _byPeriod[(year, code)];

  static FinancialLine? line(FinancialPeriod? p, String key) {
    if (p == null) return null;
    for (final l in p.lines) {
      if (l.key == key) return l;
    }
    return null;
  }

  static String basis(FinancialPeriod p) =>
      '${p.bsnsYear} ${reportCodeLabel(p.reportCode)} · 접수 ${p.rceptNo}';

  /// 순이익·자본은 연결이면 지배주주 몫, 별도면 회사 전체.
  String get netIncomeKey => isConsolidated ? 'netIncomeOwners' : 'netIncome';
  String get netIncomeLabel => isConsolidated ? '지배주주 순이익' : '당기순이익';
  String get equityKey => isConsolidated ? 'equityOwners' : 'equity';
  String get equityLabel => isConsolidated ? '지배주주 자본' : '자본총계';

  /// 기간 흐름 계정(손익·현금흐름)의 해당 기간 누적값.
  static BigInt? cumulative(FinancialPeriod? p, String key) {
    final l = line(p, key);
    if (l == null) return null;
    if (p!.reportCode == FinancialReportCode.annual ||
        p.reportCode == FinancialReportCode.q1) {
      return l.cumulativeAmount ?? l.amount;
    }
    return l.cumulativeAmount;
  }

  /// 사업연도별 값.
  List<PeriodPoint> annual() => [
    for (final p in data.periods)
      if (p.reportCode == FinancialReportCode.annual)
        PeriodPoint(
          label: '${p.bsnsYear}',
          revenue: _raw(p, 'revenue', '매출액'),
          operatingIncome: _raw(p, 'operatingIncome', '영업이익'),
        ),
  ];

  /// 분기별 3개월 값. 4분기는 사업보고서 − 3분기 누적으로 계산한다.
  List<PeriodPoint> quarterly() {
    final years = {for (final p in data.periods) p.bsnsYear}.toList()..sort();
    final points = <PeriodPoint>[];
    for (final y in years) {
      for (final (q, code) in [
        (1, FinancialReportCode.q1),
        (2, FinancialReportCode.halfYear),
        (3, FinancialReportCode.q3),
      ]) {
        final p = period(y, code);
        if (p == null) continue;
        points.add(
          PeriodPoint(
            label: '${y % 100}.$q분기',
            revenue: _quarter(p, 'revenue', '매출액'),
            operatingIncome: _quarter(p, 'operatingIncome', '영업이익'),
          ),
        );
      }
      // 3분기보고서가 없는 해(분기 수집 범위 밖)는 4분기를 계산할 수 없으므로 칸을 두지 않는다.
      if (period(y, FinancialReportCode.annual) != null &&
          period(y, FinancialReportCode.q3) != null) {
        points.add(
          PeriodPoint(
            label: '${y % 100}.4분기',
            revenue: _fourthQuarter(y, 'revenue', '매출액'),
            operatingIncome: _fourthQuarter(y, 'operatingIncome', '영업이익'),
            derivedNote: '4분기 = 사업보고서 연간 값 − 3분기보고서 누적 값',
          ),
        );
      }
    }
    return points;
  }

  DerivedValue _raw(FinancialPeriod p, String key, String label) {
    final l = line(p, key);
    return DerivedValue(
      value: l?.amount?.toDouble(),
      formula: '$label (${basis(p)})',
      inputs: [MetricInput(l?.accountName ?? label, l?.amount, basis(p))],
      missing: l == null ? '$label 계정이 없음' : null,
    );
  }

  /// 1분기는 당기 금액, 반기·3분기는 3개월 금액(누적과 따로 공시된 경우만).
  DerivedValue _quarter(FinancialPeriod p, String key, String label) {
    final l = line(p, key);
    final threeMonths =
        p.reportCode == FinancialReportCode.q1 || l?.cumulativeAmount != null
        ? l?.amount
        : null;
    return DerivedValue(
      value: threeMonths?.toDouble(),
      formula: '$label 3개월 (${basis(p)})',
      inputs: [
        MetricInput('${l?.accountName ?? label} 3개월', threeMonths, basis(p)),
      ],
      missing: l == null
          ? '$label 계정이 없음'
          : threeMonths == null
          ? '3개월 금액이 따로 공시되지 않음'
          : null,
    );
  }

  DerivedValue _fourthQuarter(int year, String key, String label) {
    final annual = period(year, FinancialReportCode.annual)!;
    final q3 = period(year, FinancialReportCode.q3);
    final a = line(annual, key)?.amount;
    final c = cumulative(q3, key);
    return DerivedValue(
      value: (a == null || c == null) ? null : (a - c).toDouble(),
      formula: '$label 4분기 = 사업보고서 − 3분기 누적',
      inputs: [
        MetricInput('$label 연간', a, basis(annual)),
        MetricInput(
          '$label 3분기 누적',
          c,
          q3 == null ? '$year 3분기보고서 없음' : basis(q3),
        ),
      ],
      missing: a == null
          ? '사업보고서에 $label 계정이 없음'
          : c == null
          ? '3분기 누적 값이 없음'
          : null,
    );
  }

  /// 가장 최근 보고서.
  FinancialPeriod? get latest =>
      data.periods.isEmpty ? null : data.periods.last;

  /// 최근 12개월 합. 최근 보고서가 사업보고서면 그 값,
  /// 아니면 전년 사업보고서 + 올해 누적 − 전년 같은 기간 누적.
  DerivedValue trailing(String key, String label) {
    final p = latest;
    if (p == null) {
      return DerivedValue(
        value: null,
        formula: label,
        inputs: const [],
        missing: '재무 자료 없음',
      );
    }
    if (p.reportCode == FinancialReportCode.annual) {
      final a = line(p, key)?.amount;
      return DerivedValue(
        value: a?.toDouble(),
        formula: '$label = ${p.bsnsYear} 사업보고서 연간 값',
        inputs: [MetricInput('$label 연간', a, basis(p))],
        missing: a == null ? '$label 계정이 없음' : null,
      );
    }
    final prevAnnual = period(p.bsnsYear - 1, FinancialReportCode.annual);
    final prevSame = period(p.bsnsYear - 1, p.reportCode);
    final a = line(prevAnnual, key)?.amount;
    final cur = cumulative(p, key);
    final prev = cumulative(prevSame, key);
    final code = reportCodeLabel(p.reportCode);
    final value = (a == null || cur == null || prev == null)
        ? null
        : (a + cur - prev).toDouble();
    return DerivedValue(
      value: value,
      formula:
          '$label(최근 12개월) = ${p.bsnsYear - 1} 사업보고서 + ${p.bsnsYear} $code 누적 − ${p.bsnsYear - 1} $code 누적',
      inputs: [
        MetricInput(
          '${p.bsnsYear - 1} 연간',
          a,
          prevAnnual == null ? '${p.bsnsYear - 1} 사업보고서 없음' : basis(prevAnnual),
        ),
        MetricInput('${p.bsnsYear} $code 누적', cur, basis(p)),
        MetricInput(
          '${p.bsnsYear - 1} $code 누적',
          prev,
          prevSame == null ? '${p.bsnsYear - 1} $code 보고서 없음' : basis(prevSame),
        ),
      ],
      missing: value == null ? '최근 12개월 합에 필요한 값이 모자람' : null,
    );
  }

  /// 가장 최근 보고서의 재무상태표 값.
  DerivedValue latestBalance(String key, String label) {
    final p = latest;
    final l = line(p, key);
    return DerivedValue(
      value: l?.amount?.toDouble(),
      formula: '$label = 최근 보고서 기말 값',
      inputs: [
        if (p != null) MetricInput(label, l?.amount, basis(p)),
      ],
      missing: l == null ? '$label 계정이 없음' : null,
    );
  }

  /// 표시할 파생 지표. 모두 원천 값으로 계산하고 계산식을 함께 돌려준다.
  List<DerivedMetric> metrics() {
    final market = data.market;
    final capBasis = market == null
        ? '시세 없음'
        : '기준일 ${formatDate(market.baseDate)} · 종목 ${market.securities.length}개 합';
    final capInput = MetricInput('시가총액', market?.marketCap, capBasis);
    final cap = market?.marketCap?.toDouble();

    final netIncome = trailing(netIncomeKey, netIncomeLabel);
    final revenue = trailing('revenue', '매출액');
    final opIncome = trailing('operatingIncome', '영업이익');
    final equity = latestBalance(equityKey, equityLabel);
    final liabilities = latestBalance('liabilities', '부채총계');
    final totalEquity = latestBalance('equity', '자본총계');

    DerivedValue ratio(
      String formula,
      DerivedValue top,
      DerivedValue bottom, {
      List<MetricInput>? inputs,
      double? topValue,
      String? topMissing,
      bool positiveBottom = true,
    }) {
      final t = topValue ?? top.value;
      final b = bottom.value;
      String? missing = topMissing ?? top.missing ?? bottom.missing;
      double? value;
      if (missing == null && t != null && b != null) {
        if (positiveBottom && b <= 0) {
          missing = '분모가 0 이하 (적자·자본잠식)';
        } else {
          value = t / b;
        }
      }
      return DerivedValue(
        value: value,
        formula: formula,
        inputs: inputs ?? [...top.inputs, ...bottom.inputs],
        missing: value == null ? (missing ?? '값이 모자람') : null,
      );
    }

    final capValue = DerivedValue(
      value: cap,
      formula: '시가총액 = 발행 종목(보통주·우선주 등) 시가총액 합',
      inputs: [
        for (final s in market?.securities ?? const <SecurityQuote>[])
          MetricInput('${s.name} (${s.shortCode})', s.marketCap, capBasis),
      ],
      missing: cap == null ? '시세를 수집하지 않았거나 종목이 기업에 연결되지 않음' : null,
    );

    final per = ratio(
      'PER = 시가총액 ÷ ${netIncome.formula}',
      capValue,
      netIncome,
      inputs: [capInput, ...netIncome.inputs],
    );
    final pbr = ratio(
      'PBR = 시가총액 ÷ $equityLabel (최근 기말)',
      capValue,
      equity,
      inputs: [capInput, ...equity.inputs],
    );
    final margin = ratio(
      '영업이익률 = 영업이익 ÷ 매출액 (각각 최근 12개월)\n${opIncome.formula}\n${revenue.formula}',
      opIncome,
      revenue,
    );
    final roe = ratio(
      'ROE = ${netIncome.formula} ÷ $equityLabel (최근 기말 값, 평균 아님)',
      netIncome,
      equity,
    );
    final debt = ratio(
      '부채비율 = 부채총계 ÷ 자본총계 (최근 기말)',
      liabilities,
      totalEquity,
    );

    return [
      DerivedMetric(
        key: 'marketCap',
        label: '시가총액',
        display: formatKrw(market?.marketCap),
        derived: capValue,
      ),
      DerivedMetric(
        key: 'per',
        label: 'PER',
        display: formatTimes(per.value),
        derived: per,
      ),
      DerivedMetric(
        key: 'pbr',
        label: 'PBR',
        display: formatTimes(pbr.value),
        derived: pbr,
      ),
      DerivedMetric(
        key: 'operatingMargin',
        label: '영업이익률',
        display: formatPercent(margin.value),
        derived: margin,
      ),
      DerivedMetric(
        key: 'roe',
        label: 'ROE',
        display: formatPercent(roe.value),
        derived: roe,
      ),
      DerivedMetric(
        key: 'debtRatio',
        label: '부채비율',
        display: formatPercent(debt.value),
        derived: debt,
      ),
    ];
  }
}
