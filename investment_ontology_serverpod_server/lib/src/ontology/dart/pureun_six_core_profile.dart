import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A single immutable official OFS document with no printed revenue aggregate.
/// Neither a bank classifier nor a general six-account extraction policy.
abstract final class PureunSixCoreProfile {
  static const receipt = '20230315000460';
  static const corpCode = '00124805';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=1&offset=814&length=4035&dtd=dart3.xsd';
  static const statementUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=19&offset=137556&length=103202&dtd=dart3.xsd';
  static const coverSha =
      '535cde2bfccf39b211ea8587cc5c8d9bbcd2dc247edf9b864451a98742bfa270';
  static const statementSha =
      '99ea72005735072fb8e3ea115310c8842af19780f4e6e244f1c4a3ac44f120bd';
  static const digest =
      '30b34d6fc9896d56718159750d114db09055c47e1e3b8ce7e6fbb87ba8f95f4d';
  static const title =
      'DART 원문 HTML 부분 핵심6계정(푸른 정확원문·매출 총액 미확보·유형자산취득 미수집·전체 재무제표 아님)';
  static const printedLabels = <String, String>{
    'assets': '자 산 총 계',
    'liabilities': '부 채 총 계',
    'equity': '자 본 총 계',
    'operatingIncome': 'X. 영업이익',
    'netIncome': 'XIV. 당기순이익',
    'operatingCashFlow': 'I. 영업활동으로 인한 현금흐름',
  };
  static const amounts = <String, String>{
    'assets': '1408747122384',
    'liabilities': '1099346254004',
    'equity': '309400868380',
    'operatingIncome': '26263414902',
    'netIncome': '20081583946',
    'operatingCashFlow': '-11240281637',
  };
  static const printedAmounts = <String, String>{
    'assets': '1,408,747,122,384',
    'liabilities': '1,099,346,254,004',
    'equity': '309,400,868,380',
    'operatingIncome': '26,263,414,902',
    'netIncome': '20,081,583,946',
    'operatingCashFlow': '(11,240,281,637)',
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
          '푸른저축은행' &&
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
        '푸른 six-core immutable source identity mismatch',
      );
    }
    final cover = _compact(_text(coverHtml));
    if (!cover.contains('회사명:(주)푸른상호저축은행대표이사:') ||
        !cover.contains('사업연도2022년01월01일부터2022년12월31일까지')) {
      throw const FormatException('푸른 cover declaration mismatch');
    }
    final tables = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).toList();
    List<List<String>> cells(int i) =>
        RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
            .allMatches(tables[i].group(1)!)
            .map(
              (r) => RegExp(
                r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
                caseSensitive: false,
                dotAll: true,
              ).allMatches(r.group(1)!).map((c) => _text(c.group(1)!)).toList(),
            )
            .toList();
    final bs = cells(1), pl = cells(3), ce = cells(5), cf = cells(7);
    for (final (i, title) in [(0, '재무상태표'), (2, '포괄손익계산서'), (6, '현금흐름표')]) {
      final caption = _compact(_text(tables[i].group(1)!));
      final current = i == 0
          ? '제53(당)기말2022년12월31일현재'
          : '제53(당)기2022년1월1일부터2022년12월31일까지';
      if (!caption.startsWith('$title$current') ||
          !caption.endsWith('주식회사푸른상호저축은행(단위:원)')) {
        throw const FormatException('푸른 primary dates/unit mismatch');
      }
    }
    if (bs.first.map(_compact).join('|') !=
            '과목|주석|제53(당)기말|제52(전)기말|제51(전전)기말' ||
        pl.first.map(_compact).join('|') != '과목|주석|제53(당)기|제52(전)기|제51(전)기' ||
        cf.first.map(_compact).join('|') != '과목|제53(당)기|제52(전)기|제51(전전)기') {
      throw const FormatException('푸른 current column mismatch');
    }
    List<String> unique(List<List<String>> rows, String label) {
      final matches = rows
          .where((r) => r.isNotEmpty && _compact(r.first) == label)
          .toList();
      if (matches.length != 1) {
        throw const FormatException('푸른 missing/duplicate whole row');
      }
      return matches.single;
    }

    BigInt number(String s) {
      final neg = s.startsWith('(') && s.endsWith(')');
      final raw = neg ? s.substring(1, s.length - 1) : s;
      if (!RegExp(r'^\d{1,3}(?:,\d{3})*$').hasMatch(raw)) {
        throw const FormatException('푸른 ambiguous amount');
      }
      final n = BigInt.parse(raw.replaceAll(',', ''));
      return neg ? -n : n;
    }

    final selected = <String, List<String>>{
      'assets': unique(bs, '자산총계'),
      'liabilities': unique(bs, '부채총계'),
      'equity': unique(bs, '자본총계'),
      'operatingIncome': unique(pl, 'X.영업이익'),
      'netIncome': unique(pl, 'XIV.당기순이익'),
      'operatingCashFlow': unique(cf, 'I.영업활동으로인한현금흐름'),
    };
    const indices = {
      'assets': 2,
      'liabilities': 2,
      'equity': 2,
      'operatingIncome': 3,
      'netIncome': 3,
      'operatingCashFlow': 2,
    };
    for (final e in selected.entries) {
      final r = e.value;
      if (r.length !=
              ({'assets', 'liabilities', 'equity'}.contains(e.key)
                  ? 5
                  : e.key == 'operatingCashFlow'
                  ? 7
                  : 8) ||
          number(r[indices[e.key]!]).toString() != amounts[e.key]) {
        throw const FormatException('푸른 direct current mismatch');
      }
    }
    if (number(selected['assets']![2]) !=
        number(selected['liabilities']![2]) + number(selected['equity']![2])) {
      throw const FormatException('푸른 BS inequality');
    }
    if (pl.any(
      (r) =>
          r.isNotEmpty &&
          {'매출액', '매출', '영업수익', '수익(매출액)'}.contains(
            _compact(r.first).replaceFirst(RegExp(r'^[Ⅰ-ⅫIVXLCDM\d]+[.)]'), ''),
          ),
    )) {
      throw const FormatException('푸른 revenue absence profile changed');
    }
    // CE has no own printed unit. Its raw integers and dates only corroborate
    // the primary KRW tables; no CE amount is assigned a currency or stored.
    if (_compact(_text(tables[4].group(1)!)) !=
            '자본변동표제53(당)기2022년1월1일부터2022년12월31일까지제52(전)기2021년1월1일부터2021년12월31일까지제51(전전)기2020년1월1일부터2020년12월31일까지' ||
        ce.first.map(_compact).join('|') !=
            '과목|자본금|자본잉여금|기타자본항목|기타포괄손익누계액|이익잉여금|합계') {
      throw const FormatException('푸른 CE raw period/header mismatch');
    }
    final a = ce.indexWhere(
          (r) => r.isNotEmpty && _compact(r.first) == '2022.01.01(당기초)',
        ),
        b = ce.indexWhere(
          (r) => r.isNotEmpty && _compact(r.first) == '2022.12.31(당기말)',
        );
    if (a != 21 || b != 30) {
      throw const FormatException('푸른 CE current block mismatch');
    }
    final current = ce.sublist(a + 1, b).where((r) => r.length == 7).toList();
    if (current.length != 6 ||
        number(unique(current, '3.당기순이익').last) !=
            number(selected['netIncome']![3]) ||
        number(ce[b].last) != number(selected['equity']![2])) {
      throw const FormatException('푸른 CE direct raw crosscheck mismatch');
    }
    BigInt rawOrZero(String t) => t == '-' ? BigInt.zero : number(t);
    if (number(ce[a].last) +
            current.map((r) => rawOrZero(r.last)).reduce((x, y) => x + y) !=
        number(ce[b].last)) {
      throw const FormatException('푸른 CE raw rollforward mismatch');
    }
    final opening = number(unique(cf, 'V.기초의현금')[2]),
        closing = number(unique(cf, 'VI.기말의현금(주석7)')[2]);
    if (closing != number(unique(bs, 'I.현금및현금성자산')[2]) ||
        opening +
                number(selected['operatingCashFlow']![2]) +
                number(unique(cf, 'II.투자활동으로인한현금흐름')[2]) +
                number(unique(cf, 'III.재무활동으로인한현금흐름')[2]) !=
            closing) {
      throw const FormatException('푸른 cash rollforward mismatch');
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
            'printedAmount': entry.value[indices[entry.key]!],
            'printedCurrentCells': [entry.value[indices[entry.key]!]],
            'printedUnit': '원',
            'scale': '1',
            'tableIndex':
                {'assets', 'liabilities', 'equity'}.contains(entry.key)
                ? 1
                : entry.key == 'operatingCashFlow'
                ? 7
                : 3,
            'pureunSixCore': {
              'profile': 'exact-pureun-ofs-20230315000460-v1',
              'accountKey': entry.key,
              'coverSha256': coverSha,
              'statementSha256': statementSha,
              'combinedSha256': digest,
              'missingRequiredAccounts': ['revenue'],
              'missingReason': 'Whole aggregate revenue row not printed; no summed/zero proxy',
              'uncollectedOptionalAccounts': ['capex'],
              'ceTableIndex': 5,
              'ceCurrentStartRow': 21,
              'ceCurrentEndRow': 30,
              'cePrintedUnit': 'unknown',
              'ceUse': 'raw-period-and-number-corroboration-only; currency not assigned',
              'ceWholeProfit': '20081583946',
              'ceEndingEquity': '309400868380',
              'ceOpeningEquity': '296326259447',
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
      final proof = p['pureunSixCore'];
      if (proof is! Map ||
          proof['cePrintedUnit'] != 'unknown' ||
          proof['ceUse'] !=
              'raw-period-and-number-corroboration-only; currency not assigned' ||
          proof['profile'] != 'exact-pureun-ofs-20230315000460-v1' ||
          proof['coverSha256'] != coverSha ||
          proof['statementSha256'] != statementSha ||
          proof['combinedSha256'] != digest ||
          proof['ceWholeProfit'] != '20081583946' ||
          proof['ceEndingEquity'] != '309400868380' ||
          proof['ceOpeningEquity'] != '296326259447' ||
          proof['ceTableIndex'] != 5 ||
          proof['ceCurrentStartRow'] != 21 ||
          proof['ceCurrentEndRow'] != 30 ||
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
          p['printedAmount'] != printedAmounts[key] ||
          row['account_nm'] != p['printedAccount'] ||
          _compact(row['account_nm'].toString()) !=
              _compact(printedLabels[key] ?? '') ||
          p['tableIndex'] !=
              ({'assets', 'liabilities', 'equity'}.contains(key)
                  ? 1
                  : key == 'operatingCashFlow'
                  ? 7
                  : 3) ||
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
