import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable OFS source. Seven direct core rows; no inferred PPE total.
abstract final class CurachemRestatedCurrentSevenSource {
  static const receipt = '20240306000708';
  static const corp = '01205514';
  static const rule = 'curachem-own-restated-current-seven-v1';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240306000708&dcmNo=9690467&eleId=1&offset=956&length=4044&dtd=dart4.xsd';
  static const bodyUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240306000708&dcmNo=9690467&eleId=21&offset=183589&length=61938&dtd=dart4.xsd';
  static const coverSha =
      'b0d82ed890954f97d9b95cd7f1086994741f5769a08a1585fd7e281edafd7a4d';
  static const bodySha =
      '65e7498523d663f364a989637fd90ea092f72c727580d89d15bda93c129673be';
  static String compact(String v) =>
      v.replaceAll(RegExp(r'<[^>]*>|&nbsp;|\s'), '');
  static List<Map<String, dynamic>> parse({
    required String targetReceipt,
    required String companyCode,
    required String companyName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String cover,
    required String body,
  }) {
    void guard(bool valid, String reason) {
      if (!valid) throw FormatException('Curachem own current seven: $reason');
    }

    guard(
      targetReceipt == receipt &&
          companyCode == corp &&
          !consolidated &&
          start == DateTime.utc(2023) &&
          end == DateTime.utc(2023, 12, 31),
      'identity/basis/period',
    );
    guard(
      coverSource.toString() == coverUri &&
          statementSource.toString() == bodyUri &&
          sha256.convert(utf8.encode(cover)).toString() == coverSha &&
          sha256.convert(utf8.encode(body)).toString() == bodySha,
      'original coordinates/digests',
    );
    final text = compact(body), coverText = compact(cover);
    guard(
      coverText.contains('주식회사큐라켐') &&
          coverText.contains('2023년01월01일') &&
          coverText.contains('2023년12월31일'),
      'own issuer/current cover',
    );
    guard(
      RegExp(r'\(단위:원\)').allMatches(text).length == 4 &&
          RegExp('2023년01월01일부터2023년12월31일까지').allMatches(text).length == 3 &&
          text.contains('2023년12월31일현재'),
      'independently printed statement dates/units',
    );
    final tables =
        RegExp(
              r'<TABLE\b[^>]*>(.*?)</TABLE>',
              caseSensitive: false,
              dotAll: true,
            )
            .allMatches(body)
            .map(
              (t) =>
                  RegExp(
                        r'<TR\b[^>]*>(.*?)</TR>',
                        caseSensitive: false,
                        dotAll: true,
                      )
                      .allMatches(t[1]!)
                      .map(
                        (r) => RegExp(
                          r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
                          caseSensitive: false,
                          dotAll: true,
                        ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
                      )
                      .toList(),
            )
            .toList();
    guard(
      tables.length == 4 &&
          tables[0].length == 60 &&
          tables[1].length == 38 &&
          tables[2].length == 15 &&
          tables[3].length == 49,
      'original physical grid',
    );
    for (final table in [0, 1, 3]) {
      guard(
        tables[table][0].join('|') == '|2021연도(제13기)|2022연도(제14기)|2023연도(제15기)',
        'ascending current year column',
      );
    }
    BigInt money(int t, int r, int c) {
      final v = tables[t][r][c];
      guard(
        RegExp(
          r'^(?:-?(?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)|\((?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)\))$',
        ).hasMatch(v),
        'printed grouped monetary cell',
      );
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final cells = [
      (0, 34, '자산총계', 'BS'),
      (0, 47, '부채총계', 'BS'),
      (0, 58, '자본총계', 'BS'),
      (1, 1, 'Ⅰ.매출액', 'IS'),
      (1, 22, 'Ⅴ.영업이익', 'IS'),
      (1, 37, 'Ⅹ.당기순이익', 'IS'),
      (3, 1, 'Ⅰ.영업활동으로인한현금흐름', 'CF'),
    ];
    final values = <BigInt>[];
    for (final c in cells) {
      guard(tables[c.$1][c.$2][0] == c.$3, 'direct current account label');
      values.add(money(c.$1, c.$2, 3));
    }
    guard(
      values[0] == values[1] + values[2] && money(0, 59, 3) == values[0],
      'BS whole totals',
    );
    guard(
      tables[2][0].join('|') == '|자본금|자본잉여금|이익잉여금|총계' &&
          tables[2][11][0] == '2023년01월01일(기초자본)' &&
          tables[2][14][0] == '2023년12월31일(기말자본)',
      'own CE actual current dates/header',
    );
    guard(
      money(2, 14, 4) == values[2] &&
          money(2, 13, 4) == values[5] &&
          money(2, 11, 4) + money(2, 13, 4) == values[2],
      'current CE whole/NI/roll',
    );
    guard(
      tables[2][12][0] == '우선주의보통주전환' &&
          tables[2][12][4] == '-' &&
          money(2, 12, 1) + money(2, 12, 2) == BigInt.zero,
      'printed conversion components net zero; whole remains dash',
    );
    guard(
      tables[2][4][0] == '2022년01월01일(기초자본)' &&
          tables[2][5][0] == '회계변경효과' &&
          tables[2][6][0] == '2022.01.01(전기초)-수정후금액' &&
          tables[2][8][0] == '회계변경효과' &&
          tables[2][9][0] == '당기순이익-수정후금액' &&
          tables[2][10][0] == '2022년12월31일(기말자본)',
      'own explicitly printed comparative restatement chain',
    );
    guard(
      money(2, 4, 4) + money(2, 5, 4) == money(2, 6, 4) &&
          money(2, 7, 4) + money(2, 8, 4) == money(2, 9, 4) &&
          money(2, 6, 4) + money(2, 9, 4) == money(2, 10, 4) &&
          money(2, 10, 4) == money(2, 11, 4) &&
          money(0, 58, 2) == money(2, 4, 4) + money(2, 7, 4) &&
          money(0, 58, 2) + money(2, 5, 4) + money(2, 8, 4) == money(2, 11, 4),
      'prior BS equity plus actual printed accounting-change rows equals current CE opening',
    );
    guard(
      values[6] + money(3, 26, 3) + money(3, 38, 3) == money(3, 46, 3) &&
          money(3, 47, 3) + money(3, 46, 3) == money(3, 48, 3) &&
          money(0, 4, 3) == money(3, 48, 3) &&
          money(0, 4, 2) == money(3, 47, 3),
      'current CF activity/cash/BS scopes',
    );
    guard(values[5] == money(3, 2, 3), 'current whole NI CF');
    return [
      for (var i = 0; i < cells.length; i++)
        {
          'rcept_no': receipt,
          'corp_code': corp,
          'bsns_year': '2023',
          'reprt_code': '11011',
          'fs_div': 'OFS',
          'sj_div': cells[i].$4,
          'account_id': null,
          'account_nm': cells[i].$3,
          'account_detail': '-',
          'thstrm_nm': cells[i].$4 == 'BS'
              ? '2023-12-31'
              : '2023-01-01~2023-12-31',
          'thstrm_amount': values[i].toString(),
          'currency': 'KRW',
          'ord': '${i + 1}',
          'html_provenance': {
            'source': bodyUri,
            'sourceSha256': bodySha,
            'basis': 'OFS',
            'periodStart': '2023-01-01',
            'periodEnd': '2023-12-31',
            'printedLabel': cells[i].$3,
            'printedUnit': '원',
            'multiplier': '1',
            'tableIndex': cells[i].$1,
            'rowIndex': cells[i].$2,
            'column': 3,
            'currentCell': tables[cells[i].$1][cells[i].$2][3],
            'currentHeader': tables[cells[i].$1][0][3],
            'partialCore7': true,
            'detailHierarchyComplete': false,
            'notesVerified': false,
            'notesReadScopeComplete': false,
            'ownPrintedRestatement': {
              'tableIndex': 2,
              'wholeColumn': 4,
              'accountingChangeRows': [5, 8],
              'rawCells': [tables[2][5][4], tables[2][8][4]],
              'comparativeFieldsImported': false,
              'comparativeBalanceResidualWon':
                  (money(0, 34, 2) - money(0, 47, 2) - money(0, 58, 2))
                      .toString(),
            },
            'detailDeficitMagnitudeNotImported': true,
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'uncollectedOptionalAccounts': ['capex'],
            'optionalAccountsNotCollected': ['capex'],
            'missingAccountReasons': {
              'capex': 'No printed whole PPE acquisition total; research-equipment component is not the total.',
            },
            'supportingPeriodEvidence': {
              'policy': rule,
              'source': bodyUri,
              'sourceSha256': bodySha,
              'wholeNetIncomeVerified': true,
              'fullStatementCollected': false,
              'openingEquity': money(2, 11, 4).toString(),
              'closingEquity': values[2].toString(),
              'currentProfit': values[5].toString(),
              'openingCash': money(3, 47, 3).toString(),
              'closingCash': money(3, 48, 3).toString(),
              'cashIncrease': money(3, 46, 3).toString(),
              'allStatementRowsVerified': false,
            },
          },
        },
    ];
  }
}
