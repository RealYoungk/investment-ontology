import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One own current-year source. Preserve printed thousand-won residuals;
/// never invent a whole PPE acquisition amount from the contradictory zero.
abstract final class Talos2021CurrentSevenSource {
  static const rule = 'talos-own-2021-current-seven-v1';
  static const sources = {
    'shell': (
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20221027000409',
      'de574753aa6ecb61c699a51026f4b52f31ed86894c3613dde011c72b30ca6aa6',
    ),
    'cover': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20221027000409&dcmNo=8850347&eleId=1&offset=795&length=4026&dtd=dart3.xsd',
      '46a39bf332b78f26c997c6584f6d22f8dfbf183fbf28dc40056d04f2044676bf',
    ),
    'ofs': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20221027000409&dcmNo=8850347&eleId=21&offset=183582&length=68022&dtd=dart3.xsd',
      '09e57bf14a980f2209851a223e5f8e007fc654463055efc76d620637dc4126b9',
    ),
  };
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    if (receipt != '20221027000409' ||
        corp != '01020269' ||
        consolidated ||
        start != DateTime.utc(2021) ||
        end != DateTime.utc(2021, 12, 31)) {
      throw const FormatException('Talos exact own annual identity mismatch');
    }
    for (final e in sources.entries) {
      if (uris[e.key]?.toString() != e.value.$1 ||
          raw[e.key] == null ||
          sha256.convert(utf8.encode(raw[e.key]!)).toString() != e.value.$2) {
        throw const FormatException('Talos exact original URI/SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    if (!cover.contains('주식회사 탈로스') ||
        !cover.contains('2021년 01월 01일') ||
        !cover.contains('2021년 12월 31일')) {
      throw const FormatException('Talos own cover period/issuer missing');
    }
    final actors = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    if (actors.length != 1 || actors.single != corp) {
      throw const FormatException('Talos official own actor ambiguous');
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
          ).allMatches(tr[1]!))
            text(c[1]!),
        ],
    ];
    if (rows.length != 203 ||
        [0, 78, 130, 145].any((i) => rows[i].single != '(단위 : 천원)') ||
        [
          1,
          79,
          146,
        ].any((i) => rows[i].join('|') != '과 목|2019연도|2020연도|2021연도') ||
        rows[140].join('|') !=
            '2021연도 (제17기)|기초|2,830,235|4,004,288|0|-5,161,658|1,672,865' ||
        rows[144].first != '기말' ||
        rows[147].last != '(제17기)') {
      throw const FormatException(
        'Talos exact 2021 current year/right column conflict',
      );
    }
    BigInt money(String value) => value == '-'
        ? BigInt.zero
        : BigInt.parse(
            value.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt amt(int r, [int c = 3]) => money(rows[r][c]);
    if (amt(45) != amt(63) + amt(76) ||
        amt(77) != amt(45) ||
        amt(129) != amt(141, 5) ||
        amt(129) != amt(149) ||
        amt(140, 6) + amt(141, 5) + amt(143, 5) - amt(144, 5) != BigInt.one ||
        amt(144, 5) != amt(76) ||
        amt(81) - amt(83) - amt(88) != BigInt.one ||
        amt(88) - amt(89) != amt(115) ||
        amt(127) - amt(128) - amt(129) != -BigInt.one ||
        amt(149) + amt(150) + amt(160) != amt(148) ||
        amt(148) + amt(179) + amt(191) != amt(200) ||
        amt(201) + amt(200) != amt(202) ||
        amt(202) != amt(6) ||
        amt(201) != amt(6, 2) ||
        amt(189) != BigInt.zero ||
        amt(185) != BigInt.from(37841) ||
        amt(187) != BigInt.from(10784)) {
      throw const FormatException(
        'Talos exact current reconciliation/residual or missing PPE scope conflict',
      );
    }
    const specs = [
      (45, 'BS', '자산총계'),
      (63, 'BS', '부채총계'),
      (76, 'BS', '자본총계'),
      (81, 'IS', 'Ⅰ. 매출액'),
      (115, 'IS', 'Ⅴ. 영업이익(손실)'),
      (129, 'IS', 'Ⅹ. 당기순이익(손실)'),
      (148, 'CF', 'Ⅰ. 영업활동으로 인한 현금흐름'),
    ];
    for (final s in specs) {
      if (rows[s.$1].first != s.$3) {
        throw const FormatException('Talos direct current row label mismatch');
      }
    }
    return specs
        .map(
          (s) => <String, dynamic>{
            'rcept_no': receipt,
            'corp_code': corp,
            'bsns_year': '2021',
            'reprt_code': '11011',
            'account_id': null,
            'account_nm': rows[s.$1].first,
            'account_detail': '-',
            'sj_div': s.$2,
            'thstrm_nm': s.$2 == 'BS' ? '2021-12-31' : '2021-01-01~2021-12-31',
            'thstrm_amount': (amt(s.$1) * BigInt.from(1000)).toString(),
            'currency': 'KRW',
            'html_provenance': {
              'source': uris['ofs'].toString(),
              'sourceReceipt': receipt,
              'sourceSha256': sources['ofs']!.$2,
              'ruleVersion': rule,
              'printedLabel': rows[s.$1].first,
              'printedAmount': rows[s.$1][3],
              'currentColumn': 3,
              'htmlTrIndex': s.$1,
              'unit': '천원',
              'unitMultiplier': '1000',
              'basis': 'OFS',
              'periodStart': '2021-01-01',
              'periodEnd': '2021-12-31',
              'fullStatementCollected': false,
              'partialCore7': true,
              'allStatementRowsVerified': false,
              'detailHierarchyComplete': false,
              'notesVerified': false,
              'notesReadScopeComplete': false,
              'uncollectedOptionalAccounts': ['capex'],
              'optionalAccountsNotCollected': ['capex'],
              'missingAccountReasons': {
                'capex': 'Printed PPE acquisition row is zero but machine/equipment detail is nonzero; no unambiguous whole acquisition total collected.',
              },
              'printedThousandWonResiduals': {
                'CE opening+current-profit+revaluation-closing': '1',
                'PL revenue-cost-gross': '1',
                'PL pre-tax-tax-net': '-1',
              },
              'numericCellCorrection': false,
              'wholeNetIncomeExact': true,
              'coreAmountsConflicting': false,
              'printedCurrentNI': rows[129][3],
              'printedWholeCENI': rows[141][5],
              'printedCFNI': rows[149][3],
              'printedClosingEquity': rows[144][5],
              'printedBSEquity': rows[76][3],
              'fullStatementVerified': false,
              'currentProof': 'own cover2021, BS/PL/CF2021 rightmost column, CE own year2021 opening/currentprofit/closing; exact BS and CF cash; printed CE/PL residuals preserved',
            },
          },
        )
        .toList();
  }
}
