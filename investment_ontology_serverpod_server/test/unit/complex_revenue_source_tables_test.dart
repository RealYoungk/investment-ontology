import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/complex_revenue_source_tables.dart';

void main() {
  for (final name in ['이마트', '영원무역', '현대자동차']) {
    test('$name preserves source without aggregating hierarchy', () {
      final text = File('test/fixtures/business_complex_revenue/$name.txt')
          .readAsStringSync();
      final tables = ComplexRevenueSourceTables.parse(text);
      expect(tables, isNotEmpty);
      expect(tables.every((t) => t.measures.isEmpty), isTrue);
      for (final table in tables) {
        expect(text.contains(table.evidence), isTrue);
        expect(table.rows.every((r) => text.contains(r.cells.single)), isTrue);
      }
    });
  }
  test('preceding unrelated table does not supply sales context', () {
    const text =
        '매출 | 2026년 | 2025년\n상품 | 10 | 20\n구분 | 2026년 | 2025년\n원재료 | 10 | 20\n기타 | 30 | 40\n합계 | 40 | 60';
    expect(ComplexRevenueSourceTables.parse(text), isEmpty);
  });
  test('R&D denominator and purchases do not become revenue tables', () {
    for (final title in ['연구개발비용', '원재료 매입액']) {
      final text =
          '$title\n구분 | 2026년 | 2025년\n합계 | 30 | 40\n매출액 | 100 | 200\n합계 | 130 | 240';
      expect(ComplexRevenueSourceTables.parse(text), isEmpty);
    }
  });
  test('new period header and section stop source table scope', () {
    const text =
        '매출 현황\n구분 | 2026년 | 2025년\n상품 | 10 | 20\n소계 | 10 | 20\n합계 | 10 | 20\n구분 | 2024년 | 2023년\n자산 | 100 | 200\n## 다음 절\n매출 | 99 | 99';
    final result = ComplexRevenueSourceTables.parse(
      text,
      reportPeriod: '2026 반기',
    );
    expect(result, hasLength(1));
    expect(result.single.evidence, isNot(contains('2024년')));
    expect(result.single.scope, isNot('2026 반기'));
    expect(
      result.single.rows.every(
        (r) => r.cells.length == result.single.columns.length,
      ),
      isTrue,
    );
  });
  test('Kolon R&D capitalization is not sales composition', () {
    final text = File('test/fixtures/business_complex_revenue/kolon-rnd.txt')
        .readAsStringSync();
    expect(ComplexRevenueSourceTables.parse(text), isEmpty);
  });
  test('Doosan investment effect sales growth is not revenue', () {
    final text = File(
      'test/fixtures/business_complex_revenue/doosan-investment.txt',
    ).readAsStringSync();
    expect(ComplexRevenueSourceTables.parse(text), isEmpty);
  });
}
