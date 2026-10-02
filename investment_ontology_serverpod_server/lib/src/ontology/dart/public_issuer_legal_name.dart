import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Raw official evidence, revalidated by the financial parser, never an alias flag.
class PublicIssuerLegalName {
  const PublicIssuerLegalName({
    required this.shellHtml,
    required this.shellSource,
    required this.overviewHtml,
    required this.overviewSource,
  });
  final String shellHtml;
  final Uri shellSource;
  final String overviewHtml;
  final Uri overviewSource;

  static String _text(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String normalize(String s) =>
      s.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s+'), '');

  static bool _viewer(Uri u, String receipt, String dcm) =>
      u.scheme == 'https' &&
      u.host == 'dart.fss.or.kr' &&
      !u.hasPort &&
      u.userInfo.isEmpty &&
      u.fragment.isEmpty &&
      u.path == '/report/viewer.do' &&
      u.queryParametersAll.length == 6 &&
      [
        'rcpNo',
        'dcmNo',
        'eleId',
        'offset',
        'length',
        'dtd',
      ].every((k) => u.queryParametersAll[k]?.length == 1) &&
      u.queryParameters['rcpNo'] == receipt &&
      u.queryParameters['dcmNo'] == dcm &&
      [
        'eleId',
        'offset',
        'length',
      ].every((k) => RegExp(r'^\d{1,9}$').hasMatch(u.queryParameters[k]!)) &&
      int.parse(u.queryParameters['length']!) > 0 &&
      int.parse(u.queryParameters['length']!) <= 5 * 1024 * 1024 &&
      const ['dart3.xsd', 'dart4.xsd'].contains(u.queryParameters['dtd']);

  Map<String, String>? verify({
    required String receipt,
    required String corpCode,
    required String masterName,
    required String printedName,
    required Uri coverSource,
    required String coverHtml,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt) ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode) ||
        shellSource !=
            Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
              'rcpNo': receipt,
            }) ||
        periodEnd.difference(periodStart).inDays < 364 ||
        periodEnd.difference(periodStart).inDays > 365) {
      return null;
    }
    final corps = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shellHtml).map((m) => m.group(1)!).toSet();
    final docs = RegExp("openPdfDownload\\('$receipt',\\s*'(\\d+)'\\)")
        .allMatches(shellHtml)
        .map((m) => m.group(1)!)
        .toSet();
    if (corps.length != 1 || corps.single != corpCode || docs.length != 1) {
      return null;
    }
    final dcm = docs.single;
    if (!_viewer(coverSource, receipt, dcm) ||
        !_viewer(overviewSource, receipt, dcm)) {
      return null;
    }
    bool node(String label, Uri uri) {
      final matches = <Map<String, String>>[];
      for (final b in RegExp(
        r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
        dotAll: true,
      ).allMatches(shellHtml)) {
        if (b.group(2)!.replaceAll(RegExp(r'\s+'), '') != label) {
          continue;
        }
        final values = <String, String>{};
        for (final a in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(b.group(3)!)) {
          if (values.containsKey(a.group(1))) return false;
          values[a.group(1)!] = a.group(2)!;
        }
        matches.add(values);
      }
      return matches.length == 1 &&
          matches.single.length == 6 &&
          matches.single.entries.every(
            (e) => uri.queryParameters[e.key] == e.value,
          );
    }

    if (!node('사업보고서', coverSource) || !node('I.회사의개요', overviewSource)) {
      return null;
    }
    final cover = _text(coverHtml).replaceAll(' ', '');
    final names = RegExp(r'회사명:(.*?)(?:공동)?대표이사:').allMatches(cover).toList();
    String date(DateTime d) =>
        '${d.year}년${d.month.toString().padLeft(2, '0')}월${d.day.toString().padLeft(2, '0')}일';
    if (names.length != 1 ||
        normalize(names.single.group(1)!) != normalize(printedName) ||
        !cover.contains('사업연도${date(periodStart)}부터${date(periodEnd)}까지')) {
      return null;
    }
    final bodies = RegExp(
      r'<body\b[^>]*>(.*?)</body>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(overviewHtml).toList();
    if (bodies.length != 1 ||
        RegExp(
          r'<(?:script|style)\b',
          caseSensitive: false,
        ).hasMatch(bodies.single.group(1)!)) {
      return null;
    }
    // DART may print heading and direct declaration in one P separated by BR.
    final overviewBody = bodies.single
        .group(1)!
        .replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '</p><p>',
        );
    // Only a direct issuer naming paragraph, bounded by the next paragraph heading.
    final paragraphs = RegExp(
      r'<p\b[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(overviewBody).toList();
    final headings = <RegExpMatch>[];
    for (final p in paragraphs) {
      if (RegExp(r'^(?:\d+\.|[가-힣]\.)\s*회사의\s*(?:법적[ㆍ·]상업적\s*)?명칭$')
          .hasMatch(_text(p.group(1)!))) {
        headings.add(p);
      }
    }
    if (headings.length != 1) return null;
    final scopeHeadings = paragraphs
        .where((p) => _text(p.group(1)!).replaceAll(' ', '') == 'I.회사의개요')
        .toList();
    if (scopeHeadings.length != 1 ||
        scopeHeadings.single.end >= headings.single.start) {
      return null;
    }
    final namingStart = headings.single.start;
    final sectionHeaders = RegExp(
      r'<p\b[^>]*class=["\x27]section-2["\x27][^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(overviewBody).toList();
    final ownSections = sectionHeaders
        .where((p) => _text(p.group(1)!).replaceAll(' ', '') == '1.회사의개요')
        .toList();
    if (ownSections.length != 1 ||
        ownSections.single.end >= namingStart ||
        sectionHeaders.any(
          (p) => p.start > ownSections.single.end && p.start < namingStart,
        )) {
      return null;
    }
    final beforeHeading = overviewBody.substring(0, namingStart);
    if (RegExp(
          r'<table\b',
          caseSensitive: false,
        ).allMatches(beforeHeading).length !=
        RegExp(
          r'</table>',
          caseSensitive: false,
        ).allMatches(beforeHeading).length) {
      return null;
    }
    final start = headings.single.end;
    final next = paragraphs
        .where(
          (p) =>
              p.start >= start &&
              RegExp(r'^(?:\d+\.|[가-힣]\.)\s*\S').hasMatch(_text(p.group(1)!)),
        )
        .toList();
    if (next.isEmpty) return null;
    final section = overviewBody.substring(start, next.first.start);
    if (RegExp(
      r'<(?:script|style)\b',
      caseSensitive: false,
    ).hasMatch(section)) {
      return null;
    }
    final candidates = <String>[], quotes = <String>[];
    for (final tr in RegExp(
      r'<tr\b[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(section)) {
      final cells = RegExp(
        r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(tr.group(1)!).map((m) => _text(m.group(1)!)).toList();
      if (cells.isNotEmpty && cells.first == '한글') {
        if (cells.length != 2 || cells[1].isEmpty) return null;
        candidates.add(cells[1]);
        quotes.add(cells.join(' | '));
      }
    }
    for (final p in RegExp(
      r'<p\b[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(section)) {
      final t = _text(p.group(1)!);
      final m = RegExp(r"^(?:당사|당 회사|당 저축은행)의 명칭은 '([^']+)'이라고 표기합니다\.$")
          .firstMatch(t);
      final direct = RegExp(
        r"^당사의 법적[ㆍ·]상업적 명칭은 '([^']+)'으로 표기하며, 영문으로는 '[^']+'\s*로 표기합니다\.$",
      ).firstMatch(t);
      final naming = m ?? direct;
      if (naming != null) {
        candidates.add(naming.group(1)!);
        quotes.add(t);
      }
    }
    if (candidates.length != 1 ||
        normalize(candidates.single) != normalize(printedName)) {
      return null;
    }
    return {
      'currentName': masterName,
      'printedHistoricalName': printedName,
      'declaredLegalName': candidates.single,
      'receipt': receipt,
      'corpCode': corpCode,
      'periodStart': periodStart.toIso8601String().substring(0, 10),
      'periodEnd': periodEnd.toIso8601String().substring(0, 10),
      'evidence': quotes.single,
      'shellSource': shellSource.toString(),
      'shellSha256': sha256.convert(utf8.encode(shellHtml)).toString(),
      'coverSource': coverSource.toString(),
      'coverSha256': sha256.convert(utf8.encode(coverHtml)).toString(),
      'legalNameEvidenceSource': overviewSource.toString(),
      'legalNameEvidenceSha256': sha256
          .convert(utf8.encode(overviewHtml))
          .toString(),
      'validationNote': '동일 공식 법인코드/원접수/표지기간 및 회사개요 직접 법적명칭 검증; 현재 회사명과 다름',
    };
  }
}
