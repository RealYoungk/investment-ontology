import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exact printed 당기/당기말 dates; no numerical term is synthesized.
abstract final class ProtiaPrintedCurrentPeriod {
  static const receipt = '20230320000571', corp = '01267958';
  static const coverUri =
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230320000571&dcmNo=9074672&eleId=1&offset=800&length=4077&dtd=dart3.xsd',
      statementUri =
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230320000571&dcmNo=9074672&eleId=21&offset=352125&length=42899&dtd=dart3.xsd';
  static const coverSha =
          '6d17e2cdba6665d2fa575ed2e83da25cbcea6c4562e1311e6e81673374252890',
      statementSha =
          'e7aee95915b0715675aac1af27b6b5763f0a7106dc1c8b7f86ece54e39bcd715';
  static String compact(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', '')
      .replaceAll(RegExp(r'\s+'), '');
  static Map<String, dynamic> verify({
    required String targetReceipt,
    required String companyCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String cover,
    required String body,
  }) {
    if (targetReceipt != receipt ||
        companyCode != corp ||
        consolidated ||
        start != DateTime.utc(2022, 1, 1) ||
        end != DateTime.utc(2022, 12, 31) ||
        coverSource.toString() != coverUri ||
        statementSource.toString() != statementUri) {
      throw const FormatException('Protia exact source identity mismatch');
    }
    final text = compact(body), c = compact(cover);
    if (!c.contains('2022년01월01일부터2022년12월31일까지') ||
        !c.contains('주식회사프로테옴텍') ||
        RegExp(r'당기말2022년12월31일현재').allMatches(text).length != 1 ||
        RegExp(r'당기2022년1월1일부터2022년12월31일까지').allMatches(text).length != 4) {
      throw const FormatException(
        'Protia printed current full period mismatch',
      );
    }
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (m) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(m[1]!).map((n) => compact(n[1]!)).toList(),
        )
        .toList();
    List<String> row(String label) {
      final r = rows.where((x) => x.isNotEmpty && x.first == label).toList();
      if (r.length != 1) {
        throw FormatException('Protia ambiguous supporting row: $label');
      }
      return r.single;
    }

    BigInt amount(String label, int column) {
      final r = row(label);
      if (column >= r.length ||
          !RegExp(r'^(?:[0-9,]+|\([0-9,]+\))$').hasMatch(r[column])) {
        throw const FormatException('Protia current supporting amount missing');
      }
      return BigInt.parse(
        r[column].replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final opening = amount('2022.01.01(당기초)', 5),
        closing = amount('2022.12.31(당기말)', 5),
        profit = amount('당기순이익', 5);
    final headers = rows
        .where(
          (r) =>
              r.length == 4 &&
              r[0] == '구분' &&
              r[1] == '주석' &&
              r[2].startsWith('당기') &&
              r[3].startsWith('전기'),
        )
        .toList();
    if (headers.length != 3 ||
        headers.where((r) => r[2] == '당기말').length != 1 ||
        headers.where((r) => r[2] == '당기').length != 2) {
      throw const FormatException(
        'Protia unique primary current headers mismatch',
      );
    }
    if (opening != amount('자본총계', 3) ||
        closing != amount('자본총계', 2) ||
        profit != amount('Ⅷ.당기순이익(손실)', 2) ||
        amount('자산총계', 2) != amount('부채총계', 2) + closing) {
      throw const FormatException(
        'Protia primary/CE equity and profit contradiction',
      );
    }
    if (sha256.convert(utf8.encode(cover)).toString() != coverSha ||
        sha256.convert(utf8.encode(body)).toString() != statementSha) {
      throw const FormatException('Protia immutable source digest mismatch');
    }
    return {
      'policy': 'protia-printed-current-full-period-v1',
      'source': statementUri,
      'basis': 'OFS',
      'periodStart': '2022-01-01',
      'periodEnd': '2022-12-31',
      'printedCurrentHeader': '당기/당기말',
      'numericTermSynthesized': false,
      'openingEquity': opening.toString(),
      'closingEquity': closing.toString(),
      'currentProfit': profit.toString(),
      'sourceSha256': statementSha,
    };
  }
}
