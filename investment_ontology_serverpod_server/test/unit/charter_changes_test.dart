import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/charter_comparison_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_charter_source.dart';

void main() {
  test('정관과 무관한 대형 표의 rowspan은 비교표 추출을 막지 않는다', () {
    final result = CharterComparisonRules.parse(
      '<TABLE><TR><TD rowspan="500">주주명</TD></TR></TABLE>'
      '<TABLE><TR><TH>현행</TH><TH>개정안</TH></TR>'
      '<TR><TD>제1조 금액 300억원</TD><TD>제1조 금액 1000억원</TD></TR></TABLE>',
    );
    expect((result['changes'] as List).length, 1);
  });
  test('임기 상한 변경은 판별하되 위험·승인 판정은 만들지 않는다', () {
    final row = CharterComparisonRules.explain(
      '제25조 (이사의 임기) 임기는 3년으로 한다.',
      '제25조 (이사의 임기) 임기는 3년을 초과하지 못한다.',
    );
    expect(row['title'], contains('최대 3년'));
    expect(row.containsKey('approved'), isFalse);
    expect(
      CharterComparisonRules.explain('임기는 3년으로 한다.', '임기는 3년으로 한다.')['topic'],
      '기타 변경',
    );
    expect(
      CharterComparisonRules.explain(
        '발행 가능한 주식은 3년으로 한다.',
        '발행 가능한 주식은 3년 이내',
      )['topic'],
      '기타 변경',
    );
  });
  test('정정신고의 정정전후 표와 사업목적 표를 정관 대비표로 오인하지 않는다', () {
    final data = CharterComparisonRules.fromTables([
      [
        ['항목', '정정전', '정정후', '정정사유'],
        ['안건', '추가', '소각', '정정'],
      ],
      [
        ['구분', '사업목적', '사업영위여부'],
        ['1', '반도체', '영위'],
      ],
    ]);
    expect(data['changes'], isEmpty);
    expect(data['history'], isEmpty);
  });
  test('이력은 실제 날짜 열로 정렬하며 불가능 날짜·제안문은 버린다', () {
    final data = CharterComparisonRules.fromTables([
      [
        ['정관변경일', '주요변경사항', '변경이유'],
        ['2024.03.20', '주권 삭제', '전자등록'],
        ['2026.03.18', '임기 변경', '조문 정비'],
        ['2026.02.30', '허위 날짜', '오류'],
        ['상정 예정', '미승인', '안건'],
      ],
    ]);
    expect((data['history'] as List).map((r) => r['date']), [
      '2026-03-18',
      '2024-03-20',
    ]);
  });
  test('실제 공식 PDF의 3페이지를 연결해 잘린 조문을 복원한다', () {
    final raw = jsonDecode(
      File('assets/charter/00126380.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final tables = (raw['tables'] as List)
        .map((t) => (t as List).map((r) => (r as List).cast<String>()).toList())
        .toList();
    final changes =
        CharterComparisonRules.fromTables(tables)['changes'] as List;
    expect(changes.length, 11);
    final retirement = changes.singleWhere((r) => r['topic'] == '자기주식');
    expect(retirement['before'], contains('소각할 수'));
    expect(retirement['after'], contains('삭제'));
    final committee = changes.singleWhere(
      (r) => (r['before'] as String).contains('제28조의2'),
    );
    expect(committee['after'], contains('독립이사후보추천위원회'));
    final timing = changes.singleWhere((r) => r['topic'] == '시행 시점');
    expect(timing['after'], contains('2027년 1월 1'));
    expect(timing['after'], contains('2026년 9월 10'));
    expect(
      changes.where((r) => (r['title'] as String).contains('최대 3년')).length,
      1,
    );
  });
  test('삭제된 소각 조항은 실제 소각 금지로 해석하지 않는다', () {
    final row = CharterComparisonRules.explain('제8조의3 (주식의 소각)', '제8조의3 삭제');
    expect(row['meaning'], contains('소각 금지'));
    expect(row['meaning'], contains('해석할 수는 없습니다'));
  });
  test('viewer 좌표는 기업과 접수번호에 묶는다', () {
    const shell =
        "openCorpInfoNew('00126380', 'winCorpInfo', '/dsae001/selectPopup.ax');"
        "node2['text'] = '5. 정관에 관한 사항'; node2['rcpNo'] = '20260814003699';"
        "node2['dcmNo'] = '123'; node2['eleId'] = '8'; node2['offset'] = '50';"
        "node2['length'] = '100'; node2['dtd'] = 'dart4.xsd'; cnt++;";
    expect(
      PublicCharterSource.bodyUris(
        '20260814003699',
        '00126380',
        shell,
      ).single.host,
      'dart.fss.or.kr',
    );
    expect(
      () => PublicCharterSource.bodyUris('20260814003699', '00999999', shell),
      throwsFormatException,
    );
    expect(
      () => PublicCharterSource.bodyUris('20260310002820', '00126380', shell),
      throwsFormatException,
    );
  });
}
