import '../../generated/protocol.dart';

/// Monthly observations keep gaps and missing share classes, not zero caps.
/// Without a delisting registry, a once-observed share class stays expected.
/// Disappearing quotes leave a gap instead of understating total capitalization.
abstract final class CompanyCapHistory {
  static List<CompanyMarketCap> build({
    required List<DateTime> marketDates,
    required List<Security> securities,
    required List<MarketSnapshot> snapshots,
    required Map<int, (DateTime, DateTime)> coverage,
    Map<int, Source> sources = const {},
  }) {
    final months = <(int, int), DateTime>{};
    for (final date in marketDates) {
      final key = (date.year, date.month);
      if (months[key] == null || months[key]!.isBefore(date)) {
        months[key] = date;
      }
    }
    if (months.isNotEmpty) {
      final observed = months.values.toList()..sort();
      var month = DateTime.utc(observed.first.year, observed.first.month);
      final end = DateTime.utc(observed.last.year, observed.last.month);
      while (!month.isAfter(end)) {
        // Calendar month-end is only a null placeholder when no market day was
        // collected; never join two observed months across a hidden gap.
        months.putIfAbsent((
          month.year,
          month.month,
        ), () => DateTime.utc(month.year, month.month + 1, 0));
        month = DateTime.utc(month.year, month.month + 1);
      }
    }
    final byDate = <DateTime, Map<int, MarketSnapshot>>{};
    for (final s in snapshots) {
      (byDate[s.baseDate] ??= {})[s.securityId] = s;
    }
    final dates = months.values.toList()..sort();
    return [
      for (final date in dates)
        _point(date, securities, byDate[date] ?? {}, coverage, sources),
    ];
  }

  static CompanyMarketCap _point(
    DateTime date,
    List<Security> securities,
    Map<int, MarketSnapshot> rows,
    Map<int, (DateTime, DateTime)> coverage,
    Map<int, Source> sources,
  ) {
    final expected = securities.where((s) {
      final span = coverage[s.id];
      return span != null && !date.isBefore(span.$1);
    }).toList();
    BigInt? cap = expected.isEmpty ? null : BigInt.zero;
    for (final security in expected) {
      final value = rows[security.id]?.marketCap;
      cap = cap == null || value == null || value <= BigInt.zero
          ? null
          : cap + value;
    }
    return CompanyMarketCap(
      baseDate: date,
      marketCap: cap,
      securities: [
        for (final s in expected)
          SecurityQuote(
            securityId: s.id!,
            shortCode: s.shortCode,
            name: s.name,
            closePrice: rows[s.id]?.closePrice,
            listedShares: rows[s.id]?.listedShares,
            marketCap: rows[s.id]?.marketCap,
            volume: rows[s.id]?.volume,
          ),
      ],
      source: sources[rows.values.firstOrNull?.sourceId],
    );
  }
}
