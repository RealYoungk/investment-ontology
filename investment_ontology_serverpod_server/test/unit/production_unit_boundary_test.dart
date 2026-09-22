import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:test/test.dart';

// 합성 표: 실제 공시의 오류 건수나 영향을 입증하는 자료는 아니다.
void main() {
  test('한 표에 여러 품목이 있으면 공통 단위를 모든 품목에 유지한다', () {
    final rows = ProductionFacts.parse('''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
알루미늄 | 200 | 100 | 50%
''');
    expect(rows.map((r) => r.unit), ['톤', '톤']);
  });

  test('다음 표에 명시한 새 단위를 우선한다', () {
    final rows = ProductionFacts.parse('''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
(단위 : 개, %)
품목 | 생산능력 | 생산실적 | 가동률
센서 | 200 | 100 | 50%
''');
    expect(rows.map((r) => r.unit), ['톤', '개']);
  });

  test('새 절의 표에 단위가 없으면 이전 표의 톤을 물려받지 않는다', () {
    final rows = ProductionFacts.parse('''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
## 2. 전자부품 생산현황
품목 | 생산능력 | 생산실적 | 가동률
센서 | 200 | 100 | 50%
''');
    expect(rows, hasLength(2));
    expect(rows.first.unit, '톤');
    expect(rows.last.utilization, 50);
    expect(
      rows.last.unit,
      isEmpty,
      reason: '센서 표의 단위는 불명확하다. 가동률만 사용할 수 있어야 한다.',
    );
  });
  test('새 절의 머리글 없는 숫자 행은 이전 표의 행으로 읽지 않는다', () {
    final rows = ProductionFacts.parse('''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
## 다른 지표
센서 | 200 | 100 | 50%
''');
    expect(rows.map((r) => r.label), ['철강']);
  });

  test('새 절을 사이에 둔 세로형 행을 하나의 생산 표로 합치지 않는다', () {
    final rows = ProductionFacts.parse('''
철강 | 생산능력(톤) | 100
## 다른 지표
생산실적 | 80
가동률(%) | 80
''');
    expect(rows, isEmpty);
  });

  test('새 절 안에 적힌 단위는 정상적으로 사용한다', () {
    final rows = ProductionFacts.parse('''
## 전자부품
(단위 : 개, %)
품목 | 생산능력 | 생산실적 | 가동률
센서 | 200 | 100 | 50%
''');
    expect(rows.single.unit, '개');
    expect(rows.single.capacity, 200);
  });
  test('절 제목 없이 새 머리글이 나오면 앞 표의 단위를 소비하지 않는다', () {
    final rows = ProductionFacts.parse('''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
품목 | 생산능력 | 생산실적 | 가동률
센서 | 200 | 100 | 50%
''');
    expect(rows.map((r) => r.unit), ['톤', '']);
  });

  test('제외한 회사의 단위는 당사 표로 넘어오지 않는다', () {
    final rows = ProductionFacts.parse(
      '''
[다른회사]
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
[우리회사]
품목 | 생산능력 | 생산실적 | 가동률
센서 | 200 | 100 | 50%
''',
      owner: '우리회사',
      otherCompanies: {'다른회사'},
    );
    expect(rows, hasLength(1));
    expect(rows.single.label, '센서');
    expect(rows.single.unit, isEmpty);
  });

  test('회사 경계에서 미완성 세로형 값도 초기화한다', () {
    final rows = ProductionFacts.parse('''
철강 | 생산능력(톤) | 100
[우리회사]
생산실적 | 80
가동률(%) | 80
''', owner: '우리회사');
    expect(rows, isEmpty);
  });
  test('세 키워드가 있는 설명문에 적힌 단위는 실제 머리글까지 유지한다', () {
    final rows = ProductionFacts.parse('''
가동률은 생산능력 대비 생산실적입니다. (단위: 대, %)
사업부문 | 법인명 | 소재지 | 2024년
생산능력 | 생산실적 | 가동률(%)
차량 | HMC | 한국 | 100 | 80 | 80%
''');
    expect(rows.single.unit, '대');
  });
}
