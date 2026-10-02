import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/macro/macro_metrics.dart';

void main() {
  final points = [
    IndexPoint(date: DateTime.utc(2026, 9, 1), value: 4),
    IndexPoint(date: DateTime.utc(2026, 10, 1), value: 5),
  ];
  MacroSeriesView series(bool rate) => MacroSeriesView(
    seriesId: 'test',
    name: 'test',
    group: '금리',
    unit: '%',
    rate: rate,
    points: points,
    status: 'ready',
  );
  test(
    'Yield changes use percentage points, prices use percentage changes',
    () {
      expect(MacroMetrics.change(series(true), points.first), 1);
      expect(MacroMetrics.delta(series(true), 1), '+1.00%p');
      expect(MacroMetrics.change(series(false), points.first), 25);
      expect(MacroMetrics.delta(series(false), 25), '+25.00%');
    },
  );
  test('Fixed calendar baselines require nearby earlier observation', () {
    expect(MacroMetrics.base(points, 30), points.first);
    expect(MacroMetrics.base(points, 20), isNull);
    expect(MacroMetrics.base(points, 365), isNull);
    expect(MacroMetrics.base(points, 0), isNull);
  });
  test('Zero and negative bases never generate misleading percent returns', () {
    for (final value in [0.0, -1.0]) {
      expect(
        MacroMetrics.change(
          series(false),
          IndexPoint(date: points.first.date, value: value),
        ),
        isNull,
      );
    }
  });
}
