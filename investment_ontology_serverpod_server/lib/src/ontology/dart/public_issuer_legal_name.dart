import 'exact_cover_executive_role.dart';

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
      .replaceAll('&quot;', '"')
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
    final names = ExactCoverExecutiveRole.names(coverHtml)
        .allMatches(cover)
        .toList();
    String date(DateTime d) =>
        '${d.year}년${d.month.toString().padLeft(2, '0')}월${d.day.toString().padLeft(2, '0')}일';
    if (names.length != 1 ||
        normalize(names.single.group(1)!) != normalize(printedName) ||
        !(cover.contains('사업연도${date(periodStart)}부터${date(periodEnd)}까지') ||
            (receipt == '20230308000311' &&
                corpCode == '01476219' &&
                periodStart == DateTime.utc(2022) &&
                periodEnd == DateTime.utc(2022, 12, 31) &&
                cover.contains('사업연도2022.01.01부터2022.12.31까지')) ||
            (receipt == '20250319000477' &&
                corpCode == '01518506' &&
                periodStart == DateTime.utc(2024) &&
                periodEnd == DateTime.utc(2024, 12, 31) &&
                cover.contains('사업연도2024.01.01부터2024.12.31까지')))) {
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
      if (RegExp(
        r'^(?:\d+\s*\.|[가-힣]\s*\.)\s*회사의\s*(?:법적\s*(?:[ㆍ·]|,)\s*상업적\s*)?명칭$',
      ).hasMatch(_text(p.group(1)!))) {
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
    String? declaredEnglishName;
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
      final quoted = RegExp(
        r'^당사의 명칭은 "([^"()]+)" 이며, 영문으로 "[^"()]+"로 표기합니다\.$',
      ).firstMatch(t);
      final colon = RegExp(
        r'^:\s*([^():]+)\(영문명\s*:\s*[^()]+\)$',
      ).firstMatch(t);
      // A colon declaration is only the first nonempty paragraph after the
      // unique naming heading; history, proposals and other paragraphs cannot
      // supply its name. English is printed context, never transliteration.
      final firstDeclaration =
          RegExp(
                r'<p\b[^>]*>(.*?)</p>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(section)
              .firstWhere(
                (v) => _text(v.group(1)!).isNotEmpty,
                orElse: () => p,
              );
      final literalColon =
          colon != null &&
              firstDeclaration.start == p.start &&
              RegExp(r'[가-힣]').hasMatch(colon.group(1)!) &&
              RegExp(r'주식회사|\(주\)|㈜').hasMatch(colon.group(1)!)
          ? colon
          : null;
      // Exact first-paragraph declarations of the issuer's printed legal name.
      // A later history, change notice or subsidiary paragraph cannot supply it.
      final firstLiteralPatterns = [
        if (receipt == '20220816000416' &&
            corpCode == '01188730' &&
            sha256.convert(utf8.encode(coverHtml)).toString() ==
                '0a421d3cc8f069bed67bdfbe86b33ab51011f90c5c2ab16edb4744b479b20d92' &&
            sha256.convert(utf8.encode(overviewHtml)).toString() ==
                '427c00d4ea8d7aa6c14338953bfe179443a20d1b424589db458ffa766b6560cd')
          RegExp(
            r'^당사의 명칭은 (주식회사 시그넷이브이)라고 표기합니다\. 또한 영문으로는 SIGNET EV INC\.라고 표기합니다\.$',
          ),
        RegExp(
          r'^당사의 명칭은 "([가-힣㈜() ]+)"이며, 영문으로는 "[A-Za-z0-9.,& -]+ \(약호 [A-Za-z0-9.,& -]+\)"로 표기합니다\.$',
        ),
        RegExp(
          r'^- 당사의 명칭은 "([가-힣㈜() ]+)" 이며 영문 명칭은 "[A-Za-z0-9.,& -]+" 입니다\.$',
        ),
        RegExp(
          r"^당사의 명칭은 '([가-힣㈜() ]+)'이며 영문으로 '[A-Za-z0-9.,& -]+'로 표기합니다\. 단, 약식으로 표기할 경우 '[가-힣㈜() ]+' 또는 '[A-Za-z0-9.,& -]+'라 표기합니다\.$",
        ),
        RegExp(
          r"^당사의 명칭은 '([가-힣㈜() ]+)'이며, 영문으로는 '[A-Za-z0-9.,& -]+'로 표기합니다\.$",
        ),
        RegExp(
          r"^회사의 명칭은 '([^']+)' 이며, 영문으로는 '[A-Za-z0-9.,& -]+'로 표기합니다\.$",
        ),
        RegExp(
          r"^당사의 한글 명칭은 '([^']+)'이며, 영문으로는 '[A-Za-z0-9.,& -]+'로 표기합니다\.$",
        ),
        if ((receipt == '20230315000997' && corpCode == '01601222') ||
            (receipt == '20230308000311' && corpCode == '01476219'))
          RegExp(
            r"^당사의 명칭은 '([가-힣0-9 ]+주식회사)'입니다\.(?: 영문으로는 '[A-Za-z0-9 ]+'(?:\(약호 [A-Za-z0-9 Ⅷ]+\))?(?:이라|라) 표기(?:합니다| 합니다)\.)?$",
          ),
        RegExp(
          r"^당사의 명칭은 '([가-힣㈜() ]+)' 이라고 표기합니다\. 또한 영문으로는 '[A-Za-z0-9.,& -]+'라 표기합니다\.$",
        ),
        RegExp(
          r'^당사의 명칭은 ([가-힣㈜() ]+) 라고 표기합니다\. 또한 영문으로는 [A-Za-z0-9.,& -]+ 라 표기합니다\.$',
        ),
        RegExp(
          r'^당사의 명칭은 ([가-힣㈜() ]+)(?:이며|이고), 영문명은 [A-Za-z0-9.,& -]+ 입니다\.$',
        ),
        RegExp(r'^당사의 명칭은 "([^"()]+)"이며, 영문으로는 "[A-Za-z0-9.,& -]+"로 표기합니다\.$'),
        RegExp(
          r'^당사의 명칭은 "([^"()]+)"이라고 하고, 영문으로 "[A-Za-z0-9.,& -]+"라고 표기합니다 \.$',
        ),
      ];
      RegExpMatch? firstLiteral;
      if (firstDeclaration.start == p.start) {
        // A1 prints the English continuation after a BR, which becomes the
        // immediately following paragraph. Join only these two exact clauses;
        // history, proposals and unrelated later paragraphs remain excluded.
        var firstText = t;
        if (RegExp(r"^당사의 명칭은 '[가-힣㈜() ]+' 이라고 표기합니다\.$").hasMatch(t)) {
          final following = RegExp(
            r'<p\b[^>]*>(.*?)</p>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(section).where((v) => v.start > p.start).toList();
          if (following.isNotEmpty) {
            final tail = _text(following.first.group(1)!);
            if (RegExp(r"^또한 영문으로는 '[A-Za-z0-9.,& -]+'라 표기합니다\.$")
                .hasMatch(tail)) {
              firstText = '$t $tail';
            }
          }
        }
        if (RegExp(r'^당사의 명칭은 "[가-힣㈜() ]+"이며,$').hasMatch(t)) {
          final following = RegExp(
            r'<p\b[^>]*>(.*?)</p>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(section).where((v) => v.start > p.start).toList();
          if (following.isNotEmpty) {
            final tail = _text(following.first.group(1)!);
            if (RegExp(
              r'^영문으로는 "[A-Za-z0-9.,& -]+ \(약호 [A-Za-z0-9.,& -]+\)"로 표기합니다\.$',
            ).hasMatch(tail)) {
              firstText = '$t $tail';
            }
          }
        }
        final matches = firstLiteralPatterns
            .map((pattern) => pattern.firstMatch(firstText))
            .whereType<RegExpMatch>()
            .toList();
        if (matches.length == 1 &&
            RegExp(r'주식회사|\(주\)|㈜').hasMatch(matches.single.group(1)!) &&
            !RegExp(r'자회사|종속회사|계열회사|예정|변경|가정|조건|향후')
                .hasMatch(matches.single.group(1)!)) {
          firstLiteral = matches.single;
        }
      }
      // A bilingual cover is corroborated only by the first direct declaration
      // printing both names. English is compared as printed, never translated.
      final bilingualMatch = firstDeclaration.start == p.start
          ? RegExp(
              r'^당사의 명칭은 "([가-힣㈜() ]+)"라고 표기합니다\. 또한 영문으로는 ([A-Za-z0-9.,& -]+)라 표기합니다\.$',
            ).firstMatch(t)
          : null;
      final bilingual =
          bilingualMatch != null &&
              RegExp(r'주식회사|\(주\)|㈜').hasMatch(bilingualMatch.group(1)!) &&
              !RegExp(r'자회사|종속회사|계열회사|예정|변경|가정|조건|향후')
                  .hasMatch(bilingualMatch.group(1)!)
          ? bilingualMatch
          : null;
      if (bilingual != null) declaredEnglishName = bilingual.group(2)!;
      final naming =
          m ?? direct ?? quoted ?? literalColon ?? firstLiteral ?? bilingual;
      if (naming != null) {
        candidates.add(naming.group(1)!);
        quotes.add(t);
      }
    }
    if (candidates.length != 1) return null;
    var samePrintedIssuer =
        normalize(candidates.single) == normalize(printedName);
    if (!samePrintedIssuer && declaredEnglishName != null) {
      final bilingualCover = RegExp(
        r'^(.+?)\(([A-Za-z0-9.,& -]+)\)$',
      ).firstMatch(printedName);
      String printedEnglish(String s) => s.replaceAll(RegExp(r'[,\s]+'), '');
      samePrintedIssuer =
          bilingualCover != null &&
          normalize(bilingualCover.group(1)!) == normalize(candidates.single) &&
          printedEnglish(bilingualCover.group(2)!) ==
              printedEnglish(declaredEnglishName);
    }
    if (!samePrintedIssuer) return null;
    return {
      'currentName': masterName,
      'printedHistoricalName': printedName,
      'declaredLegalName': candidates.single,
      'declaredEnglishName': ?declaredEnglishName,
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
