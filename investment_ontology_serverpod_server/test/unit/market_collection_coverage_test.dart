import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_collection_coverage.dart';

void main() {
  test('KST rolling scope uses five years and actual dates exclude recent unpublished uncertainty', () {
    final now = DateTime.utc(2026, 10, 1, 16);
    final start = MarketCollectionCoverage.scopeStart(now);
    expect(start, DateTime.utc(2021, 10, 2));
    final latest = DateTime.utc(2026, 9, 30);
    final days = [
      for (
        var d = start;
        !d.isAfter(latest);
        d = d.add(const Duration(days: 1))
      )
        d,
    ];
    final value = MarketCollectionCoverage.summarize(
      now: now,
      latestPriceDate: latest,
      latestPriceSecurities: 2873,
      latestIndexDate: latest,
      latestIndexCount: 171,
      priceDates: days,
      indexDates: days,
    );
    expect(value.expectedWeekdays, 1303);
    expect(value.priceDaysStored, 1303);
    expect(value.indexDaysStored, 1303);
    expect(value.historicalPendingDates, 0);
    expect(value.recentUnconfirmedDates, 1);
  });
  test('ledger dates include zero-row holidays; missing price/index date counted once', () {
    final now = DateTime.utc(2026, 10, 2);
    final start = MarketCollectionCoverage.scopeStart(now);
    final latest = DateTime.utc(2026, 9, 30);
    final days = [
      for (
        var d = start;
        !d.isAfter(latest);
        d = d.add(const Duration(days: 1))
      )
        d,
    ];
    final missing = DateTime.utc(2026, 9, 29);
    final value = MarketCollectionCoverage.summarize(
      now: now,
      latestPriceDate: latest,
      latestPriceSecurities: 1,
      latestIndexDate: latest,
      latestIndexCount: 1,
      priceDates: days.where((d) => d != missing),
      indexDates: days.where((d) => d != missing),
    );
    expect(value.historicalPendingDates, 1);
    expect(value.expectedWeekdays - value.priceDaysStored, 1);
    expect(value.expectedWeekdays - value.indexDaysStored, 1);
  });
  test('no actual price does not claim a confirmed source range', () {
    final value = MarketCollectionCoverage.summarize(
      now: DateTime.utc(2026, 10, 2),
      latestPriceDate: null,
      latestPriceSecurities: 0,
      latestIndexDate: null,
      latestIndexCount: 0,
      priceDates: [],
      indexDates: [],
    );
    expect(value.scopeThrough, isNull);
    expect(value.expectedWeekdays, 0);
    expect(value.recentUnconfirmedDates, greaterThan(0));
  });
}
