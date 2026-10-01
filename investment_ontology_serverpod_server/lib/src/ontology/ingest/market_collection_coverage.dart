import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'market_snapshot_sync.dart';

typedef MarketCoverage = ({
  DateTime? latestPriceDate,
  int latestPriceSecurities,
  DateTime? latestIndexDate,
  int latestIndexCount,
  DateTime scopeStart,
  DateTime? scopeThrough,
  int expectedWeekdays,
  int priceDaysStored,
  int indexDaysStored,
  int historicalPendingDates,
  int recentUnconfirmedDates,
});

/// Read-only coverage. Zero-row holiday ledgers count as processed dates.
/// Dates after the latest actual price are unconfirmed, not proven holidays
/// or proven unpublished responses. No external API is called by this helper.
abstract final class MarketCollectionCoverage {
  static Future<MarketCoverage> read(Session session, {DateTime? now}) async {
    final checked = now ?? DateTime.now();
    final start = scopeStart(checked);
    final latest = (await session.db.unsafeQuery('''
      SELECT (SELECT max("baseDate") FROM market_snapshot) AS price_date,
        (SELECT count(DISTINCT "securityId") FROM market_snapshot
          WHERE "baseDate"=(SELECT max("baseDate") FROM market_snapshot)) AS price_count,
        (SELECT max("baseDate") FROM market_index_snapshot) AS index_date,
        (SELECT count(*) FROM market_index_snapshot
          WHERE "baseDate"=(SELECT max("baseDate") FROM market_index_snapshot)) AS index_count
    ''')).single.toColumnMap();
    final priceDays = await MarketSnapshotDay.db.find(
      session,
      where: (t) => t.baseDate >= start,
    );
    final indexDays = await MarketIndexDay.db.find(
      session,
      where: (t) => t.baseDate >= start,
    );
    return summarize(
      now: checked,
      latestPriceDate: latest['price_date'] as DateTime?,
      latestPriceSecurities: latest['price_count'] as int,
      latestIndexDate: latest['index_date'] as DateTime?,
      latestIndexCount: latest['index_count'] as int,
      priceDates: priceDays.map((d) => d.baseDate),
      indexDates: indexDays.map((d) => d.baseDate),
    );
  }

  static DateTime scopeStart(DateTime now) {
    final today = MarketSnapshotSync.kstDate(now);
    return DateTime.utc(today.year - 5, today.month, today.day);
  }

  static MarketCoverage summarize({
    required DateTime now,
    required DateTime? latestPriceDate,
    required int latestPriceSecurities,
    required DateTime? latestIndexDate,
    required int latestIndexCount,
    required Iterable<DateTime> priceDates,
    required Iterable<DateTime> indexDates,
  }) {
    final today = MarketSnapshotSync.kstDate(now);
    final start = scopeStart(now);
    DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final through = latestPriceDate == null
        ? null
        : (day(latestPriceDate).isAfter(yesterday)
              ? yesterday
              : day(latestPriceDate));
    final prices = priceDates.map(day).toSet();
    final indexes = indexDates.map(day).toSet();
    var expected = 0,
        priceStored = 0,
        indexStored = 0,
        historicalPending = 0,
        recent = 0;
    for (
      var date = start;
      !date.isAfter(yesterday);
      date = date.add(const Duration(days: 1))
    ) {
      if (date.weekday > DateTime.friday) continue;
      if (through == null || date.isAfter(through)) {
        recent++;
        continue;
      }
      expected++;
      final hasPrice = prices.contains(date);
      final hasIndex = indexes.contains(date);
      if (hasPrice) priceStored++;
      if (hasIndex) indexStored++;
      if (!hasPrice || !hasIndex) historicalPending++;
    }
    return (
      latestPriceDate: latestPriceDate,
      latestPriceSecurities: latestPriceSecurities,
      latestIndexDate: latestIndexDate,
      latestIndexCount: latestIndexCount,
      scopeStart: start,
      scopeThrough: through,
      expectedWeekdays: expected,
      priceDaysStored: priceStored,
      indexDaysStored: indexStored,
      historicalPendingDates: historicalPending,
      recentUnconfirmedDates: recent,
    );
  }
}
