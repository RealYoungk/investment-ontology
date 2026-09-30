import '../company_detail/business/overview_metrics.dart';
import 'financial_metrics.dart';

/// Selection is explanatory, never a buy/sell score. Missing data is not a loss.
class MetricProfile {
  const MetricProfile(this.title, this.reason, this.keys);
  final String title;
  final String reason;
  final List<String> keys;

  static MetricProfile forCompany(
    String? industry,
    String name,
    List<DerivedMetric> metrics,
  ) {
    double? value(String key) =>
        metrics.where((m) => m.key == key).firstOrNull?.derived.value;
    if (usesFinancialOverviewMetrics(industry, name)) {
      return const MetricProfile(
        '금융 · 자본과 수익성',
        '자본 대비 가격과 자본이 벌어들이는 이익을 함께 봅니다.',
        ['marketCap', 'pbr', 'roe', 'per', 'roa', 'profitGrowth'],
      );
    }
    if (isAssetInvestmentVehicle(name)) {
      return const MetricProfile(
        '자산 운용 · 자본과 현금',
        '장부자본과 현금을 확인하고, 배당은 주주환원 탭에서 봅니다.',
        ['marketCap', 'pbr', 'roe', 'per', 'cash', 'debtRatio'],
      );
    }
    final per = metrics.where((m) => m.key == 'per').firstOrNull;
    final loss = per?.derived.missing?.startsWith('순이익 0 이하') ?? false;
    if (loss) {
      return const MetricProfile(
        '적자 구간 · 매출과 현금',
        '매출 규모·성장과 손실 폭을 함께 읽습니다. PSR만으로 수익성을 판단하지 않습니다.',
        [
          'marketCap',
          'psr',
          'revenueGrowth',
          'operatingMargin',
          'cash',
          'fcfYield',
        ],
      );
    }
    final code = int.tryParse((industry ?? '').padRight(2).substring(0, 2));
    if (code != null &&
        (code >= 10 && code <= 39 || code >= 49 && code <= 52)) {
      return MetricProfile(
        '설비 중심 · 이익과 투자',
        '영업이익과 감가상각 전 이익을 비교하고 설비투자 부담을 함께 봅니다.',
        [
          'marketCap',
          value('evEbitda') != null ? 'evEbitda' : 'por',
          'per',
          'operatingMargin',
          'capexRatio',
          'fcfYield',
        ],
      );
    }
    return const MetricProfile(
      '사업 성장 · 가격과 수익성',
      '매출 성장과 이익 전환을 확인하고 현재 가격을 비교합니다.',
      [
        'marketCap',
        'per',
        'psr',
        'revenueGrowth',
        'operatingMargin',
        'fcfYield',
      ],
    );
  }

  List<DerivedMetric> select(List<DerivedMetric> metrics) => [
    for (final key in keys) ...metrics.where((m) => m.key == key),
  ];
}

const metricDescriptions = <String, String>{
  'per': '순이익에 비해 주식 가격이 어느 수준인가',
  'pbr': '장부자본에 비해 주식 가격이 어느 수준인가',
  'por': '영업이익 대비 가격 · 이자·세금 차이는 반영하지 않음',
  'psr': '매출 대비 가격 · 이익률과 함께 비교',
  'pcf': '영업에서 들어오는 현금 대비 가격',
  'peg': '예상 이익 성장률까지 고려한 가격',
  'evEbitda': '부채·현금을 반영한 가격과 감가상각 전 이익',
  'evOperating': '부채·현금을 반영한 기업가치 대비 영업이익',
  'evSales': '부채·현금을 반영한 기업가치 대비 매출',
  'revenueGrowth': '최근 12개월 매출의 전년 대비 변화',
  'profitGrowth': '최근 12개월 순이익의 전년 대비 변화',
  'roe': '자기자본이 벌어들이는 이익',
  'roa': '전체 자산이 벌어들이는 이익',
  'operatingMargin': '매출에서 영업이익으로 남는 비율',
  'ebitdaMargin': '매출에서 감가상각 전 이익으로 남는 비율',
  'ebitda': '영업이익에 공시된 상각 비용을 더한 값',
  'ocfMargin': '매출에 비해 영업현금흐름이 얼마나 남는가',
  'capexRatio': '매출 대비 유형자산 취득 부담',
  'debtRatio': '자본 대비 부채총계 · 이자부채와 다름',
  'cash': '최근 기말 현금및현금성자산',
  'freeCashFlow': '영업현금흐름에서 유형자산 취득을 뺀 금액',
  'fcfYield': '시가총액 대비 설비투자 후 현금흐름',
};
const metricGroups = <String, List<String>>{
  '가격': [
    'per',
    'pbr',
    'por',
    'psr',
    'pcf',
    'evEbitda',
    'evOperating',
    'evSales',
    'peg',
  ],
  '성장·수익성': [
    'revenueGrowth',
    'profitGrowth',
    'roe',
    'roa',
    'operatingMargin',
    'ebitda',
    'ebitdaMargin',
  ],
  '현금·투자': [
    'cash',
    'ocfMargin',
    'capexRatio',
    'freeCashFlow',
    'fcfYield',
    'debtRatio',
  ],
};

/// Sector-inappropriate multiples are excluded from the explorer as well.
bool metricApplies(String key, String? industry, String name) {
  if (usesFinancialOverviewMetrics(industry, name)) {
    return const {
      'marketCap',
      'per',
      'pbr',
      'peg',
      'roe',
      'roa',
      'profitGrowth',
      'cash',
    }.contains(key);
  }
  if (isAssetInvestmentVehicle(name)) {
    return !const {
      'freeCashFlow',
      'fcfYield',
      'capexRatio',
      'ebitda',
      'ebitdaMargin',
      'evEbitda',
    }.contains(key);
  }
  return true;
}
