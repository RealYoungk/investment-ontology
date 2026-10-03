import 'dart:convert';

import 'package:http/http.dart' as http;

/// Receipt/company-bound official viewer sections, not search snippets.
class PublicCharterSource {
  PublicCharterSource({http.Client? client})
    : _client = client ?? http.Client(),
      _owns = client == null;
  final http.Client _client;
  final bool _owns;
  void close() {
    if (_owns) _client.close();
  }

  Future<String> _get(Uri uri, {Uri? referer}) async {
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'InvestmentOntology/1.0',
            if (referer != null) 'Referer': referer.toString(),
          },
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200 ||
        (response.request?.url.host ?? uri.host) != 'dart.fss.or.kr' ||
        response.bodyBytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Charter source HTTP/identity invalid');
    }
    return utf8.decode(response.bodyBytes);
  }

  static List<Uri> bodyUris(
    String receipt,
    String corpCode,
    String shell, {
    bool notice = false,
  }) {
    final companies = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m[1]).toSet();
    if (companies.length != 1 || companies.single != corpCode) {
      throw const FormatException('Charter source issuer mismatch');
    }
    final uris = <Uri>[];
    final titles = <String>{};
    for (final node in RegExp(
      r'''node\d+\[['"]text['"]\]\s*=\s*['"]([^'"]+)['"];(.*?)(?:cnt\+\+)''',
      dotAll: true,
    ).allMatches(shell)) {
      final title = node[1]!.replaceAll(RegExp(r'\s+'), '');
      if (!(notice
          ? RegExp(r'^(?:\d+\.)?주주총회목적사항별기재사항$').hasMatch(title)
          : RegExp(r'^(?:\d+\.)?정관에관한사항$').hasMatch(title))) {
        continue;
      }
      if (!titles.add(title)) {
        throw const FormatException('Ambiguous charter section');
      }
      final fields = <String, String>{};
      for (final field in RegExp(
        r'''\[['"](rcpNo|dcmNo|eleId|offset|length|dtd)['"]\]\s*=\s*['"]([^'"]+)['"]''',
      ).allMatches(node[2]!)) {
        if (fields.containsKey(field[1])) {
          throw const FormatException('Duplicate charter coordinate');
        }
        fields[field[1]!] = field[2]!;
      }
      if (fields.length != 6 ||
          fields['rcpNo'] != receipt ||
          ![
            'dcmNo',
            'eleId',
            'offset',
            'length',
          ].every((k) => RegExp(r'^\d+$').hasMatch(fields[k]!)) ||
          int.parse(fields['length']!) <= 0 ||
          !RegExp(r'^[\w.-]+$').hasMatch(fields['dtd']!)) {
        throw const FormatException('Unbound charter coordinates');
      }
      uris.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', fields));
    }
    if (uris.isEmpty) throw const FormatException('Charter section absent');
    return uris;
  }

  /// Latest corrected notices in a bounded year, same path for every issuer.
  Future<List<({String receipt, String name})>> discover(
    String corpCode,
  ) async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    String ymd(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final uri = Uri.https('dart.fss.or.kr', '/dsab007/detailSearch.ax', {
      'textCrpCik': corpCode,
      'reportName': '주주총회소집공고',
      'startDate': ymd(DateTime(today.year - 1, today.month, today.day)),
      'endDate': ymd(today),
      'currentPage': '1',
      'maxResults': '100',
      'sort': 'date',
      'series': 'desc',
      'finalReport': 'recent',
    });
    final html = await _get(uri);
    if (!RegExp(r'\[\d+/\d+\]').hasMatch(html) &&
        !html.contains('조회 결과가 없습니다')) {
      throw const FormatException('Notice discovery response incomplete');
    }
    return noticeReceipts(html, corpCode);
  }

  static List<({String receipt, String name})> noticeReceipts(
    String html,
    String corpCode,
  ) {
    final result = <({String receipt, String name})>[];
    for (final row in RegExp(
      r'<tr\b[^>]*>.*?</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final text = row[0]!;
      final issuer = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
          .firstMatch(text)?[1];
      if (issuer != corpCode) continue;
      final link = RegExp(
        r'''openReportViewer\(['"]([0-9]{14})['"],['"]['"]\).*?>(.*?)</a>''',
        dotAll: true,
      ).firstMatch(text);
      if (link == null) continue;
      final name = link[2]!
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'\s+'), '');
      if (!RegExp(r'^(?:\[(?:기재|첨부)정정\])?주주총회소집공고$').hasMatch(name)) continue;
      result.add((receipt: link[1]!, name: name));
    }
    result.sort((a, b) => b.receipt.compareTo(a.receipt));
    return result;
  }

  Future<({String document, List<String> urls})> fetch(
    String receipt,
    String corpCode, {
    bool notice = false,
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt) ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Invalid charter identity');
    }
    final shellUri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    final shell = await _get(shellUri);
    final sources = bodyUris(receipt, corpCode, shell, notice: notice);
    final bodies = <String>[];
    for (final uri in sources) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final body = await _get(uri, referer: shellUri);
      if (!RegExp(r'<TABLE\b', caseSensitive: false).hasMatch(body) ||
          body.contains("node1['text']")) {
        throw const FormatException('Actual charter body missing');
      }
      bodies.add(body);
    }
    return (
      document: bodies.join('\n'),
      urls: sources.map((s) => s.toString()).toList(),
    );
  }
}
