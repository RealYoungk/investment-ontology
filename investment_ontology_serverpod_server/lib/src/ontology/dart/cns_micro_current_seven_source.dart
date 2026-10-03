import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two finite own annual sources. No global header/date relaxation and no
/// synthetic PPE total from printed per-asset acquisition details.
abstract final class CnsMicroCurrentSevenSource {
  static final List _profiles = jsonDecode(
    r'''[{"receipt": "20230323000647", "corp": "01116380", "year": 2022, "name": "(주)씨앤에스링크", "rule": "cnslink-2022-own-current-seven-v1", "sources": [{"label": "shell", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230323000647", "sha256": "ba19e4130cf45066e2d5864ab49652b6afb1568702fe78bf2f74ec11b04692ac", "file": "shell.html"}, {"label": "cover", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000647&dcmNo=9095234&eleId=1&offset=812&length=4139&dtd=dart3.xsd", "sha256": "6ad2c352783751ae583878b849fa180825e4c3fdc46c68371db190f613f12701", "file": "cover.html"}, {"label": "ofs", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000647&dcmNo=9095234&eleId=21&offset=261990&length=75159&dtd=dart3.xsd", "sha256": "a06702b4cbabc5205391b6ac36820b85d7ed1836c97548737df1fb28578eac81", "file": "ofs.html"}], "rows": [{"index": 55, "column": 3, "kind": "BS", "label": "자 산 총 계", "printed": "8,857,831,382"}, {"index": 71, "column": 3, "kind": "BS", "label": "부 채 총 계", "printed": "6,935,338,185"}, {"index": 84, "column": 3, "kind": "BS", "label": "자 본 총 계", "printed": "1,922,493,197"}, {"index": 88, "column": 3, "kind": "IS", "label": "Ⅰ.매출액(주석19,19)", "printed": "19,991,208,651"}, {"index": 121, "column": 3, "kind": "IS", "label": "Ⅴ.영업이익(손실)", "printed": "(147,756,862)"}, {"index": 139, "column": 3, "kind": "IS", "label": "Ⅹ.당기순이익(손실)", "printed": "(412,587,926)"}, {"index": 152, "column": 3, "kind": "CF", "label": "Ⅰ.영업활동으로 인한 현금흐름", "printed": "331,138,751"}], "rowCount": 211, "witnesses": {"0": ["(단위 : 원)"], "1": ["과 목", "2020년도 (제21기)", "2021년도 (제22기)", "2022년도 (제23기)"], "86": ["(단위 : 원)"], "87": ["과 목", "2020년도 (제21기)", "2021년도 (제22기)", "2022년도 (제23기)"], "142": ["(단위 : 원)"], "143": ["과 목", "자 본 금", "자 본 잉여금", "자 본 조 정", "이 익 잉여금", "총 계"], "147": ["2022.1.1(당기초)", "789,980,000", "214,324,405", "(31,270,070)", "1,362,046,788", "2,335,081,123"], "148": ["당기순이익", "-", "-", "-", "(412,587,926)", "(412,587,926)"], "149": ["2022.12.31(당기말)", "789,980,000", "214,324,405", "(31,270,070)", "949,458,862", "1,922,493,197"], "150": ["(단위 : 원)"], "151": ["과 목", "2020년도 (제21기)", "2021년도 (제22기)", "2022년도 (제21기)"]}, "equations": [{"result": [55, 3], "terms": [[71, 3, 1], [84, 3, 1]]}, {"result": [85, 3], "terms": [[55, 3, 1]]}, {"result": [55, 3], "terms": [[3, 3, 1], [20, 3, 1]]}, {"result": [71, 3], "terms": [[57, 3, 1], [67, 3, 1]]}, {"result": [90, 3], "terms": [[88, 3, 1], [89, 3, -1]]}, {"result": [121, 3], "terms": [[90, 3, 1], [91, 3, -1]]}, {"result": [137, 3], "terms": [[121, 3, 1], [122, 3, 1], [129, 3, -1]]}, {"result": [139, 3], "terms": [[137, 3, 1], [138, 3, -1]]}, {"result": [148, 5], "terms": [[139, 3, 1]]}, {"result": [153, 3], "terms": [[139, 3, 1]]}, {"result": [149, 5], "terms": [[147, 5, 1], [148, 5, 1]]}, {"result": [149, 5], "terms": [[84, 3, 1]]}, {"result": [147, 5], "terms": [[84, 2, 1]]}, {"result": [152, 3], "terms": [[153, 3, 1], [154, 3, 1], [162, 3, 1], [166, 3, 1]]}, {"result": [181, 3], "terms": [[182, 3, 1], [188, 3, 1]]}, {"result": [199, 3], "terms": [[200, 3, 1], [203, 3, 1]]}, {"result": [208, 3], "terms": [[152, 3, 1], [181, 3, 1], [199, 3, 1]]}, {"result": [210, 3], "terms": [[209, 3, 1], [208, 3, 1]]}, {"result": [210, 3], "terms": [[5, 3, 1]]}, {"result": [209, 3], "terms": [[5, 2, 1]]}], "anomaly": "CF current header prints 2022년도 (제21기) while BS/PL print 제23기; retained verbatim, current year column bound by own annual cover and dated current CE"}, {"receipt": "20240321000933", "corp": "01206717", "year": 2023, "name": "(주)마이크로엔엑스", "rule": "micronx-2023-own-current-seven-v1", "sources": [{"label": "shell", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240321000933", "sha256": "e0470da3b22112b61938dc66725e2db2e530392b80824b806e3aca97146bd397", "file": "shell.html"}, {"label": "cover", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321000933&dcmNo=9748926&eleId=1&offset=952&length=4096&dtd=dart4.xsd", "sha256": "f9b3ac9d9bf3ef514f8f8383fc465522a6a748c631c7a68fbc2a902c35a1b99b", "file": "cover.html"}, {"label": "ofs", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321000933&dcmNo=9748926&eleId=21&offset=532559&length=76012&dtd=dart4.xsd", "sha256": "bd134689b385e2cecac4838f2ba81a134a3c6464494293732146ea5e00d53748", "file": "ofs.html"}], "rows": [{"index": 60, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "25,104,359,650"}, {"index": 76, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "14,798,747,907"}, {"index": 90, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "10,305,611,743"}, {"index": 97, "column": 2, "kind": "IS", "label": "I. 매출액(주석14)", "printed": "8,349,068,677"}, {"index": 131, "column": 2, "kind": "IS", "label": "V. 영업이익", "printed": "590,611,790"}, {"index": 149, "column": 2, "kind": "IS", "label": "X. 당기순이익(손실)", "printed": "166,398,850"}, {"index": 171, "column": 2, "kind": "CF", "label": "I. 영업활동으로인한현금흐름", "printed": "(465,157,269)"}], "rowCount": 229, "witnesses": {"0": ["제 23(당) 기 2023년 12월 31일 현재"], "2": ["주식회사 마이크로엔엑스", "(단위 : 원)"], "3": ["과 목", "제 23(당) 기", "제 22(전) 기"], "93": ["제 23(당) 기 2023년 1월 1일부터 2023년 12월 31일까지"], "95": ["주식회사 마이크로엔엑스", "(단위 : 원)"], "96": ["과 목", "제 23(당) 기", "제 22(전) 기"], "151": ["제 23(당) 기 2023년 1월 1일부터 2022년 12월 31일까지"], "153": ["주식회사 마이크로엔엑스", "(단위 : 원)"], "154": ["과 목", "자 본 금", "자 본 잉여금", "기타포괄 손익누계액", "이 익 잉여금", "총 계"], "161": ["2023.01.01(당기초)", "1,636,360,000", "2,339,562,000", "5,953,393,700", "(444,108,804)", "9,485,206,896"], "164": ["당기순손익", "-", "-", "-", "166,398,850", "166,398,850"], "165": ["2023.12.31(당기말)", "1,636,360,000", "2,339,562,000", "6,607,399,697", "(277,709,954)", "10,305,611,743"], "167": ["제 23(당) 기 2023년 1월 1일부터 2023년 12월 31일까지"], "169": ["주식회사 마이크로엔엑스", "(단위 : 원)"], "170": ["과 목", "제 23(당) 기", "제 22(전) 기"]}, "equations": [{"result": [60, 2], "terms": [[76, 2, 1], [90, 2, 1]]}, {"result": [91, 2], "terms": [[60, 2, 1]]}, {"result": [60, 2], "terms": [[5, 2, 1], [26, 2, 1]]}, {"result": [76, 2], "terms": [[62, 2, 1], [70, 2, 1]]}, {"result": [105, 2], "terms": [[97, 2, 1], [100, 2, -1]]}, {"result": [131, 2], "terms": [[105, 2, 1], [106, 2, -1]]}, {"result": [147, 2], "terms": [[131, 2, 1], [132, 2, 1], [140, 2, -1]]}, {"result": [149, 2], "terms": [[147, 2, 1], [148, 2, -1]]}, {"result": [164, 5], "terms": [[149, 2, 1]]}, {"result": [172, 1], "terms": [[149, 2, 1]]}, {"result": [165, 5], "terms": [[161, 5, 1], [162, 5, 1], [163, 5, 1], [164, 5, 1]]}, {"result": [165, 5], "terms": [[90, 2, 1]]}, {"result": [161, 5], "terms": [[90, 4, 1]]}, {"result": [171, 2], "terms": [[172, 1, 1], [173, 1, 1], [181, 1, 1], [184, 1, 1]]}, {"result": [202, 2], "terms": [[203, 1, 1], [206, 1, 1]]}, {"result": [218, 2], "terms": [[219, 1, 1], [222, 1, 1]]}, {"result": [225, 2], "terms": [[171, 2, 1], [202, 2, 1], [218, 2, 1]]}, {"result": [227, 2], "terms": [[226, 2, 1], [225, 2, 1]]}, {"result": [227, 2], "terms": [[7, 1, 1]]}, {"result": [226, 2], "terms": [[7, 3, 1]]}], "anomaly": "CE title prints 2023년1월1일부터2022년12월31일까지; retained verbatim. Current CE opening2023Jan1/closing2023Dec31 plus own cover, full current PL/CF range and same NI independently bind current rows"}]''',
  );

  /// Detached evidence copies for source audits; callers cannot alter guards.
  static List get profiles => jsonDecode(jsonEncode(_profiles)) as List;
  static bool supports(String rule) => _profiles.any((p) => p['rule'] == rule);
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    final p = _profiles.singleWhere(
      (p) => p['receipt'] == receipt,
      orElse: () =>
          throw const FormatException('CNS/Micro exact receipt mismatch'),
    ) as Map;
    final year = p['year'] as int;
    if (corp != p['corp'] ||
        consolidated ||
        start != DateTime.utc(year) ||
        end != DateTime.utc(year, 12, 31)) {
      throw const FormatException('CNS/Micro own annual binding mismatch');
    }
    for (final s in p['sources'] as List) {
      final label = s['label'] as String;
      if (uris[label]?.toString() != s['url'] ||
          raw[label] == null ||
          sha256.convert(utf8.encode(raw[label]!)).toString() != s['sha256']) {
        throw const FormatException('CNS/Micro original URI/SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    final ownName = year == 2022 ? '주식회사 씨앤에스링크' : '주식회사 마이크로엔엑스';
    if (!cover.contains(ownName) ||
        !cover.contains('$year년 01월 01일') ||
        !cover.contains('$year년 12월 31일')) {
      throw const FormatException('CNS/Micro exact own cover period mismatch');
    }
    final actors = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    if (actors.length != 1 || actors.single != corp) {
      throw const FormatException('CNS/Micro own actor mismatch');
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
    if (rows.length != p['rowCount']) {
      throw const FormatException('CNS/Micro current row structure changed');
    }
    for (final w in (p['witnesses'] as Map).entries) {
      if (rows[int.parse(w.key as String)].join('|') !=
          (w.value as List).join('|')) {
        throw const FormatException(
          'CNS/Micro current unit/header/period witness mismatch',
        );
      }
    }
    BigInt money(String v) => v == '-'
        ? BigInt.zero
        : BigInt.parse(
            v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt amount(List xy) => money(rows[xy[0] as int][xy[1] as int]);
    for (final e in p['equations'] as List) {
      final sum = (e['terms'] as List).fold(
        BigInt.zero,
        (sum, term) => sum + amount(term) * BigInt.from(term[2] as int),
      );
      if (amount(e['result'] as List) != sum) {
        throw const FormatException(
          'CNS/Micro current BS PL CE CF reconciliation conflict',
        );
      }
    }
    return [
      for (final s in p['rows'] as List)
        {
          'rcept_no': receipt,
          'corp_code': corp,
          'bsns_year': '$year',
          'reprt_code': '11011',
          'account_id': null,
          'account_nm': s['label'],
          'account_detail': '-',
          'sj_div': s['kind'],
          'thstrm_nm': s['kind'] == 'BS'
              ? '$year-12-31'
              : '$year-01-01~$year-12-31',
          'thstrm_amount': money(rows[s['index'] as int][s['column'] as int])
              .toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': uris['ofs'].toString(),
            'sourceReceipt': receipt,
            'sourceSha256': (p['sources'] as List).singleWhere(
              (s) => s['label'] == 'ofs',
            )['sha256'],
            'ruleVersion': p['rule'],
            'printedLabel': rows[s['index'] as int][0],
            'printedAmount': rows[s['index'] as int][s['column'] as int],
            'currentColumn': s['column'],
            'htmlTrIndex': s['index'],
            'unit': '원',
            'unitMultiplier': '1',
            'basis': 'OFS',
            'periodStart': '$year-01-01',
            'periodEnd': '$year-12-31',
            'partialCore7': true,
            'wholeNetIncomeExact': true,
            'coreAmountsConflicting': false,
            'fullStatementCollected': false,
            'fullStatementVerified': false,
            'allStatementRowsVerified': false,
            'notesVerified': false,
            'numericCellCorrection': false,
            'genericRoundingTolerance': false,
            'uncollectedOptionalAccounts': ['capex'],
            'optionalAccountsNotCollected': ['capex'],
            'missingAccountReasons': {
              'capex': 'Per-asset acquisitions are printed; no unambiguous whole PPE acquisition total collected, no sum or zero substitution.',
            },
            'printedCurrentPeriodAnomaly': p['anomaly'],
            'currentPeriodWitnesses': p['witnesses'],
            'priorNumericPeriodsCollected': false,
            'currentProof': 'Exact own cover and dated current CE rows; current PL=CE=CF NI; exact BS/PL/CE/CFO/current cash roll and BS cash',
          },
        },
    ];
  }
}
