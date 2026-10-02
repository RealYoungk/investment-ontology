/// Independent dates and whole totals, printed in the same separate statement.
/// This supplies no missing primary amount and never handles parent/NCI totals.
abstract final class AnnualEquityPeriod {
  static bool primaryDatesMatch(
    String prefix,
    String kind,
    DateTime start,
    DateTime end,
  ) {
    final dates = RegExp(r'(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?')
        .allMatches(prefix)
        .toList();
    if (dates.isEmpty) return true;
    DateTime? date(RegExpMatch m) {
      final d = DateTime.utc(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
      return d.year == int.parse(m[1]!) &&
              d.month == int.parse(m[2]!) &&
              d.day == int.parse(m[3]!)
          ? d
          : null;
    }

    return kind == 'BS'
        ? (date(dates.first) == end ||
              (dates.length >= 2 &&
                  date(dates.first) == start &&
                  date(dates[1]) == end))
        : dates.length >= 2 &&
              date(dates.first) == start &&
              date(dates[1]) == end;
  }

  static Map<String, dynamic>? verify({
    required String scope,
    required String term,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    if (consolidated) return null;
    String compact(String v) => v.replaceAll(RegExp(r'\s+'), '');
    String text(String v) => compact(
      v
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&#160;', ' ')
          .replaceAll('&amp;', '&'),
    );
    const headings = ['재무상태표', '손익계산서', '자본변동표', '현금흐름표'];
    const components = {
      '자본금',
      '자본잉여금',
      '자본조정',
      '기타자본',
      '기타자본항목',
      '기타불입자본',
      '기타포괄손익누계액',
      '이익잉여금',
      '결손금',
      '이익잉여금(결손금)',
      '이익잉여금(또는결손금)',
    };
    DateTime? date(String v) {
      final m = RegExp(
        r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?',
      ).firstMatch(v);
      if (m == null) return null;
      final d = DateTime.utc(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
      if (d.year != int.parse(m[1]!) ||
          d.month != int.parse(m[2]!) ||
          d.day != int.parse(m[3]!)) {
        return null;
      }
      return d;
    }

    BigInt? amount(String v) {
      if (!RegExp(r'^(?:-?\d{1,3}(?:,\d{3})*|-?\d+|\(\d{1,3}(?:,\d{3})*\))$')
          .hasMatch(v)) {
        return null;
      }
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final proofs = <Map<String, dynamic>>[];
    var index = 0;
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(scope)) {
      final tableIndex = index++;
      final prefix = text(scope.substring(0, table.start));
      final ce = prefix.lastIndexOf('자본변동표');
      if (ce < 0 ||
          headings
              .where((h) => h != '자본변동표')
              .any((h) => prefix.lastIndexOf(h) > ce)) {
        continue;
      }
      final local = prefix.substring(ce);
      final units = RegExp(r'\(단위[:：]([^)]*)\)').allMatches(local).toList();
      if (units.length != 1) continue;
      final multiplier = switch (units.single[1]) {
        '원' => BigInt.one,
        '천원' => BigInt.from(1000),
        '백만원' => BigInt.from(1000000),
        _ => null,
      };
      if (multiplier == null) continue;
      final rows = <List<String>>[];
      var spans = false;
      for (final row in RegExp(
        r'<TR\b[^>]*>(.*?)</TR>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(table[1]!)) {
        final cells = RegExp(
          r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(row[1]!).toList();
        if (cells.any(
          (c) => RegExp(
            r'(?:rowspan|colspan)\s*=\s*["\x27]?([2-9]|\d{2,})',
            caseSensitive: false,
          ).hasMatch(c[1]!),
        )) {
          spans = true;
        }
        rows.add(cells.map((c) => text(c[2]!)).toList());
      }
      if (spans ||
          rows.isEmpty ||
          rows.first.length < 5 ||
          rows.first.length > 9) {
        continue;
      }
      final header = rows.first;
      if (!{'과목', '구분', '내역'}.contains(header.first) ||
          !{'총계', '합계', '자본총계'}.contains(header.last) ||
          header
              .sublist(1, header.length - 1)
              .any((v) => !components.contains(v)) ||
          header.sublist(1, header.length - 1).toSet().length !=
              header.length - 2) {
        continue;
      }
      final begin = <int>[], finish = <int>[];
      for (var i = 1; i < rows.length; i++) {
        if (rows[i].length != header.length) continue;
        final label = rows[i].first;
        if (date(label) == start &&
            RegExp(r'\((?:당기초|기초|보고금액)\)$').hasMatch(label)) {
          begin.add(i);
        }
        if (date(label) == end && RegExp(r'\((?:당기말|기말)\)$').hasMatch(label)) {
          finish.add(i);
        }
      }
      if (begin.length != 1 ||
          finish.length != 1 ||
          begin.single >= finish.single) {
        continue;
      }
      if (rows.where((r) => r.isNotEmpty && r.first.contains('당기초')).length >
              1 ||
          rows.where((r) => r.isNotEmpty && r.first.contains('당기말')).length >
              1) {
        continue;
      }
      final profits = <int>[];
      for (var i = begin.single + 1; i < finish.single; i++) {
        if (rows[i].length == header.length &&
            {
              '당기순이익',
              '당기순손실',
              '당기순손익',
              '당기순이익(손실)',
              '당기순손익(손실)',
            }.contains(rows[i].first)) {
          profits.add(i);
        }
      }
      if (profits.length != 1) continue;
      final equity = amount(rows[finish.single].last),
          profit = amount(rows[profits.single].last);
      if (equity == null || profit == null) continue;
      proofs.add({
        'mode': 'separate-independent-printed-equity-period-v1',
        'tableIndex': tableIndex,
        'currentTerm': term,
        'periodStart': start.toIso8601String().substring(0, 10),
        'periodEnd': end.toIso8601String().substring(0, 10),
        'startRow': begin.single,
        'endRow': finish.single,
        'profitRow': profits.single,
        'wholeTotalColumn': header.length - 1,
        'wholeHeader': header.join('|'),
        'closingEquity': (equity * multiplier).toString(),
        'currentProfit': (profit * multiplier).toString(),
        'unit': units.single[1],
      });
    }
    return proofs.length == 1 ? proofs.single : null;
  }
}
