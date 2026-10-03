import 'package:test/test.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';

Map<String, dynamic> parse(String body) => CapitalStructureParser.parse(
  body,
  receipt: '20260814002145',
  periodEnd: '2026-06-30',
  companyName: '원포유',
);
String bond({String shares = '563063', String date = '2026.06.30'}) =>
    '''
<p>미상환 전환사채 발행현황 (기준일: $date) (단위: 원, 주)</p>
<table><tr><th>회차</th><th>주식의 종류</th><th>미상환 권면총액</th><th>전환가액</th><th>전환비율</th><th>전환가능주식수</th></tr>
<tr><td>2</td><td>기명식 보통주</td><td>1000000000</td><td>1776</td><td>100</td><td>$shares</td></tr></table>
''';
void main() {
  test('공시 수량 검산과 미확보 구분', () {
    final data = parse('${bond()}<p>미상환 신주인수권부사채 발행현황 해당사항 없습니다.</p>');
    expect(data['states'], {'CB': 'verified', 'BW': 'none', 'EB': 'missing'});
    expect((data['entries'] as List).single['shares'], '563063');
  });
  test('검산 실패 수량은 보존하고 완전한 합계에서 제외', () {
    final data = parse(bond(shares: '999'));
    expect(data['states']['CB'], 'partial');
    expect((data['entries'] as List).single['validation'], 'mismatch');
  });
  test('다른 기준일과 중복 회차는 합계 미확정', () {
    expect(parse(bond(date: '2025.12.31'))['states']['CB'], 'partial');
    expect(parse(bond() + bond())['states']['CB'], 'partial');
  });
  test('셀 병합 복원', () {
    expect(
      CapitalStructureParser.grid(
        '<table><tr><td rowspan="2">A</td><td colspan="2">B</td></tr><tr><td>C</td><td>D</td></tr></table>',
      ),
      [
        ['A', 'B', 'B'],
        ['A', 'C', 'D'],
      ],
    );
  });
  test('주식 총수 기준일이 다르면 분모로 채택하지 않음', () {
    expect(
      parse(
        '<p>기준일: 2025.12.31</p><table><tr><td>구분</td><td>보통주</td></tr><tr><td>발행주식의 총수</td><td>100</td></tr></table>',
      )['stocks'],
      isEmpty,
    );
  });
}
