part of 'public_financial_html.dart';

/// Invoked only after the public cover/basis/URI/current-title guards pass.
/// Does not infer gross revenue from the banking/securities net-income parts.
abstract final class _RevenuePartialAnnual {
  static List<Map<String, dynamic>>? parse({
    required String html,
    required String originalHtml,
    required String originalCover,
    required Uri source,
    required String receipt,
    required String corp,
    required String term,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    String compact(String value) => PublicFinancialHtml._compact(value);
    String normalized(String value) => FinancialAccounts.normalizedName(value);
    BigInt? money(String value) {
      final v = compact(value);
      if (v.isEmpty || v == '-') return null;
      if (!RegExp(
        r'^(?:-?(?:\d+|\d{1,3}(?:,\d{3})+)|\((?:\d+|\d{1,3}(?:,\d{3})+)\))$',
      ).hasMatch(v)) {
        throw const FormatException('Partial core malformed printed amount');
      }
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    const roles = {
      '자산총계': ('assets', 'BS'),
      '부채총계': ('liabilities', 'BS'),
      '자본총계': ('equity', 'BS'),
      '영업이익': ('operating', 'CIS'),
      '영업이익(손실)': ('operating', 'CIS'),
      '영업손익': ('operating', 'CIS'),
      '영업손실': ('operating', 'CIS'),
      '당기순이익': ('profit', 'CIS'),
      '당기순이익(손실)': ('profit', 'CIS'),
      '당기순손실': ('profit', 'CIS'),
      '영업활동으로인한현금흐름': ('cfo', 'CF'),
      '영업활동현금흐름': ('cfo', 'CF'),
      '영업활동으로부터의현금흐름': ('cfo', 'CF'),
    };
    const revenueNames = {'매출', '매출액', '영업수익', '수익(매출액)'};
    final values = <String, BigInt>{};
    final rows = <Map<String, dynamic>>[];
    final statements = <String>{};
    Map<String, dynamic>? missing;
    final tables = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html).toList();
    ({String caption, String unit, BigInt multiplier}) caption(
      int at,
      String kind,
    ) {
      final prefix = compact(PublicFinancialHtml._text(html.substring(0, at)));
      final titleMatches = RegExp(
        r'신탁재무상태표|신탁계산서|연결재무상태표|재무상태표|연결포괄손익계산서|포괄손익계산서|연결손익계산서|손익계산서|연결현금흐름표|현금흐름표|연결자본변동표|자본변동표',
      ).allMatches(prefix).toList();
      if (titleMatches.isEmpty) {
        throw const FormatException(
          'Partial primary statement caption missing',
        );
      }
      final title = titleMatches.last;
      if (title[0]!.startsWith('신탁') ||
          (consolidated && !title[0]!.startsWith('연결')) ||
          (!consolidated && title[0]!.startsWith('연결'))) {
        throw const FormatException(
          'Partial primary issuer statement basis/scope mismatch',
        );
      }
      final expectedTitles = switch (kind) {
        'BS' => {'재무상태표', '연결재무상태표'},
        'CIS' => {'포괄손익계산서', '손익계산서', '연결포괄손익계산서', '연결손익계산서'},
        'CF' => {'현금흐름표', '연결현금흐름표'},
        'CE' => {'자본변동표', '연결자본변동표'},
        _ => <String>{},
      };
      if (!expectedTitles.contains(title[0])) {
        throw const FormatException(
          'Partial primary statement caption role mismatch',
        );
      }
      final body = prefix.substring(title.start);
      final unit = RegExp(r'\(단위[:：](원|천원|백만원)\)$').firstMatch(body)?[1];
      final multiplier = switch (unit) {
        '원' => BigInt.one,
        '천원' => BigInt.from(1000),
        '백만원' => BigInt.from(1000000),
        _ => throw const FormatException(
          'Partial primary independent money unit missing',
        ),
      };
      return (caption: body, unit: unit!, multiplier: multiplier);
    }

    for (var tableIndex = 0; tableIndex < tables.length; tableIndex++) {
      final t = tables[tableIndex];
      final g = _FinancialHtmlGrid.parse(t[1]!);
      if (g.isEmpty) continue;
      final names = g.map((r) => normalized(r.first?.text ?? '')).toSet();
      final kind = names.containsAll({'자산총계', '부채총계', '자본총계'})
          ? 'BS'
          : names.any((n) => roles[n]?.$1 == 'operating') &&
                names.any((n) => roles[n]?.$1 == 'profit')
          ? 'CIS'
          : names.any((n) => roles[n]?.$1 == 'cfo')
          ? 'CF'
          : null;
      if (kind == null) continue;
      if (!statements.add(kind)) {
        throw const FormatException(
          'Partial duplicate whole primary statement',
        );
      }
      final context = caption(t.start, kind);
      final current = g.first
          .whereType<_FinancialHtmlCell>()
          .where(
            (c) =>
                RegExp('^제$term(?:\\(당\\))?기(?:기말|말)?\$')
                    .hasMatch(compact(c.text)),
          )
          .toSet();
      if (current.length != 1) {
        throw const FormatException('Partial current term header ambiguous');
      }
      final header = current.single;
      List<_FinancialHtmlCell> currentCells(List<_FinancialHtmlCell?> r) {
        if (r.length != g.first.length ||
            r.any((c) => c == null) ||
            header.column + header.colspan > r.length) {
          throw const FormatException('Partial current row malformed');
        }
        final cells = r
            .sublist(header.column, header.column + header.colspan)
            .toSet()
            .cast<_FinancialHtmlCell>()
            .toList();
        if (cells.any((c) => c.colspan != 1 || c.rowspan != 1)) {
          throw const FormatException('Partial spanning current amount');
        }
        return cells;
      }

      final grossRows = kind == 'CIS'
          ? g
                .skip(1)
                .where(
                  (r) => revenueNames.contains(normalized(r.first?.text ?? '')),
                )
                .toList()
          : <List<_FinancialHtmlCell?>>[];
      if (kind == 'CIS') {
        if (grossRows.length > 1) {
          throw const FormatException('Partial multiple gross revenue labels');
        }
        if (grossRows.isNotEmpty) {
          final cells = currentCells(grossRows.single);
          if (cells.any(
                (c) => compact(c.text).isNotEmpty && compact(c.text) != '-',
              ) ||
              cells.where((c) => compact(c.text) == '-').length != 1) {
            // A numeric total must use the full-core path, never partial fallback.
            return null;
          }
          missing = {
            'reason': 'printed-dash-unavailable',
            'printedLabel': grossRows.single.first!.text,
            'printedCurrentCells': cells.map((c) => c.text).toList(),
          };
        } else {
          missing = {
            'reason': 'no-recognized-single-whole-revenue-row',
            'wholeRevenueLabelsChecked': revenueNames.toList(),
            'actualPrintedStatementLabels': g
                .skip(1)
                .map((r) => r.first?.text ?? '')
                .toList(),
          };
        }
      }
      for (final r in g.skip(1)) {
        final role = roles[normalized(r.first?.text ?? '')];
        if (role == null || role.$2 != kind) continue;
        if (values.containsKey(role.$1)) {
          throw const FormatException('Partial duplicate mandatory core');
        }
        final cells = currentCells(r);
        final amounts = cells
            .map((c) => money(c.text))
            .whereType<BigInt>()
            .toList();
        if (amounts.length != 1) {
          throw const FormatException('Partial current amount ambiguous');
        }
        final normalizedValue = amounts.single * context.multiplier;
        // Positive loss labels are not silently converted in this partial path.
        if (normalized(r.first!.text).endsWith('손실') &&
            normalizedValue > BigInt.zero) {
          throw const FormatException(
            'Partial printed loss sign contradiction',
          );
        }
        values[role.$1] = normalizedValue;
        rows.add({
          'rcept_no': receipt,
          'corp_code': corp,
          'bsns_year': '${end.year}',
          'reprt_code': '11011',
          'account_id': null,
          'account_nm': r.first!.text,
          'account_detail': '-',
          'sj_div': kind,
          'thstrm_nm': kind == 'BS'
              ? end.toIso8601String().substring(0, 10)
              : '${start.toIso8601String().substring(0, 10)}~${end.toIso8601String().substring(0, 10)}',
          'thstrm_amount': normalizedValue.toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': source.toString(),
            'tableIndex': tableIndex,
            'printedLabel': r.first!.text,
            'currentColumn': header.column,
            'currentColumnSpan': header.colspan,
            'currentHeader': header.text,
            'printedCurrentCells': cells.map((c) => c.text).toList(),
            'basis': consolidated ? 'CFS' : 'OFS',
            'unit': context.unit,
            'unitMultiplier': context.multiplier.toString(),
            'normalizedUnit': '원',
            'periodStart': start.toIso8601String().substring(0, 10),
            'periodEnd': end.toIso8601String().substring(0, 10),
          },
        });
      }
    }
    if (missing == null ||
        values.length != 6 ||
        !values.keys.toSet().containsAll({
          'assets',
          'liabilities',
          'equity',
          'operating',
          'profit',
          'cfo',
        }) ||
        values['assets'] != values['liabilities']! + values['equity']!) {
      return null;
    }
    final wholeProofs = <Map<String, dynamic>>[];
    DateTime? rowDate(String raw) {
      final m = RegExp(
        r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?(?:\(당기초\)|\(당기말\))?$',
      ).firstMatch(compact(raw));
      if (m == null) return null;
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

    for (var i = 0; i < tables.length; i++) {
      final t = tables[i], g = _FinancialHtmlGrid.parse(t[1]!);
      if (g.isEmpty ||
          !{'과목', '과목(주1)'}.contains(compact(g.first.first?.text ?? '')) ||
          compact(g.first.last?.text ?? '') != '총계') {
        continue;
      }
      final context = caption(t.start, 'CE');
      if (!context.caption.startsWith(consolidated ? '연결자본변동표' : '자본변동표')) {
        continue;
      }
      final starts = [
        for (var r = 1; r < g.length; r++)
          if (rowDate(g[r].first?.text ?? '') == start) r,
      ];
      final ends = [
        for (var r = 1; r < g.length; r++)
          if (rowDate(g[r].first?.text ?? '') == end) r,
      ];
      if (starts.length != 1 ||
          ends.length != 1 ||
          ends.single <= starts.single) {
        throw const FormatException(
          'Partial independent CE current dates ambiguous',
        );
      }
      final profits = g
          .sublist(starts.single + 1, ends.single)
          .where(
            (r) => {'당기순이익', '당기순손실', '당기순이익(손실)'}.contains(
              normalized(r.first?.text ?? '')
                  .replaceFirst(RegExp(r'^\([0-9]+\)'), ''),
            ),
          )
          .toList();
      if (profits.length != 1) {
        throw const FormatException(
          'Partial independent CE whole profit ambiguous',
        );
      }
      BigInt whole(List<_FinancialHtmlCell?> r) {
        final col = g.first.length - 1;
        if (r.length != g.first.length ||
            r[col] == null ||
            r[col]!.column != col ||
            r[col]!.colspan != 1 ||
            r[col]!.rowspan != 1) {
          throw const FormatException(
            'Partial independent CE total column missing',
          );
        }
        final value = money(r[col]!.text);
        if (value == null) {
          throw const FormatException(
            'Partial independent CE total unavailable',
          );
        }
        return value * context.multiplier;
      }

      final profit = whole(profits.single), equity = whole(g[ends.single]);
      if (profit != values['profit'] || equity != values['equity']) {
        throw const FormatException(
          'Partial independent CE whole profit equity conflict',
        );
      }
      wholeProofs.add({
        'tableIndex': i,
        'wholeColumn': g.first.length - 1,
        'rawHeader': g.first.map((c) => c?.text).toList(),
        'printedProfitCells': profits.single.map((c) => c?.text).toList(),
        'printedClosingCells': g[ends.single].map((c) => c?.text).toList(),
        'wholeProfit': profit.toString(),
        'closingEquity': equity.toString(),
        'unit': context.unit,
        'currentStartLabel': g[starts.single].first!.text,
        'currentEndLabel': g[ends.single].first!.text,
      });
    }
    if (wholeProofs.length != 1) {
      throw const FormatException('Partial independent whole CE proof missing');
    }
    final bodySha = sha256.convert(utf8.encode(originalHtml)).toString();
    for (final row in rows) {
      (row['html_provenance'] as Map<String, dynamic>)['partialCoreProof'] = {
        'rule': 'source-six-with-unavailable-whole-revenue-v1',
        'corpCode': corp,
        'receipt': receipt,
        'basis': consolidated ? 'CFS' : 'OFS',
        'source': source.toString(),
        'bodySha256': bodySha,
        'sourceDigest': sha256
            .convert(utf8.encode('$originalCover\n$originalHtml'))
            .toString(),
        'periodStart': start.toIso8601String().substring(0, 10),
        'periodEnd': end.toIso8601String().substring(0, 10),
        'missingAccount': 'revenue',
        'revenueUnavailable': missing,
        'wholeCE': wholeProofs.single,
      };
    }
    return rows;
  }
}
