import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'printed_current_annual_profiles.dart';

/// Four exact official statements. This is not a general current-header grammar.
/// All dates are printed; the raw source and selected current cells remain intact.
abstract final class PrintedCurrentAnnualSource {
  static const rule = 'exact-printed-current-annual-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(printedCurrentAnnualProfilesJson) as List)
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
    final text = compact(body);
    guard(
      RegExp(r'\(단위:원\)').allMatches(text).length == 4,
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
      opening.first == '$year.01.01(당기초)' &&
          closing.first == '$year.12.31(당기말)' &&
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
    guard(
      values[6] + cf[0] + cf[1] + (fxInNet ? cf[2] : BigInt.zero) == cf[3] &&
          cf[4] + cf[3] + (fxInNet ? BigInt.zero : cf[2]) == cf[5],
      'CF activity/FX/cash contradiction',
    );
    final bsCash = p['bsCash'] as Map,
        bs = checked(bsCash),
        column = bsCash['column'] as int;
    guard(
      money(bs[column]) == cf[5] &&
          money(bs.skip(column + 1).firstWhere((x) => x.isNotEmpty)) == cf[4],
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
    final printedFullRanges = RegExp('$year년0?1월0?1일부터$year년12월31일까지')
        .allMatches(text)
        .length;
    guard(
      printedFullRanges == 3,
      'CIS/CE/CF independently printed annual ranges missing',
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
      'openingCash': cf[4].toString(),
      'closingCash': cf[5].toString(),
      'cashIncrease': cf[3].toString(),
      'exchangeCash': cf[2].toString(),
      'sourceSha256': p['bodySha'],
      'collectedAccounts': [
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
      ],
      'optionalAccountsNotCollected': ['capex'],
      'fullStatementCollected': false,
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
          'account_nm': core[i]['label'],
          'account_detail': '-',
          'thstrm_nm': core[i]['kind'] == 'BS' ? to : '$from~$to',
          'thstrm_amount': values[i].toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource.toString(),
            'basis': basis,
            'periodStart': from,
            'periodEnd': to,
            'printedLabel': core[i]['label'],
            'printedUnit': '원',
            'multiplier': '1',
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
