import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One issuer's own 2022 annual section. Prior unaudited CE rows are witnesses
/// for opening balances only, never separately collected annual values.
abstract final class Talos2022ExactSource {
  static const rule = 'talos-own-2022-current-eight-v1';
  static const sources = {
    'shell': (
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230718000182',
      'f41e4924df3fabc6126e47577c02718ee62df8d100936f073d304b975b1d5002',
    ),
    'cover': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230718000182&dcmNo=9352642&eleId=3&offset=17145&length=4026&dtd=dart3.xsd',
      '1d01d38a28db1f20e4149df54ff7087c435a019b0558c82aab0826105e6e3d96',
    ),
    'ofs': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230718000182&dcmNo=9352642&eleId=23&offset=195816&length=31745&dtd=dart3.xsd',
      'b41f1ddaa94bb3a0443217b02de4103a89e8201dd609d9e4f3348ce7a3d7f0c3',
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
    if (receipt != '20230718000182' ||
        corp != '01020269' ||
        consolidated ||
        start != DateTime.utc(2022) ||
        end != DateTime.utc(2022, 12, 31)) {
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
        !cover.contains('2022년 01월 01일') ||
        !cover.contains('2022년 12월 31일')) {
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
    if (rows.length != 111 ||
        [0, 40, 63, 81].any((i) => rows[i].join('|') != '(단위 : 원)') ||
        rows[1].join('|') != '과 목|제 18 (당)기말|제 17 (전)기말|제 16 (전전)기말' ||
        rows[41].join('|') != '과 목|제 18(당) 기|제 17(전)기' ||
        rows[82].join('|') != '구 분|제 18(당)기|제 17(전)기' ||
        rows[64].join('|') != '과 목|자 본 금|자본잉여금|자본조정|기타포괄 손익누계액|이익잉여금|총 계' ||
        rows[71].first != '2022년 1월 1일(당기초) "감사받지 아니한 재무제표"' ||
        rows[80].first != '2022년 12월 31일(당기말)') {
      throw const FormatException(
        'Talos direct current header/date/unit conflict',
      );
    }
    BigInt money(String value) => value == '-'
        ? BigInt.zero
        : BigInt.parse(
            value.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt amt(int r, [int c = 1]) => money(rows[r][c]);
    BigInt sum(List<int> rs, [int c = 1]) =>
        rs.fold(BigInt.zero, (a, r) => a + amt(r, c));
    if (amt(16) != amt(31) + amt(38) ||
        amt(39) != amt(16) ||
        amt(42) - amt(43) != amt(44) ||
        amt(44) - amt(45) - amt(46) != amt(47) ||
        amt(47) + amt(48) - amt(49) + amt(50) - amt(51) != amt(52) ||
        amt(52) - amt(53) != amt(54) ||
        amt(54) + amt(55) != amt(59) ||
        amt(73, 6) != amt(54) ||
        amt(85) != amt(54) ||
        amt(71, 6) + sum([73, 74, 75, 77, 78, 79], 6) != amt(80, 6) ||
        amt(80, 6) != amt(38) ||
        amt(71, 6) != amt(38, 2) ||
        sum([83, 91, 99]) != amt(108) ||
        amt(109) + amt(108) != amt(110) ||
        amt(110) != amt(4) ||
        amt(109) != amt(4, 2) ||
        sum([85, 86, 87]) != amt(84) ||
        sum([84, 88, 89, 90]) != amt(83) ||
        amt(92) + amt(95) != amt(91) ||
        sum([96, 97, 98]) != amt(95) ||
        amt(100) + amt(103) != amt(99) ||
        sum([104, 105, 106]) != amt(103)) {
      throw const FormatException(
        'Talos independent current BS PL CE CF conflict',
      );
    }
    const specs = [
      (16, 'BS', '자산총계'),
      (31, 'BS', '부채총계'),
      (38, 'BS', '자본총계'),
      (42, 'IS', 'Ⅰ.매출액'),
      (47, 'IS', 'Ⅳ.영업이익'),
      (54, 'IS', 'Ⅶ. 당기순이익(손실)'),
      (83, 'CF', 'Ⅰ.영업활동 순현금흐름'),
      (97, 'CF', '유형자산의 취득'),
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
            'bsns_year': '2022',
            'reprt_code': '11011',
            'account_id': null,
            'account_nm': rows[s.$1].first,
            'account_detail': '-',
            'sj_div': s.$2,
            'thstrm_nm': s.$2 == 'BS' ? '2022-12-31' : '2022-01-01~2022-12-31',
            'thstrm_amount': (s.$1 == 97 ? amt(s.$1).abs() : amt(s.$1))
                .toString(),
            'currency': 'KRW',
            'html_provenance': {
              'source': uris['ofs'].toString(),
              'sourceReceipt': receipt,
              'sourceSha256': sources['ofs']!.$2,
              'ruleVersion': rule,
              'printedLabel': rows[s.$1].first,
              'printedAmount': rows[s.$1][1],
              'currentColumn': 1,
              'htmlTrIndex': s.$1,
              'unit': '원',
              'unitMultiplier': '1',
              'basis': 'OFS',
              'periodStart': '2022-01-01',
              'periodEnd': '2022-12-31',
              'fullStatementCollected': false,
              'printedPriorOpeningAuditStatus': '감사받지 아니한 재무제표',
              'priorOpeningUsage': 'current CE reconciliation witness only; no prior numeric period collected',
              'currentProof': 'own dated CE rows71..80; BS=liabilities+equity; PL and CF totals exact; CF cash equals own BS cash',
              if (s.$1 == 97) 'outflowNormalized': true,
            },
          },
        )
        .toList();
  }
}
