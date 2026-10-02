import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/capital_structure_card.dart';

void main() {
  test('20% new shares reduce 10% ownership to 8.333%, not 8%', () {
    expect(dilutedOwnership(100, 1000, 200), closeTo(8.333333, 0.000001));
    expect(dilutedOwnership(100, 1000, 0), 10);
  });
  test('missing/invalid denominator and impossible holdings are rejected', () {
    expect(dilutedOwnership(10, 0, 20), isNull);
    expect(dilutedOwnership(1001, 1000, 20), isNull);
    expect(dilutedOwnership(10, 1000, -1), isNull);
    expect(dilutedOwnership(double.nan, 1000, 10), isNull);
    expect(dilutedOwnership(0, 1000, 20), 0);
  });
}
