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
      sort: ScreenSort.values.asNameMap()[q['sort']] ?? ScreenSort.marketCap,
      ascending: q['asc'] == '1',
    );
  }

  final Market? market;
  final double? perMax;
  final double? pbrMax;
  final double? roeMin;
  final double? marginMin;
  final ScreenSort sort;
  final bool ascending;

  bool get hasCondition =>
      perMax != null || pbrMax != null || roeMin != null || marginMin != null;

  ScreenFilter copyWith({
    Market? Function()? market,
    double? Function()? perMax,
    double? Function()? pbrMax,
    double? Function()? roeMin,
    double? Function()? marginMin,
    ScreenSort? sort,
    bool? ascending,
  }) => ScreenFilter(
    market: market == null ? this.market : market(),
    perMax: perMax == null ? this.perMax : perMax(),
    pbrMax: pbrMax == null ? this.pbrMax : pbrMax(),
    roeMin: roeMin == null ? this.roeMin : roeMin(),
    marginMin: marginMin == null ? this.marginMin : marginMin(),
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
      other.sort == sort &&
      other.ascending == ascending;

  @override
  int get hashCode =>
      Object.hash(market, perMax, pbrMax, roeMin, marginMin, sort, ascending);
}
