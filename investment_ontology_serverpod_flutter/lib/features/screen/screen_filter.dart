import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// 스크리너 조건. 주소(`/screen?market=kospi&per=10&roe=15&sort=per&asc=1`)와 오간다.
@immutable
class ScreenFilter {
  const ScreenFilter({
    this.market,
    this.perMax,
    this.pbrMax,
    this.roeMin,
    this.marginMin,
    this.debtMax,
    this.dividendMin,
    this.fcfMin,
    this.revenueGrowthMin,
    this.opGrowthMin,
    this.liquidityMin,
    this.sort = ScreenSort.marketCap,
    this.ascending = false,
  });

  factory ScreenFilter.fromQuery(Map<String, String> q) {
    double? number(String key) {
      final v = double.tryParse(q[key] ?? '');
      return v == null || v <= 0 ? null : v;
    }

    return ScreenFilter(
      market: switch (q['market']) {
        'kospi' => Market.kospi,
        'kosdaq' => Market.kosdaq,
        'konex' => Market.konex,
        _ => null,
      },
      perMax: number('per'),
      pbrMax: number('pbr'),
      roeMin: number('roe'),
      marginMin: number('margin'),
      debtMax: number('debt'),
      dividendMin: number('div'),
      fcfMin: number('fcf'),
      revenueGrowthMin: number('rgrow'),
      opGrowthMin: number('ogrow'),
      liquidityMin: number('liq'),
      sort: ScreenSort.values.asNameMap()[q['sort']] ?? ScreenSort.marketCap,
      ascending: q['asc'] == '1',
    );
  }

  final Market? market;
  final double? perMax;
  final double? pbrMax;
  final double? roeMin;
  final double? marginMin;
  final double? debtMax;
  final double? dividendMin;
  final double? fcfMin;
  final double? revenueGrowthMin;
  final double? opGrowthMin;

  /// 하루 평균 거래대금 최소 (억원)
  final double? liquidityMin;
  final ScreenSort sort;
  final bool ascending;

  bool get hasCondition => conditionCount > 0;

  /// 걸린 조건 수 (시장·정렬은 조건이 아니다).
  int get conditionCount => [
    perMax,
    pbrMax,
    roeMin,
    marginMin,
    debtMax,
    dividendMin,
    fcfMin,
    revenueGrowthMin,
    opGrowthMin,
    liquidityMin,
  ].whereType<double>().length;

  ScreenFilter copyWith({
    Market? Function()? market,
    double? Function()? perMax,
    double? Function()? pbrMax,
    double? Function()? roeMin,
    double? Function()? marginMin,
    double? Function()? debtMax,
    double? Function()? dividendMin,
    double? Function()? fcfMin,
    double? Function()? revenueGrowthMin,
    double? Function()? opGrowthMin,
    double? Function()? liquidityMin,
    ScreenSort? sort,
    bool? ascending,
  }) => ScreenFilter(
    market: market == null ? this.market : market(),
    perMax: perMax == null ? this.perMax : perMax(),
    pbrMax: pbrMax == null ? this.pbrMax : pbrMax(),
    roeMin: roeMin == null ? this.roeMin : roeMin(),
    marginMin: marginMin == null ? this.marginMin : marginMin(),
    debtMax: debtMax == null ? this.debtMax : debtMax(),
    dividendMin: dividendMin == null ? this.dividendMin : dividendMin(),
    fcfMin: fcfMin == null ? this.fcfMin : fcfMin(),
    revenueGrowthMin: revenueGrowthMin == null
        ? this.revenueGrowthMin
        : revenueGrowthMin(),
    opGrowthMin: opGrowthMin == null ? this.opGrowthMin : opGrowthMin(),
    liquidityMin: liquidityMin == null ? this.liquidityMin : liquidityMin(),
    sort: sort ?? this.sort,
    ascending: ascending ?? this.ascending,
  );

  String get location {
    final q = <String, String>{
      if (market case final m?) 'market': m.name,
      if (perMax case final v?) 'per': _trim(v),
      if (pbrMax case final v?) 'pbr': _trim(v),
      if (roeMin case final v?) 'roe': _trim(v),
      if (marginMin case final v?) 'margin': _trim(v),
      if (debtMax case final v?) 'debt': _trim(v),
      if (dividendMin case final v?) 'div': _trim(v),
      if (fcfMin case final v?) 'fcf': _trim(v),
      if (revenueGrowthMin case final v?) 'rgrow': _trim(v),
      if (opGrowthMin case final v?) 'ogrow': _trim(v),
      if (liquidityMin case final v?) 'liq': _trim(v),
      if (sort != ScreenSort.marketCap) 'sort': sort.name,
      if (ascending) 'asc': '1',
    };
    if (q.isEmpty) return '/screen';
    return '/screen?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  bool operator ==(Object other) =>
      other is ScreenFilter &&
      other.market == market &&
      other.perMax == perMax &&
      other.pbrMax == pbrMax &&
      other.roeMin == roeMin &&
      other.marginMin == marginMin &&
      other.debtMax == debtMax &&
      other.dividendMin == dividendMin &&
      other.fcfMin == fcfMin &&
      other.revenueGrowthMin == revenueGrowthMin &&
      other.opGrowthMin == opGrowthMin &&
      other.liquidityMin == liquidityMin &&
      other.sort == sort &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(
    market,
    perMax,
    pbrMax,
    roeMin,
    marginMin,
    debtMax,
    dividendMin,
    fcfMin,
    revenueGrowthMin,
    opGrowthMin,
    liquidityMin,
    sort,
    ascending,
  );
}
