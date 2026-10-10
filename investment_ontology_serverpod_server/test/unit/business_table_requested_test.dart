import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  for (final (name, topic, value, unit) in [
    ('gigavis-material', 'materialPurchase', 13048, '백만원'),
    ('gigavis-investment', 'investmentPlan', 18500, '백만원'),
    ('qrt-projects', 'researchProjects', 2080, '백만원'),
    ('sphere-material', 'materialPurchase', 67326372, '천원'),
    ('sphere-projects', 'researchProjects', 400, '백만원'),
  ]) {
    test('source-audited $name preserves the printed amount and unit', () {
      final source = File('test/fixtures/business_tables/requested/$name.txt')
          .readAsStringSync();
      final tables = BusinessTableInsights.parse(source, reportPeriod: '원문 기간');
      final table = tables.singleWhere((t) => t.topic == topic);
      expect(table.measures.first.value, value);
      expect(table.measures.first.unit, unit);
      expect(source.contains(table.evidence), isTrue);
    });
  }
  test('Sunic combined amount/share cells preserve all six items and merged metadata', () {
    final source = File(
      'test/fixtures/business_tables/requested/sunic-material.txt',
    ).readAsStringSync();
    final table = BusinessTableInsights.parse(
      source,
      reportPeriod: '2025 연간',
    ).single;
    expect(table.rows, hasLength(7));
    expect(table.measures, hasLength(36));
    expect(table.rows[1].cells[0], 'OLED 제조장비');
    expect(table.rows[1].cells[1], '원재료');
    expect(table.rows[1].cells[2], 'PUMP 외');
    expect(table.measures.first.value, 13446);
    expect(table.measures.first.unit, '백만원');
    expect(table.measures[1].value, 7.6);
    expect(table.measures[1].unit, '%');
    expect(table.measures.first.period, '2025년');
  });
  for (final (name, topic, rows, value, unit) in [
    ('mico-tube', 'materialPurchase', 1, 32258, '백만원'),
    ('sunic-contract', 'majorContracts', 2, 23615140000, '원'),
    ('gigavis-sensitivity', 'riskSensitivity', 4, 9900, '천원'),
  ]) {
    test('previously missed $name is extracted from its explicit shape', () {
      final source = File('test/fixtures/business_tables/requested/$name.txt')
          .readAsStringSync();
      final table = BusinessTableInsights.parse(
        source,
        reportPeriod: '2026 반기',
      ).singleWhere((t) => t.topic == topic);
      expect(table.rows, hasLength(rows));
      expect(table.measures.first.value, value);
      expect(table.measures.first.unit, unit);
      expect(source.contains(table.evidence), isTrue);
      if (name == 'sunic-contract') {
        expect(table.measures.last.value, 19000000000);
      }
      if (name == 'gigavis-sensitivity') {
        expect(
          table.measures.map((m) => m.value),
          containsAll([9900, -9900, 197796, -197796]),
        );
        expect(table.measures.first.period, contains('당반기'));
      }
    });
  }
}
