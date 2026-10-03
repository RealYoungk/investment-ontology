import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_charter_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/charter_comparison_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/charter_xml.dart';

void main() {
  test('다른 기업·소집결의·철회는 소집공고로 받지 않고 정정 공고는 최신순이다', () {
    String row(String code, String receipt, String name) =>
        '''<tr><td><a onclick="openCorpInfoNew('$code')">회사</a></td><td><a onclick="openReportViewer('$receipt',''); return false;">$name</a></td></tr>''';
    final notices = PublicCharterSource.noticeReceipts(
      [
        row('00164779', '20260305001231', '[기재정정] 주주총회소집공고'),
        row('00126380', '20260305001232', '주주총회소집공고'),
        row('00164779', '20260205001231', '주주총회소집공고'),
        row('00164779', '20260306001231', '주주총회소집결의'),
        row('00164779', '20260307001231', '[철회]주주총회소집공고'),
      ].join(),
      '00164779',
    );
    expect(notices.map((n) => n.receipt), ['20260305001231', '20260205001231']);
  });
  test('두 열·제목 행이 있는 실제 조문 대비표도 읽고 이유를 만들지 않는다', () {
    final result = CharterComparisonRules.fromTables([
      [
        ['정관 신구조문 대비표'],
        ['현행 조문', '개정 조문'],
        ['제25조 (이사의 임기) 임기는 3년으로 한다.', '제25조 (이사의 임기) 임기는 3년을 초과하지 못한다.'],
      ],
    ]);
    final change = (result['changes'] as List).single;
    expect(change['reason'], '');
    expect(change['title'], contains('최대 3년'));
  });
  test('공시 XML의 기업 코드가 다르면 원문을 저장하지 않는다', () {
    final text =
        '<DOCUMENT><COMPANY-NAME AREGCIK="00164779">SK하이닉스</COMPANY-NAME></DOCUMENT>';
    final bytes = utf8.encode(text);
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('report.xml', bytes.length, bytes)),
    );
    expect(CharterXml.boundDocument(zip, '00164779'), text);
    expect(
      () => CharterXml.boundDocument(zip, '00126380'),
      throwsFormatException,
    );
  });
  test('동일 기업 원문이 여러 개 들어 있으면 임의로 선택하지 않는다', () {
    final bytes = utf8.encode(
      '<COMPANY-NAME AREGCIK="00164779">회사</COMPANY-NAME>',
    );
    final zip = ZipEncoder().encode(
      Archive()
        ..addFile(ArchiveFile('a.xml', bytes.length, bytes))
        ..addFile(ArchiveFile('b.xml', bytes.length, bytes)),
    );
    expect(
      () => CharterXml.boundDocument(zip, '00164779'),
      throwsFormatException,
    );
  });
  test('알 수 없는 조항도 바뀐 원문을 발췌하고 동일 조문은 변경으로 세지 않는다', () {
    const old =
        '제10조 (전환사채) 회사는 주주 이외의 자에게 사채 총액이 300억원을 초과하지 않는 범위 내에서 전환사채를 발행할 수 있다.';
    const next =
        '제10조 (전환사채) 회사는 주주 이외의 자에게 사채 총액이 1000억원을 초과하지 않는 범위 내에서 전환사채를 발행할 수 있다.';
    final changes =
        CharterComparisonRules.fromTables([
              [
                ['변경 전', '변경 후'],
                [old, next],
                [next, next],
              ],
            ])['changes']
            as List;
    expect(changes, hasLength(1));
    expect(changes.single['beforeShort'], contains('300억원'));
    expect(changes.single['afterShort'], contains('1000억원'));
    expect(changes.single['before'], old);
    expect(changes.single['after'], next);
    expect(changes.single['topic'], '기타 변경');
  });
}
