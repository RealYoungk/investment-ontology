import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/market/new_observations.dart';

void main() {
  final previous = DateTime.utc(2026, 10, 1);
  bool check({
    DateTime? prior,
    DateTime? latest,
    int count = 2801,
    int offset = 1,
  }) => canRecordObservation(
    date: previous.add(Duration(days: offset)),
    previousDate: prior,
    latestKnownDate: latest,
    previousCount: 2800,
    currentCount: count,
  );

  test(
    'initial baseline and incomplete collection do not create observations',
    () {
      expect(check(latest: previous), isFalse);
      expect(check(prior: previous, latest: previous, count: 2000), isFalse);
    },
  );
  test('backfill and long recovery gaps do not create observations', () {
    expect(
      check(prior: previous, latest: previous.add(const Duration(days: 2))),
      isFalse,
    );
    expect(check(prior: previous, latest: previous, offset: 7), isFalse);
  });
  test('normal next session and weekend continuity allow observations', () {
    expect(check(prior: previous, latest: previous), isTrue);
    expect(check(prior: previous, latest: previous, offset: 4), isTrue);
  });
}
