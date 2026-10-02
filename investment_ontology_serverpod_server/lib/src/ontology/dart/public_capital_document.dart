import 'dart:convert';

import 'package:http/http.dart' as http;

/// Receipt/company-bound official viewer sections, not search snippets.
class PublicCapitalDocument {
  PublicCapitalDocument({http.Client? client})
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
      throw const FormatException('Capital source HTTP/identity invalid');
    }
    return utf8.decode(response.bodyBytes);
  }

  static List<Uri> bodyUris(String receipt, String corpCode, String shell) {
    final companies = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m[1]).toSet();
    if (companies.length != 1 || companies.single != corpCode) {
      throw const FormatException('Capital source issuer mismatch');
    }
    final uris = <Uri>[];
    final titles = <String>{};
    for (final node in RegExp(
      r'''node\d+\[['"]text['"]\]\s*=\s*['"]([^'"]+)['"];(.*?)(?:cnt\+\+)''',
      dotAll: true,
    ).allMatches(shell)) {
      final title = node[1]!.replaceAll(RegExp(r'\s+'), '');
      if (!RegExp(r'^\d+\.(자본금변동사항|주식의총수등|증권의발행을통한자금조달에관한사항)$')
          .hasMatch(title)) {
        continue;
      }
      if (!titles.add(title)) {
        throw const FormatException('Ambiguous capital section');
      }
      final fields = <String, String>{};
      for (final field in RegExp(
        r'''\[['"](rcpNo|dcmNo|eleId|offset|length|dtd)['"]\]\s*=\s*['"]([^'"]+)['"]''',
      ).allMatches(node[2]!)) {
        if (fields.containsKey(field[1])) {
          throw const FormatException('Duplicate capital coordinate');
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
        throw const FormatException('Unbound capital coordinates');
      }
      uris.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', fields));
    }
    if (uris.isEmpty) throw const FormatException('Capital sections absent');
    return uris;
  }

  Future<({String document, List<String> urls})> fetch(
    String receipt,
    String corpCode,
  ) async {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt) ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Invalid capital identity');
    }
    final shellUri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    final shell = await _get(shellUri);
    final sources = bodyUris(receipt, corpCode, shell);
    final bodies = <String>[];
    for (final uri in sources) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final body = await _get(uri, referer: shellUri);
      if (!RegExp(r'<TABLE\b', caseSensitive: false).hasMatch(body) ||
          body.contains("node1['text']")) {
        throw const FormatException('Actual capital body missing');
      }
      bodies.add(body);
    }
    return (
      document: bodies.join('\n'),
      urls: sources.map((s) => s.toString()).toList(),
    );
  }
}
