import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable OFS source. Seven direct core rows; no inferred PPE total.
abstract final class KonasolCurrentSevenSource {
  static const receipt = '20250331003105';
  static const corp = '00666329';
  static const rule = 'konasol-own-current-seven-v1';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250331003105&dcmNo=10487194&eleId=1&offset=965&length=4507&dtd=dart4.xsd';
  static const bodyUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250331003105&dcmNo=10487194&eleId=21&offset=211750&length=121606&dtd=dart4.xsd';
  static const coverSha =
      'b8b51e70c7aed7c30c244bad71365fa4fe1ba9717fea10f37058c720165c9bc8';
  static const bodySha =
      'ac34ecf1b77b07d918e6720ab1b5d06fb6da3b4fcb92e94047628e72fed0074f';
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
      if (!valid) throw FormatException('Konasol own current seven: $reason');
    }

    guard(
      targetReceipt == receipt &&
          companyCode == corp &&
          !consolidated &&
          start == DateTime.utc(2024) &&
          end == DateTime.utc(2024, 12, 31),
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
      coverText.contains('주식회사코나솔') &&
          coverText.contains('2024년01월01일') &&
          coverText.contains('2024년12월31일'),
      'own issuer/current cover',
    );
    guard(
      RegExp(r'\(단위:원\)').allMatches(text).length == 4,
      'printed primary/CE units',
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
      tables.length == 8 &&
          tables[1].length == 109 &&
          tables[3].length == 73 &&
          tables[5].length == 12 &&
          tables[7].length == 93,
      'original physical grid',
    );
    for (final table in [1, 3]) {
      guard(
        tables[table][0].join('|') == '과목|제28기|제27기|제26기' &&
            tables[table][1].join('|') == '(2024년)|(2023년)|(2022년)',
        'printed current annual column',
      );
    }
    guard(
      tables[7][0].join('|') == '과목|2024년|2023년|2022년',
      'printed current CF year',
    );
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
      (1, 70, '자산총계', 'BS'),
      (1, 92, '부채총계', 'BS'),
      (1, 107, '자본총계', 'BS'),
      (3, 2, 'Ⅰ.매출액', 'IS'),
      (3, 46, 'Ⅴ.영업이익', 'IS'),
      (3, 72, 'Ⅹ.당기순이익', 'IS'),
      (7, 2, 'Ⅰ.영업활동으로인한현금흐름', 'CF'),
    ];
    final values = <BigInt>[];
    for (final c in cells) {
      guard(tables[c.$1][c.$2][0] == c.$3, 'direct current account label');
      values.add(money(c.$1, c.$2, 1));
    }
    guard(
      values[0] == values[1] + values[2] && money(1, 108, 1) == values[0],
      'BS whole totals',
    );
    guard(
      tables[5][0].join('|') == '과목|자본금|자본|자본|기타포괄|이익|총계' &&
          tables[5][1].join('|') == '잉여금|조정|손익누계액|잉여금' &&
          tables[5][8][0] == '2024년01월01일(보고금액)' &&
          tables[5][11][0] == '2024년12월31일(당기말)',
      'own CE annual dates and component headers',
    );
    guard(
      money(5, 11, 6) == values[2] &&
          money(5, 10, 6) == values[5] &&
          money(5, 8, 6) + money(5, 9, 6) + money(5, 10, 6) == values[2] &&
          money(1, 107, 2) == money(5, 8, 6),
      'whole CE/NI/current roll',
    );
    guard(
      values[6] + money(7, 43, 1) + money(7, 77, 1) == money(7, 90, 1) &&
          money(7, 91, 1) + money(7, 90, 1) == money(7, 92, 1) &&
          money(1, 5, 1) == money(7, 92, 1),
      'current CF activity/cash/BS',
    );
    guard(
      tables[1][6][0] == '정부보조금' &&
          money(1, 5, 2) + money(1, 6, 2) == money(7, 91, 1),
      'own printed prior cash government grant scope',
    );
    guard(values[5] == money(7, 3, 1), 'whole NI CF');
    return [
      for (var i = 0; i < cells.length; i++)
        {
          'rcept_no': receipt,
          'corp_code': corp,
          'bsns_year': '2024',
          'reprt_code': '11011',
          'fs_div': 'OFS',
          'sj_div': cells[i].$4,
          'account_id': null,
          'account_nm': cells[i].$3,
          'account_detail': '-',
          'thstrm_nm': cells[i].$4 == 'BS'
              ? '2024-12-31'
              : '2024-01-01~2024-12-31',
          'thstrm_amount': values[i].toString(),
          'currency': 'KRW',
          'ord': '${i + 1}',
          'html_provenance': {
            'source': bodyUri,
            'sourceSha256': bodySha,
            'basis': 'OFS',
            'periodStart': '2024-01-01',
            'periodEnd': '2024-12-31',
            'printedLabel': cells[i].$3,
            'printedUnit': '원',
            'multiplier': '1',
            'tableIndex': cells[i].$1,
            'rowIndex': cells[i].$2,
            'column': 1,
            'currentCell': tables[cells[i].$1][cells[i].$2][1],
            'currentHeader': tables[cells[i].$1][0][1],
            'flowCaptionPrintedStart': false,
            'annualIntervalEvidence': 'Own annual cover 2024-01-01 through 2024-12-31 and own CE actual current opening/closing dates; each primary current-year column independently pinned.',
            'cashScope': {
              'ownPriorBSCashRow': 5,
              'ownPriorGovernmentGrantRow': 6,
              'priorColumn': 2,
              'governmentGrantLabel': tables[1][6][0],
              'governmentGrantRaw': tables[1][6][2],
            },
            'partialCore7': true,
            'detailHierarchyComplete': false,
            'notesVerified': false,
            'notesReadScopeComplete': false,
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'uncollectedOptionalAccounts': ['capex'],
            'optionalAccountsNotCollected': ['capex'],
            'missingAccountReasons': {
              'capex': 'No printed whole PPE acquisition total; printed acquisition components are not the total.',
            },
            'supportingPeriodEvidence': {
              'policy': rule,
              'source': bodyUri,
              'sourceSha256': bodySha,
              'wholeNetIncomeVerified': true,
              'fullStatementCollected': false,
              'openingEquity': money(5, 8, 6).toString(),
              'closingEquity': values[2].toString(),
              'currentProfit': values[5].toString(),
              'openingCash': money(7, 91, 1).toString(),
              'closingCash': money(7, 92, 1).toString(),
              'cashIncrease': money(7, 90, 1).toString(),
              'allStatementRowsVerified': false,
            },
          },
        },
    ];
  }
}
