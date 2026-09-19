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

  /// zip에서 본문 파일(`<접수번호>.xml`, 없으면 첫 XML)을 골라 뽑는다. 못 찾으면 null.
  static ({String title, String text})? fromZip(List<int> zip, String rceptNo) {
    final archive = ZipDecoder().decodeBytes(zip);
    final xmls = [
      for (final f in archive.files)
        if (f.isFile && f.name.toLowerCase().endsWith('.xml')) f,
    ];
    if (xmls.isEmpty) return null;
    final main =
        xmls.where((f) => f.name == '$rceptNo.xml').firstOrNull ??
        (xmls..sort((a, b) => a.name.length.compareTo(b.name.length))).first;
    return fromXml(utf8.decode(main.content, allowMalformed: true));
  }

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
