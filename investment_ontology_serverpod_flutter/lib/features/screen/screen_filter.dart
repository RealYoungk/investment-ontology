import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// 스크리너 조건. 주소(`/screen?market=kospi&per=10&roe=15&sort=per&asc=1`)와 오간다.
@immutable
class ScreenFilter {
  const ScreenFilter({
    this.market,
    this.presetIds = const [],
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
    this.payoutMax,
    this.dividendYearsMin,
    this.volumeMin,
    this.volumeRatioMin,
    this.marketCapMin,
    this.return3mMin,
    this.return12mMin,
    this.bandPositionMin,

    this.sort = ScreenSort.marketCap,
    this.ascending = false,
  });

  factory ScreenFilter.fromQuery(Map<String, String> q) {
    double? number(String key) {
      final v = double.tryParse(q[key] ?? '');
      final signed = const {
        'roe',
        'margin',
        'rgrow',
        'ogrow',
        'fcf',
        'r3m',
        'r12m',
      }.contains(key);
      if (v == null || !v.isFinite || (!signed && v < 0)) return null;
      if (key == 'divyears' && (v > 3 || v != v.roundToDouble())) return null;
      if (key == 'band' && v > 100) return null;
      if ((key == 'r3m' || key == 'r12m') && v < -100) return null;
      return v;
    }

    return ScreenFilter(
      presetIds:
          (q['presets'] ?? '')
              .split(',')
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
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
      payoutMax: number('payout'),
      dividendYearsMin: number('divyears'),
      volumeMin: number('vol'),
      volumeRatioMin: number('volratio'),
      marketCapMin: number('cap'),
      return3mMin: number('r3m'),
      return12mMin: number('r12m'),
      bandPositionMin: number('band'),

      sort: ScreenSort.values.asNameMap()[q['sort']] ?? ScreenSort.marketCap,
      ascending: q['asc'] == '1',
    );
  }

  final Market? market;
  final List<String> presetIds;
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
  final double? payoutMax;
  final double? dividendYearsMin;
  final double? volumeMin;
  final double? volumeRatioMin;
  final double? marketCapMin;
  final double? return3mMin;
  final double? return12mMin;
  final double? bandPositionMin;

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
    payoutMax,
    dividendYearsMin,
    volumeMin,
    volumeRatioMin,
    marketCapMin,
    return3mMin,
    return12mMin,
    bandPositionMin,
  ].whereType<double>().length;

  ScreenFilter copyWith({
    List<String>? presetIds,
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
    double? Function()? payoutMax,
    double? Function()? dividendYearsMin,
    double? Function()? volumeMin,
    double? Function()? volumeRatioMin,
    double? Function()? marketCapMin,
    double? Function()? return3mMin,
    double? Function()? return12mMin,
    double? Function()? bandPositionMin,

    ScreenSort? sort,
    bool? ascending,
  }) => ScreenFilter(
    presetIds: presetIds ?? this.presetIds,
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
    payoutMax: payoutMax == null ? this.payoutMax : payoutMax(),
    dividendYearsMin: dividendYearsMin == null
        ? this.dividendYearsMin
        : dividendYearsMin(),
    volumeMin: volumeMin == null ? this.volumeMin : volumeMin(),
    volumeRatioMin: volumeRatioMin == null
        ? this.volumeRatioMin
        : volumeRatioMin(),
    marketCapMin: marketCapMin == null ? this.marketCapMin : marketCapMin(),
    return3mMin: return3mMin == null ? this.return3mMin : return3mMin(),
    return12mMin: return12mMin == null ? this.return12mMin : return12mMin(),
    bandPositionMin: bandPositionMin == null
        ? this.bandPositionMin
        : bandPositionMin(),
    sort: sort ?? this.sort,
    ascending: ascending ?? this.ascending,
  );

  String get location {
    final q = <String, String>{
      if (presetIds.isNotEmpty) 'presets': presetIds.join(','),
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
      if (payoutMax case final v?) 'payout': _trim(v),
      if (dividendYearsMin case final v?) 'divyears': _trim(v),
      if (volumeMin case final v?) 'vol': _trim(v),
      if (volumeRatioMin case final v?) 'volratio': _trim(v),
      if (marketCapMin case final v?) 'cap': _trim(v),
      if (return3mMin case final v?) 'r3m': _trim(v),
      if (return12mMin case final v?) 'r12m': _trim(v),
      if (bandPositionMin case final v?) 'band': _trim(v),

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
      other.presetIds.join(',') == presetIds.join(',') &&
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
      other.payoutMax == payoutMax &&
      other.dividendYearsMin == dividendYearsMin &&
      other.volumeMin == volumeMin &&
      other.volumeRatioMin == volumeRatioMin &&
      other.marketCapMin == marketCapMin &&
      other.return3mMin == return3mMin &&
      other.return12mMin == return12mMin &&
      other.bandPositionMin == bandPositionMin &&
      other.sort == sort &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hashAll([
    presetIds.join(','),
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
    payoutMax,
    dividendYearsMin,
    volumeMin,
    volumeRatioMin,
    marketCapMin,
    return3mMin,
    return12mMin,
    bandPositionMin,

    sort,
    ascending,
  ]);
}
