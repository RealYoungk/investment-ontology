import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable official source. Flow captions print the end, not the start.
abstract final class DoznCorroboratedFlowPeriod {
  static const receipt = '20250328001780';
  static const corp = '01563667';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250328001780&dcmNo=10474522&eleId=1&offset=950&length=4543&dtd=dart4.xsd';
  static const statementUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250328001780&dcmNo=10474522&eleId=21&offset=558030&length=53877&dtd=dart4.xsd';
  static const consolidatedUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250328001780&dcmNo=10474522&eleId=19&offset=202829&length=70331&dtd=dart4.xsd';
  static const consolidatedSha =
      '39948296402bc3478a4388387ba6482d6beecfe0cb7510aed5453ee29a42e7c9';
  static const coverSha =
      'e8bc263ff9e02446abb967017bd2459d352fa7518b3591cb4c5890c7d08d3b80';
  static const statementSha =
      'e11debec5b65e7752c4fbfee9d2d92fe4b7d3879c5108ddf3bca19d1bc348e10';
  static String _compact(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', '')
      .replaceAll(RegExp(r'\s+'), '');
  static Map<String, dynamic> verify({
    required String cover,
    required String body,
    required Uri coverSource,
    required Uri statementSource,
    required String targetReceipt,
    required String companyCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) {
    if (targetReceipt != receipt ||
        companyCode != corp ||
        start != DateTime.utc(2024, 1, 1) ||
        end != DateTime.utc(2024, 12, 31) ||
        coverSource.toString() != coverUri ||
        statementSource.toString() !=
            (consolidated ? consolidatedUri : statementUri)) {
      throw const FormatException('Dozn exact source identity mismatch');
    }
    final c = _compact(cover);
    if (!c.contains('2024년01월01일부터2024년12월31일까지') ||
        !c.contains('제8기') ||
        !c.contains('주식회사더즌')) {
      throw const FormatException('Dozn annual cover period mismatch');
    }
    final text = _compact(body);
    if (RegExp(r'제8기:2024년12월31일현재').allMatches(text).length != 4 ||
        RegExp(r'\(단위:원\)').allMatches(text).length != 4) {
      throw const FormatException('Dozn each statement caption/unit mismatch');
    }
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (m) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(m[1]!).map((cell) => _compact(cell[1]!)).toList(),
        )
        .toList();
    List<String> row(String label) {
      final matches = rows
          .where((r) => r.isNotEmpty && r.first == label)
          .toList();
      if (matches.length != 1) {
        throw FormatException('Dozn supporting row ambiguous: $label');
      }
      return matches.single;
    }

    BigInt number(String label, {bool last = false}) {
      final r = row(label);
      if (r.length < 2) {
        throw FormatException('Dozn supporting current column missing: $label');
      }
      final n = last ? r.last : r[1];
      if (!RegExp(r'^(?:[0-9,]+|\([0-9,]+\))$').hasMatch(n)) {
        throw FormatException('Dozn supporting number invalid: $label');
      }
      return BigInt.parse(
        n.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final opening = number('2024.01.01(기초자본)', last: true);
    final closing = number('2024.12.31(기말자본)', last: true);
    final profitRows = rows
        .where(
          (r) =>
              r.isNotEmpty &&
              r.first == '당기순이익' &&
              r.length == (consolidated ? 9 : 6),
        )
        .toList();
    if (profitRows.length != 3 ||
        profitRows.last.last !=
            (consolidated ? '9,917,308,588' : '10,348,432,461') ||
        opening !=
            BigInt.parse((consolidated ? '30759747402' : '30431701786')) ||
        closing !=
            BigInt.parse((consolidated ? '41367841817' : '41377666510'))) {
      throw const FormatException(
        'Dozn CE opening/closing/profit contradiction',
      );
    }
    final bsEquity = row('자본총계');
    if (bsEquity.length != 4 ||
        BigInt.parse(bsEquity[1].replaceAll(',', '')) != closing ||
        BigInt.parse(bsEquity[2].replaceAll(',', '')) != opening ||
        number('자산총계') != number('부채총계') + closing) {
      throw const FormatException(
        'Dozn BS/CE equity and balance contradiction',
      );
    }
    final cash = row('현금및현금성자산');
    final begin = number('기초의현금');
    final finish = number('기말의현금');
    final increase = number('현금의증가');
    final fx = number('현금및현금성자산의환율변동효과');
    if (cash.length != 4 ||
        cash[1] != (consolidated ? '80,683,745,769' : '79,158,449,860') ||
        cash[2] != (consolidated ? '62,036,528,499' : '61,061,036,103') ||
        begin != BigInt.parse((consolidated ? '62036528499' : '61061036103')) ||
        finish !=
            BigInt.parse((consolidated ? '80683745769' : '79158449860')) ||
        begin + increase + fx != finish) {
      throw const FormatException('Dozn CF/BS cash rollforward contradiction');
    }
    if (number('영업활동으로인한현금흐름') +
            number(consolidated ? '투자활동으로인한현금흐름' : '투자활동현금흐름') +
            number(consolidated ? '재무활동으로인한현금흐름' : '재무활동현금흐름') !=
        increase) {
      throw const FormatException(
        'Dozn CF activities rollforward contradiction',
      );
    }
    if (sha256.convert(utf8.encode(cover)).toString() != coverSha ||
        sha256.convert(utf8.encode(body)).toString() !=
            (consolidated ? consolidatedSha : statementSha)) {
      throw const FormatException('Dozn immutable source digest mismatch');
    }
    return {
      'policy': 'dozn-exact-cover-ce-cash-corroboration-v1',
      'source': statementSource.toString(),
      'basis': consolidated ? 'CFS' : 'OFS',
      'periodStart': '2024-01-01',
      'periodEnd': '2024-12-31',
      'flowCaptionPrintedStart': false,
      'startEvidence': 'annual cover and CE printed opening date',
      'openingEquity': opening.toString(),
      'closingEquity': closing.toString(),
      'openingEquityEqualsPreviousBS': true,
      'closingEquityEqualsCurrentBS': true,
      'ceProfitEqualsCisWholeProfit': true,
      'currentProfit': consolidated ? '9917308588' : '10348432461',
      'openingCash': begin.toString(),
      'closingCash': finish.toString(),
      'cashIncrease': increase.toString(),
      'cashFx': fx.toString(),
      'operatingCash': number('영업활동으로인한현금흐름').toString(),
      'investingCash': number(consolidated ? '투자활동으로인한현금흐름' : '투자활동현금흐름')
          .toString(),
      'financingCash': number(consolidated ? '재무활동으로인한현금흐름' : '재무활동현금흐름')
          .toString(),
      'openingCashEqualsPreviousBS': true,
      'closingCashEqualsCurrentBS': true,
      'sourceSha256': consolidated ? consolidatedSha : statementSha,
    };
  }
}
