import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../common/formatters.dart';

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

/// 원 단위 금액을 조·억·만원으로 끝까지 적는다: "234조 34억 3,455만원". 1만원 아래는 원.
/// 큰 수를 자릿수 세지 않고 읽게 하려는 표기라, 값이 클수록 이 표기를 쓴다.
String formatKrwLong(double won) {
  if (!won.isFinite) return '—';
  final sign = won < 0 ? '-' : '';
  var a = won.abs().round();
  if (a < 10000) return '$sign${formatCount(a)}원';
  final parts = <String>[];
  final jo = a ~/ 1000000000000;
  a %= 1000000000000;
  final eok = a ~/ 100000000;
  a %= 100000000;
  final man = a ~/ 10000;
  if (jo > 0) parts.add('${formatCount(jo)}조');
  if (eok > 0) parts.add('${formatCount(eok)}억');
  if (man > 0) parts.add('${formatCount(man)}만');
  return '$sign${parts.join(' ')}원';
}

/// 공시 단위 그대로 적힌 값을 읽기 좋게: 백만원·억원·조원은 [formatKrwLong]으로,
/// 나머지 단위(%, 대, 톤…)는 값 그대로.
String formatUnitAmount(double value, String unit) => switch (unit) {
  '백만원' => formatKrwLong(value * 1000000),
  '천원' => formatKrwLong(value * 1000),
  '억원' => formatKrwLong(value * 100000000),
  '조원' => formatKrwLong(value * 1000000000000),
  '원' => formatKrwLong(value),
  _ => '${formatDecimal(value)}$unit',
};

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

String financialBasisReason(String? reason) => switch (reason) {
  'incomplete_consolidated' => '연결 자료 부족 · 별도 자동 적용',
  'newer_separate' => '별도에 더 최신 자료 있음',
  'separate_only' => '별도 자료만 수집됨',
  'manual' => '직접 선택',
  'no_financials' => '재무 자료 없음',
  _ => '연결 우선 자동 선택',
};

String? screenMetricNote(ScreenRow row, String label) {
  final key = switch (label.replaceAll(RegExp(r'\(.*\)'), '')) {
    'PER' => 'per',
    'PBR' => 'pbr',
    'ROE' => 'roe',
    '영업이익률' => 'operatingMargin',
    '부채비율' => 'debtRatio',
    'FCF 수익률' => 'fcfYield',
    '매출 성장률' => 'revenueGrowth',
    '영업이익 성장률' => 'operatingIncomeGrowth',
    _ => null,
  };
  return row.metricNotes?[key];
}

/// 계산에 들어간 원천 값 하나.
class MetricInput {
  const MetricInput(
    this.label,
    this.amount,
    this.basis, {
    this.currency = 'KRW',
  });

  final String currency;

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

  Set<String> get currencies => {
    for (final input in inputs)
      if (input.amount != null) input.currency,
  };

  String? get currencyIssue => currencies.length > 1
      ? '${currencies.join("·")} 통화 불일치 · 환율 환산 필요'
      : null;

  String formatAmount() {
    if (value == null) return '—';
    final currency = currencies.firstOrNull ?? 'KRW';
    return currency == 'KRW'
        ? formatKrw(BigInt.from(value!))
        : '${formatKrw(BigInt.from(value!)).replaceAll('원', '')} $currency';
  }

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
    this.netIncome,
    this.derivedNote,
  });

  final String label;
  final DerivedValue revenue;
  final DerivedValue operatingIncome;
  final DerivedValue? netIncome;

  /// 원천 값을 그대로 쓰지 않고 계산한 칸이면 그 설명 (예: 4분기).
  final String? derivedNote;

  /// 당기순이익률 = 전체 당기순이익 ÷ 같은 기간 매출액.
  double? get netMargin {
    final r = revenue.value, n = netIncome?.value;
    if (r == null || n == null || r <= 0) return null;
    return n / r;
  }

  /// 영업이익률 = 영업이익 ÷ 매출액.
  double? get operatingMargin {
    final r = revenue.value, o = operatingIncome.value;
    if (r == null || o == null || r <= 0) return null;
    return o / r;
  }
}

/// 한 기간의 현금흐름.
class CashPoint {
  const CashPoint({
    required this.label,
    required this.operating,
    required this.capex,
    required this.free,
    this.missing,
  });

  final String label;
  final double? operating;
  final double? capex;

  /// 잉여현금흐름 = 영업활동 현금흐름 − 유형자산의 취득.
  final double? free;
  final String? missing;
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
      if (l.key == key) {
        return l.unavailableReason == null
            ? l
            // Construct explicitly: the release web compiler can retain the
            // original BigInt fields when generated copyWith receives null.
            : FinancialLine(
                key: l.key,
                factId: l.factId,
                statement: l.statement,
                accountId: l.accountId,
                accountName: l.accountName,
                currency: l.currency,
                unavailableReason: l.unavailableReason,
              );
      }
    }
    return null;
  }

  static String basis(FinancialPeriod p) =>
      '${p.bsnsYear} ${reportCodeLabel(p.reportCode)} · 접수 ${p.rceptNo}';

  /// 순이익·자본은 연결이면 지배주주 몫, 별도면 회사 전체.
  String get netIncomeKey =>
      isConsolidated &&
          (latest == null ||
              _trailingAt(latest!, 'netIncomeOwners') != null ||
              _trailingAt(latest!, 'netIncome') == null)
      ? 'netIncomeOwners'
      : 'netIncome';
  String get netIncomeLabel =>
      netIncomeKey == 'netIncomeOwners' ? '지배주주 순이익' : '당기순이익';
  String get equityKey =>
      isConsolidated && line(latest, 'equityOwners')?.amount != null
      ? 'equityOwners'
      : 'equity';
  String get equityLabel => equityKey == 'equityOwners' ? '지배주주 자본' : '자본총계';

  /// 기간 흐름 계정(손익·현금흐름)의 해당 기간 누적값.
  static BigInt? cumulative(FinancialPeriod? p, String key) {
    final l = line(p, key);
    if (l == null) return null;
    // 현금흐름표는 분기·반기에도 누적만 공시한다 (3개월 값이 따로 없어 amount가 누적이다).
    if (p!.reportCode == FinancialReportCode.annual ||
        p.reportCode == FinancialReportCode.q1 ||
        l.statement == FinancialStatementKind.cashFlow) {
      return l.cumulativeAmount ?? l.amount;
    }
    return l.cumulativeAmount;
  }

  /// 사업연도별 값. 사업보고서가 아직 없는 최근 해는 분기·반기보고서의 **누적**으로
  /// 한 칸을 더 두고(예: "2026 반기 누적"), 그것도 없으면 "없음"으로 빈 칸을 둔다 —
  /// 올해 칸이 아예 없으면 데이터가 빠진 건지 안 나온 건지 알 수 없다.
  List<PeriodPoint> annual({DateTime? now}) {
    final points = [
      for (final p in data.periods)
        if (p.reportCode == FinancialReportCode.annual)
          PeriodPoint(
            label: '${p.bsnsYear}',
            revenue: _raw(p, 'revenue', '매출액'),
            operatingIncome: _raw(p, 'operatingIncome', '영업이익'),
            netIncome: _raw(p, 'netIncome', '당기순이익'),
          ),
    ];
    final lastAnnual = lastAnnualYear;
    final latest = latestInterim();
    if (latest != null) {
      final l = reportCodeLabel(latest.reportCode);
      points.add(
        PeriodPoint(
          label: '${latest.bsnsYear} $l 누적',
          revenue: _cumulativeValue(latest, 'revenue', '매출액'),
          operatingIncome: _cumulativeValue(latest, 'operatingIncome', '영업이익'),
          netIncome: _cumulativeValue(latest, 'netIncome', '당기순이익'),
          derivedNote: '사업보고서가 아직 없어 $l보고서까지의 누적 값',
        ),
      );
    }
    final thisYear = (now ?? DateTime.now()).year;
    final covered = latest?.bsnsYear ?? lastAnnual;
    if (points.isNotEmpty && (covered == null || covered < thisYear)) {
      points.add(
        PeriodPoint(
          label: '$thisYear 없음',
          revenue: const DerivedValue(
            value: null,
            formula: '올해 보고서가 아직 없음',
            inputs: [],
            missing: '올해 분기·반기보고서가 아직 없음',
          ),
          operatingIncome: const DerivedValue(
            value: null,
            formula: '올해 보고서가 아직 없음',
            inputs: [],
            missing: '올해 분기·반기보고서가 아직 없음',
          ),
          derivedNote: '아직 공시된 보고서가 없는 해',
        ),
      );
    }
    return points;
  }

  DerivedValue _cumulativeValue(FinancialPeriod p, String key, String label) {
    final l = line(p, key);
    final v = cumulative(p, key);
    return DerivedValue(
      value: v?.toDouble(),
      formula: '$label 누적 (${basis(p)})',
      inputs: [MetricInput(l?.accountName ?? label, v, basis(p))],
      missing:
          l?.unavailableReason ??
          (l?.amount == null ? '${p.bsnsYear} 연간 $label 계정 없음' : null),
    );
  }

  /// 연도별 현금흐름. 유형자산 취득은 양수로 적는 회사와 음수로 적는 회사가
  /// 섞여 있어 절댓값으로 본다 (기업 머리의 FCF와 같은 규칙).
  List<CashPoint> cashFlowAnnual({DateTime? now}) {
    CashPoint point(FinancialPeriod p, String label) {
      // 현금흐름표는 분기·반기에도 누적만 공시하므로 amount가 곧 누적이다.
      final ocf = line(p, 'operatingCashFlow')?.amount?.toDouble();
      final capex = line(p, 'capex')?.amount?.abs().toDouble();
      return CashPoint(
        label: label,
        operating: ocf,
        capex: capex,
        free: ocf == null || capex == null ? null : ocf - capex,
      );
    }

    final points = [
      for (final p in data.periods)
        if (p.reportCode == FinancialReportCode.annual)
          point(p, '${p.bsnsYear}'),
    ];
    // 사업보고서가 아직 없는 최근 해는 분기·반기 누적으로, 그것도 없으면 "없음".
    final latest = latestInterim();
    if (latest != null) {
      points.add(
        point(
          latest,
          '${latest.bsnsYear} ${reportCodeLabel(latest.reportCode)} 누적',
        ),
      );
    }
    final thisYear = (now ?? DateTime.now()).year;
    final covered = latest?.bsnsYear ?? lastAnnualYear;
    if (points.isNotEmpty && (covered == null || covered < thisYear)) {
      points.add(
        CashPoint(
          label: '$thisYear 없음',
          operating: null,
          capex: null,
          free: null,
        ),
      );
    }
    return points;
  }

  /// 누적 공시에서 같은 사업연도의 직전 누적을 빼서 얻는 3개월 현금흐름.
  List<CashPoint> cashFlowQuarterly() {
    final years = {for (final p in data.periods) p.bsnsYear}.toList()..sort();
    return [
      for (final year in years)
        for (final (quarter, code) in [
          (1, FinancialReportCode.q1),
          (2, FinancialReportCode.halfYear),
          (3, FinancialReportCode.q3),
          (4, FinancialReportCode.annual),
        ])
          if (period(year, code) case final p?)
            _cashQuarterPoint(p, '${year % 100}.$quarter분기'),
    ];
  }

  CashPoint _cashQuarterPoint(FinancialPeriod p, String label) {
    final operating = _cashQuarterAmount(p, 'operatingCashFlow', '영업현금');
    final capex = _cashQuarterAmount(p, 'capex', '유형자산 취득');
    final missing = {
      if (operating.missing != null) operating.missing!,
      if (capex.missing != null) capex.missing!,
    };
    return CashPoint(
      label: label,
      operating: operating.value,
      capex: capex.value,
      free: operating.value == null || capex.value == null
          ? null
          : operating.value! - capex.value!,
      missing: missing.isEmpty ? null : missing.join(' · '),
    );
  }

  ({double? value, String? missing}) _cashQuarterAmount(
    FinancialPeriod p,
    String key,
    String label,
  ) {
    final currentLine = line(p, key);
    final current = cumulative(p, key);
    if (current == null) {
      return (
        value: null,
        missing:
            currentLine?.unavailableReason ??
            '${p.bsnsYear} ${reportCodeLabel(p.reportCode)} $label 계정 없음',
      );
    }
    // 취득액의 양수/음수 표기 차이는 각 누적 원천에서 먼저 정규화한다.
    final normalized = key == 'capex' ? current.abs() : current;
    if (p.reportCode == FinancialReportCode.q1) {
      return (value: normalized.toDouble(), missing: null);
    }
    final priorCode = switch (p.reportCode) {
      FinancialReportCode.halfYear => FinancialReportCode.q1,
      FinancialReportCode.q3 => FinancialReportCode.halfYear,
      FinancialReportCode.annual => FinancialReportCode.q3,
      FinancialReportCode.q1 => throw StateError('Handled above'),
    };
    final priorPeriod = period(p.bsnsYear, priorCode);
    final priorLine = line(priorPeriod, key);
    final prior = cumulative(priorPeriod, key);
    if (prior == null) {
      return (
        value: null,
        missing:
            priorLine?.unavailableReason ??
            '${p.bsnsYear} ${reportCodeLabel(priorCode)} $label 누적값 없음',
      );
    }
    if ((currentLine?.currency ?? 'KRW') != (priorLine?.currency ?? 'KRW')) {
      return (value: null, missing: '$label 누적값의 표시 통화가 다름');
    }
    final value = normalized - (key == 'capex' ? prior.abs() : prior);
    if (key == 'capex' && value.isNegative) {
      return (value: null, missing: '유형자산 취득 누적액이 이전 기간보다 작음');
    }
    return (value: value.toDouble(), missing: null);
  }

  /// 가장 최근 사업보고서의 사업연도.
  int? get lastAnnualYear => data.periods
      .where((p) => p.reportCode == FinancialReportCode.annual)
      .fold<int?>(null, (m, p) => m == null || p.bsnsYear > m ? p.bsnsYear : m);

  /// 마지막 사업보고서 뒤에 오는 해의 가장 최근 분기·반기보고서.
  FinancialPeriod? latestInterim() {
    const rank = {
      FinancialReportCode.q1: 1,
      FinancialReportCode.halfYear: 2,
      FinancialReportCode.q3: 3,
    };
    final lastAnnual = lastAnnualYear;
    FinancialPeriod? latest;
    for (final p in data.periods) {
      if (p.reportCode == FinancialReportCode.annual) continue;
      if (lastAnnual != null && p.bsnsYear <= lastAnnual) continue;
      if (latest == null ||
          p.bsnsYear > latest.bsnsYear ||
          (p.bsnsYear == latest.bsnsYear &&
              rank[p.reportCode]! > rank[latest.reportCode]!)) {
        latest = p;
      }
    }
    return latest;
  }

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
            netIncome: _quarter(p, 'netIncome', '당기순이익'),
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
            netIncome: _fourthQuarter(y, 'netIncome', '당기순이익'),
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
      missing:
          l?.unavailableReason ??
          (l?.amount == null ? '${p.bsnsYear} 연간 $label 계정 없음' : null),
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
          ? '${p.bsnsYear} 연간 $label 계정 없음'
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

  /// 분기마다의 최근 12개월 값 하나.
  ///
  /// 사업보고서면 그 해 연간, 분기·반기면 전년 연간 + 올해 누적 − 전년 같은 기간 누적.
  /// 분기 실적은 들쭉날쭉해 한 해치로 더해 놓아야 흐름이 보인다.
  List<({String label, int year, FinancialReportCode code, double? value})>
  trailingSeries(String key) {
    final out =
        <({String label, int year, FinancialReportCode code, double? value})>[];
    for (final p in data.periods) {
      final value = _trailingAt(p, key);
      if (value == null) continue;
      out.add((
        label: p.reportCode == FinancialReportCode.annual
            ? '${p.bsnsYear}'
            : "${p.bsnsYear % 100}.${reportCodeLabel(p.reportCode)}",
        year: p.bsnsYear,
        code: p.reportCode,
        value: value,
      ));
    }
    return out;
  }

  /// 분기마다의 최근 12개월 기준 이익률과 ROE.
  ///
  /// 이익률은 같은 12개월끼리 나누고, ROE는 그 시점 기말 자본으로 나눈다
  /// (기업 머리의 지표와 같은 규칙).
  List<({String label, double? margin, double? netMargin, double? roe})>
  trailingRatios() {
    final out =
        <({String label, double? margin, double? netMargin, double? roe})>[];
    for (final p in data.periods) {
      final revenue = _trailingAt(p, 'revenue');
      final operating = _trailingAt(p, 'operatingIncome');
      final ownersNet = isConsolidated
          ? _trailingAt(p, 'netIncomeOwners')
          : null;
      final ownersEquity = isConsolidated
          ? line(p, 'equityOwners')?.amount?.toDouble()
          : null;
      final totalNet = _trailingAt(p, 'netIncome');
      final net = ownersNet ?? totalNet;
      final useOwners = ownersNet != null && ownersEquity != null;
      final equity = useOwners
          ? ownersEquity
          : line(p, 'equity')?.amount?.toDouble();
      if (revenue == null && net == null) continue;
      double? over(double? a, double? b) =>
          a == null || b == null || b <= 0 ? null : 100 * a / b;
      out.add((
        label: p.reportCode == FinancialReportCode.annual
            ? '${p.bsnsYear}'
            : "${p.bsnsYear % 100}.${reportCodeLabel(p.reportCode)}",
        margin: over(operating, revenue),
        netMargin: over(net, revenue),
        roe: over(useOwners ? ownersNet : totalNet, equity),
      ));
    }
    return out;
  }

  /// 이 보고서 시점의 최근 12개월 값.
  double? _trailingAt(FinancialPeriod p, String key) {
    if (p.reportCode == FinancialReportCode.annual) {
      return line(p, key)?.amount?.toDouble();
    }
    final prevAnnual = line(
      period(p.bsnsYear - 1, FinancialReportCode.annual),
      key,
    )?.amount;
    final cur = cumulative(p, key);
    final prev = cumulative(period(p.bsnsYear - 1, p.reportCode), key);
    if (prevAnnual == null || cur == null || prev == null) return null;
    final currencies = {
      for (final source in [
        line(period(p.bsnsYear - 1, FinancialReportCode.annual), key),
        line(p, key),
        line(period(p.bsnsYear - 1, p.reportCode), key),
      ])
        if (source != null) source.currency ?? 'KRW',
    };
    if (currencies.length > 1) return null;
    return _trailingSum(key, prevAnnual, cur, prev);
  }

  // Cash outflows may change sign convention between filings. Normalize each
  // acquisition input before the TTM subtraction, not the final sum afterwards.
  static double? _trailingSum(
    String key,
    BigInt annual,
    BigInt current,
    BigInt prior,
  ) {
    final total = key == 'capex'
        ? annual.abs() + current.abs() - prior.abs()
        : annual + current - prior;
    if (key == 'capex' && total.isNegative) return null;
    return total.toDouble();
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
        inputs: [
          MetricInput(
            '$label 연간',
            a,
            basis(p),
            currency: line(p, key)?.currency ?? 'KRW',
          ),
        ],
        missing: a == null ? '${p.bsnsYear} 연간 $label 계정 없음' : null,
      );
    }
    final prevAnnual = period(p.bsnsYear - 1, FinancialReportCode.annual);
    final prevSame = period(p.bsnsYear - 1, p.reportCode);
    final a = line(prevAnnual, key)?.amount;
    final cur = cumulative(p, key);
    final prev = cumulative(prevSame, key);
    final code = reportCodeLabel(p.reportCode);
    final currencies = {
      for (final source in [
        line(prevAnnual, key),
        line(p, key),
        line(prevSame, key),
      ])
        if (source != null) source.currency ?? 'KRW',
    };
    final value =
        (currencies.length > 1 || a == null || cur == null || prev == null)
        ? null
        : _trailingSum(key, a, cur, prev);
    return DerivedValue(
      value: value,
      formula:
          '${key == 'capex' ? '$label(각 공시 금액의 절댓값)' : label}(최근 12개월) = ${p.bsnsYear - 1} 사업보고서 + ${p.bsnsYear} $code 누적 − ${p.bsnsYear - 1} $code 누적',
      inputs: [
        MetricInput(
          '$label · ${p.bsnsYear - 1} 연간',
          a,
          prevAnnual == null ? '${p.bsnsYear - 1} 사업보고서 없음' : basis(prevAnnual),
          currency: line(prevAnnual, key)?.currency ?? 'KRW',
        ),
        MetricInput(
          '$label · ${p.bsnsYear} $code 누적',
          cur,
          basis(p),
          currency: line(p, key)?.currency ?? 'KRW',
        ),
        MetricInput(
          '$label · ${p.bsnsYear - 1} $code 누적',
          prev,
          prevSame == null ? '${p.bsnsYear - 1} $code 보고서 없음' : basis(prevSame),
          currency: line(prevSame, key)?.currency ?? 'KRW',
        ),
      ],
      missing: currencies.length > 1
          ? '${currencies.join('·')} 통화 불일치 · 환율 환산 필요'
          : value == null && a != null && cur != null && prev != null
          ? '$label 기간별 금액 불일치 · 공시 확인 필요'
          : value == null
          ? '${[
              if (a == null) '${p.bsnsYear - 1} 연간',
              if (cur == null) '${p.bsnsYear} $code 누적',
              if (prev == null) '${p.bsnsYear - 1} $code 누적',
            ].join(' · ')} $label 자료 부족'
          : null,
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
        if (p != null)
          MetricInput(
            label,
            l?.amount,
            basis(p),
            currency: l?.currency ?? 'KRW',
          ),
      ],
      missing:
          l?.unavailableReason ?? (l?.amount == null ? '$label 자료 부족' : null),
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
      String nonPositiveReason = '분모가 0 이하',
    }) {
      final t = topValue ?? top.value;
      final b = bottom.value;
      final currencies = {...top.currencies, ...bottom.currencies};
      String? missing = currencies.length > 1
          ? '${currencies.join("·")} 통화 불일치 · 환율 환산 필요'
          : topMissing ?? top.missing ?? bottom.missing;
      double? value;
      if (missing == null && t != null && b != null) {
        if (positiveBottom && b <= 0) {
          missing = nonPositiveReason;
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

    // 상장사의 자산총계가 1억원보다 작을 수는 없다. 그보다 작으면 재무제표를 원이
    // 아닌 단위(천원 등)로 낸 것이라, 시가총액과 섞는 지표는 계산하지 않는다.
    final assets = latestBalance('assets', '자산총계');
    final scaleMismatch = assets.value == null || assets.value! < 100000000;
    final scaleNote = latest == null
        ? '재무 자료 없음'
        : assets.value == null
        ? (line(latest, 'assets')?.unavailableReason ?? '자산총계 누락 · 금액 단위 확인 불가')
        : '재무 금액 단위 확인 필요';

    final capValue = DerivedValue(
      value: cap != null && cap > 0 ? cap : null,
      formula: '시가총액 = 발행 종목(보통주·우선주 등) 시가총액 합',
      inputs: [
        for (final s in market?.securities ?? const <SecurityQuote>[])
          MetricInput('${s.name} (${s.shortCode})', s.marketCap, capBasis),
      ],
      missing: cap == null
          ? '시세를 수집하지 않았거나 종목이 기업에 연결되지 않음'
          : cap <= 0
          ? '시가총액 0 이하 · 시세 확인 필요'
          : null,
    );

    final per = ratio(
      'PER = 시가총액 ÷ ${netIncome.formula}',
      capValue,
      netIncome,
      inputs: [capInput, ...netIncome.inputs],
      nonPositiveReason: '순이익 0 이하 · PER 계산 불가',
      topMissing: scaleMismatch ? scaleNote : null,
    );
    final pbr = ratio(
      'PBR = 시가총액 ÷ $equityLabel (최근 기말)',
      capValue,
      equity,
      inputs: [capInput, ...equity.inputs],
      nonPositiveReason: '자본 0 이하 · PBR 계산 불가',
      topMissing: scaleMismatch ? scaleNote : null,
    );
    final margin = ratio(
      '영업이익률 = 영업이익 ÷ 매출액 (각각 최근 12개월)\n${opIncome.formula}\n${revenue.formula}',
      opIncome,
      revenue,
      nonPositiveReason: '매출액 0 이하',
    );
    // ROE must use the same ownership scope on both sides.
    final roeOwners =
        netIncomeKey == 'netIncomeOwners' && equityKey == 'equityOwners';
    final roeNet = roeOwners ? netIncome : trailing('netIncome', '당기순이익');
    final roeEquity = roeOwners ? equity : latestBalance('equity', '자본총계');
    final roe = ratio(
      'ROE = ${roeNet.formula} ÷ ${roeOwners ? '지배주주 자본' : '자본총계'} (최근 기말 값, 평균 아님)',
      roeNet,
      roeEquity,
      nonPositiveReason: '자본 0 이하 · ROE 계산 불가',
    );
    final debt = ratio(
      '부채비율 = 부채총계 ÷ 자본총계 (최근 기말)',
      liabilities,
      totalEquity,
      nonPositiveReason: '자본 0 이하 · 부채비율 계산 불가',
    );

    // 잉여현금흐름 = 영업활동 현금흐름 − 유형자산 취득. 공시는 취득액을 양수로 적는
    // 회사와 음수로 적는 회사가 섞여 있어 절댓값으로 뺀다.
    final ocf = trailing('operatingCashFlow', '영업활동 현금흐름');
    final capex = trailing('capex', '유형자산의 취득');
    final fcfCurrencies = {...ocf.currencies, ...capex.currencies};
    final fcfValue =
        fcfCurrencies.length > 1 || ocf.value == null || capex.value == null
        ? null
        : ocf.value! - capex.value!.abs();
    final fcf = DerivedValue(
      value: fcfValue,
      formula:
          '잉여현금흐름(FCF) = 영업활동 현금흐름 − 유형자산의 취득 (각각 최근 12개월)\n'
          '${ocf.formula}\n${capex.formula}',
      inputs: [...ocf.inputs, ...capex.inputs],
      missing: fcfCurrencies.length > 1
          ? '현금흐름·투자액 통화 불일치 · 환율 환산 필요'
          : fcfValue == null
          ? (ocf.missing ?? capex.missing)
          : null,
    );
    final fcfYield = ratio(
      'FCF 수익률 = 잉여현금흐름 ÷ 시가총액',
      fcf,
      capValue,
      inputs: [...fcf.inputs, capInput],
      topMissing: scaleMismatch ? scaleNote : null,
    );

    DerivedValue combine(
      String formula,
      List<DerivedValue> values,
      double Function(List<double>) calculate,
    ) {
      final absent = values.where((v) => v.value == null).firstOrNull;
      final currencies = {for (final v in values) ...v.currencies};
      return DerivedValue(
        value: absent == null && currencies.length <= 1
            ? calculate(values.map((v) => v.value!).toList())
            : null,
        formula: formula,
        inputs: [
          for (final v in values)
            for (final input in v.inputs)
              MetricInput(
                '${v.formula.split('=')[0].trim()} · ${input.label}',
                input.amount,
                input.basis,
                currency: input.currency,
              ),
        ],
        missing: currencies.length > 1
            ? '${currencies.join('·')} 통화 불일치 · 환율 환산 필요'
            : absent?.missing,
      );
    }

    DerivedValue growth(String key, String label) {
      final now = trailing(key, label);
      final p = latest;
      final same = p == null ? null : period(p.bsnsYear - 1, p.reportCode);
      final pastPeriods = same == null
          ? <FinancialPeriod>[]
          : data.periods.take(data.periods.indexOf(same) + 1).toList();
      final before = same == null
          ? DerivedValue(
              value: null,
              formula: '',
              inputs: const [],
              missing: '전년 같은 시점의 $label 자료 부족',
            )
          : FinancialView(data.copyWith(periods: pastPeriods))
                .trailing(key, label);
      return combine('$label 성장률 = (최근 12개월 ÷ 전년 같은 시점 12개월 − 1) × 100', [
        now,
        before,
      ], (v) => v[0] / v[1] - 1).copyPositiveBase(before, label);
    }

    final salesGrowth = growth('revenue', '매출액');
    final profitGrowth = growth(netIncomeKey, netIncomeLabel);
    final psr = ratio(
      'PSR = 시가총액 ÷ 최근 12개월 매출액\n${revenue.formula}',
      capValue,
      revenue,
      nonPositiveReason: '매출액 0 이하 · PSR 계산 불가',
      topMissing: scaleMismatch ? scaleNote : null,
    );
    final por = ratio(
      'POR = 시가총액 ÷ 최근 12개월 영업이익\n${opIncome.formula}',
      capValue,
      opIncome,
      nonPositiveReason: '영업이익 0 이하 · POR 계산 불가',
      topMissing: scaleMismatch ? scaleNote : null,
    );
    final pcf = ratio(
      'P/OCF = 시가총액 ÷ 최근 12개월 영업현금흐름\n${ocf.formula}',
      capValue,
      ocf,
      nonPositiveReason: '영업현금흐름 0 이하',
      topMissing: scaleMismatch ? scaleNote : null,
    );
    final daTotal = trailing('depreciationAmortisation', '감가상각·무형자산상각 합계');
    final da = daTotal.value != null
        ? daTotal
        : combine('감가상각비 + 무형자산상각비', [
            trailing('depreciation', '감가상각비'),
            trailing('amortisation', '무형자산상각비'),
          ], (v) => v[0] + v[1]);
    final ebitda = combine(
      'EBITDA(공시 계산) = 최근 12개월 영업이익 + 감가상각·무형자산상각비\n현금흐름표의 상각 조정을 사용. 회사의 조정 EBITDA와 다를 수 있음.',
      [opIncome, da],
      (v) => v[0] + v[1],
    );
    final cash = latestBalance('cash', '현금및현금성자산');
    final debtTotal = latestBalance(
      'interestDebtIncludingLeases',
      '차입금·사채·리스부채 합계',
    );
    final minority = !isConsolidated
        ? const DerivedValue(
            value: 0,
            formula: '별도 재무는 비지배지분 조정 없음',
            inputs: [],
          )
        : latestBalance('noncontrollingInterest', '비지배지분');
    final evRaw = combine(
      'EV = 시가총액 + 이자부채(리스 포함) + 비지배지분 − 현금및현금성자산\n이자부채·비지배지분은 공시 장부금액. 현금 외 금융자산은 차감하지 않음.',
      [capValue, debtTotal, minority, cash],
      (v) => v[0] + v[1] + v[2] - v[3],
    );
    final ev = scaleMismatch
        ? DerivedValue(
            value: null,
            formula: evRaw.formula,
            inputs: evRaw.inputs,
            missing: scaleNote,
          )
        : evRaw;
    final extra = <DerivedMetric>[];
    void add(
      String key,
      String label,
      DerivedValue v, {
      bool percent = false,
      bool amount = false,
    }) => extra.add(
      DerivedMetric(
        key: key,
        label: label,
        derived: v,
        display: amount
            ? v.formatAmount()
            : percent
            ? formatPercent(v.value)
            : formatTimes(v.value),
      ),
    );
    add('psr', 'PSR', psr);
    add('por', 'POR', por);
    add('pcf', 'P/OCF', pcf);
    add('revenueGrowth', '매출 성장률', salesGrowth, percent: true);
    add('profitGrowth', '순이익 성장률', profitGrowth, percent: true);
    add(
      'roa',
      'ROA',
      ratio(
        'ROA = 최근 12개월 당기순이익 ÷ 최근 기말 자산총계 (평균 아님)',
        trailing('netIncome', '당기순이익'),
        assets,
      ),
      percent: true,
    );
    add(
      'ocfMargin',
      '영업현금흐름률',
      ratio('영업현금흐름률 = 최근 12개월 영업현금흐름 ÷ 매출액', ocf, revenue),
      percent: true,
    );
    final capexAbs = DerivedValue(
      value: capex.value?.abs(),
      formula: capex.formula,
      inputs: capex.inputs,
      missing: capex.missing,
    );
    add(
      'capexRatio',
      '설비투자 / 매출',
      ratio('설비투자 / 매출 = 최근 12개월 유형자산 취득 절댓값 ÷ 매출액', capexAbs, revenue),
      percent: true,
    );
    add('cash', '보유 현금', cash, amount: true);
    add('ebitda', 'EBITDA(공시 계산)', ebitda, amount: true);
    add(
      'ebitdaMargin',
      'EBITDA 마진',
      ratio('EBITDA 마진 = 공시 계산 EBITDA ÷ 최근 12개월 매출액', ebitda, revenue),
      percent: true,
    );
    add(
      'evEbitda',
      'EV/EBITDA',
      ratio(
        'EV/EBITDA = 기업가치 ÷ 최근 12개월 EBITDA\n${ev.formula}\n${ebitda.formula}',
        ev,
        ebitda,
        nonPositiveReason: 'EBITDA 0 이하',
      ),
    );
    add(
      'evOperating',
      'EV/영업이익',
      ratio(
        'EV/영업이익 = 기업가치 ÷ 최근 12개월 영업이익\n${ev.formula}',
        ev,
        opIncome,
        nonPositiveReason: '영업이익 0 이하',
      ),
    );
    add(
      'evSales',
      'EV/Sales',
      ratio('EV/Sales = 기업가치 ÷ 최근 12개월 매출액\n${ev.formula}', ev, revenue),
    );
    add(
      'peg',
      'PEG(예상)',
      const DerivedValue(
        value: null,
        formula: 'PEG = 예상 PER ÷ 예상 연평균 EPS 성장률(%, 20%는 20으로 나눔)\n동일 추정 시점·기간의 컨센서스를 사용.',
        inputs: [],
        missing: '예상 EPS·성장률 데이터 미연결',
      ),
    );

    return [
      ...extra,
      DerivedMetric(
        key: 'marketCap',
        label: '시가총액',
        display: capValue.value == null ? '—' : formatKrw(market?.marketCap),
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
      DerivedMetric(
        key: 'freeCashFlow',
        label: '잉여현금흐름',
        display: fcf.formatAmount(),
        derived: fcf,
      ),
      DerivedMetric(
        key: 'fcfYield',
        label: 'FCF 수익률',
        display: formatPercent(fcfYield.value),
        derived: fcfYield,
      ),
    ];
  }
}

extension on DerivedValue {
  DerivedValue copyPositiveBase(DerivedValue base, String label) {
    if (base.value == null || base.value! > 0) return this;
    return DerivedValue(
      value: null,
      formula: formula,
      inputs: inputs,
      missing: '전년 $label 0 이하 · 성장률 비교 불가',
    );
  }
}
