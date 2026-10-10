import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';

void main() {
  test('split metric header binds extra merged labels from the right', () {
    final rows = ProductionFacts.parse('''(단위 : 천대)
부 문 | 품 목 | 제57기
생산능력 대수 | 실제 생산 대수 | 가동률
DX 부문 | TV, 모니터 등 | 56,283 | 44,361 | 78.8%
스마트폰 등 | 270,050 | 214,259 | 79.3%
''');
    expect(rows.length, 2);
    expect(rows.first.capacity, 56283);
    expect(rows.first.production, 44361);
    expect(rows.last.capacity, 270050);
    expect(rows.last.utilization, 79.3);
  });
  test('unnamed whole-company vertical table retains validated totals', () {
    final rows = ProductionFacts.parse("""(단위 : 배치)
구 분 | 2025년도(제15기) | 2024년도(제14기) | 2023년도(제13기)
생산능력 | 1,034 | 833 | 733
생산실적 | 733 | 626 | 523
가동률 | 70.9% | 75.2% | 71.4%
""");
    expect(rows.single.label, '전체');
    expect(rows.single.unit, '배치');
    expect(rows.single.capacity, 1034);
    expect(rows.single.utilization, 70.9);
  });
  test('inconsistent production arithmetic remains excluded', () {
    expect(
      ProductionFacts.parse('''생산능력 대수 | 실제 생산 대수 | 가동률
TV | 100 | 40 | 90%
'''),
      isEmpty,
    );
  });
}
