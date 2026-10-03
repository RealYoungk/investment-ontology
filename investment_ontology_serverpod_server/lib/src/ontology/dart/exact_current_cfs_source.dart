import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'exact_current_cfs_profiles.dart';

/// Two immutable own-receipt consolidated sources with missing title tags.
/// This does not relax general headings, issuer matching, or whole-statement scope.
abstract final class ExactCurrentCfsSource {
  static const rule = 'exact-current-cfs-seven-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(exactCurrentCfsProfilesJson) as List)
          .cast<Map<String, dynamic>>();
  static String compact(String v) => v
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
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Map<String, String> raw,
    required Map<String, Uri> uris,
  }) {
    void guard(bool ok, String why) {
      if (!ok) throw FormatException('Exact CFS: $why');
    }

    final choices = profiles.where((p) => p['receipt'] == receipt).toList();
    guard(choices.length == 1 && consolidated, 'unregistered receipt/basis');
    final p = choices.single;
    guard(
      corpCode == p['corp'] &&
          companyName == p['name'] &&
          start == DateTime.utc(2024) &&
          end == DateTime.utc(2024, 12, 31),
      'issuer/period mismatch',
    );
    guard(
      raw.keys.toSet().containsAll(['shell', 'cover', 'cfs']) &&
          raw.length == 3 &&
          uris.length == 3,
      'source set mismatch',
    );
    for (final s in p['sources'] as List) {
      guard(
        uris[s['label']].toString() == s['url'] &&
            sha256.convert(utf8.encode(raw[s['label']]!)).toString() ==
                s['sha256'],
        'source coordinate/digest mismatch',
      );
    }
    final shell = raw['shell']!;
    final corp = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m[1]!).toSet();
    guard(
      corp.length == 1 && corp.single == corpCode,
      'own shell issuer mismatch',
    );
    final nodes = RegExp(
      r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
      dotAll: true,
    ).allMatches(shell).where((m) => compact(m[2]!) == '2.연결재무제표').toList();
    guard(nodes.length == 1, 'unique consolidated node missing');
    final attributes = <String, String>{};
    for (final a in RegExp(
      r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
    ).allMatches(nodes.single[3]!)) {
      guard(!attributes.containsKey(a[1]), 'duplicate node coordinate');
      attributes[a[1]!] = a[2]!;
    }
    guard(
      attributes.length == 6 &&
          attributes.entries.every(
            (a) => uris['cfs']!.queryParameters[a.key] == a.value,
          ),
      'CFS node/source chain mismatch',
    );
    guard(
      compact(raw['cover']!).contains(p['coverName'] as String) &&
          compact(raw['cover']!).contains('2024년01월01일부터2024년12월31일까지'),
      'cover issuer/annual period missing',
    );
    final body = raw['cfs']!;
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (tr) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(tr[1]!).map((c) => compact(c[1]!)).toList(),
        )
        .toList();
    List<String> checked(Map cell) {
      final i = cell['rowIndex'] as int;
      guard(i >= 0 && i < rows.length, 'row coordinate out of range');
      final expected = (cell['row'] as List)
          .map((v) => compact(v as String))
          .toList();
      guard(
        jsonEncode(rows[i]) == jsonEncode(expected),
        'current raw row mismatch',
      );
      return rows[i];
    }

    BigInt money(String s) {
      guard(
        RegExp(r'^(?:-?[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
            .hasMatch(s),
        'unprinted monetary value',
      );
      return BigInt.parse(
        s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    BigInt current(Map cell) => money(checked(cell)[cell['column'] as int]);
    final core = (p['core'] as List).cast<Map>();
    final values = core.map(current).toList();
    for (var i = 0; i < core.length; i++) {
      guard(
        values[i].toString() == core[i]['amountKRW'],
        'direct current amount mismatch',
      );
    }
    final ce = (p['ce'] as List).cast<Map>();
    final op = checked(ce[0]), ni = checked(ce[1]), cl = checked(ce[2]);
    final whole = ce[2]['wholeColumn'] as int;
    final ceBlock = (p['ceBlock'] as List).cast<Map>();
    for (final cell in ceBlock) {
      checked(cell);
    }
    final ceChanges = ceBlock
        .skip(1)
        .take(ceBlock.length - 2)
        .map(checked)
        .where(
          (r) => r.length > whole && r[whole] != '-' && r[whole].isNotEmpty,
        )
        .map((r) => money(r[whole]));
    guard(
      values[0] == values[1] + values[2] &&
          money(ni[whole]) == values[5] &&
          money(cl[whole]) == values[2] &&
          money(op[whole]) + ceChanges.fold(BigInt.zero, (a, b) => a + b) ==
              money(cl[whole]),
      'BS/CE whole contradiction',
    );
    final bsEquity = checked(core[2]);
    final priorEquity = bsEquity
        .skip((core[2]['column'] as int) + 1)
        .firstWhere((v) => v.isNotEmpty);
    guard(money(priorEquity) == money(op[whole]), 'prior BS/CE contradiction');
    final cash = (p['cash'] as List).cast<Map>();
    final cf = cash.map(current).toList();
    final bc = p['bsCash'] as Map;
    final bsCash = checked(bc);
    guard(
      values[6] + cf[0] + cf[1] == cf[2] &&
          cf[4] + cf[2] + cf[3] == cf[5] &&
          money(bsCash[bc['column'] as int]) == cf[5] &&
          money(bsCash[bc['priorColumn'] as int]) == cf[4],
      'current cash contradiction',
    );
    final priorColumn = receipt == '20250321000195' ? 2 : 4;
    BigInt prior(Map c) => money(checked(c)[priorColumn]);
    guard(
      prior(core[6]) + prior(cash[0]) + prior(cash[1]) == prior(cash[2]) &&
          prior(cash[4]) + prior(cash[2]) + prior(cash[3]) == prior(cash[5]),
      'prior cash contradiction',
    );
    for (final u in p['unitRows'] as List) {
      guard(checked(u).last == '(단위:원)', 'individual unit missing');
    }
    for (final range in p['periodRows'] as List) {
      checked(range);
    }
    guard(
      (p['periodRows'] as List).length == 4 &&
          (p['unitRows'] as List).length == 4,
      'four periods/units missing',
    );
    final evidence = {
      'policy': rule,
      'flowCaptionPrintedStart': true,
      'periodStart': '2024-01-01',
      'periodEnd': '2024-12-31',
      'basis': 'CFS',
      'source': uris['cfs'].toString(),
      'sourceSha256': (p['sources'] as List).last['sha256'],
      'wholeEquityColumn': whole,
      'openingEquity': money(op[whole]).toString(),
      'closingEquity': values[2].toString(),
      'currentProfit': values[5].toString(),
      'openingCash': cf[4].toString(),
      'closingCash': cf[5].toString(),
      'cashIncrease': cf[2].toString(),
      'exchangeCash': cf[3].toString(),
      'ownShellCoverUniqueCfsNode': true,
      'issuerPrintedInStatement': receipt == '20250424000405',
      'collectedAccounts': core.map((c) => c['role']).toList(),
      'optionalAccountsNotCollected': ['capex'],
      'fullStatementCollected': false,
    };
    return [
      for (var i = 0; i < core.length; i++)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '2024',
          'reprt_code': '11011',
          'fs_div': 'CFS',
          'sj_div': core[i]['kind'],
          'account_id': null,
          'account_nm': core[i]['printedLabel'],
          'account_detail': '-',
          'thstrm_nm': i < 3 ? '2024-12-31' : '2024-01-01~2024-12-31',
          'thstrm_amount': values[i].toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': uris['cfs'].toString(),
            'basis': 'CFS',
            'periodStart': '2024-01-01',
            'periodEnd': '2024-12-31',
            'printedLabel': core[i]['printedLabel'],
            'printedUnit': '원',
            'fullStatementCollected': false,
            'uncollectedOptionalAccounts': ['capex'],
            'multiplier': '1',
            'rowIndex': core[i]['rowIndex'],
            'column': core[i]['column'],
            'currentCell': checked(core[i])[core[i]['column'] as int],
            'supportingPeriodEvidence': evidence,
          },
        },
    ];
  }
}
