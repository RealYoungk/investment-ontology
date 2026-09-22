import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/market/comparison_date.dart';

void main() {
  test('한 달 전은 30일 전이 아니라 달력상 같은 날', () {
    expect(
      comparisonMonth(DateTime.utc(2026, 9, 21), 1),
      DateTime.utc(2026, 8, 21),
    );
  });
  test('월말은 비교 월의 마지막 날로 제한', () {
    expect(
      comparisonMonth(DateTime.utc(2026, 3, 31), 1),
      DateTime.utc(2026, 2, 28),
    );
    expect(
      comparisonMonth(DateTime.utc(2024, 3, 31), 1),
      DateTime.utc(2024, 2, 29),
    );
  });
  test('윤일의 1년 전과 연도 경계', () {
    expect(
      comparisonMonth(DateTime.utc(2024, 2, 29), 12),
      DateTime.utc(2023, 2, 28),
    );
    expect(
      comparisonMonth(DateTime.utc(2026, 1, 31), 1),
      DateTime.utc(2025, 12, 31),
    );
  });
}
