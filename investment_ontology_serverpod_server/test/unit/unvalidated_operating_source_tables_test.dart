import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/unvalidated_operating_source_tables.dart';

void main() {
  test('unit and table boundaries never infer percent or accept infinity', () {
    for (final source in [
      '사업소 | 평균가동률\nA | 33',
      '(단위 : %)\n## 새 절\n사업소 | 평균가동률\nA | 33',
      '(단위 : %)\n항목 | 금액\n사업소 | 평균가동률\nA | 33',
      '(단위 : %)\n사업소 | 평균가동률\nA | Infinity',
    ]) {
      expect(UnvalidatedOperatingSourceTables.parse(source, '2025'), isEmpty);
    }
    expect(
      UnvalidatedOperatingSourceTables.parse(
        '사업소 | 평균가동률\nA | 103.2%',
        '2025',
      ).single.measures.single.value,
      103.2,
    );
  });
  test('S-Oil preserves periods and source-only status', () {
    final cards = UnvalidatedOperatingSourceTables.parse(
      File('test/fixtures/business_operating_source/soil.txt')
          .readAsStringSync(),
      '2026 반기',
    );
    final values = cards.expand((c) => c.measures).toList();
    expect(values.any((m) => m.value == 98008 && m.unit == '천배럴'), isTrue);
    expect(
      values.any((m) => m.value == 236050 && m.period.contains('2025')),
      isTrue,
    );
    expect(cards.first.validation, contains('검산 미수행'));
    expect(
      cards.first.rows.every(
        (r) => r.cells.length == cards.first.columns.length,
      ),
      isTrue,
    );
  });
  test('two-column utilization accepts over 100', () {
    final cards = UnvalidatedOperatingSourceTables.parse(
      File('test/fixtures/business_operating_source/amore.txt')
          .readAsStringSync(),
      '2026 반기',
    );
    expect(
      cards
          .expand((c) => c.measures)
          .any((m) => m.value == 126.3 && m.unit == '%'),
      isTrue,
    );
  });
  test('scoped limitation keeps exact prose without zero', () {
    final cards = UnvalidatedOperatingSourceTables.parse(
      '## 자회사\n자회사 A의 생산능력 산출이 곤란합니다.\n연구개발비는 별도로 계상하지 않습니다.',
      '2025',
    );
    expect(cards.length, 2);
    expect(cards.every((c) => c.measures.isEmpty), isTrue);
    expect(cards.first.evidence, '자회사 A의 생산능력 산출이 곤란합니다.');
  });
}
