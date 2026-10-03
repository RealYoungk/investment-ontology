import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'primary_historical_issuer.dart';
import 'anymedi_audit_period_profile.dart';

/// Own main statement values; linked audit is only a period/amount witness.
abstract final class AnyMediAuditPeriodSource {
  static const rule = 'exact-anymedi-current-ofs-audit-period-eight-v1';
  static Map<String, dynamic> get profile =>
      jsonDecode(anymediAuditPeriodProfileJson) as Map<String, dynamic>;
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
    void guard(bool ok, String reason) {
      if (!ok) throw FormatException('AnyMedi own audit period: $reason');
    }

    final p = profile;
    guard(
      receipt == p['receipt'] &&
          corpCode == p['corpCode'] &&
          companyName == p['name'] &&
          !consolidated,
      'issuer/receipt/basis mismatch',
    );
    guard(
      start == DateTime.utc(2021, 1, 1) && end == DateTime.utc(2021, 12, 31),
      'actual main statement interval mismatch',
    );
    guard(raw.length == 6 && uris.length == 6, 'six-source chain required');
    for (final s in p['sources'] as List) {
      final l = s['label'] as String;
      guard(
        raw[l] != null &&
            uris[l]?.toString() == s['url'] &&
            sha256.convert(utf8.encode(raw[l]!)).toString() == s['sha256'],
        'exact source URI/SHA mismatch',
      );
    }
    bool ownCorp(String shell) {
      final cs = RegExp(
        r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
      ).allMatches(shell).map((m) => m[1]).toSet();
      return cs.length == 1 && cs.single == corpCode;
    }

    guard(
      ownCorp(raw['shell']!) && ownCorp(raw['audit-shell']!),
      'both own shell issuers required',
    );
    bool node(String shell, String title, Uri uri, String ownReceipt) {
      final matches = <Map<String, String>>[];
      for (final b in RegExp(
        r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
        dotAll: true,
      ).allMatches(shell)) {
        if (b[2]!.replaceAll(RegExp(r'\s+'), '') != title) continue;
        final coords = <String, String>{};
        for (final m in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(b[3]!)) {
          if (coords.containsKey(m[1])) return false;
          coords[m[1]!] = m[2]!;
        }
        matches.add(coords);
      }
      return matches.length == 1 &&
          matches.single.length == 6 &&
          matches.single['rcpNo'] == ownReceipt &&
          uri.queryParametersAll.length == 6 &&
          matches.single.entries.every(
            (e) =>
                uri.queryParametersAll[e.key]?.length == 1 &&
                uri.queryParameters[e.key] == e.value,
          );
    }

    guard(
      node(raw['shell']!, '사업보고서', uris['cover']!, receipt) &&
          node(raw['shell']!, '4.재무제표', uris['ofs']!, receipt),
      'own primary cover/OFS nodes required',
    );
    guard(
      node(
            raw['audit-shell']!,
            '독립된감사인의감사보고서',
            uris['audit-opinion']!,
            '20221226000436',
          ) &&
          node(
            raw['audit-shell']!,
            '(첨부)재무제표',
            uris['audit-statement']!,
            '20221226000436',
          ),
      'own audit opinion/statement nodes required',
    );
    final observed =
        RegExp(
              r'<option\b[^>]*value=["\x27]([^"\x27]+)["\x27][^>]*>([^<]*감사보고서[^<]*)</option>',
              caseSensitive: false,
            )
            .allMatches(raw['shell']!)
            .where(
              (m) =>
                  PrimaryHistoricalIssuer.text(m[2]!)
                      .replaceAll(RegExp(r'^2022\.12\.26'), '') ==
                  '감사보고서',
            )
            .map((m) => m[1]!.replaceAll('&amp;', '&'))
            .toSet();
    guard(
      observed.length == 1 &&
          observed.single == 'rcpNo=20221226000436&dcmNo=8921665',
      'unique observed own audit relationship required',
    );
    final compact = PrimaryHistoricalIssuer.text;
    final cover = compact(raw['cover']!),
        mainText = compact(raw['ofs']!),
        auditText = compact(raw['audit-statement']!),
        opinion = compact(raw['audit-opinion']!);
    guard(
      cover.contains('2021년12월21일') && cover.contains('애니메디솔루션'),
      'printed cover discrepancy must remain',
    );
    guard(
      mainText.contains('제6기2021년12월31일현재') &&
          RegExp('2021년1월1일부터2021년12월31일까지').allMatches(mainText).length == 3 &&
          RegExp(r'\(단위:원\)').allMatches(mainText).length == 4,
      'own main BS/CIS/CE/CF periods/units',
    );
    guard(
      auditText.contains('2021년01월01일부터2021년12월31일까지') &&
          auditText.contains('애니메디솔루션주식회사') &&
          opinion.contains(compact(p['auditVerbatimPeriodQuote'] as String)),
      'audit own issuer/period/opinion witness',
    );
    List<List<String>> rows(String body) =>
        RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
            .allMatches(body)
            .map(
              (r) => RegExp(
                r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                caseSensitive: false,
              ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
            )
            .toList();
    final main = rows(raw['ofs']!), audit = rows(raw['audit-statement']!);
    for (final index in [14, 59, 82, 106]) {
      guard(
        audit[index].length == 2 &&
            audit[index][0] == '애니메디솔루션주식회사' &&
            audit[index][1] == '(단위:원)',
        'audit four own statement printed won units',
      );
    }
    List<String> exact(List<List<String>> rs, int i, List wanted) {
      guard(
        i < rs.length &&
            jsonEncode(rs[i]) ==
                jsonEncode(wanted.map((s) => compact(s as String)).toList()),
        'bound printed row mismatch',
      );
      return rs[i];
    }

    BigInt money(String v) {
      guard(
        RegExp(r'^(?:[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
            .hasMatch(v),
        'unprinted/malformed number',
      );
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final core = (p['core8'] as List).cast<Map>();
    final amounts = <BigInt>[];
    for (final c in core) {
      final m = money(
        exact(
          main,
          c['mainRowIndex'] as int,
          c['mainRawRow'] as List,
        )[c['mainColumn'] as int],
      );
      final a = money(
        exact(
          audit,
          c['auditRowIndex'] as int,
          c['auditRawRow'] as List,
        )[c['auditColumn'] as int],
      );
      guard(
        m == a && m.toString() == c['amountKRW'],
        'independent own main/audit current amount disagreement',
      );
      amounts.add(m);
    }
    guard(amounts[0] == amounts[1] + amounts[2], 'own BS exact equation');
    for (final prefix in ['main', 'audit']) {
      final rs = prefix == 'main' ? main : audit;
      final ce = p['${prefix}CE'] as Map;
      final wc = ce['wholeColumn'] as int;
      final opening = exact(
            rs,
            ce['openingRowIndex'] as int,
            ce['openingRawRow'] as List,
          ),
          ni = exact(rs, ce['NIRowIndex'] as int, ce['NIRawRow'] as List),
          closing = exact(
            rs,
            ce['closingRowIndex'] as int,
            ce['closingRawRow'] as List,
          );
      guard(
        opening.first.contains('2021년1월1일') &&
            closing.first.contains('2021년12월31일'),
        'whole CE actual current dates',
      );
      var move = BigInt.zero;
      for (final c in ce['movementRows'] as List) {
        move += money(exact(rs, c['rowIndex'] as int, c['rawRow'] as List)[wc]);
      }
      guard(
        money(ni[wc]) == amounts[5] &&
            money(closing[wc]) == amounts[2] &&
            money(opening[wc]) + move == money(closing[wc]),
        'whole NI/CE close/roll mismatch',
      );
      final cash = [
        for (final c in p['${prefix}CashRows'] as List)
          exact(rs, c['rowIndex'] as int, c['rawRow'] as List),
      ];
      final current = prefix == 'main' ? 2 : 3,
          prior = prefix == 'main' ? 4 : 5,
          bs = prefix == 'main' ? 1 : 2;
      for (final col in [current, prior]) {
        guard(
          money(cash[1][col]) + money(cash[2][col]) + money(cash[3][col]) ==
                  money(cash[4][col]) &&
              money(cash[5][col]) + money(cash[4][col]) ==
                  money(cash[6][col]) &&
              money(cash[0][col == current ? bs : bs + 2]) ==
                  money(cash[6][col]),
          'printed cash activities/roll/BS mismatch',
        );
      }
      guard(
        money(cash[6][prior]) == money(cash[5][current]),
        'printed prior close/current opening mismatch',
      );
    }
    final statementSource = uris['ofs']!.toString();
    final mainSHA = (p['sources'] as List).singleWhere(
      (s) => s['label'] == 'ofs',
    )['sha256'];
    return [
      for (var i = 0; i < 8; i++)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '2021',
          'reprt_code': '11011',
          'fs_div': 'OFS',
          'sj_div': i < 3
              ? 'BS'
              : i < 6
              ? 'CIS'
              : 'CF',
          'account_id': null,
          'account_nm': (core[i]['mainRawRow'] as List).first,
          'account_detail': '-',
          'thstrm_nm': i < 3 ? '2021-12-31' : '2021-01-01~2021-12-31',
          'thstrm_amount': core[i]['amountKRW'],
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource,
            'sourceSha256': mainSHA,
            'basis': 'OFS',
            'periodStart': '2021-01-01',
            'periodEnd': '2021-12-31',
            'printedLabel': (core[i]['mainRawRow'] as List).first,
            'rawCurrentRow': core[i]['mainRawRow'],
            'printedCurrentCells': [
              (core[i]['mainRawRow'] as List)[core[i]['mainColumn'] as int],
            ],
            'currentColumn': core[i]['mainColumn'],
            'unit': '원',
            'unitMultiplier': '1',
            'signRule': 'printed-numeric-sign',
            'annualShortPeriod': false,
            'annualComparableToFullYear': true,
            'coverPrintedEndConflict': '2021-12-21',
            'coverConflictNotRewritten': true,
            'actualPeriodEvidence': 'own main BS/CIS/CE/CF printed Dec31 plus explicitly linked own audit confirms Dec31; cover remains Dec21',
            'supportingAuditReceipt': '20221226000436',
            'supportingAuditSources': [
              for (final s in p['sources'] as List)
                if ((s['label'] as String).startsWith('audit-'))
                  {'role': s['label'], 'URI': s['url'], 'SHA256': s['sha256']},
            ],
            'auditVerbatimPeriodQuote': p['auditVerbatimPeriodQuote'],
            'FXNotPrintedNoZeroFactInvented': true,
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'uncollectedOptionalAccounts': <String>[],
            'supportingPeriodEvidence': {
              'policy': rule,
              'wholeEquityColumn': 5,
              'wholeCurrentProfit': amounts[5].toString(),
              'fullStatementCollected': false,
            },
          },
        },
    ];
  }
}
