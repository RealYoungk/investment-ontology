import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:test/test.dart';

/// 실제 사업보고서 본문에서 가져온 표 모양으로 확인한다.
void main() {
  test('머리글 아래 표에서 생산능력·생산실적·가동률을 읽는다', () {
    const text = '''
(2) 주요 제품 생산실적 및 가동률
사업부문 | 품 목 | 단 위 | 생산능력 | 생산실적 | 평균가동률
에너지솔루션 | 소형전지 | 백만개 | 2,520 | 1,269 | 50%
전자재료 | EMC | 톤 | 4,655 | 1,227 | 26%
※ 전자재료 부문의 편광필름 사업 양도에 따라 제외하였습니다.
''';
    final rows = ProductionFacts.parse(text);
    expect(rows, hasLength(2));
    expect(rows.first.label, '에너지솔루션 · 소형전지');
    expect(rows.first.unit, '백만개');
    expect(rows.first.capacity, 2520);
    expect(rows.first.production, 1269);
    expect(rows.first.utilization, 50);
    expect(rows.first.evidence, contains('2,520'));
    expect(rows.last.unit, '톤');
  });

  test('가동률이 생산실적 ÷ 생산능력과 어긋나면 버린다 (열을 잘못 읽은 것)', () {
    const text = '''
사업부문 | 품 목 | 단 위 | 생산능력 | 생산실적 | 평균가동률
에너지솔루션 | 소형전지 | 백만개 | 2,520 | 1,269 | 90%
''';
    expect(ProductionFacts.parse(text), isEmpty);
  });

  test('머리글이 없으면 아무것도 읽지 않는다', () {
    const text = '''
사업부문 | 품 목 | 단 위 | 값 | 값 | 비율
에너지솔루션 | 소형전지 | 백만개 | 2,520 | 1,269 | 50%
''';
    expect(ProductionFacts.parse(text), isEmpty);
  });

  test('단위를 못 찾으면 이름만 남고 단위는 비어 저장하지 않는다', () {
    const text = '''
구 분 | 생산능력 | 생산실적 | 가동률
반도체 | 1,000 | 800 | 80%
''';
    final rows = ProductionFacts.parse(text);
    expect(rows, hasLength(1));
    expect(rows.first.label, '반도체');
    expect(rows.first.unit, isEmpty);
  });

  test('머리글의 단위를 쓴다', () {
    const text = '''
(단위 : 백만원, %)
사업부문 | 생산능력 | 생산실적 | 가동률
반도체 | 1,000 | 800 | 80%
''';
    // 머리글 줄과 단위 줄이 따로여도, 단위가 적힌 머리글 줄이면 받는다.
    const withUnit = '''
사업부문 | 생산능력 | 생산실적 | 가동률 (단위 : 백만원)
반도체 | 1,000 | 800 | 80%
''';
    expect(ProductionFacts.parse(text).first.unit, isEmpty);
    expect(ProductionFacts.parse(withUnit).first.unit, '백만원');
  });
}
