import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';

void main() {
  test('All 25 validated revenue rows survive extraction', () {
    final text =
        '(단위 : 백만원, %)\n부문 | 매출액 | 비중\n${List.generate(25, (i) => '제품$i | 100 | 4.0%').join('\n')}\n합계 | 2500 | 100%';
    expect(SegmentRevenue.parse(text), hasLength(25));
    expect(
      SegmentRevenue.parse(
        text.replaceFirst('제품24 | 100 | 4.0%', '제품24 | 100 | 40.0%'),
      ),
      isEmpty,
    );
  });
  test('All 45 validated production rows survive extraction', () {
    final text =
        '(단위 : 대, %)\n품목 | 생산능력 | 생산실적 | 가동률\n${List.generate(45, (i) => '제품$i | 100 | 50 | 50%').join('\n')}';
    expect(ProductionFacts.parse(text), hasLength(45));
  });
}
