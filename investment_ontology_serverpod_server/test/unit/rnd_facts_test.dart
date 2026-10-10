import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:test/test.dart';

/// 실제 사업보고서의 "연구개발비용" 표 모양으로 확인한다. 검산(비율 = 계 ÷ 매출액)은
/// 재무제표가 필요해 store()에서 하고, 여기서는 표를 읽는 부분만 본다.
void main() {
  test('삼기처럼 비용 절의 합계와 짧은 비율 표기를 읽는다', () {
    const text = '''
3) 연구개발비용
(단위 : 천원)
구분 | 2026년 반기 | 2025년 | 2024년
판관비 | 1,130,222 | 2,681,072 | 2,247,429
합계 | 1,130,222 | 2,681,072 | 2,247,429
(매출액 대비 비율) | 1.4% | 3.1% | 2.8%
''';
    final result = RndFacts.parse(text, bsnsYear: 2026)!;
    expect(result.totals.single.values, [1130222, 2681072, 2247429]);
    expect(result.ratio!.values, [1.4, 3.1, 2.8]);
    expect(
      RndFacts.parse(text.replaceFirst('연구개발비용', '매출 현황'), bsnsYear: 2026),
      isNull,
    );
    expect(
      RndFacts.parse(
        text.replaceFirst('구분 |', '4) 매출 현황\n구분 |'),
        bsnsYear: 2026,
      ),
      isNull,
    );
  });
  test('연도 머리글·계 줄·비율 줄·매출액 줄을 읽는다 (한국전력기술)', () {
    const t = '''
2) 연구개발비용
(기준일 : 2025.12.31) | (단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
매 출 액 | 518,768 | 569,494 | 554,364
연구개발비용 계 | 62,127 | 58,967 | 50,009
(정부보조금) | 23,492 | 18,805 | 10,920
연구개발비 / 매출액 비율 [연구개발비용계÷당기매출액×100] | 12.0% | 10.4% | 9.0%
주) 연구개발비용은 정부보조금(국고보조금)을 차감하기 전의 지출총액입니다.
''';
    final r = RndFacts.parse(t, bsnsYear: 2025)!;
    expect(r.years, [2025, 2024, 2023]);
    expect(r.unit, '백만원');
    expect(r.totals.single.values, [62127, 58967, 50009]);
    expect(r.ratio!.values, [12.0, 10.4, 9.0]);
    expect(r.revenue, [518768, 569494, 554364]);
  });

  test('제N기(연도) 머리글, 괄호 음수, 계 줄 둘 (엘앤에프·CJ)', () {
    const t = '''
3) 연구개발비용
| (단위 : 백만원)
과목 | 제26기(2025년) | 제25기 (2024년) | 제24기 (2023년) | 비고
연구개발비용 총계 | 195,482 | 211,573 | 227,106 | -
(정부보조금) | (956) | (437) | (1,147) | -
연구개발비용 계 | 194,526 | 211,136 | 225,959 | -
회계처리 | 개발비 자산화 (무형자산) | (25,558) | (27,163) | (23,134) | -
연구개발비/매출액비율[연구개발비용계/당기매출액X100] | 1.29% | 1.34% | 1.45% | -
''';
    final r = RndFacts.parse(t, bsnsYear: 2025)!;
    expect(r.years, [2025, 2024, 2023]);
    expect(r.totals.map((t) => t.values.first), [195482, 194526]);
    expect(r.ratio!.values.first, 1.29);
    expect(r.revenue, isNull);
  });

  test('제N기만 있으면 당기부터 내려가고, 기 번호가 뒤섞이면 받지 않는다', () {
    const t = '''
(단위 : 백만원)
과 목 | 제77기 | 제76기 | 제75기 | 비고
연구개발비용 합계 | 4,954,447 | 4,188,404 | 4,905,334 | -
연구개발비 / 매출액 비율[연구개발비용계÷당기매출액×100] | 7.5% | 12.8% | 11.0% | -
''';
    final r = RndFacts.parse(t, bsnsYear: 2024)!;
    expect(r.years, [2024, 2023, 2022]);
    expect(r.totals.single.values.first, 4954447);

    const bad = '''
(단위 : 백만원)
과 목 | 제75기 | 제77기 | 제76기
연구개발비용 합계 | 4,954,447 | 4,188,404 | 4,905,334
연구개발비 / 매출액 비율 | 7.5% | 12.8% | 11.0%
''';
    expect(RndFacts.parse(bad, bsnsYear: 2024), isNull);
  });

  test('단위가 없거나 비율 줄이 없으면 표로 보지 않는다', () {
    const noUnit = '''
과목 | 2025년 | 2024년 | 2023년
연구개발비용 계 | 62,127 | 58,967 | 50,009
연구개발비 / 매출액 비율 | 12.0% | 10.4% | 9.0%
''';
    expect(RndFacts.parse(noUnit, bsnsYear: 2025), isNull);
    const noRatio = '''
(단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
연구개발비용 계 | 62,127 | 58,967 | 50,009
''';
    expect(RndFacts.parse(noRatio, bsnsYear: 2025), isNull);
  });
}
