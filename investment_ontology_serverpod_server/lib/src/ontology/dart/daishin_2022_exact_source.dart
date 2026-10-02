import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One pinned original report; no historical-name alias or rounding tolerance.
abstract final class Daishin2022ExactSource {
  static const rule = 'daishin-2022-exact-cash-scope-whole-eight-v1';
  static final Map<String, dynamic> _p = jsonDecode(
    r'''{"sources": [{"url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230316001545", "sha256": "e949368ffbfe28ffa297e9b8778db6c3bf68bfc72ba02d33f3d949570f5393f2", "file": "shell.html", "label": "shell"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001545&dcmNo=9068010&eleId=1&offset=796&length=4032&dtd=dart3.xsd", "sha256": "c95cb328b2cd3e097a5b9d8b53b0c52a5abacf383a0fffa6f0482416bdb6c514", "file": "cover.html", "label": "cover"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001545&dcmNo=9068010&eleId=19&offset=2645588&length=65913&dtd=dart3.xsd", "sha256": "8d6067c712462c9ca615a357aa53f713a8fe4453c78181f1c5865b5179dce404", "file": "ofs.html", "label": "ofs"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001545&dcmNo=9068010&eleId=20&offset=2711505&length=998963&dtd=dart3.xsd", "sha256": "f2c3f95e45c947316fa0e725086c1e297d97f16e17ef7be073d6156bb6cfdf9b", "file": "notes.html", "label": "notes"}], "rows": [{"index": 17, "column": 2, "kind": "BS", "printed": "13,561,139,399", "label": "자 산 총 계", "value": "13561139399000"}, {"index": 31, "column": 2, "kind": "BS", "printed": "11,511,801,876", "label": "부 채 총 계", "value": "11511801876000"}, {"index": 38, "column": 2, "kind": "BS", "printed": "2,049,337,523", "label": "자 본 총 계", "value": "2049337523000"}, {"index": 46, "column": 2, "kind": "CIS", "printed": "3,107,330,022", "label": "Ⅰ. 영업수익", "value": "3107330022000"}, {"index": 65, "column": 2, "kind": "CIS", "printed": "88,877,753", "label": "Ⅲ. 영업이익", "value": "88877753000"}, {"index": 71, "column": 2, "kind": "CIS", "printed": "86,474,236", "label": "Ⅶ. 당기순이익 (대손준비금반영후 조정이익 당기: 87,133백만원 전기: 178,664백만원)(주석23)", "value": "86474236000"}, {"index": 116, "column": 2, "kind": "CF", "printed": "382,074,231", "label": "Ⅰ. 영업활동으로부터의 현금흐름", "value": "382074231000"}, {"index": 160, "column": 1, "kind": "CF", "printed": "(14,288,414)", "label": "9. 유형자산의 취득", "value": "14288414000"}]}''',
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
    if (receipt != '20230316001545' ||
        corp != '00110893' ||
        consolidated ||
        start != DateTime.utc(2022) ||
        end != DateTime.utc(2022, 12, 31)) {
      throw const FormatException('Daishin exact annual identity mismatch');
    }
    for (final s in _p['sources'] as List) {
      final label = s['label'] as String;
      if (uris[label]?.toString() != s['url'] ||
          raw[label] == null ||
          sha256.convert(utf8.encode(raw[label]!)).toString() != s['sha256']) {
        throw const FormatException('Daishin exact raw URI/SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    if (!cover.contains('대신증권') || !cover.contains('2022')) {
      throw const FormatException('Daishin pinned cover identity missing');
    }
    final shellIds = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m.group(1))
        .toSet();
    if (shellIds.length != 1 || shellIds.single != corp) {
      throw const FormatException('Daishin official corp ambiguous');
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
    if (rows.length != 177) {
      throw const FormatException('Daishin pinned row scope mismatch');
    }
    BigInt money(String x) => BigInt.parse(
      x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
    );
    final result = <Map<String, dynamic>>[];
    for (final spec in _p['rows'] as List) {
      final r = rows[spec['index'] as int], col = spec['column'] as int;
      if (r.first != spec['label'] || r[col] != spec['printed']) {
        throw const FormatException(
          'Daishin direct current whole row mismatch',
        );
      }
      final printedAmount = money(r[col]);
      final normalizedAmount = spec['index'] == 160
          ? printedAmount.abs()
          : printedAmount;
      final won = normalizedAmount * BigInt.from(1000);
      if (won.toString() != spec['value']) {
        throw const FormatException('Daishin direct amount scaling mismatch');
      }
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '2022',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': r.first,
        'account_detail': '-',
        'sj_div': spec['kind'],
        'thstrm_nm': spec['kind'] == 'BS'
            ? '2022-12-31'
            : '2022-01-01~2022-12-31',
        'thstrm_amount': won.toString(),
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
          'unit': '천원',
          'unitMultiplier': '1000',
          'basis': 'OFS',
          'periodStart': '2022-01-01',
          'periodEnd': '2022-12-31',
          'fullStatementCollected': false,
          'cashScopeProof': {
            'notesSource': uris['notes'].toString(),
            'notesSha256': (_p['sources'] as List).singleWhere(
              (s) => s['label'] == 'notes',
            )['sha256'],
            'directDefinition':
                '현금흐름표상의 현금및현금성자산은 재무상태표상의 현금및예치금에서 주석6의 예치금을 차감한 금액입니다.',
            'currentDepositNetFromPrintedComponents': '449165262',
            'priorDepositNetFromPrintedComponents': '571502033',
            'currentCFCashPrinted': '867128698',
            'priorCFCashPrinted': '211853659',
            'reconciliationUnit': '천원',
            'numericCellCorrection': false,
          },
        },
      });
    }
    BigInt amt(int row, int column) => money(rows[row][column]);
    for (final index in [3, 44, 86, 114]) {
      if (rows[index].join('|') != '대신증권주식회사|(단위 : 천원)') {
        throw const FormatException(
          'Daishin each primary printed unit/issuer conflict',
        );
      }
    }
    if (rows[1].single != '제62(당)기 2022년 12월 31일 현재' ||
        [42, 84, 112].any(
          (i) => rows[i].single != '제62(당)기 2022년 1월 1일부터 2022년 12월 31일까지',
        ) ||
        rows[4][1] != '제62(당)기말' ||
        rows[45][1] != '제62(당)기' ||
        rows[115][1] != '제62(당)기' ||
        rows[99].first != '2022.1.1(당기초)' ||
        rows[109].first != '2022.12.31(당기말)' ||
        rows[101].first != '당기순이익' ||
        rows[87].last != '총 계') {
      throw const FormatException(
        'Daishin current annual period/column conflict',
      );
    }
    final notes = <List<String>>[
      for (final tr in RegExp(
        r'<tr\b[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(raw['notes']!))
        [
          for (final c in RegExp(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr.group(1)!))
            text(c.group(1)!),
        ],
    ];
    const definition =
        '현금흐름표상의 현금및현금성자산은 재무상태표상의 현금및예치금에서 주석6의 예치금을 차감한 금액입니다.';
    if (!text(raw['notes']!).contains(definition) ||
        notes[479].join('|') != '구분|예치기관|당기말|전기말' ||
        notes[1818].join('|') != '구분|당기말|전기말') {
      throw const FormatException('Daishin note 6/36 direct scope missing');
    }
    BigInt noteAmt(int row, int column) => money(notes[row][column]);
    BigInt noteSum(List<int> indexes, int column) => indexes
        .map((i) => noteAmt(i, column))
        .fold(BigInt.zero, (a, b) => a + b);
    final deposits = noteSum([481, 482, 483, 484, 485, 486, 487], 2);
    final priorDeposits = noteSum([481, 483, 484, 485, 486, 487], 3);
    if (notes[482][3] != '-' ||
        notes[1822][2] != '-' ||
        deposits != BigInt.from(449165262) ||
        priorDeposits != BigInt.from(571502033) ||
        noteAmt(480, 2) + deposits != noteAmt(488, 2) ||
        noteAmt(480, 3) + priorDeposits != noteAmt(488, 3) ||
        amt(6, 2) - deposits != amt(175, 2) ||
        amt(6, 4) - priorDeposits != amt(174, 2) ||
        noteSum([1819, 1820, 1821, 1822, 1823, 1824], 1) != noteAmt(1825, 1) ||
        noteSum([1819, 1820, 1821, 1823, 1824], 2) != noteAmt(1825, 2) ||
        noteAmt(1825, 1) != amt(175, 2) ||
        noteAmt(1825, 2) != amt(174, 2) ||
        amt(17, 2) != amt(31, 2) + amt(38, 2) ||
        amt(101, 6) != amt(71, 2) ||
        amt(109, 6) != amt(38, 2) ||
        amt(99, 6) != amt(38, 4) ||
        amt(99, 6) +
                [
                  101,
                  102,
                  103,
                  104,
                  106,
                  107,
                  108,
                ].map((i) => amt(i, 6)).fold(BigInt.zero, (a, b) => a + b) !=
            amt(109, 6) ||
        [
              116,
              151,
              163,
              172,
            ].map((i) => amt(i, 2)).fold(BigInt.zero, (a, b) => a + b) !=
            amt(173, 2) ||
        amt(174, 2) + amt(173, 2) != amt(175, 2)) {
      throw const FormatException(
        'Daishin independent BS CE CF note-scope conflict',
      );
    }
    for (final row in result) {
      final provenance = row['html_provenance'] as Map<String, dynamic>;
      final proof = provenance['cashScopeProof'] as Map<String, dynamic>;
      proof['depositComponents'] = [
        for (final index in [481, 482, 483, 484, 485, 486, 487])
          {
            'htmlTrIndex': index,
            'printedLabel': notes[index][0],
            'currentPrinted': notes[index][2],
            'priorPrinted': notes[index][3],
          },
      ];
      proof['cashComponents'] = [
        for (final index in [1819, 1820, 1821, 1822, 1823, 1824])
          {
            'htmlTrIndex': index,
            'printedLabel': notes[index][0],
            'currentPrinted': notes[index][1],
            'priorPrinted': notes[index][2],
          },
      ];
      proof['wholeCECurrentNI'] = {
        'htmlTrIndex': 101,
        'column': 6,
        'printedAmount': rows[101][6],
      };
      proof['wholeCEClosingEquity'] = {
        'htmlTrIndex': 109,
        'column': 6,
        'printedAmount': rows[109][6],
      };
      proof['wholeCEOpeningEquity'] = {
        'htmlTrIndex': 99,
        'column': 6,
        'printedAmount': rows[99][6],
      };
      proof['allIndependentChecksDifference'] = '0';
      proof['dashToZeroConversion'] = false;
    }
    return result;
  }
}
