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
    bool requireWhole = false,
    bool strictCfsWholeHeader = false,
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

    String gridBody(String raw) {
      if (!requireWhole ||
          consolidated ||
          !compact(PublicFinancialHtml._text(raw)).contains('지배기업소유주지분')) {
        return raw;
      }
      return raw.replaceAllMapped(
        RegExp(
          r'<TR\b[^>]*>\s*<TD\b([^>]*)>(.*?)</TD>\s*</TR>',
          caseSensitive: false,
          dotAll: true,
        ),
        (m) {
          final attrs = m[1]!;
          final spans = RegExp(
            r'colspan\s*=\s*["\x27]?(\d+)',
            caseSensitive: false,
          ).allMatches(attrs).toList();
          if (spans.length != 1 ||
              spans.single[1] != '7' ||
              RegExp(r'rowspan\s*=', caseSensitive: false).hasMatch(attrs) ||
              compact(PublicFinancialHtml._text(m[2]!)) !=
                  '자본에직접반영된소유주와의거래등:') {
            return m[0]!;
          }
          return '';
        },
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
      '연결당기순이익': ('profit', 'CIS'),
      '당기순이익(손실)': ('profit', 'CIS'),
      '당기순손실': ('profit', 'CIS'),
      '영업활동으로인한현금흐름': ('cfo', 'CF'),
      '영업활동현금흐름': ('cfo', 'CF'),
      '영업활동으로부터의현금흐름': ('cfo', 'CF'),
      '유형자산취득': ('capex', 'CF'),
      '유형자산의취득': ('capex', 'CF'),
    };
    const revenueNames = {'매출', '매출액', '영업수익', '수익(매출액)'};
    final values = <String, BigInt>{};
    final rows = <Map<String, dynamic>>[];
    final statements = <String>{};
    final blankHeaders = <String>{};
    var annotatedWholeProfit = false;
    var fullwidthGrossPrefix = false;
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
      final ceUnits = kind == 'CE'
          ? RegExp(r'\(단위[:：]([^)]*)\)').allMatches(body).toList()
          : <RegExpMatch>[];
      // A declared CE may print prior/current equity tables consecutively under
      // one own statement heading and one explicit money-unit caption.
      final unit = kind == 'CE'
          ? (ceUnits.length == 1 ? ceUnits.single[1] : null)
          : RegExp(r'\(단위[:：](원|천원|백만원)\)$').firstMatch(body)?[1];
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
      final g = _FinancialHtmlGrid.parse(gridBody(t[1]!));
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
      final blank = compact(g.first.first?.text ?? '').isEmpty;
      if (blank) {
        if (g.first.length != 4 ||
            g.first.any((c) => c == null || c.colspan != 1 || c.rowspan != 1) ||
            compact(g.first[1]!.text) != '제$term기' ||
            compact(g.first[2]!.text) != '제${int.parse(term) - 1}기' ||
            compact(g.first[3]!.text) != '제${int.parse(term) - 2}기') {
          throw const FormatException('Whole blank primary header unsupported');
        }
        blankHeaders.add(kind);
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
          fullwidthGrossPrefix = RegExp(r'^[Ⅰ-ⅫIVXLCDM]+．')
              .hasMatch(compact(grossRows.single.first!.text));
          if (cells.any(
                (c) => compact(c.text).isNotEmpty && compact(c.text) != '-',
              ) ||
              cells.where((c) => compact(c.text) == '-').length != 1) {
            final amounts = cells
                .map((c) => money(c.text))
                .whereType<BigInt>()
                .toList();
            if (amounts.length != 1) {
              return null;
            }
            values['revenue'] = amounts.single * context.multiplier;
            rows.add({
              'rcept_no': receipt,
              'corp_code': corp,
              'bsns_year': '${end.year}',
              'reprt_code': '11011',
              'account_id': null,
              'account_nm': grossRows.single.first!.text,
              'account_detail': '-',
              'sj_div': 'CIS',
              'thstrm_nm':
                  '${start.toIso8601String().substring(0, 10)}~${end.toIso8601String().substring(0, 10)}',
              'thstrm_amount': values['revenue'].toString(),
              'currency': 'KRW',
              'html_provenance': {
                'source': source.toString(),
                'tableIndex': tableIndex,
                'printedLabel': grossRows.single.first!.text,
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
          } else {
            missing = {
              'reason': 'printed-dash-unavailable',
              'printedLabel': grossRows.single.first!.text,
              'printedCurrentCells': cells.map((c) => c.text).toList(),
            };
          }
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
        final printed = r.first?.text ?? '';
        if (RegExp(FinancialAccounts.adjustedProfitAnnotation).hasMatch(
          compact(printed)
              .replaceFirst(RegExp(r'^(Vlll|lll|[Ⅰ-ⅫIVXLCDM0-9]+)[.)．]'), ''),
        )) {
          annotatedWholeProfit = true;
        }
        final role = roles[normalized(printed)];
        if (role == null || role.$2 != kind) continue;
        if (role.$1 == 'capex' && !values.containsKey('revenue')) continue;
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
    final fullRecovery = values.containsKey('revenue');
    if (requireWhole && !fullRecovery) {
      return null;
    }
    if (fullRecovery &&
        !(blankHeaders.containsAll({'BS', 'CIS', 'CF'}) &&
                blankHeaders.length == 3 ||
            annotatedWholeProfit ||
            fullwidthGrossPrefix)) {
      return null;
    }
    if ((!fullRecovery && missing == null) ||
        values.length !=
            (fullRecovery ? (values.containsKey('capex') ? 8 : 7) : 6) ||
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
      final m =
          RegExp(
            r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?(?:\(당기초\)|\(당기말\)|\(전기말\)|\(기초자본\)|\(기말자본\))?$',
          ).firstMatch(
            compact(raw).replaceFirst(
              RegExp(r'^[Ⅰ-ⅫIVXLCDM]+[.)](?=20[0-9]{2}(?:년|\.))'),
              '',
            ),
          );
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
      final t = tables[i], g = _FinancialHtmlGrid.parse(gridBody(t[1]!));
      final ofWhole =
          fullRecovery &&
          !consolidated &&
          g.length > 2 &&
          compact(g.first.first?.text ?? '') == '과목' &&
          g.first.first?.rowspan == 2 &&
          g.first.length == 7 &&
          compact(g.first.last?.text ?? '') == '지배기업소유주지분' &&
          g.first.last?.colspan == 6 &&
          compact(g[1].last?.text ?? '') == '합계' &&
          !g
              .take(2)
              .expand((r) => r)
              .any((c) => compact(c?.text ?? '').contains('비지배'));
      if (g.isEmpty ||
          !{'과목', '과목(주1)'}.contains(compact(g.first.first?.text ?? '')) ||
          (compact(g.first.last?.text ?? '') != '총계' && !ofWhole)) {
        continue;
      }
      if (strictCfsWholeHeader) {
        final whole =
            g.length > 2 &&
            g[0].length == 8 &&
            g[1].length == 8 &&
            compact(g[0][0]?.text ?? '') == '과목' &&
            g[0][0]?.rowspan == 2 &&
            g[0][0]?.colspan == 1 &&
            identical(g[0][0], g[1][0]) &&
            compact(g[0][1]?.text ?? '') == '지배기업소유주지분' &&
            g[0][1]?.colspan == 5 &&
            g[0][1]?.rowspan == 1 &&
            [for (var c = 1; c <= 5; c++) identical(g[0][1], g[0][c])]
                .every((v) => v) &&
            compact(g[0][6]?.text ?? '') == '비지배지분' &&
            compact(g[0][7]?.text ?? '') == '총계' &&
            [6, 7].every(
              (c) =>
                  g[0][c]?.colspan == 1 &&
                  g[0][c]?.rowspan == 2 &&
                  identical(g[0][c], g[1][c]),
            ) &&
            [for (var c = 1; c <= 5; c++) compact(g[1][c]?.text ?? '')]
                    .join('|') ==
                '자본금|연결자본잉여금|연결자본조정|연결기타포괄손익누계액|연결이익잉여금' &&
            [
              for (var c = 1; c <= 5; c++)
                g[1][c]?.rowspan == 1 && g[1][c]?.colspan == 1,
            ].every((v) => v);
        if (!whole) {
          throw const FormatException('Exact CFS whole CE hierarchy mismatch');
        }
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
          if (rowDate(g[r].first?.text ?? '') == end &&
              !compact(g[r].first?.text ?? '').endsWith('(전기말)'))
            r,
      ];
      if (ends.isEmpty) continue;
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
            (r) => {'당기순이익', '연결당기순이익', '당기순손실', '당기순이익(손실)'}.contains(
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

      if (strictCfsWholeHeader) {
        final profitCells = profits.single;
        if ([for (var c = 1; c <= 4; c++) compact(profitCells[c]?.text ?? '')]
            .any((v) => v != '-')) {
          throw const FormatException(
            'Exact CFS profit whole attribution ambiguous',
          );
        }
        BigInt explicit(int c, List<_FinancialHtmlCell?> row) {
          if (row[c] == null ||
              row[c]!.column != c ||
              row[c]!.colspan != 1 ||
              row[c]!.rowspan != 1) {
            throw const FormatException('Exact CFS component column ambiguous');
          }
          final v = money(row[c]!.text);
          if (v == null) {
            throw const FormatException('Exact CFS component unavailable');
          }
          return v;
        }

        if (explicit(5, profitCells) + explicit(6, profitCells) !=
            explicit(7, profitCells)) {
          throw const FormatException(
            'Exact CFS parent and NCI profit total conflict',
          );
        }
        final closing = g[ends.single];
        if ([for (var c = 1; c <= 6; c++) explicit(c, closing)]
                .fold(BigInt.zero, (a, b) => a + b) !=
            explicit(7, closing)) {
          throw const FormatException(
            'Exact CFS closing components total conflict',
          );
        }
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
        if (ofWhole)
          'wholeOFSHeaderRows': g
              .take(2)
              .map((r) => r.map((c) => c?.text).toList())
              .toList(),
        if (ofWhole) 'classificationLiteral': '자본에 직접 반영된 소유주와의 거래 등:',
        if (ofWhole) 'classificationSourceUnmodified': true,
      });
    }
    if (wholeProofs.length != 1) {
      throw const FormatException('Partial independent whole CE proof missing');
    }
    final bodySha = sha256.convert(utf8.encode(originalHtml)).toString();
    for (final row in rows) {
      (row['html_provenance'] as Map<String, dynamic>)[fullRecovery
          ? 'wholeCoreProof'
          : 'partialCoreProof'] = {
        'rule': fullRecovery
            ? 'whole-core-independent-ce-v1'
            : 'source-six-with-unavailable-whole-revenue-v1',
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
        if (!fullRecovery) 'missingAccount': 'revenue',
        if (!fullRecovery) 'revenueUnavailable': missing,
        'wholeCE': wholeProofs.single,
        if (fullRecovery) 'primaryBlankHeaders': blankHeaders.toList(),
        if (fullRecovery) 'printedProfitAnnotation': annotatedWholeProfit,
        if (strictCfsWholeHeader)
          'wholeCfsHierarchy': 'own-parent-components5-nci6-whole-total7',
        if (fullRecovery)
          'uncollectedOptional': values.containsKey('capex')
              ? <String>[]
              : ['capex'],
      };
    }
    return rows;
  }
}
