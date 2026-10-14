import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:test/test.dart';

void main() {
  test('segment amount with fused comma groups cannot pass ratio self check', () {
    const valid =
        '(단위 : 천원)\n부문 | 매출액 | 비중\nA | 1,000 | 50%\nB | 1,000 | 50%\n합계 | 2,000 | 100%';
    expect(SegmentRevenue.parse(valid), hasLength(2));
    final rows = SegmentRevenue.parse(
      valid.replaceFirst('A | 1,000', 'A | 1,00,0'),
    );
    expect(rows.any((r) => r.label == 'A'), isFalse);
  });
  test('combined segment amount rejects invalid comma even with printed ratio', () {
    const text =
        '(단위 : 천원)\n품목 | 매출액(비율)\nA | 1,00,0 (50%)\nB | 1,000 (50%)\n합계 | 2,000 (100%)';
    expect(SegmentRevenue.parse(text).any((r) => r.label == 'A'), isFalse);
  });
  test('production fused numbers cannot validate each other', () {
    const valid = '구분 | 단위 | 생산능력 | 생산실적 | 가동률\nA | 톤 | 1,000 | 500 | 50 %';
    expect(ProductionFacts.parse(valid), hasLength(1));
    expect(
      ProductionFacts.parse(valid.replaceFirst('1,000 | 500', '1,00 | 5,0')),
      isEmpty,
    );
  });
  test('production percent does not erase malformed separators', () {
    const text = '구분 | 단위 | 생산능력 | 생산실적 | 가동률\nA | 톤 | 100 | 50 | 5,0%';
    expect(ProductionFacts.parse(text), isEmpty);
  });
}
