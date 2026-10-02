import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two pinned own CFS sources. Whole column is never the parent's or NCI column.
abstract final class HistoricalCfsWholeProof {
  static const _profiles = {
    '20240319000287': (
      corp: '00321204',
      year: 2023,
      term: 26,
      url: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240319000287&dcmNo=9729336&eleId=19&offset=196240&length=103475&dtd=dart4.xsd',
      sha: '913c63362c29784cbd022fa89ca7a28ec1c6202678e2e79a44e8b3547ca2f8b3',
      header: '구분|자본금|연결자본조정|연결기타포괄손익누계액|연결이익잉여금|비지배지분|총계',
      start: 'Ⅰ.2023.01.01(26기초)',
      end: 'Ⅲ.2023.12.31(26기말)',
      profit: '당기순이익',
      caption: '자본변동표제26기2023.01.01부터2023.12.31까지',
      owner: '관악산업주식회사와그종속기업(단위:원)',
    ),
    '20230714000217': (
      corp: '01085442',
      year: 2022,
      term: 17,
      url: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230714000217&dcmNo=9349856&eleId=21&offset=309543&length=90592&dtd=dart3.xsd',
      sha: '3ac7c8e40987923e8ec2c19706cf25de43218b734bc88a2fd6503835fa1d25f6',
      header: '과목|자본금|연결자본잉여금|연결자본조정|연결이익잉여금|비지배분|총계',
      start: '2022.01.01(당기초)',
      end: '2022.12.31(당기말)',
      profit: '당기순이익(손실)',
      caption: '자본변동표제17(당)기2022년01월01일부터2022년12월31일까지',
      owner: '주식회사휴벡셀과그종속기업(단위:원)',
    ),
  };
  static bool eligible(String receipt) => _profiles.containsKey(receipt);
  static String _text(String v) => v
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', '')
      .replaceAll(RegExp(r'\s+'), '');
  static Map<String, dynamic> verify({
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required Uri source,
    required String html,
    required BigInt netIncome,
    required BigInt equity,
  }) {
    final p = _profiles[receipt];
    void guard(bool valid, String reason) {
      if (!valid) {
        throw FormatException('Historical CFS whole CE proof: $reason');
      }
    }

    guard(p != null, 'unknown source');
    final profile = p!;
    guard(
      corp == profile.corp &&
          start == DateTime.utc(profile.year) &&
          end == DateTime.utc(profile.year, 12, 31) &&
          source.toString() == profile.url,
      'owner/period/URI mismatch',
    );
    guard(
      sha256.convert(utf8.encode(html)).toString() == profile.sha,
      'raw SHA mismatch',
    );
    final proofs = <Map<String, dynamic>>[];
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final preceding = _text(html.substring(0, table.start));
      final at = preceding.lastIndexOf('자본변동표');
      if (at < 0 ||
          [
            '재무상태표',
            '손익계산서',
            '현금흐름표',
          ].any((s) => preceding.lastIndexOf(s) > at)) {
        continue;
      }
      final rows = <List<String>>[];
      final invalidSpans = <bool>[];
      for (final tr in RegExp(
        r'<TR\b[^>]*>(.*?)</TR>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(table[1]!)) {
        final cells = RegExp(
          r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(tr[1]!).toList();
        if (cells.isEmpty) {
          continue;
        }
        invalidSpans.add(
          !cells.every(
            (c) => !RegExp(
              r'(?:colspan|rowspan)\s*=\s*["\x27]?[2-9]',
              caseSensitive: false,
            ).hasMatch(c[1]!),
          ),
        );
        rows.add(cells.map((c) => _text(c[2]!)).toList());
      }
      if (rows.isEmpty || rows.first.join('|') != profile.header) {
        continue;
      }
      guard(!invalidSpans.any((v) => v), 'cell span mismatch');
      final caption = preceding.substring(at);
      guard(
        caption.startsWith(profile.caption) && caption.endsWith(profile.owner),
        'current caption/unit mismatch',
      );
      int unique(String label) {
        final found = [
          for (var i = 1; i < rows.length; i++)
            if (rows[i].first == label) i,
        ];
        guard(found.length == 1, 'current row ambiguous');
        return found.single;
      }

      final a = unique(profile.start), b = unique(profile.end);
      guard(a < b, 'current row order');
      final profits = [
        for (var i = a + 1; i < b; i++)
          if (rows[i].first == profile.profit) i,
      ];
      guard(profits.length == 1, 'current whole profit ambiguous');
      BigInt whole(int i) {
        guard(rows[i].length == 7, 'whole total shape');
        var v = rows[i][6];
        final neg = v.startsWith('(') && v.endsWith(')');
        if (neg) {
          v = v.substring(1, v.length - 1);
        }
        guard(
          RegExp(r'^\d{1,3}(?:,\d{3})*$|^\d+$').hasMatch(v),
          'whole money malformed',
        );
        final value = BigInt.parse(v.replaceAll(',', ''));
        return neg ? -value : value;
      }

      final profit = whole(profits.single), closing = whole(b);
      guard(
        profit == netIncome && closing == equity,
        'whole profit/equity contradiction',
      );
      proofs.add({
        'rule': 'exact-historical-CFS-whole-CE-v1',
        'receipt': receipt,
        'corpCode': corp,
        'source': source.toString(),
        'sha256': profile.sha,
        'periodStart': '${profile.year}-01-01',
        'periodEnd': '${profile.year}-12-31',
        'currentTerm': profile.term,
        'wholeColumn': 6,
        'parentComponentColumns': [1, 2, 3, 4],
        'nonControllingColumn': 5,
        'printedCurrentProfitCells': rows[profits.single],
        'printedClosingEquityCells': rows[b],
        'header': rows.first,
        'currentProfit': profit.toString(),
        'closingEquity': closing.toString(),
        'currentStartLabel': profile.start,
        'currentEndLabel': profile.end,
      });
    }
    guard(proofs.length == 1, 'whole CE source missing or ambiguous');
    return proofs.single;
  }
}
