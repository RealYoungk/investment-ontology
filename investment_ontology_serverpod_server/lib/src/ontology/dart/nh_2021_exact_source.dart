import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One pinned original report; no historical-name alias or rounding tolerance.
abstract final class Nh2021ExactSource {
  static const rule = 'nh-2021-exact-whole-eight-v1';
  static final Map<String, dynamic> _p = jsonDecode(
    r'''{"sources": [{"url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220315000644", "sha256": "526baef54c32033a36ecd34ca6ee2f82bda79a9ab972eb6e34f0a142304940df", "file": "shell.html", "label": "shell"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315000644&dcmNo=8459965&eleId=1&offset=795&length=4059&dtd=dart3.xsd", "sha256": "e3cdb87cebac73274b604cd7905d7d074cc1d876bf56d9b9f1edf5d2c76349b0", "file": "cover.html", "label": "cover"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315000644&dcmNo=8459965&eleId=3&offset=19757&length=203294&dtd=dart3.xsd", "sha256": "12ea1fe49d64fd6b8a98a37f3ad26f96ff2d5bdeaf811ed34a906997549ff606", "file": "overview.html", "label": "overview"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315000644&dcmNo=8459965&eleId=19&offset=2483873&length=104154&dtd=dart3.xsd", "sha256": "fe57ba04109042c81cbf8db1ec63a62557558b2ac1fc4ce7ecf2bcbce5e27e8e", "file": "ofs.html", "label": "ofs"}], "rows": [{"index": 19, "column": 2, "kind": "BS", "printed": "55,828,248", "label": "자산 총계", "value": "55828248000000"}, {"index": 31, "column": 2, "kind": "BS", "printed": "49,364,881", "label": "부채 총계", "value": "49364881000000"}, {"index": 37, "column": 2, "kind": "BS", "printed": "6,463,367", "label": "자본 총계", "value": "6463367000000"}, {"index": 46, "column": 2, "kind": "CIS", "printed": "10,238,650", "label": "영업수익", "value": "10238650000000"}, {"index": 69, "column": 2, "kind": "CIS", "printed": "1,205,948", "label": "영업이익", "value": "1205948000000"}, {"index": 74, "column": 2, "kind": "CIS", "printed": "793,512", "label": "당기순이익 (대손준비금반영후 조정이익: 당기 : 782,640 백 만원 , 전기 : 484,955 백만원, 전전기 : 418,256백만원)", "value": "793512000000"}, {"index": 137, "column": 2, "kind": "CF", "printed": "3,771,076", "label": "Ⅰ. 영업활동으로 인한 현금흐름", "value": "3771076000000"}, {"index": 159, "column": 1, "kind": "CF", "printed": "(51,956)", "label": "유형자산의 취득", "value": "51956000000"}]}''',
  ) as Map<String, dynamic>;
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    if (receipt != '20220315000644' ||
        corp != '00120182' ||
        consolidated ||
        start != DateTime.utc(2021) ||
        end != DateTime.utc(2021, 12, 31)) {
      throw const FormatException('NH exact annual identity mismatch');
    }
    for (final s in _p['sources'] as List) {
      final label = s['label'] as String;
      if (uris[label]?.toString() != s['url'] ||
          raw[label] == null ||
          sha256.convert(utf8.encode(raw[label]!)).toString() != s['sha256']) {
        throw const FormatException('NH exact raw URI/SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final ov = text(raw['overview']!);
    if (!ov.contains('엔에이치투자증권주식회사') ||
        !ov.contains('NH INVESTMENT & SECURITIES CO.,LTD.')) {
      throw const FormatException(
        'NH self-declared bilingual identity missing',
      );
    }
    final shellIds = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m.group(1))
        .toSet();
    if (shellIds.length != 1 || shellIds.single != corp) {
      throw const FormatException('NH official corp ambiguous');
    }
    final rows = <List<String>>[
      for (final tr in RegExp(
        r'<tr\b[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(raw['ofs']!))
        [
          for (final c in RegExp(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr.group(1)!))
            text(c.group(1)!),
        ],
    ];
    if (rows.length != 180) {
      throw const FormatException('NH pinned row scope mismatch');
    }
    BigInt money(String x) => BigInt.parse(
      x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
    );
    final result = <Map<String, dynamic>>[];
    for (final spec in _p['rows'] as List) {
      final r = rows[spec['index'] as int], col = spec['column'] as int;
      if (r.first != spec['label'] || r[col] != spec['printed']) {
        throw const FormatException('NH direct current whole row mismatch');
      }
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '2021',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': r.first,
        'account_detail': '-',
        'sj_div': spec['kind'],
        'thstrm_nm': spec['kind'] == 'BS'
            ? '2021-12-31'
            : '2021-01-01~2021-12-31',
        'thstrm_amount': spec['value'],
        'currency': 'KRW',
        'html_provenance': {
          'source': uris['ofs'].toString(),
          'sourceReceipt': receipt,
          'ruleVersion': rule,
          'sourceSha256': (_p['sources'] as List).singleWhere(
            (s) => s['label'] == 'ofs',
          )['sha256'],
          'printedLabel': r.first,
          'printedAmount': r[col],
          'currentColumn': col,
          'htmlTrIndex': spec['index'],
          'unit': '백만원',
          'unitMultiplier': '1000000',
          'basis': 'OFS',
          'periodStart': '2021-01-01',
          'periodEnd': '2021-12-31',
          'fullStatementCollected': false,
          'selfDeclaredIssuerQuote':
              '엔에이치투자증권주식회사 / NH INVESTMENT & SECURITIES CO.,LTD.',
          'issuerOverviewSource': uris['overview'].toString(),
          'issuerOverviewSha256': (_p['sources'] as List).singleWhere(
            (s) => s['label'] == 'overview',
          )['sha256'],
        },
      });
    }
    BigInt amt(int row, int column) => money(rows[row][column]);
    if (amt(19, 2) != amt(31, 2) + amt(37, 2) ||
        amt(124, 5) != amt(74, 2) ||
        amt(129, 5) != amt(37, 2) ||
        amt(119, 5) != money(rows[37][4]) ||
        amt(119, 5) +
                [
                  121,
                  122,
                  124,
                  126,
                  127,
                  128,
                ].map((i) => amt(i, 5)).fold(BigInt.zero, (a, b) => a + b) !=
            amt(129, 5) ||
        amt(137, 2) + amt(145, 2) + amt(161, 2) != amt(175, 2) ||
        amt(177, 2) + amt(175, 2) + amt(176, 2) != amt(178, 2) ||
        amt(7, 1) != amt(178, 2) ||
        amt(7, 3) != amt(177, 2)) {
      throw const FormatException('NH independent BS CE cash proof conflict');
    }
    return result;
  }
}
