import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable official sources whose flow captions print only the closing date.
/// The annual start comes from the cover and independently dated whole CE.
abstract final class ContentsOnCorroboratedFlowPeriod {
  static const profiles =
      <
        String,
        ({
          int year,
          String coverUri,
          String bodyUri,
          String coverSha,
          String bodySha,
        })
      >{
        '20220323000557': (
          year: 2021,
          coverUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220323000557&dcmNo=8495645&eleId=1&offset=805&length=4028&dtd=dart3.xsd',
          bodyUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220323000557&dcmNo=8495645&eleId=21&offset=161853&length=73179&dtd=dart3.xsd',
          coverSha: '3f22fa35b41f75e85e7f270b0f4cd5b6c13f218b24d6f718c50d5288b519113e',
          bodySha: 'edc986031a7d8e29629d470c86069b422a410652c34ac970c52b7912d59f94b7',
        ),
        '20240321001908': (
          year: 2023,
          coverUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321001908&dcmNo=9755088&eleId=1&offset=964&length=4037&dtd=dart4.xsd',
          bodyUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321001908&dcmNo=9755088&eleId=21&offset=171919&length=67320&dtd=dart4.xsd',
          coverSha: '8ce265eb796913c4834bfbc793e3198979bcd704e4c57a55132d1066e6ade99b',
          bodySha: 'b0db31e47bcc93fd015248030fcb5415fc1b637cf09aac2aca080e0c86a30213',
        ),
        '20250321000964': (
          year: 2024,
          coverUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321000964&dcmNo=10445656&eleId=1&offset=953&length=4509&dtd=dart4.xsd',
          bodyUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321000964&dcmNo=10445656&eleId=21&offset=160560&length=69138&dtd=dart4.xsd',
          coverSha: '469ac257e22f2666a8447a0c0743d6f36c79b60e68c921bacf6e69ee8e351951',
          bodySha: '545fbbf353e384b73d1cd1085abbbe3ab00bce7832630071adb169d5dacb8a16',
        ),
        '20260323001088': (
          year: 2025,
          coverUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260323001088&dcmNo=11165467&eleId=1&offset=964&length=4506&dtd=dart4.xsd',
          bodyUri: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260323001088&dcmNo=11165467&eleId=21&offset=150434&length=66097&dtd=dart4.xsd',
          coverSha: '4e801c41a4f8c374d6b7c78fba9dc6ddc0159b4a550e5fe01950d36938b42adf',
          bodySha: '54451573f3405f4584b72b7db6981feafcc1844270fea4bf0f255df8d14ac1bf',
        ),
      };
  static String compact(String s) => s
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
    final p = profiles[targetReceipt];
    if (p == null ||
        companyCode != '00991225' ||
        consolidated ||
        start != DateTime.utc(p.year, 1, 1) ||
        end != DateTime.utc(p.year, 12, 31) ||
        coverSource.toString() != p.coverUri ||
        statementSource.toString() != p.bodyUri) {
      throw const FormatException('ContentsOn exact source identity mismatch');
    }
    final c = compact(cover), text = compact(body), term = p.year - 2011;
    if (!c.contains('${p.year}년01월01일부터${p.year}년12월31일까지') ||
        !c.contains('제$term기') ||
        !c.contains('회사명:(주)더콘텐츠온대표이사:')) {
      throw const FormatException('ContentsOn annual cover mismatch');
    }
    if (RegExp('제$term기${p.year}년12월31일현재').allMatches(text).length != 4 ||
        RegExp(r'\(단위:원\)').allMatches(text).length != 4) {
      throw const FormatException('ContentsOn each caption/unit mismatch');
    }
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(body)
        .map(
          (m) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(m[1]!).map((x) => compact(x[1]!)).toList(),
        )
        .toList();
    List<String> unique(String label) {
      final matches = rows
          .where((r) => r.isNotEmpty && r.first == label)
          .toList();
      if (matches.length != 1) {
        throw FormatException('ContentsOn supporting row ambiguous: $label');
      }
      return matches.single;
    }

    BigInt number(String s) {
      if (!RegExp(r'^(?:[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
          .hasMatch(s)) {
        throw const FormatException(
          'ContentsOn supporting monetary cell invalid',
        );
      }
      return BigInt.parse(
        s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    BigInt current(String label) {
      final r = unique(label);
      if (r.length != 4) {
        throw const FormatException('ContentsOn current column ambiguous');
      }
      return number(r[1]);
    }

    final first = rows.indexWhere(
      (r) => r.isNotEmpty && r.first == '${p.year}.01.01(당기초)',
    );
    final last = rows.indexWhere(
      (r) => r.isNotEmpty && r.first == '${p.year}.12.31(당기말)',
    );
    if (first < 0 ||
        last <= first ||
        rows
                .where((r) => r.isNotEmpty && r.first == '${p.year}.01.01(당기초)')
                .length !=
            1 ||
        rows
                .where((r) => r.isNotEmpty && r.first == '${p.year}.12.31(당기말)')
                .length !=
            1) {
      throw const FormatException('ContentsOn independently dated CE missing');
    }
    final opening = rows[first], closing = rows[last];
    final ni = rows
        .sublist(first + 1, last)
        .where((r) => r.isNotEmpty && {'당기순이익', '당기순이익(순손실)'}.contains(r.first))
        .toList();
    if (opening.length != 6 ||
        closing.length != 6 ||
        ni.length != 1 ||
        ni.single.length != 6 ||
        ni.single.sublist(1, 4).any((s) => s != '-') ||
        ni.single[4] != ni.single[5]) {
      throw const FormatException(
        'ContentsOn CE whole-column evidence invalid',
      );
    }
    final open = number(opening.last),
        close = number(closing.last),
        profit = number(ni.single.last);
    final equity = unique('자본총계');
    if (equity.length != 4 ||
        number(equity[1]) != close ||
        number(equity[2]) != open ||
        current('자산총계') != current('부채총계') + close ||
        current('Ⅹ.당기순이익(손실)') != profit) {
      throw const FormatException('ContentsOn BS/CIS/CE contradiction');
    }
    for (final r in [opening, closing]) {
      if (r
              .sublist(1, 5)
              .fold<BigInt>(
                BigInt.zero,
                (a, s) => a + (s == '-' ? BigInt.zero : number(s)),
              ) !=
          number(r.last)) {
        throw const FormatException(
          'ContentsOn CE components/whole contradiction',
        );
      }
    }
    final cash = unique(p.year == 2021 ? '현금및현금성자산' : '현금및현금성자산(주석3)');
    final begin = current('Ⅴ.기초의현금'),
        finish = current('Ⅵ.기말의현금'),
        increase = current('Ⅳ.현금의증가(감소)(Ⅰ+Ⅱ+Ⅲ)');
    final operating = current('Ⅰ.영업활동으로인한현금흐름'),
        investing = current('Ⅱ.투자활동으로인한현금흐름'),
        financing = current('Ⅲ.재무활동으로인한현금흐름');
    if (cash.length != 4 ||
        number(cash[1]) != finish ||
        number(cash[2]) != begin ||
        begin + increase != finish ||
        operating + investing + financing != increase) {
      throw const FormatException(
        'ContentsOn CF/BS cash rollforward contradiction',
      );
    }
    if (sha256.convert(utf8.encode(cover)).toString() != p.coverSha ||
        sha256.convert(utf8.encode(body)).toString() != p.bodySha) {
      throw const FormatException('ContentsOn immutable digest mismatch');
    }
    return {
      'policy': 'contents-on-exact-cover-ce-cash-corroboration-v1',
      'source': statementSource.toString(),
      'basis': 'OFS',
      'periodStart': '${p.year}-01-01',
      'periodEnd': '${p.year}-12-31',
      'flowCaptionPrintedStart': false,
      'startEvidence': 'annual cover and CE printed opening date',
      'openingEquity': open.toString(),
      'closingEquity': close.toString(),
      'currentProfit': profit.toString(),
      'openingCash': begin.toString(),
      'closingCash': finish.toString(),
      'cashIncrease': increase.toString(),
      'operatingCash': operating.toString(),
      'investingCash': investing.toString(),
      'financingCash': financing.toString(),
      'sourceSha256': p.bodySha,
    };
  }
}
