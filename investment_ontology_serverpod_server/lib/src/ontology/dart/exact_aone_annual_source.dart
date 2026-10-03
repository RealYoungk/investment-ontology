import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'primary_historical_issuer.dart';
import 'exact_aone_annual_profiles.dart';

/// Four source-pinned OFS packages; no general issuer/header fallback.
abstract final class ExactAoneAnnualSource {
  static const rule = 'exact-aone-current-ofs-eight-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(exactAoneAnnualProfilesJson) as List)
          .cast<Map<String, dynamic>>();
  static String compact(String s) =>
      PrimaryHistoricalIssuer.text(s)
          .replaceAll('&#160;', '')
          .replaceAll('&amp;', '&');
  static List<Map<String, dynamic>> parse({
    required String receipt,
    required String corpCode,
    required String companyName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Map<String, String> raw,
    required Map<String, Uri> uris,
  }) {
    void guard(bool ok, String why) {
      if (!ok) throw FormatException('Exact Aone current OFS: $why');
    }

    final matches = profiles.where((p) => p['receipt'] == receipt).toList();
    guard(matches.length == 1 && !consolidated, 'unknown receipt/basis');
    final p = matches.single, year = p['bsnsYear'] as int;
    guard(
      corpCode == p['corpCode'] &&
          companyName == p['name'] &&
          start == DateTime.utc(year) &&
          end == DateTime.utc(year, 12, 31),
      'issuer/year mismatch',
    );
    for (final s in p['sources'] as List) {
      final label = s['label'] as String;
      guard(
        uris[label]?.toString() == s['url'] &&
            raw[label] != null &&
            sha256.convert(utf8.encode(raw[label]!)).toString() == s['sha256'],
        'own source URI/digest mismatch',
      );
    }
    final issuer =
        PrimaryHistoricalIssuer(
          shell: raw['shell']!,
          shellSource: uris['shell']!,
        ).verify(
          receipt: receipt,
          corp: corpCode,
          consolidated: false,
          coverSource: uris['cover']!,
          cover: raw['cover']!,
          statementSource: uris['ofs']!,
          statement: raw['ofs']!,
          start: start,
          end: end,
        );
    guard(
      issuer != null && issuer['printedIssuer'] == p['printedIssuer'],
      'own shell/cover/OFS printed issuer chain missing',
    );
    final body = raw['ofs']!, text = compact(body);
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (r) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
        )
        .toList();
    List<String> exact(List expected, int index) {
      final row = rows[index];
      guard(
        jsonEncode(row) ==
            jsonEncode(expected.map((s) => compact(s as String)).toList()),
        'bound raw row mismatch',
      );
      return row;
    }

    BigInt money(String s) {
      guard(
        RegExp(r'^(?:-?[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
            .hasMatch(s),
        'unprinted/malformed monetary cell',
      );
      return BigInt.parse(
        s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final core = (p['independentDirect8'] as List).cast<Map>();
    final values = [
      for (final c in core)
        money(
          exact(c['rawRow'] as List, c['rowIndex'] as int)[c['column'] as int],
        ),
    ];
    for (var i = 0; i < values.length; i++) {
      guard(
        values[i].toString() == core[i]['amountKRW'],
        'current numeric sign changed',
      );
    }
    // The bound BS monetary column itself prints its calendar year. FY24 also
    // prints '(전)' in that same cell; keep this contradictory term verbatim.
    final bsHeader = rows[5][2];
    guard(
      bsHeader.contains('($year년말)'),
      'BS bound current column year missing',
    );
    guard(
      text.contains('$year년12월31일현재') &&
          RegExp('$year년0?1월0?1일부터$year년12월31일까지').allMatches(text).length == 3,
      'independent BS/CIS/CE/CF printed dates missing',
    );
    final ce = p['wholeCE'] as Map;
    final opening = (ce['opening'] as List)
            .map((s) => compact(s as String))
            .toList(),
        ni = (ce['NI'] as List).map((s) => compact(s as String)).toList(),
        closing = (ce['closing'] as List)
            .map((s) => compact(s as String))
            .toList();
    guard(
      rows.any((r) => jsonEncode(r) == jsonEncode(opening)) &&
          rows.any((r) => jsonEncode(r) == jsonEncode(ni)) &&
          rows.any((r) => jsonEncode(r) == jsonEncode(closing)),
      'whole CE source rows missing',
    );
    guard(
      opening.first == '$year.1.1(당기초)' &&
          closing.first == '$year.12.31(당기말)' &&
          money(ni.last) == values[5] &&
          money(closing.last) == values[2],
      'current CE interval/whole scope mismatch',
    );
    var changes = BigInt.zero;
    for (final m in ce['numericMovementRows'] as List) {
      final row = (m as List).map((s) => compact(s as String)).toList();
      guard(
        rows.any((r) => jsonEncode(r) == jsonEncode(row)),
        'current CE movement source missing',
      );
      changes += money(row.last);
    }
    guard(
      values[0] == values[1] + values[2] &&
          money(opening.last) + changes == money(closing.last),
      'whole balance/equity roll contradiction',
    );
    final cash = (p['cashRows'] as List).cast<Map>();
    final cr = [
      for (final c in cash) exact(c['row'] as List, c['rowIndex'] as int),
    ];
    final bs = (p['bsCash'] as List).map((s) => compact(s as String)).toList();
    guard(jsonEncode(rows[8]) == jsonEncode(bs), 'BS cash source changed');
    for (final col in [1, 2]) {
      // FX is printed dash/blank. It remains null; these checks use the printed
      // three-activity total, reported increase and cash roll independently.
      guard(cr[5][col].isEmpty || cr[5][col] == '-', 'FX source changed');
      guard(
        money(cr[0][col]) + money(cr[1][col]) + money(cr[2][col]) ==
                money(cr[3][col]) &&
            money(cr[4][col]) + money(cr[3][col]) == money(cr[6][col]) &&
            money(bs[col + 1]) == money(cr[6][col]),
        'current/prior reported cash contradiction',
      );
    }
    guard(
      money(cr[6][2]) == money(cr[4][1]),
      'prior close/current opening cash mismatch',
    );
    final from = '$year-01-01', to = '$year-12-31';
    return [
      for (var i = 0; i < core.length; i++)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '$year',
          'reprt_code': '11011',
          'fs_div': 'OFS',
          'sj_div': i < 3
              ? 'BS'
              : i < 6
              ? 'CIS'
              : 'CF',
          'account_id': null,
          'account_nm': (core[i]['rawRow'] as List).first,
          'account_detail': '-',
          'thstrm_nm': i < 3 ? to : '$from~$to',
          'thstrm_amount': values[i].toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': uris['ofs'].toString(),
            'sourceSha256': (p['sources'] as List).last['sha256'],
            'basis': 'OFS',
            'periodStart': from,
            'periodEnd': to,
            'printedLabel': (core[i]['rawRow'] as List).first,
            'printedCurrentCells': [
              (core[i]['rawRow'] as List)[core[i]['column'] as int],
            ],
            'rawCurrentRow': core[i]['rawRow'],
            'currentColumn': core[i]['column'],
            'unit': '원',
            'unitMultiplier': '1',
            'signRule': 'printed-numeric-sign',
            'exactIssuerIdentity': issuer,
            'printedBSCurrentColumnHeader': bsHeader,
            'BSHeaderTermConflict': year == 2024,
            'currentColumnDateEvidence':
                'Bound BS column prints $year년말; current CIS/CE/CF independently print full $year annual interval. The FY2024 term marker 전 is retained as a source contradiction.',
            'currentFX': null,
            'priorFX': null,
            'printedCurrentFX': cr[5][1],
            'printedPriorFX': cr[5][2],
            'FXInferredZero': false,
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'uncollectedOptionalAccounts': <String>[],
            'supportingPeriodEvidence': {
              'policy': rule,
              'wholeCurrentProfit': values[5].toString(),
              'openingEquity': money(opening.last).toString(),
              'closingEquity': values[2].toString(),
              'fullStatementCollected': false,
            },
          },
        },
    ];
  }
}
