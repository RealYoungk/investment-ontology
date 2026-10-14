import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/literal_table_number.dart';
import 'package:test/test.dart';

void main() {
  test('merged filing cells never become single gigantic amounts', () {
    for (final cell in [
      '255,2255,5058,08599732,621',
      '24,5791226,350',
      '11,04',
      '551,888,',
      '1,',
      '75.261.622.380.299.62',
    ]) {
      expect(literalTableNumber(cell), isNull, reason: cell);
    }
    expect(literalTableNumber('302,433'), 302433);
    expect(literalTableNumber('1234567'), 1234567);
    expect(literalTableNumber('-1,234.50'), -1234.5);
    expect(literalTableNumber('(1,234)'), -1234);
    expect(literalTableNumber('▲1,234'), -1234);
    expect(literalTableNumber('47.6%'), 47.6);
  });
  test('bank merged source rows remain readable without fabricated charts', () {
    const text =
        '(단위 : 억원, %)\n구 분 | 조달항목 | 2026년 2분기 | 2025년 | 2024년\n'
        '평균잔액 | 이자율 | 비중 | 평균잔액 | 이자율 | 비중 | 평균잔액 | 이자율 | 비중\n'
        '원화자금 | 예 수 금양도성예금증서차 입 금원 화 콜 머 니기 타 | 255,2255,5058,08599732,621 | 2.012.771.732.462.78 | 75.261.622.380.299.62 | 238,22510,3477,5361,71427,248 | 2.122.921.552.612.83 | 74.573.242.360.548.53 | 227,06110,5557,5173,76620,206 | 2.533.901.753.463.77 | 75.433.512.501.256.71\n'
        '소 계 | 302,433 | 2.10 | 89.17 | 285,070 | 2.20 | 89.24 | 269,105 | 2.67 | 89.40\n';
    final tables = BusinessTableInsights.parse(text, reportPeriod: '2026 반기');
    expect(tables, isNotEmpty);
    expect(tables.first.evidence, contains('255,2255,5058'));
    expect(
      tables.expand((t) => t.measures).any((m) => m.value > 1e10),
      isFalse,
    );
    expect(
      tables
          .expand((t) => t.rows)
          .any((r) => r.cells.contains('255,2255,5058,08599732,621')),
      isTrue,
    );
  });
}
