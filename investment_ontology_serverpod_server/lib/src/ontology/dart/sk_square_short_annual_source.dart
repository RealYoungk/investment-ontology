import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'primary_historical_issuer.dart';
import 'sk_square_short_annual_profile.dart';

/// One own first annual report; declared source interval is sixty-one days.
abstract final class SkSquareShortAnnualSource {
  static const rule = 'sk-square-first-short-annual-current-eight-v1';
  static Map<String, dynamic> get profile =>
      jsonDecode(skSquareShortAnnualProfileJson) as Map<String, dynamic>;
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
      if (!ok) throw FormatException('SK Square exact short annual: $reason');
    }

    final p = profile;
    guard(
      receipt == p['receipt'] &&
          corpCode == p['corpCode'] &&
          companyName == p['name'] &&
          consolidated,
      'receipt/issuer/basis mismatch',
    );
    guard(
      start == DateTime.utc(2021, 11, 1) && end == DateTime.utc(2021, 12, 31),
      'printed short interval mismatch',
    );
    for (final s in p['sources'] as List) {
      final l = s['label'] as String;
      guard(
        raw[l] != null &&
            uris[l]?.toString() == s['url'] &&
            sha256.convert(utf8.encode(raw[l]!)).toString() == s['sha256'],
        'source coordinates/digest mismatch',
      );
    }
    final shell = raw['shell']!;
    final corps = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m[1]).toSet();
    guard(
      corps.length == 1 && corps.single == corpCode,
      'own shell corp mismatch',
    );
    bool node(String title, Uri uri) {
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
          matches.single['rcpNo'] == receipt &&
          uri.queryParametersAll.length == 6 &&
          matches.single.entries.every(
            (e) =>
                uri.queryParametersAll[e.key]?.length == 1 &&
                uri.queryParameters[e.key] == e.value,
          );
    }

    guard(
      node('사업보고서', uris['cover']!) && node('2.연결재무제표', uris['cfs']!),
      'unique own cover/CFS nodes missing',
    );
    final compact = PrimaryHistoricalIssuer.text;
    final cover = compact(raw['cover']!),
        body = raw['cfs']!,
        text = compact(body);
    guard(
      cover.contains('회사명:에스케이스퀘어주식회사') &&
          cover.contains('사업연도2021년11월01일부터2021년12월31일까지'),
      'actual printed cover issuer/start/end missing',
    );
    guard(
      RegExp('2021년11월1일부터2021년12월31일까지').allMatches(text).length == 4 &&
          RegExp(r'\(단위:백만원\)').allMatches(text).length == 5 &&
          RegExp('SK스퀘어주식회사및그종속기업').allMatches(text).length == 5,
      'independent flow intervals/units/printed statement issuer missing',
    );
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (r) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
        )
        .toList();
    List<String> exact(Map c) {
      final row = rows[c['rowIndex'] as int];
      guard(
        jsonEncode(row) ==
            jsonEncode(
              (c['rawRow'] as List).map((s) => compact(s as String)).toList(),
            ),
        'bound printed row mismatch',
      );
      return row;
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
    final amounts = [for (final c in core) money(exact(c)[c['column'] as int])];
    for (var i = 0; i < 8; i++) {
      guard(
        amounts[i].toString() == core[i]['printedAmount'] &&
            (amounts[i] * BigInt.from(1000000)).toString() ==
                core[i]['amountKRW'],
        'printed multiplier/amount mismatch',
      );
    }
    final ce = p['wholeCE'] as Map;
    final opening = exact(ce['opening'] as Map),
        ni = exact(ce['NI'] as Map),
        closing = exact(ce['closing'] as Map);
    final wc = ce['wholeColumn'] as int;
    guard(
      opening.first == '2021.11.1(분할설립일)' &&
          closing.first == '2021.12.31(당기말)' &&
          money(ni[wc]) == amounts[5] &&
          money(closing[wc]) == amounts[2],
      'whole current CE scope mismatch',
    );
    var movement = BigInt.zero;
    for (final c in ce['numericMovements'] as List) {
      movement += money(exact(c as Map)[wc]);
    }
    guard(
      amounts[0] == amounts[1] + amounts[2] &&
          money(opening[wc]) + movement == money(closing[wc]),
      'BS/CE exact roll contradiction',
    );
    final cash = [for (final c in p['cashRows'] as List) exact(c as Map)];
    guard(
      money(cash[1][2]) + money(cash[2][2]) + money(cash[3][2]) ==
              money(cash[4][2]) &&
          money(cash[5][2]) + money(cash[4][2]) + money(cash[6][2]) ==
              money(cash[7][2]) &&
          money(cash[0][1]) == money(cash[7][2]),
      'current activities/printed FX/roll/BS cash contradiction',
    );
    return [
      for (var i = 0; i < 8; i++)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '2021',
          'reprt_code': '11011',
          'fs_div': 'CFS',
          'sj_div': i < 3
              ? 'BS'
              : i < 6
              ? 'CIS'
              : 'CF',
          'account_id': null,
          'account_nm': (core[i]['rawRow'] as List).first,
          'account_detail': '-',
          'thstrm_nm': i < 3 ? '2021-12-31' : '2021-11-01~2021-12-31',
          'thstrm_amount': core[i]['amountKRW'],
          'currency': 'KRW',
          'html_provenance': {
            'source': uris['cfs'].toString(),
            'sourceSha256': (p['sources'] as List).last['sha256'],
            'basis': 'CFS',
            'periodStart': '2021-11-01',
            'periodEnd': '2021-12-31',
            'printedLabel': (core[i]['rawRow'] as List).first,
            'rawCurrentRow': core[i]['rawRow'],
            'printedCurrentCells': [
              (core[i]['rawRow'] as List)[core[i]['column'] as int],
            ],
            'currentColumn': core[i]['column'],
            'unit': '백만원',
            'unitMultiplier': '1000000',
            'normalizedUnit': '원',
            'signRule': 'printed-numeric-sign',
            'annualShortPeriod': true,
            'annualComparableToFullYear': false,
            'periodDurationReason':
                '분할설립 후 최초 사업보고서 원문 기간2021.11.01~2021.12.31(61일)',
            'priorComparativeNotPrinted': true,
            'openingCashRole':
                '분할설립일 current opening cash; no prior-year CF inferred',
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'uncollectedOptionalAccounts': <String>[],
            'supportingPeriodEvidence': {
              'policy': rule,
              'wholeEquityColumn': wc,
              'parentEquityColumn': ce['parentSubtotalColumn'],
              'wholeCurrentProfit': amounts[5].toString(),
              'fullStatementCollected': false,
            },
          },
        },
    ];
  }
}
