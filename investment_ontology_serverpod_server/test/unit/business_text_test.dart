import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_text.dart';
import 'package:test/test.dart';

/// 첨부 문서도 절 코드 D-0-2-0-0을 쓰므로, 본문은 "사업의 내용" 제목이 있는 XML로 골라야 한다.
void main() {
  const attachment = '''
<DOCUMENT><BODY>
<TITLE AASSOCNOTE="D-0-1-0-0">1. 감사대상업무</TITLE><P>회사명 | 현대제철</P>
<TITLE AASSOCNOTE="D-0-2-0-0">2. 감사참여자 구분별 인원수</TITLE><P>투입 인원수 | 7</P>
<TITLE AASSOCNOTE="D-0-3-0-0">3. 주요 감사실시내용</TITLE><P>현장감사</P>
</BODY></DOCUMENT>''';
  const report = '''
<DOCUMENT><BODY>
<TITLE AASSOCNOTE="D-0-1-0-0">I. 회사의 개요</TITLE><P>개요</P>
<TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE>
<TITLE AASSOCNOTE="D-0-2-1-0">1. 사업의 개요</TITLE><P>당사는 철강을 만든다.</P>
<TITLE AASSOCNOTE="D-0-3-0-0">III. 재무에 관한 사항</TITLE><P>재무</P>
</BODY></DOCUMENT>''';

  List<int> zipOf(Map<String, String> files) {
    final archive = Archive();
    for (final e in files.entries) {
      archive.addFile(ArchiveFile.bytes(e.key, utf8.encode(e.value)));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  test('첨부가 먼저 와도 사업의 내용이 있는 XML을 본문으로 고른다', () {
    final zip = zipOf({
      '20260319000771_00001.xml': attachment,
      '20260319000771_00002.xml': report,
    });
    final doc = BusinessText.fromZip(zip, '20260319000771')!;
    expect(doc.title, 'II. 사업의 내용');
    expect(doc.text, contains('철강을 만든다'));
    expect(doc.text, isNot(contains('감사참여자')));
  });

  test('접수번호 이름의 파일이 본문이면 그것을 고른다', () {
    final zip = zipOf({
      '20260319000771.xml': report,
      'ETC.xml': attachment,
    });
    final doc = BusinessText.fromZip(zip, '20260319000771')!;
    expect(doc.text, contains('철강을 만든다'));
  });

  test(
    'EUC-KR bytes declaring UTF-8 decode without lost Korean characters',
    () {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            '20220308000798.xml',
            const CP949Codec().encode(
              '<?xml version="1.0" encoding="utf-8"?>$report',
            ),
          ),
        );
      final doc = BusinessText.fromZip(
        ZipEncoder().encodeBytes(archive),
        '20220308000798',
      )!;
      expect(doc.title, 'II. 사업의 내용');
      expect(doc.text, contains('철강을 만든다'));
      expect(doc.text, isNot(contains('\uFFFD')));
    },
  );

  test('invalid bytes in both encodings are not silently saved as replacement characters', () {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('broken.xml', [...utf8.encode(report), 255]));
    expect(
      BusinessText.fromZip(ZipEncoder().encodeBytes(archive), 'broken'),
      isNull,
    );
  });

  test('사업의 내용이 어디에도 없으면 null', () {
    final zip = zipOf({'20260319000771.xml': attachment});
    // 첨부만 있으면 D-0-2-0-0이 걸려도 본문이 아니다 — 자료 없음으로 둔다.
    expect(BusinessText.fromZip(zip, '20260319000771'), isNull);
  });
}
