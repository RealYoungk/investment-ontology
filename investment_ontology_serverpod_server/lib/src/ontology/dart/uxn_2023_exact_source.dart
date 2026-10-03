import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exact own FY2023 only; the two unaudited FY2022 BS columns are witnesses,
/// never recovered FY2022 financial facts. PL's printed point-in-time title is
/// retained and bound to own cover + dated CE/CF, without rewriting source.
abstract final class Uxn2023ExactSource {
  static const rule = 'uxn-2023-own-current-eight-v1';
  static const sources = {
    'shell': (
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240320001200',
      '9a7f2ee6217acb28619d10fb0d4a793ac2d402aad986dbe15de38c8007e0ec7c',
    ),
    'cover': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001200&dcmNo=9738846&eleId=1&offset=957&length=4664&dtd=dart4.xsd',
      '495686bea5c9dd5b0957c0a0e3d33bd0dcb3485cbfb6a8ce77c7dff9bbbc0206',
    ),
    'ofs': (
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001200&dcmNo=9738846&eleId=21&offset=502665&length=50296&dtd=dart4.xsd',
      '90ff02a27e145f72eb629cfc3b38a7a3e5f94362e3865c91f1afe5d4e24bcab3',
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
    if (receipt != '20240320001200' ||
        corp != '01396931' ||
        consolidated ||
        start != DateTime.utc(2023) ||
        end != DateTime.utc(2023, 12, 31)) {
      throw const FormatException('UXN exact own FY2023 identity mismatch');
    }
    for (final e in sources.entries) {
      if (uris[e.key]?.toString() != e.value.$1 ||
          raw[e.key] == null ||
          sha256.convert(utf8.encode(raw[e.key]!)).toString() != e.value.$2) {
        throw const FormatException('UXN exact original URI/SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    if (!cover.contains('주식회사 유엑스엔') ||
        !cover.contains('2023년 01월 01일') ||
        !cover.contains('2023년 12월 31일')) {
      throw const FormatException('UXN own cover mismatch');
    }
    final actors = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    if (actors.length != 1 || actors.single != corp) {
      throw const FormatException('UXN own actor mismatch');
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
    final html = text(raw['ofs']!);
    if (rows.length != 123 ||
        rows[0].join('|') !=
            '과 목|2023년도 (제12(당)기말)|2022년도 (제11(전)기말) (감사받지 아니한 재무제표)|2022년도 (제11기(전)기초) (감사받지 아니한 재무제표)' ||
        [43, 85].any(
          (i) =>
              rows[i].join('|') !=
              '과 목|2023년도 (제12(당)기말)|2022년도 (제11(전)기말) (감사받지 아니한 재무제표)',
        ) ||
        rows[66].join('|') != '과 목|자 본 금|자 본 잉여금|기 타 자본항목|결손금|총 계' ||
        rows[77].first != '2023.01.01(당기초) (감사받지 아니한 재무제표)' ||
        rows[84].first != '2023.12.31(당기말)' ||
        !html.contains('다. 자본변동표 제12(당)기 2023년 01월 01일부터 2023년 12월 31일까지') ||
        !html.contains('라. 현금흐름표 제12(당)기 2023년 01월 01일부터 2023년 12월 31일까지') ||
        !html.contains('나. (포괄)손익계산서 제12(당)기 2023년 12월 31일 현재') ||
        RegExp(r'주식회사 유엑스엔 \(단위 : 원\)').allMatches(html).length != 4) {
      throw const FormatException(
        'UXN printed current date/unit/header mismatch',
      );
    }
    BigInt money(String v) => v == '-'
        ? BigInt.zero
        : BigInt.parse(
            v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt amt(int r, [int c = 1]) => money(rows[r][c]);
    BigInt sum(List<int> rs, [int c = 1]) =>
        rs.fold(BigInt.zero, (a, r) => a + amt(r, c));
    if (amt(17) != amt(35) + amt(41) ||
        amt(42) != amt(17) ||
        amt(2) + amt(11) != amt(17) ||
        amt(19) + amt(27) != amt(35) ||
        sum([37, 38, 39, 40]) != amt(41) ||
        amt(44) - amt(45) != amt(46) ||
        amt(46) - amt(47) != amt(48) ||
        amt(50) - amt(51) != amt(49) ||
        amt(53) - amt(54) != amt(52) ||
        sum([48, 49, 52, 55]) != amt(56) ||
        amt(56) - amt(57) != amt(58) ||
        amt(58) + amt(59) != amt(62) ||
        amt(80, 5) != amt(58) ||
        amt(88) != amt(58) ||
        amt(77, 5) + sum([79, 80, 82, 83], 5) != amt(84, 5) ||
        amt(84, 5) != amt(41) ||
        amt(77, 5) != amt(41, 2) ||
        sum([88, 89, 90]) != amt(87) ||
        sum([87, 91, 92, 93]) != amt(86) ||
        amt(95) + amt(103) != amt(94) ||
        amt(112) + amt(115) != amt(111) ||
        sum([86, 94, 111, 119]) != amt(120) ||
        amt(121) + amt(120) != amt(122) ||
        amt(122) != amt(3) ||
        amt(121) != amt(3, 2) ||
        amt(109) <= BigInt.zero ||
        sum([104, 105, 106, 107, 108, 109, 110]) != -amt(103)) {
      throw const FormatException(
        'UXN exact current BS PL CE CF arithmetic mismatch',
      );
    }
    const specs = [
      (17, 'BS', '자 산 총 계'),
      (35, 'BS', '부 채 총 계'),
      (41, 'BS', '자 본 총 계'),
      (44, 'IS', 'Ⅰ. 매출액'),
      (48, 'IS', 'Ⅴ. 영업손실'),
      (58, 'IS', 'XI. 당기순손실'),
      (86, 'CF', 'Ⅰ. 영업활동 현금흐름'),
      (109, 'CF', '유형자산의 취득'),
    ];
    for (final s in specs) {
      if (rows[s.$1].first != s.$3) {
        throw const FormatException('UXN current exact raw label mismatch');
      }
    }
    return specs
        .map(
          (s) => <String, dynamic>{
            'rcept_no': receipt,
            'corp_code': corp,
            'bsns_year': '2023',
            'reprt_code': '11011',
            'account_id': null,
            'account_nm': rows[s.$1].first,
            'account_detail': '-',
            'sj_div': s.$2,
            'thstrm_nm': s.$2 == 'BS' ? '2023-12-31' : '2023-01-01~2023-12-31',
            'thstrm_amount': (s.$1 == 109 ? amt(s.$1).abs() : amt(s.$1))
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
              'periodStart': '2023-01-01',
              'periodEnd': '2023-12-31',
              'fullStatementCollected': false,
              'printedPriorOpeningAuditStatus': '감사받지 아니한 재무제표',
              'printedPLPeriodTitle': '제12(당)기 2023년 12월 31일 현재',
              'PLAnnualPeriodBinding': 'own annual cover; same current PL=CE=CF net loss; dated own CE/CF annual range',
              'priorNumericPeriodsCollected': false,
              'fullStatementVerified': false,
              'allStatementRowsVerified': false,
              'numericCellCorrection': false,
              'genericRoundingTolerance': false,
              'priorOpeningUsage': 'current CE reconciliation witness only; no prior numeric period collected',
              'currentProof': 'own CE77..84 and CF dated full2023 range; BS totals, PL/CE/CF NI, CFO and cash roll exact; repeated prior2022 headers are not current columns',
              if (s.$1 == 109) 'outflowNormalized': true,
            },
          },
        )
        .toList();
  }
}
