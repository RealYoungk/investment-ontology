import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One exact connected statement; direct whole-company current cells only.
/// All dates are printed; the raw source and selected current cells remain intact.
abstract final class DbFy22WholeCurrentSource {
  static const rule = 'db-fy22-exact-self-declared-issuer-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(dbFy22WholeCurrentProfileJson) as List)
          .cast<Map<String, dynamic>>();
  static bool matches(String receipt, bool consolidated) => profiles.any(
    (p) =>
        p['receipt'] == receipt && p['basis'] == (consolidated ? 'cfs' : 'ofs'),
  );
  static String compact(String value) => value
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), '');

  static List<Map<String, dynamic>> parse({
    required String receipt,
    required String corpCode,
    required String companyName,
    required String cover,
    required String body,
    required Uri coverSource,
    required Uri statementSource,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    final choices = profiles
        .where(
          (p) =>
              p['receipt'] == receipt &&
              p['basis'] == (consolidated ? 'cfs' : 'ofs'),
        )
        .toList();
    void guard(bool valid, String reason) {
      if (!valid) throw FormatException('Exact printed annual: $reason');
    }

    guard(choices.length == 1, 'unknown receipt/basis');
    final p = choices.single, year = p['year'] as int;
    guard(
      corpCode == p['corp'] && companyName == p['name'],
      'company mismatch',
    );
    guard(
      start == DateTime.utc(year) && end == DateTime.utc(year, 12, 31),
      'period mismatch',
    );
    guard(
      coverSource.toString() == p['coverUri'] &&
          statementSource.toString() == p['bodyUri'],
      'official coordinates mismatch',
    );
    guard(
      sha256.convert(utf8.encode(cover)).toString() == p['coverSha'] &&
          sha256.convert(utf8.encode(body)).toString() == p['bodySha'],
      'immutable raw digest mismatch',
    );
    final tables = RegExp(
      r'<table\b[^>]*>([\s\S]*?)</table>',
      caseSensitive: false,
    ).allMatches(body).toList();
    guard(
      (p['printedUnitTableIndices'] as List).length == 4 &&
          (p['printedUnitTableIndices'] as List).every(
            (i) =>
                compact(tables[i as int].group(1)!)
                    .contains('(단위:${p['unit']})'),
          ),
      'each primary/CE printed unit missing',
    );
    List<List<String>> rows(int table) =>
        RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
            .allMatches(tables[table].group(1)!)
            .map(
              (tr) =>
                  RegExp(
                        r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                        caseSensitive: false,
                      )
                      .allMatches(tr.group(1)!)
                      .map((cell) => compact(cell.group(1)!))
                      .toList(),
            )
            .toList();
    List<String> checked(Map cell) {
      final row = rows(cell['table'] as int)[cell['row'] as int];
      guard(
        jsonEncode(row) == jsonEncode(cell['expected']),
        'current cell/group changed',
      );
      return row;
    }

    BigInt money(String value) {
      guard(
        RegExp(r'^(?:-?[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
            .hasMatch(value),
        'printed monetary cell invalid',
      );
      return BigInt.parse(
        value.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    BigInt current(Map cell) {
      final row = checked(cell);
      final result = money(row[cell['column'] as int]);
      guard(
        result.toString() == cell['amount'],
        'current amount/sign mismatch',
      );
      return result;
    }

    final core = (p['core'] as List).cast<Map>(),
        cash = (p['cash'] as List).cast<Map>();
    final values = core.map(current).toList(), cf = cash.map(current).toList();
    final ce = rows(p['ceTable'] as int),
        opening = ce[p['ceOpening'] as int],
        closing = ce[p['ceClosing'] as int],
        ni = ce[p['ceNi'] as int];
    guard(
      jsonEncode(opening) == jsonEncode(p['ceOpeningRow']) &&
          jsonEncode(closing) == jsonEncode(p['ceClosingRow']) &&
          jsonEncode(ni) == jsonEncode(p['ceNiRow']),
      'independent CE current dates/whole-column mismatch',
    );
    guard(
      RegExp('^(?:[IVX]+[.])?$year(?:[.]0?1[.]0?1|년0?1월0?1일)')
              .hasMatch(opening.first) &&
          RegExp('^(?:[IVX]+[.])?$year(?:[.]12[.]31|년12월31일)')
              .hasMatch(closing.first) &&
          (p['ceOpening'] as int) < (p['ceNi'] as int) &&
          (p['ceNi'] as int) < (p['ceClosing'] as int),
      'CE annual interval mismatch',
    );
    guard(
      values[0] == values[1] + values[2] &&
          values[2] == money(closing.last) &&
          values[5] == money(ni.last),
      'BS/CIS/CE whole contradiction',
    );
    final fxInNet = p['fxInNet'] as bool;
    // Missing printed FX is not a zero-valued fact. Exact OFS profiles check
    // only the directly printed activity sum/change and opening/closing cash.
    final fxObserved = p['fxObserved'] != false;
    guard(cash.length == (fxObserved ? 6 : 5), 'cash evidence count');
    guard(!fxInNet || fxObserved, 'FX-in-change proof missing');
    final exchange = fxObserved ? cf[2] : null;
    final change = cf[fxObserved ? 3 : 2];
    final cashOpening = cf[fxObserved ? 4 : 3];
    final cashClosing = cf[fxObserved ? 5 : 4];
    var activities = values[6] + cf[0] + cf[1];
    if (fxInNet && exchange != null) activities += exchange;
    var rolledCash = cashOpening + change;
    if (!fxInNet && exchange != null) rolledCash += exchange;
    guard(
      activities == change && rolledCash == cashClosing,
      'CF activity/FX/cash contradiction',
    );
    final bsCash = p['bsCash'] as Map,
        bs = checked(bsCash),
        column = bsCash['column'] as int;
    guard(
      money(bs[column]) == cashClosing &&
          money(bs.skip(column + 1).firstWhere((x) => x.isNotEmpty)) ==
              cashOpening,
      'BS current/prior cash contradiction',
    );
    final equityRow = checked(core[2]);
    guard(
      money(
            equityRow
                .skip((core[2]['column'] as int) + 1)
                .firstWhere((x) => x.isNotEmpty),
          ) ==
          money(opening.last),
      'BS prior/CE opening equity contradiction',
    );
    guard(
      (p['printedRangeTableIndices'] as List).length == 3 &&
          (p['printedRangeTableIndices'] as List).every(
            (i) =>
                RegExp('$year년0?1월0?1일부터$year년12월31일까지')
                    .hasMatch(compact(tables[i as int].group(1)!)),
          ),
      'CIS/CE/CF independently printed annual ranges missing',
    );
    final extras = p['independentExtraCells'] as Map;
    BigInt extra(String name) => current(extras[name] as Map);
    guard(
      extra('CEpriorClosingEquity') == money(opening.last) &&
          values[5] ==
              extra('CEcurrentOwnersNetIncomeNotUsed') +
                  extra('CEcurrentNCINetIncomeNotUsed') &&
          money(closing.last) ==
              closing
                  .skip(1)
                  .take(6)
                  .map(money)
                  .fold(BigInt.zero, (a, b) => a + b) &&
          extra('CFpriorOperating') +
                  extra('CFpriorInvesting') +
                  extra('CFpriorFinancing') ==
              extra('CFpriorPrintedChangeBeforeFX') &&
          extra('CFpriorOpeningCash') +
                  extra('CFpriorPrintedChangeBeforeFX') +
                  extra('CFpriorExchange') ==
              extra('CFpriorClosingCash') &&
          extra('CFpriorClosingCash') == cashOpening &&
          extra('CISpriorWholeNetIncome') == extra('CEpriorWholeNetIncome'),
      'independent prior/current whole-company checks contradict',
    );
    final basis = consolidated ? 'CFS' : 'OFS',
        from = '$year-01-01',
        to = '$year-12-31';
    final evidence = {
      'policy': rule,
      'flowCaptionPrintedStart': true,
      'periodStart': from,
      'periodEnd': to,
      'source': statementSource.toString(),
      'basis': basis,
      'openingEquity': money(opening.last).toString(),
      'closingEquity': values[2].toString(),
      'currentProfit': values[5].toString(),
      'openingCash': cashOpening.toString(),
      'closingCash': cashClosing.toString(),
      'cashIncrease': change.toString(),
      'exchangeCash': exchange?.toString(),
      'exchangeCashPrinted': fxObserved,
      'exchangeCashMissingNotAssumedZero': !fxObserved,
      'sourceSha256': p['bodySha'],
      'collectedAccounts': [
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
        'capex',
      ],
      'optionalAccountsNotCollected': <String>[],
      'fullStatementCollected': false,
      'printedUnit': p['unit'],
      'printedUnitMultiplier': p['multiplier'],
      'crossCheckAmountsUnit': 'printed-original-unit',
    };
    return [
      for (var i = 0; i < core.length; i++)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '$year',
          'reprt_code': '11011',
          'fs_div': basis,
          'sj_div': core[i]['kind'],
          'account_id': null,
          'account_nm': core[i]['printedLabel'],
          'account_detail': '-',
          'thstrm_nm': core[i]['kind'] == 'BS' ? to : '$from~$to',
          'thstrm_amount': (values[i] * BigInt.parse(p['multiplier'] as String))
              .toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource.toString(),
            'basis': basis,
            'periodStart': from,
            'periodEnd': to,
            'printedLabel': core[i]['printedLabel'],
            'printedUnit': p['unit'],
            'multiplier': p['multiplier'],
            'tableIndex': core[i]['table'],
            'rowIndex': core[i]['row'],
            'column': core[i]['column'],
            'currentCell': checked(core[i])[core[i]['column'] as int],
            'supportingPeriodEvidence': evidence,
          },
        },
    ];
  }
}

const dbFy22WholeCurrentProfileJson = r'''[
  {
    "receipt": "20230321001219",
    "basis": "cfs",
    "corp": "00115694",
    "name": "DB증권(주)",
    "year": 2022,
    "coverUri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=1&offset=784&length=3924&dtd=dart3.xsd",
    "bodyUri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=17&offset=427435&length=91713&dtd=dart3.xsd",
    "coverSha": "3cc86ccee7cd434468865a4f32e1e0f1aa57472bf8d1fc53ed796d130050fe8d",
    "bodySha": "65e8236b7a4e26fa2e249382c1b7def1c5c857359403d73991758e711c49d9ba",
    "unit": "원",
    "multiplier": "1",
    "core": [
      {
        "table": 3,
        "row": 16,
        "column": 3,
        "expected": [
          "자산총계",
          "",
          "",
          "9,757,370,294,448",
          "",
          "9,583,673,039,437"
        ],
        "amount": "9757370294448",
        "kind": "BS",
        "printedLabel": "자     산     총     계"
      },
      {
        "table": 3,
        "row": 27,
        "column": 3,
        "expected": [
          "부채총계",
          "",
          "",
          "8,710,072,105,027",
          "",
          "8,535,236,408,583"
        ],
        "amount": "8710072105027",
        "kind": "BS",
        "printedLabel": "부     채     총     계"
      },
      {
        "table": 3,
        "row": 38,
        "column": 3,
        "expected": [
          "자본총계",
          "",
          "",
          "1,047,298,189,421",
          "",
          "1,048,436,630,854"
        ],
        "amount": "1047298189421",
        "kind": "BS",
        "printedLabel": "자     본     총     계"
      },
      {
        "table": 6,
        "row": 1,
        "column": 3,
        "expected": [
          "영업수익",
          "",
          "",
          "1,223,166,577,309",
          "",
          "1,410,732,861,048"
        ],
        "amount": "1223166577309",
        "kind": "CIS",
        "printedLabel": "영업수익"
      },
      {
        "table": 6,
        "row": 16,
        "column": 3,
        "expected": [
          "영업이익",
          "",
          "",
          "23,824,123,353",
          "",
          "169,597,211,231"
        ],
        "amount": "23824123353",
        "kind": "CIS",
        "printedLabel": "영업이익"
      },
      {
        "table": 6,
        "row": 21,
        "column": 3,
        "expected": [
          "당기순이익",
          "",
          "",
          "10,770,184,612",
          "",
          "126,818,163,372"
        ],
        "amount": "10770184612",
        "kind": "CIS",
        "printedLabel": "당기순이익"
      },
      {
        "table": 13,
        "row": 1,
        "column": 2,
        "expected": [
          "Ⅰ.영업활동으로인한현금흐름",
          "",
          "(116,571,056,767)",
          "",
          "(197,242,734,468)"
        ],
        "amount": "-116571056767",
        "kind": "CF",
        "printedLabel": "Ⅰ.영업활동으로 인한 현금흐름"
      },
      {
        "table": 13,
        "row": 56,
        "column": 1,
        "expected": [
          "유형자산의취득",
          "(3,687,283,186)",
          "",
          "(6,841,895,429)",
          ""
        ],
        "amount": "-3687283186",
        "kind": "CF",
        "printedLabel": "유형자산의 취득"
      }
    ],
    "cash": [
      {
        "table": 13,
        "row": 54,
        "column": 2,
        "expected": [
          "Ⅱ.투자활동으로인한현금흐름",
          "",
          "(13,857,171,635)",
          "",
          "(22,749,548,313)"
        ],
        "amount": "-13857171635"
      },
      {
        "table": 13,
        "row": 65,
        "column": 2,
        "expected": [
          "Ⅲ.재무활동으로인한현금흐름(주석39)",
          "",
          "212,263,274,144",
          "",
          "370,671,137,231"
        ],
        "amount": "212263274144"
      },
      {
        "table": 13,
        "row": 80,
        "column": 2,
        "expected": [
          "Ⅵ.외화표시현금및현금성자산의환율변동효과",
          "",
          "(612,244,428)",
          "",
          "978,637,002"
        ],
        "amount": "-612244428"
      },
      {
        "table": 13,
        "row": 78,
        "column": 2,
        "expected": [
          "Ⅳ.현금및현금성자산의증가(감소)(=Ⅰ+Ⅱ+Ⅲ)",
          "",
          "81,835,045,742",
          "",
          "150,678,854,450"
        ],
        "amount": "81835045742"
      },
      {
        "table": 13,
        "row": 79,
        "column": 2,
        "expected": [
          "Ⅴ.기초현금및현금성자산",
          "",
          "544,685,756,338",
          "",
          "393,028,264,886"
        ],
        "amount": "544685756338"
      },
      {
        "table": 13,
        "row": 81,
        "column": 2,
        "expected": [
          "Ⅶ.당기말현금및현금성자산(주석39)",
          "",
          "625,908,557,652",
          "",
          "544,685,756,338"
        ],
        "amount": "625908557652"
      }
    ],
    "bsCash": {
      "table": 3,
      "row": 2,
      "column": 2,
      "expected": [
        "현금및현금성자산",
        "4,6,39",
        "625,908,557,652",
        "",
        "544,685,756,338",
        ""
      ],
      "amount": "625908557652"
    },
    "ceTable": 9,
    "ceOpening": 13,
    "ceClosing": 25,
    "ceNi": 15,
    "ceOpeningRow": [
      "2022.1.1(당기초)",
      "212,231,945,000",
      "118,924,276,364",
      "(7,547,101,300)",
      "96,660,496,742",
      "496,685,859,517",
      "131,481,154,531",
      "1,048,436,630,854"
    ],
    "ceClosingRow": [
      "2022.12.31(당기말)",
      "212,231,945,000",
      "118,030,876,364",
      "(11,842,082,310)",
      "111,085,683,491",
      "475,894,029,085",
      "141,897,737,791",
      "1,047,298,189,421"
    ],
    "ceNiRow": [
      "당기순이익",
      "-",
      "-",
      "-",
      "-",
      "(77,385,932)",
      "10,847,570,544",
      "10,770,184,612"
    ],
    "fxInNet": false,
    "fxObserved": true,
    "printedUnitTableIndices": [
      2,
      5,
      8,
      12
    ],
    "printedRangeTableIndices": [
      5,
      8,
      11
    ],
    "independentExtraCells": {
      "CEpriorClosingEquity": {
        "table": 9,
        "row": 12,
        "column": 7,
        "amount": "1048436630854",
        "expected": [
          "2021.12.31(전기말)",
          "212,231,945,000",
          "118,924,276,364",
          "(7,547,101,300)",
          "96,660,496,742",
          "496,685,859,517",
          "131,481,154,531",
          "1,048,436,630,854"
        ]
      },
      "CEcurrentOwnersNetIncomeNotUsed": {
        "table": 9,
        "row": 15,
        "column": 5,
        "amount": "-77385932",
        "expected": [
          "당기순이익",
          "-",
          "-",
          "-",
          "-",
          "(77,385,932)",
          "10,847,570,544",
          "10,770,184,612"
        ]
      },
      "CEcurrentNCINetIncomeNotUsed": {
        "table": 9,
        "row": 15,
        "column": 6,
        "amount": "10847570544",
        "expected": [
          "당기순이익",
          "-",
          "-",
          "-",
          "-",
          "(77,385,932)",
          "10,847,570,544",
          "10,770,184,612"
        ]
      },
      "CFpriorOperating": {
        "table": 13,
        "row": 1,
        "column": 4,
        "amount": "-197242734468",
        "expected": [
          "Ⅰ.영업활동으로인한현금흐름",
          "",
          "(116,571,056,767)",
          "",
          "(197,242,734,468)"
        ]
      },
      "CFpriorInvesting": {
        "table": 13,
        "row": 54,
        "column": 4,
        "amount": "-22749548313",
        "expected": [
          "Ⅱ.투자활동으로인한현금흐름",
          "",
          "(13,857,171,635)",
          "",
          "(22,749,548,313)"
        ]
      },
      "CFpriorFinancing": {
        "table": 13,
        "row": 65,
        "column": 4,
        "amount": "370671137231",
        "expected": [
          "Ⅲ.재무활동으로인한현금흐름(주석39)",
          "",
          "212,263,274,144",
          "",
          "370,671,137,231"
        ]
      },
      "CFpriorPrintedChangeBeforeFX": {
        "table": 13,
        "row": 78,
        "column": 4,
        "amount": "150678854450",
        "expected": [
          "Ⅳ.현금및현금성자산의증가(감소)(=Ⅰ+Ⅱ+Ⅲ)",
          "",
          "81,835,045,742",
          "",
          "150,678,854,450"
        ]
      },
      "CFpriorExchange": {
        "table": 13,
        "row": 80,
        "column": 4,
        "amount": "978637002",
        "expected": [
          "Ⅵ.외화표시현금및현금성자산의환율변동효과",
          "",
          "(612,244,428)",
          "",
          "978,637,002"
        ]
      },
      "CFpriorOpeningCash": {
        "table": 13,
        "row": 79,
        "column": 4,
        "amount": "393028264886",
        "expected": [
          "Ⅴ.기초현금및현금성자산",
          "",
          "544,685,756,338",
          "",
          "393,028,264,886"
        ]
      },
      "CFpriorClosingCash": {
        "table": 13,
        "row": 81,
        "column": 4,
        "amount": "544685756338",
        "expected": [
          "Ⅶ.당기말현금및현금성자산(주석39)",
          "",
          "625,908,557,652",
          "",
          "544,685,756,338"
        ]
      },
      "CISpriorWholeNetIncome": {
        "table": 6,
        "row": 21,
        "column": 5,
        "amount": "126818163372",
        "expected": [
          "당기순이익",
          "",
          "",
          "10,770,184,612",
          "",
          "126,818,163,372"
        ]
      },
      "CEpriorWholeNetIncome": {
        "table": 9,
        "row": 3,
        "column": 7,
        "amount": "126818163372",
        "expected": [
          "당기순이익",
          "-",
          "-",
          "-",
          "-",
          "117,284,248,406",
          "9,533,914,966",
          "126,818,163,372"
        ]
      }
    }
  }
]''';
