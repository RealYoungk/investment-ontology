import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Primary issuer identity only. Never changes a master name or numeric period.
final class PrimaryHistoricalIssuer {
  const PrimaryHistoricalIssuer({
    required this.shell,
    required this.shellSource,
  });
  final String shell;
  final Uri shellSource;
  static String text(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), '');
  Map<String, dynamic>? verify({
    required String receipt,
    required String corp,
    required bool consolidated,
    required Uri coverSource,
    required String cover,
    required Uri statementSource,
    required String statement,
    required DateTime start,
    required DateTime end,
  }) {
    if (shellSource !=
        Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {'rcpNo': receipt})) {
      return null;
    }
    final corps = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m[1]!).toSet();
    final docs = RegExp("openPdfDownload\\('$receipt',\\s*'(\\d+)'\\)")
        .allMatches(shell)
        .map((m) => m[1]!)
        .toSet();
    if (corps.length != 1 || corps.single != corp || docs.length != 1) {
      return null;
    }
    bool node(String title, Uri uri) {
      if (uri.scheme != 'https' ||
          uri.host != 'dart.fss.or.kr' ||
          uri.hasPort ||
          uri.path != '/report/viewer.do' ||
          uri.fragment.isNotEmpty ||
          uri.userInfo.isNotEmpty) {
        return false;
      }
      final matches = <Map<String, String>>[];
      for (final b in RegExp(
        r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
        dotAll: true,
      ).allMatches(shell)) {
        if (b[2]!.replaceAll(RegExp(r'\s+'), '') != title) {
          continue;
        }
        final v = <String, String>{};
        for (final a in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(b[3]!)) {
          if (v.containsKey(a[1])) return false;
          v[a[1]!] = a[2]!;
        }
        matches.add(v);
      }
      return matches.length == 1 &&
          matches.single.length == 6 &&
          matches.single['rcpNo'] == receipt &&
          matches.single['dcmNo'] == docs.single &&
          uri.queryParametersAll.length == 6 &&
          matches.single.entries.every(
            (e) =>
                uri.queryParametersAll[e.key]?.length == 1 &&
                uri.queryParameters[e.key] == e.value,
          );
    }

    if (!node('사업보고서', coverSource) ||
        !node(consolidated ? '2.연결재무제표' : '4.재무제표', statementSource)) {
      return null;
    }
    final c = text(cover);
    final names = RegExp(r'회사명:(.*?)(?:공동)?대표이사:').allMatches(c).toList();
    if (names.length != 1 || names.single[1]!.isEmpty) return null;
    final name = names.single[1]!;
    final dates = RegExp(
      r'사업연도(\d{4}(?:년\d{1,2}월\d{1,2}일|\.\d{2}\.\d{2}))부터(\d{4}(?:년\d{1,2}월\d{1,2}일|\.\d{2}\.\d{2}))까지',
    ).allMatches(c).toList();
    DateTime? date(String s) {
      final n = RegExp(r'\d+')
          .allMatches(s)
          .map((m) => int.parse(m[0]!))
          .toList();
      if (n.length != 3) return null;
      final d = DateTime.utc(n[0], n[1], n[2]);
      return d.year == n[0] && d.month == n[1] && d.day == n[2] ? d : null;
    }

    if (dates.length != 1 ||
        date(dates.single[1]!) != start ||
        date(dates.single[2]!) != end) {
      return null;
    }
    final body = text(statement);
    final quotes = <String>[];
    for (final label in ['재무상태표', '손익계산서', '자본변동표', '현금흐름표']) {
      // Only a dated title followed by its direct issuer and unit caption.
      final titles = RegExp('(?:연결)?(?:포괄)?$label(제[^<]{0,650}?)\\(단위[:：]')
          .allMatches(body)
          .toList();
      if (titles.isEmpty) return null;
      final title = titles.first[1]!;
      final suffix = consolidated
          ? '(?:와그종속기업|과그종속기업|및그종속기업|와그종속회사|과그종속회사|및그종속회사)'
          : '';
      if (!RegExp('(?:회사명:)?${RegExp.escape(name)}$suffix\$').hasMatch(title) ||
          !title.contains('${end.year}')) {
        return null;
      }
      quotes.add('${titles.first[0]}');
    }
    return {
      'kind': 'primary-source-historical-issuer',
      'receipt': receipt,
      'corpCode': corp,
      'printedIssuer': name,
      'basis': consolidated ? 'CFS' : 'OFS',
      'coverSource': coverSource.toString(),
      'statementSource': statementSource.toString(),
      'shellSha256': sha256.convert(utf8.encode(shell)).toString(),
      'coverSha256': sha256.convert(utf8.encode(cover)).toString(),
      'statementSha256': sha256.convert(utf8.encode(statement)).toString(),
      'primaryTitleQuotes': quotes,
    };
  }
}
