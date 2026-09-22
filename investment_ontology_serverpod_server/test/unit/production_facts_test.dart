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

  test('가동률만 따로 적는 표도 받되, 어느 두 칸의 비율과 맞아야 한다', () {
    const text = '''
(3) 당해 사업연도의 가동률
사업소(사업부문) | 가동가능시간 | 생산가능수량 | 실제가동시간 | 실제생산수량 | 평균가동률
용인공장 | 6,150 | 26,578 | 5,205 | 20,195 | 84.6%
평택공장 | 6,150 | 26,578 | 5,205 | 20,195 | 30.0%
''';
    final rows = ProductionFacts.parse(text);
    expect(rows, hasLength(1), reason: '30%는 어느 비율과도 맞지 않아 버린다');
    expect(rows.single.label, contains('용인공장'));
    expect(rows.single.utilization, 84.6);
    expect(rows.single.capacity, isNull, reason: '가동률만 있는 표');
  });

  test('다른 회사 이름이 붙은 구역의 표는 건너뛴다 (지주사 보고서)', () {
    const text = '''
[SK하이닉스]
사업부문 | 생산능력 | 생산실적 | 가동률
반도체 | 1,000 | 1,000 | 100%
[SK스퀘어]
사업부문 | 품 목 | 단 위 | 생산능력 | 생산실적 | 평균가동률
플랫폼 | 서비스 | 개 | 200 | 100 | 50%
''';
    final rows = ProductionFacts.parse(
      text,
      owner: '에스케이스퀘어 주식회사',
      otherCompanies: {'sk하이닉스'},
    );
    expect(rows.map((r) => r.label), ['플랫폼 · 서비스']);
    // 대괄호는 사업부문 제목에도 쓰인다 — 아는 회사 이름이 아니면 건너뛰지 않는다.
    expect(
      ProductionFacts.parse(text, owner: '에스케이스퀘어 주식회사').length,
      2,
    );
  });

  test('머리글의 단위를 쓴다', () {
    const text = '''
(단위 : 백만원, %)
사업부문 | 생산능력 | 생산실적 | 가동률
반도체 | 1,000 | 800 | 80%
''';
    // 단위 줄이 머리글 바로 위(3줄 안)에 있어도, 머리글 줄에 있어도 받는다.
    const withUnit = '''
사업부문 | 생산능력 | 생산실적 | 가동률 (단위 : 백만원)
반도체 | 1,000 | 800 | 80%
''';
    expect(ProductionFacts.parse(text).first.unit, '백만원');
    expect(ProductionFacts.parse(withUnit).first.unit, '백만원');
  });

  test('당기·전기를 나란히 적은 표에서는 당기 칸만 읽는다', () {
    const text = '''
품 목 | 단 위 | 생산능력 | 생산실적 | 가동률 | 생산능력 | 생산실적 | 가동률
소형전지 | 백만개 | 2,000 | 1,000 | 50% | 1,000 | 900 | 90%
''';
    final rows = ProductionFacts.parse(text);
    expect(rows, hasLength(1));
    expect(rows.first.capacity, 2000, reason: '전기(1,000)가 아니라 당기');
    expect(rows.first.production, 1000);
    expect(rows.first.utilization, 50);
  });

  test('단위가 머리글 윗줄에 있어도 쓰고, 품목마다 단위가 다르면 가동률만 남긴다', () {
    const t = '''
| (단위 : 천㎡, %)
사업부문 | 당기 생산능력 | 당기 생산실적 | 당기 가동률
제조 | 1,002 | 759 | 76%
(단위 : 완제의약품-백만정, 바이오의약품-백만Syringe, 수액-백만Bag, API-Ton)
사업소(사업부문) | 생산능력 | 생산실적 | 평균가동률(%)
오송공장(수액) | 54.9 | 27.5 | 50.0
''';
    final rows = ProductionFacts.parse(t, owner: '대덕전자(주)');
    expect(rows.map((r) => (r.label, r.unit, r.utilization)), [
      ('제조', '천㎡', 76.0),
      ('오송공장(수액)', '', 50.0),
    ]);
  });

  test('세로형 표(생산능력·생산실적·가동률이 줄마다)도 당기 값을 검산해 읽는다', () {
    const t = '''
(단위 : 백만원, MH)
사업부문 | 해당회사 | 품 목 | 사업소 | 구분 | 2025년 | 2024년 | 2023년
방산 | 한화시스템(주) | 전술통신장비 등 | 구미사업장 | 생산능력 | 1,729,388 | 1,289,684 | 1,166,247
생산실적 | 1,447,826 | 1,101,233 | 1,060,056
가동률(%) | 83.72 | 85.39 | 90.89
기타 | Hanwha Philly Shipyard Inc | 선박 조립 및 건조 등 | 미국 | 목표 가동시간 | 3,071,267 | - | -
실제 가동시간 | 3,154,560 | - | -
가동률(%) | 102.71 | - | -
| (단위 : 백만원)
사업부문 | 해당 회사 | 사업소 | 품 목 | 구 분 | 2025년 | 2024년
시큐리티 | 한화비전㈜ 및 해외생산법인 | 베트남 박닌 | 감시장비 등 | 생산능력 | 363,760 | 162,015
생산실적 | 332,803 | 154,799
가동률(%) | 91.49% | 95.55%
''';
    final rows = ProductionFacts.parse(t, owner: '한화시스템(주)');
    expect(rows.map((r) => r.utilization), [83.72, 102.71, 91.49]);
    expect(rows[0].label, '방산 · 한화시스템(주) · 전술통신장비 등 · 구미사업장');
    expect(rows[0].capacity, 1729388);
    expect(rows[0].unit, '백만원');
    // 목표·실제 가동시간은 생산능력이 아니라 가동률만.
    expect(rows[1].capacity, isNull);
    expect(rows[2].unit, '백만원');
  });
}
