import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A single immutable official OFS document with no printed revenue aggregate.
/// Neither a bank classifier nor a general six-account extraction policy.
abstract final class BnkSixCoreProfile {
  static const receipt = '20230309000759';
  static const corpCode = '00858364';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230309000759&dcmNo=9045525&eleId=1&offset=802&length=4169&dtd=dart3.xsd';
  static const statementUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230309000759&dcmNo=9045525&eleId=19&offset=2446792&length=69735&dtd=dart3.xsd';
  static const coverSha =
      'b9ee397fc04f2aeed1976a1f553056cae152084024d8f5db07d53b28e3f2d635';
  static const statementSha =
      'c476ee0b528fe4e52161bd17844df04e0c57b3d07550056d16e317d5e04544a0';
  static const digest =
      '907e33639687b0c7e9a54cc54f9d676fdec0a60cffb455173235463bcaad7cdf';
  static const title =
      'DART 원문 HTML 부분 핵심6계정(BNK 정확원문·매출 총액 미확보·유형자산취득 미수집·전체 재무제표 아님)';
  static const printedLabels = <String, String>{
    'assets': '자 산 총 계',
    'liabilities': '부 채 총 계',
    'equity': '자 본 총 계',
    'operatingIncome': 'VI. 영업이익',
    'netIncome': 'X. 당기순이익',
    'operatingCashFlow': 'I. 영업활동으로 인한 현금흐름',
  };
  static const amounts = <String, String>{
    'assets': '6915786817905',
    'liabilities': '1568242880230',
    'equity': '5347543937675',
    'operatingIncome': '305909289322',
    'netIncome': '305256302474',
    'operatingCashFlow': '312746783058',
  };
  static String _text(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String _compact(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static bool boundCover({
    required String targetReceipt,
    required String companyCode,
    required String companyName,
    required bool consolidated,
    required DateTime end,
    required Uri source,
    required String html,
  }) =>
      targetReceipt == receipt &&
      companyCode == corpCode &&
      !consolidated &&
      end == DateTime.utc(2022, 12, 31) &&
      _compact(companyName).replaceAll(RegExp(r'\(주\)|㈜|주식회사'), '') ==
          'BNK금융지주' &&
      source.toString() == coverUri &&
      sha256.convert(utf8.encode(html)).toString() == coverSha;
  static List<Map<String, dynamic>> parse({
    required String targetReceipt,
    required String companyCode,
    required String companyName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required String coverHtml,
    required Uri statementSource,
    required String statementHtml,
  }) {
    if (!boundCover(
          targetReceipt: targetReceipt,
          companyCode: companyCode,
          companyName: companyName,
          consolidated: consolidated,
          end: end,
          source: coverSource,
          html: coverHtml,
        ) ||
        start != DateTime.utc(2022, 1, 1) ||
        statementSource.toString() != statementUri ||
        sha256.convert(utf8.encode(statementHtml)).toString() != statementSha) {
      throw const FormatException(
        'BNK six-core immutable source identity mismatch',
      );
    }
    final cover = _compact(_text(coverHtml));
    if (!cover.contains('회사명:(주)BNK금융지주일시대표이사:') ||
        !cover.contains('사업연도2022년01월01일부터2022년12월31일까지')) {
      throw const FormatException('BNK cover declaration mismatch');
    }
    final tables = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).toList();
    List<List<String>> cells(int table) {
      return RegExp(
            r'<TR\b[^>]*>(.*?)</TR>',
            caseSensitive: false,
            dotAll: true,
          )
          .allMatches(tables[table].group(1)!)
          .map(
            (row) => RegExp(
              r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
              caseSensitive: false,
              dotAll: true,
            ).allMatches(row.group(1)!).map((m) => _text(m.group(1)!)).toList(),
          )
          .toList();
    }

    String prefix(int table) =>
        _compact(_text(statementHtml.substring(0, tables[table].start)));
    final bs = cells(2), pl = cells(6), ce = cells(11), cf = cells(15);
    final expected = [
      '재무상태표제12기2022년12월31일현재제11기2021년12월31일현재제10기2020년12월31일현재주식회사BNK금융지주(단위:원)',
      '포괄손익계산서제12기2022년01월01일부터2022년12월31일까지제11기2021년01월01일부터2021년12월31일까지제10기2020년01월01일부터2020년12월31일까지주식회사BNK금융지주(단위:원)',
      '현금흐름표제12기2022년01월01일부터2022년12월31일까지제11기2021년01월01일부터2021년12월31일까지제10기2020년01월01일부터2020년12월31일까지주식회사BNK금융지주(단위:원)',
    ];
    for (var i = 0; i < 3; i++) {
      if (!prefix([2, 6, 15][i]).endsWith(expected[i])) {
        throw const FormatException('BNK whole current dates/units mismatch');
      }
    }
    if (bs.first.map(_compact).join('|') != '과목|제12기말|제11기말|제10기말' ||
        pl.first.map(_compact).join('|') != '과목|제12기|제11기|제10기' ||
        cf.first.map(_compact).join('|') != '과목|제12기|제11기|제10기') {
      throw const FormatException('BNK current monetary column mismatch');
    }
    List<String> unique(List<List<String>> rows, String label) {
      final matches = rows
          .where((r) => r.isNotEmpty && _compact(r.first) == label)
          .toList();
      if (matches.length != 1) {
        throw const FormatException('BNK duplicate/missing whole row');
      }
      return matches.single;
    }

    BigInt number(String s) {
      final negative = s.startsWith('(') && s.endsWith(')');
      final raw = negative ? s.substring(1, s.length - 1) : s;
      if (!RegExp(r'^\d{1,3}(?:,\d{3})*$').hasMatch(raw)) {
        throw const FormatException('BNK ambiguous whole current amount');
      }
      final n = BigInt.parse(raw.replaceAll(',', ''));
      return negative ? -n : n;
    }

    final selected = <String, List<String>>{
      'assets': unique(bs, '자산총계'),
      'liabilities': unique(bs, '부채총계'),
      'equity': unique(bs, '자본총계'),
      'operatingIncome': unique(pl, 'VI.영업이익'),
      'netIncome': unique(pl, 'X.당기순이익'),
      'operatingCashFlow': unique(cf, 'I.영업활동으로인한현금흐름'),
    };
    for (final entry in selected.entries) {
      if (entry.value.length != 4 ||
          number(entry.value[1]).toString() != amounts[entry.key]) {
        throw const FormatException('BNK whole current value mismatch');
      }
    }
    if (number(selected['assets']![1]) !=
        number(selected['liabilities']![1]) + number(selected['equity']![1])) {
      throw const FormatException('BNK balance equality mismatch');
    }
    if (pl.any(
      (r) =>
          r.isNotEmpty &&
          {'매출액', '영업수익', '매출', '수익(매출액)'}.contains(
            _compact(r.first).replaceFirst(RegExp(r'^[Ⅰ-ⅫIVXLCDM\d]+[.)]'), ''),
          ),
    )) {
      throw const FormatException('BNK aggregate revenue profile changed');
    }
    // The seven-column CE current block proves whole profit and ending equity.
    if (ce.first.map(_compact).join('|') !=
        '과목|자본금|신종자본증권|기타불입자본|기타자본구성요소|이익잉여금|총계') {
      throw const FormatException('BNK CE total-column mismatch');
    }
    final a = ce.indexWhere(
      (r) => r.isNotEmpty && _compact(r.first) == '2022년01월01일',
    );
    final b = ce.indexWhere(
      (r) => r.isNotEmpty && _compact(r.first) == '2022년12월31일',
    );
    if (a != 8 ||
        b != 13 ||
        ce.skip(a).take(b - a + 1).any((r) => r.length != 7)) {
      throw const FormatException('BNK CE current dates ambiguous');
    }
    final current = ce.sublist(a + 1, b);
    final profit = unique(current, '당기순이익');
    if (number(profit.last) != number(selected['netIncome']![1]) ||
        number(profit[5]) != number(profit.last) ||
        number(ce[b].last) != number(selected['equity']![1]) ||
        number(ce[a].last) +
                current.map((r) => number(r.last)).reduce((x, y) => x + y) !=
            number(ce[b].last)) {
      throw const FormatException(
        'BNK CE whole profit/equity crosscheck mismatch',
      );
    }
    return [
      for (final entry in selected.entries)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '2022',
          'reprt_code': '11011',
          'fs_div': 'OFS',
          'sj_div': {'assets', 'liabilities', 'equity'}.contains(entry.key)
              ? 'BS'
              : entry.key == 'operatingCashFlow'
              ? 'CF'
              : 'CIS',
          'account_id': null,
          'account_nm': entry.value.first,
          'thstrm_amount': amounts[entry.key],
          'currency': 'KRW',
          'html_provenance': {
            'source': statementUri,
            'basis': 'OFS',
            'periodStart': '2022-01-01',
            'periodEnd': '2022-12-31',
            'printedAccount': entry.value.first,
            'printedAmount': entry.value[1],
            'printedCurrentCells': [entry.value[1]],
            'printedUnit': '원',
            'scale': '1',
            'tableIndex':
                {'assets', 'liabilities', 'equity'}.contains(entry.key)
                ? 2
                : entry.key == 'operatingCashFlow'
                ? 15
                : 6,
            'bnkSixCore': {
              'profile': 'exact-bnk-ofs-20230309000759-v1',
              'accountKey': entry.key,
              'coverSha256': coverSha,
              'statementSha256': statementSha,
              'combinedSha256': digest,
              'missingRequiredAccounts': ['revenue'],
              'missingReason': 'Whole aggregate revenue row not printed; no summed/zero proxy',
              'uncollectedOptionalAccounts': ['capex'],
              'ceTableIndex': 11,
              'ceCurrentStartRow': 8,
              'ceCurrentEndRow': 13,
              'ceWholeProfit': '305256302474',
              'ceEndingEquity': '5347543937675',
              'ceOpeningEquity': '5251713667367',
            },
          },
        },
    ];
  }

  /// Independent source-bound audit recognition, not trust in a caller flag.
  static bool storedProof(
    dynamic rows, {
    required String sourceDigest,
    required String sourceUrl,
    required String companyCode,
    required String targetReceipt,
    required String basis,
    required int year,
    required String reportName,
  }) {
    if (rows is! List ||
        rows.length != 6 ||
        sourceDigest != digest ||
        sourceUrl != statementUri ||
        companyCode != corpCode ||
        targetReceipt != receipt ||
        basis != 'separate' ||
        year != 2022 ||
        reportName != '사업보고서 (2022.12)') {
      return false;
    }
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map ||
          row['account_id'] != null ||
          row['currency'] != 'KRW' ||
          row['html_provenance'] is! Map) {
        return false;
      }
      final p = row['html_provenance'] as Map;
      final proof = p['bnkSixCore'];
      if (proof is! Map ||
          proof['profile'] != 'exact-bnk-ofs-20230309000759-v1' ||
          proof['coverSha256'] != coverSha ||
          proof['statementSha256'] != statementSha ||
          proof['combinedSha256'] != digest ||
          proof['ceWholeProfit'] != '305256302474' ||
          proof['ceEndingEquity'] != '5347543937675' ||
          proof['ceOpeningEquity'] != '5251713667367' ||
          proof['ceTableIndex'] != 11 ||
          proof['ceCurrentStartRow'] != 8 ||
          proof['ceCurrentEndRow'] != 13 ||
          jsonEncode(proof['missingRequiredAccounts']) != '["revenue"]' ||
          p['source'] != statementUri ||
          p['basis'] != 'OFS' ||
          p['periodStart'] != '2022-01-01' ||
          p['periodEnd'] != '2022-12-31' ||
          p['printedUnit'] != '원' ||
          p['scale'] != '1') {
        return false;
      }
      final key = proof['accountKey'];
      if (key is! String ||
          !seen.add(key) ||
          row['thstrm_amount'] != amounts[key] ||
          p['printedAmount'].toString().replaceAll(',', '') != amounts[key] ||
          row['account_nm'] != p['printedAccount'] ||
          _compact(row['account_nm'].toString()) !=
              _compact(printedLabels[key] ?? '') ||
          p['tableIndex'] !=
              ({'assets', 'liabilities', 'equity'}.contains(key)
                  ? 2
                  : key == 'operatingCashFlow'
                  ? 15
                  : 6) ||
          jsonEncode(p['printedCurrentCells']) !=
              jsonEncode([p['printedAmount']]) ||
          jsonEncode(proof['uncollectedOptionalAccounts']) != '["capex"]' ||
          proof['missingReason'] !=
              'Whole aggregate revenue row not printed; no summed/zero proxy') {
        return false;
      }
    }
    return seen.length == 6 && amounts.keys.every(seen.contains);
  }
}
