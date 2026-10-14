import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_unreconciled_source_tables.dart';

void main() {
  test('inconsistent monetary balance remains a literal source observation', () {
    const source =
        '(단위: 백만원, MT)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n영풍 | 348,000 | 1,239,960 | 315,682 | 1,507,386 | -32,318 | 267,426';
    expect(OrderFacts.parse(source), isEmpty);
    final tables = OrderUnreconciledSourceTables.parse(source, '2022 연간');
    expect(tables.single.validation, contains('검산 불일치'));
    expect(tables.single.measures.map((m) => m.value), [
      1239960.0,
      1507386.0,
      267426.0,
    ]);
    expect(tables.single.rows.single.cells.single, contains('-32,318'));
  });
  test('no money subheader means six cells remain ambiguous rather than biggest triple', () {
    const source =
        '(단위: 백만원, 개)\n품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 10000 | 100 | 4000 | 40 | 6000 | 60';
    expect(OrderFacts.parse(source), isEmpty);
    final tables = OrderUnreconciledSourceTables.parse(source, '2025 연간');
    expect(tables.single.topic, 'orderSourceAmbiguous');
    expect(tables.single.measures, isEmpty);
  });
  test(
    'Gangstem missing monetary markers remain raw, explicit zero stays numeric',
    () {
      const header = '(단위: 원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n';
      const missing = '$header합 계 | - | — | -';
      expect(OrderFacts.parse(missing), isEmpty);
      final raw = OrderUnreconciledSourceTables.parse(missing, '2026 반기');
      expect(raw.single.measures, isEmpty);
      expect(raw.single.evidence, contains('합 계 | - | — | -'));
      const blank = '$header합계 | 100 |  | 100';
      expect(OrderFacts.parse(blank), isEmpty);
      expect(
        OrderUnreconciledSourceTables.parse(
          blank,
          '2026 반기',
        ).single.measures.map((m) => m.metric),
        ['수주총액', '수주잔고'],
      );
      const partial = '$header합계 | 100 | - | 100';
      expect(OrderFacts.parse(partial), isEmpty);
      expect(
        OrderUnreconciledSourceTables.parse(
          partial,
          '2026 반기',
        ).single.measures.map((m) => m.metric),
        ['수주총액', '수주잔고'],
      );
      const explicit = '$header합계 | 100 | 0 | 100';
      expect(OrderFacts.parse(explicit).single.delivered, 0);
    },
  );
}
