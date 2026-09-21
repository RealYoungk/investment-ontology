import 'dart:convert';

import 'package:archive/archive.dart';

/// 공시 원본 파일(DART 전자공시 XML)에서 "II. 사업의 내용"을 글로 뽑는다.
///
/// 목차 제목에 붙은 `AASSOCNOTE="D-0-2-0-0"`(사업의 내용)부터 `D-0-3-…`(III. 재무에 관한 사항)
/// 전까지다. 코드가 없는 문서는 제목 글자(`II. 사업의 내용` ~ `III.`)로 찾는다.
/// 표는 칸을 ' | '로 이은 줄로, 하위 절 제목은 '## '로 시작하는 줄로 바꾼다.
abstract final class BusinessText {
  static final _startCode = RegExp(
    r'<TITLE[^>]*AASSOCNOTE="D-0-2-0-0"[^>]*>(.*?)</TITLE>',
    dotAll: true,
  );
  static final _endCode = RegExp(
    r'<TITLE[^>]*AASSOCNOTE="D-0-3-',
    dotAll: true,
  );
  static final _startText = RegExp(
    r'<TITLE[^>]*>\s*(II\.\s*사업의\s*내용[^<]*)</TITLE>',
    dotAll: true,
  );
  static final _endText = RegExp(r'<TITLE[^>]*>\s*III\.', dotAll: true);

  /// zip에서 본문 파일을 골라 뽑는다. 못 찾으면 null.
  ///
  /// 사업보고서 zip에는 본문 말고도 첨부(외부감사 실시내용, 감사보고서 …)가 같이 든다.
  /// 첨부도 절 코드 `D-0-2-0-0`을 쓰므로 코드만 믿으면 "2. 감사참여자…"가 본문으로 뽑힌다
  /// (현대제철·메리츠 FY2025가 그랬다). 그래서 "사업의 내용"이라는 제목 글자가 실제로
  /// 들어 있는 XML만 후보로 두고, 그중 `<접수번호>.xml` → 큰 파일 순으로 고른다.
  static ({String title, String text})? fromZip(List<int> zip, String rceptNo) {
    final archive = ZipDecoder().decodeBytes(zip);
    final xmls = [
      for (final f in archive.files)
        if (f.isFile && f.name.toLowerCase().endsWith('.xml'))
          (name: f.name, xml: utf8.decode(f.content, allowMalformed: true)),
    ];
    if (xmls.isEmpty) return null;
    final withBody =
        xmls.where((f) => _hasBusinessTitle.hasMatch(f.xml)).toList()
          ..sort((a, b) => b.xml.length.compareTo(a.xml.length));
    if (withBody.isEmpty) return null;
    final main =
        withBody.where((f) => f.name == '$rceptNo.xml').firstOrNull ??
        withBody.first;
    return fromXml(main.xml);
  }

  /// zip 안의 파일 이름과 크기, 본문 제목 유무 — 본문을 못 찾았을 때 로그용.
  static String describeZip(List<int> zip) {
    final archive = ZipDecoder().decodeBytes(zip);
    return [
      for (final f in archive.files)
        if (f.isFile)
          '${f.name}(${f.content.length}'
              '${f.name.toLowerCase().endsWith('.xml') && _hasBusinessTitle.hasMatch(utf8.decode(f.content, allowMalformed: true)) ? ', 본문' : ''})',
    ].join(' ');
  }

  /// 본문임을 알려 주는 제목 — 첨부 문서에는 없다. 제목 안의 다른 태그는 건너뛴다.
  static final _hasBusinessTitle = RegExp(
    r'<TITLE[^>]*>(?:(?!</TITLE>).)*사업의\s*내용',
    dotAll: true,
  );

  static ({String title, String text})? fromXml(String xml) {
    var start = _startCode.firstMatch(xml) ?? _startText.firstMatch(xml);
    if (start == null) return null;
    final rest = xml.substring(start.end);
    final end =
        (_startCode.hasMatch(xml) ? _endCode : _endText).firstMatch(rest) ??
        _endText.firstMatch(rest);
    final body = end == null ? rest : rest.substring(0, end.start);
    final title = _plain(start.group(1) ?? '').trim();
    final text = toText(body);
    if (text.trim().isEmpty) return null;
    return (title: title.isEmpty ? 'II. 사업의 내용' : title, text: text);
  }

  /// 문서 XML 조각 → 읽을 수 있는 글.
  static String toText(String xml) {
    var s = xml;
    // 하위 절 제목.
    s = s.replaceAllMapped(
      RegExp(r'<TITLE[^>]*>(.*?)</TITLE>', dotAll: true),
      (m) => '\n## ${_plain(m.group(1)!).trim()}\n',
    );
    // 표: 행마다 칸을 ' | '로 잇는다.
    s = s.replaceAllMapped(RegExp(r'<TR[^>]*>(.*?)</TR>', dotAll: true), (m) {
      final cells = [
        for (final c in RegExp(
          r'<(TD|TE|TH|TU)[^>]*>(.*?)</\1>',
          dotAll: true,
        ).allMatches(m.group(1)!))
          _plain(c.group(2)!).replaceAll(RegExp(r'\s+'), ' ').trim(),
      ];
      return '\n${cells.join(' | ')}\n';
    });
    s = s.replaceAll(
      RegExp(r'<(P|BR|/P|TABLE|/TABLE)[^>]*>', caseSensitive: false),
      '\n',
    );
    s = _plain(s);
    final lines = <String>[];
    for (final raw in s.split('\n')) {
      final line = raw.replaceAll(RegExp(r'[ \t ]+'), ' ').trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^[|\s]+$').hasMatch(line)) continue;
      lines.add(line);
    }
    return lines.join('\n');
  }

  static String _plain(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)),
      )
      .replaceAll('&amp;', '&');

  /// 글을 하위 절(`## 제목`)로 나눈다. 첫 제목 앞의 글은 제목 없이.
  static List<({String title, String text})> sections(String text) {
    final out = <({String title, String text})>[];
    var title = '';
    final buf = StringBuffer();
    void flush() {
      final body = buf.toString().trim();
      if (body.isNotEmpty || title.isNotEmpty) {
        out.add((title: title, text: body));
      }
      buf.clear();
    }

    for (final line in text.split('\n')) {
      if (line.startsWith('## ')) {
        flush();
        title = line.substring(3).trim();
      } else {
        buf.writeln(line);
      }
    }
    flush();
    return out;
  }
}
