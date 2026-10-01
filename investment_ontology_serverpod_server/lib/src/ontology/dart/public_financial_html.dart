/// Validated strict subsets of receipt-bound annual and half-year DART HTML.
/// The caller must validate corpCode against both official viewer shells; the
/// financial HTML cover supplies the company name but contains no corpCode.
/// HTML has no XBRL identifiers: every returned account_id remains null.
abstract final class PublicFinancialHtml {
  static String _text(String html) => html
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String _compact(String text) => text.replaceAll(RegExp(r'\s+'), '');
  static void _source(Uri uri, String receipt) {
    if (uri.scheme != 'https' ||
        uri.host != 'dart.fss.or.kr' ||
        uri.path != '/report/viewer.do' ||
        uri.queryParameters['rcpNo'] != receipt ||
        !RegExp(r'^\d{14}$').hasMatch(receipt) ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasPort ||
        ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd'].any(
          (key) => uri.queryParametersAll[key]?.length != 1,
        ) ||
        !const [
          'dart3.xsd',
          'dart4.xsd',
        ].contains(uri.queryParameters['dtd']) ||
        ['dcmNo', 'eleId', 'offset', 'length'].any(
          (key) => !RegExp(r'^\d+$').hasMatch(uri.queryParameters[key] ?? ''),
        )) {
      throw const FormatException('Unbound official HTML source');
    }
  }

  static List<Map<String, dynamic>> parse({
    required String coverHtml,
    required String statementHtml,
    required Uri coverSource,
    required Uri statementSource,
    required String receipt,
    required String corpCode,
    required String companyName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    _source(coverSource, receipt);
    _source(statementSource, receipt);
    if (coverSource.queryParameters['dcmNo'] !=
            statementSource.queryParameters['dcmNo'] ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Document identity mismatch');
    }
    final cover = _compact(_text(coverHtml));
    String date(DateTime d) =>
        '${d.year}년${d.month.toString().padLeft(2, '0')}월${d.day.toString().padLeft(2, '0')}일';
    if (!cover.contains('사업보고서') ||
        !cover.contains(companyName) ||
        !cover.contains('${date(periodStart)}부터${date(periodEnd)}까지') ||
        periodEnd.difference(periodStart).inDays < 364 ||
        periodEnd.difference(periodStart).inDays > 366) {
      throw const FormatException('Company annual cover mismatch');
    }
    final coverCompany = RegExp(r'회사명:(.*?)대표이사:').firstMatch(cover)?.group(1);
    if (!{'(주)$companyName', '주식회사$companyName'}.contains(coverCompany)) {
      throw const FormatException('Exact company cover mismatch');
    }
    final term = RegExp(r'\(제(\d+)기\)').firstMatch(cover)?.group(1);
    if (term == null) throw const FormatException('Missing current term');
    final text = _compact(_text(statementHtml));
    if (!(consolidated
            ? text.startsWith('2.연결재무제표')
            : text.startsWith('4.재무제표')) ||
        !text.contains('주식회사$companyName${consolidated ? '와그종속기업' : ''}') ||
        !text.contains('제$term기${date(periodEnd)}현재')) {
      throw const FormatException('Statement basis or period mismatch');
    }
    final titles = RegExp(
      '제$term기(\\d{4}년\\d{2}월\\d{2}일)(현재|부터(\\d{4}년\\d{2}월\\d{2}일)까지)',
    ).allMatches(text).toList();
    if (titles.isEmpty ||
        titles.any(
          (m) => m.group(2) == '현재'
              ? m.group(1) != date(periodEnd)
              : m.group(1) != date(periodStart) ||
                    m.group(3) != date(periodEnd),
        )) {
      throw const FormatException('Current statement title period mismatch');
    }
    final rows = <Map<String, dynamic>>[];
    final amounts = <String, BigInt>{};
    var index = 0;
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml)) {
      final tableIndex = index++;
      final tr =
          RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
              .allMatches(table.group(1)!)
              .map(
                (r) =>
                    RegExp(
                          r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
                          caseSensitive: false,
                          dotAll: true,
                        )
                        .allMatches(r.group(1)!)
                        .map((c) => _text(c.group(1)!))
                        .toList(),
              )
              .toList();
      if (tr.isEmpty || tr.first.isEmpty || _compact(tr.first.first) != '과목') {
        continue;
      }
      final currentColumns = [
        for (var i = 0; i < tr.first.length; i++)
          if (_compact(tr.first[i]) == '제$term기') i,
      ];
      if (currentColumns.length > 1) {
        throw const FormatException('Ambiguous duplicate current header');
      }
      final column = currentColumns.isEmpty ? -1 : currentColumns.single;
      if (column < 1) {
        continue;
      } // Equity statements have capital columns.
      final labels = tr
          .where((r) => r.isNotEmpty)
          .map((r) => _compact(r.first))
          .toSet();
      final String kind;
      final Set<String> wanted;
      if (labels.contains('자산총계') && labels.contains('부채총계')) {
        kind = 'BS';
        wanted = {'자산총계', '부채총계', '자본총계'};
      } else if (labels.contains('매출액') && labels.contains('영업이익')) {
        kind = 'CIS';
        wanted = {'매출액', '영업이익', '당기순이익'};
      } else if (labels.contains('영업활동으로인한현금흐름')) {
        kind = 'CF';
        wanted = {'영업활동으로인한현금흐름', '유형자산의취득'};
      } else {
        continue;
      }
      final spans = RegExp(
        r'''(?:rowspan|colspan)\s*=\s*["']?(\d+)''',
        caseSensitive: false,
      ).allMatches(table.group(1)!);
      if (spans.any((m) => int.parse(m.group(1)!) != 1)) {
        throw const FormatException('Unsupported spanning financial cells');
      }
      final preceding = _compact(
        _text(statementHtml.substring(0, table.start)),
      );
      final units = RegExp(r'\(단위:([^)]*)\)').allMatches(preceding).toList();
      if (units.isEmpty || units.last.group(1) != '원') {
        throw const FormatException('Unsupported statement unit');
      }
      for (final row in tr.skip(1)) {
        if (row.isEmpty || !wanted.contains(_compact(row.first))) {
          continue;
        }
        if (row.length != tr.first.length || column >= row.length) {
          throw const FormatException('Ambiguous current column');
        }
        final value = row[column].trim();
        if (!RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$|^-?\d+$').hasMatch(value) ||
            value.startsWith('(') != value.endsWith(')')) {
          throw const FormatException('Malformed current amount');
        }
        final amount = BigInt.parse(
          value.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
        );
        final label = _compact(row.first);
        if (amounts.containsKey(label)) {
          throw const FormatException('Duplicate core row');
        }
        amounts[label] = amount;
        rows.add({
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '${periodEnd.year}',
          'reprt_code': '11011',
          'account_id': null,
          'account_nm': row.first,
          'account_detail': '-',
          'sj_div': kind,
          'thstrm_nm':
              '${periodStart.toIso8601String().substring(0, 10)}~${periodEnd.toIso8601String().substring(0, 10)}',
          'thstrm_amount': amount.toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource.toString(),
            'tableIndex': tableIndex,
            'columnLabel': tr.first[column],
            'printedLabel': row.first,
            'printedAmount': value,
            'basis': consolidated ? 'CFS' : 'OFS',
          },
        });
      }
    }
    if (!{
          '자산총계',
          '부채총계',
          '자본총계',
          '매출액',
          '영업이익',
          '당기순이익',
          '영업활동으로인한현금흐름',
        }.every(amounts.containsKey) ||
        amounts['자산총계'] != amounts['부채총계']! + amounts['자본총계']!) {
      throw const FormatException(
        'Missing core rows or balance sheet identity mismatch',
      );
    }
    return rows;
  }

  /// Narrow half-year support with explicit period/term and a bounded header grid.
  /// The caller validates corpCode from the official shell before supplying HTML.
  static List<Map<String, dynamic>> parseHalfYear({
    required String coverHtml,
    required String statementHtml,
    required Uri coverSource,
    required Uri statementSource,
    required String receipt,
    required String corpCode,
    required String companyName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    _source(coverSource, receipt);
    _source(statementSource, receipt);
    if (consolidated ||
        coverSource.queryParameters['dcmNo'] !=
            statementSource.queryParameters['dcmNo'] ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Unsupported half-year basis or identity');
    }
    String printedDate(DateTime d) =>
        '${d.year}년${d.month.toString().padLeft(2, '0')}월${d.day.toString().padLeft(2, '0')}일';
    final cover = _compact(_text(coverHtml));
    final company = RegExp(r'회사명:(.*?)대표이사:').firstMatch(cover)?.group(1);
    final terms = RegExp(r'\(제(\d+)기(?:반기|2분기)?\)').allMatches(cover).toList();
    if (!cover.contains('반기보고서') ||
        terms.length != 1 ||
        !{'(주)$companyName', '주식회사$companyName'}.contains(company) ||
        !cover.contains(
          '${printedDate(periodStart)}부터${printedDate(periodEnd)}까지',
        ) ||
        periodStart != DateTime.utc(periodEnd.year, 1, 1) ||
        periodEnd != DateTime.utc(periodEnd.year, 6, 30)) {
      throw const FormatException('Exact half-year cover mismatch');
    }
    final term = terms.single.group(1)!;
    // Scope must be an explicitly labelled primary statement node, never notes.
    final headings = RegExp(
      r'<P\b[^>]*class=["\x27]section-2["\x27][^>]*>.*?</P>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).toList();
    final starts = headings
        .where((m) => _compact(_text(m.group(0)!)) == '4.재무제표')
        .toList();
    if (starts.length != 1) {
      throw const FormatException('Ambiguous separate statement scope');
    }
    final later = headings.where((m) => m.start > starts.single.start).toList();
    final end = later.isEmpty ? statementHtml.length : later.first.start;
    if (later.isNotEmpty &&
        _compact(_text(later.first.group(0)!)) != '5.재무제표주석') {
      throw const FormatException('Unexpected statement boundary');
    }
    final scope = statementHtml.substring(starts.single.start, end);
    final text = _compact(_text(scope));
    if (!text.contains('주식회사$companyName(단위:원)') ||
        !text.contains('제$term기반기말${printedDate(periodEnd)}현재') ||
        !text.contains(
          '제$term기반기${printedDate(periodStart)}부터${printedDate(periodEnd)}까지',
        )) {
      throw const FormatException('Half-year title/basis period mismatch');
    }
    final titles = RegExp(
      '제$term기반기(?:말)?(\\d{4}년\\d{2}월\\d{2}일)(현재|부터(\\d{4}년\\d{2}월\\d{2}일)까지)',
    ).allMatches(text).toList();
    if (titles.length < 3 ||
        titles.any(
          (m) => m.group(2) == '현재'
              ? m.group(1) != printedDate(periodEnd)
              : m.group(1) != printedDate(periodStart) ||
                    m.group(3) != printedDate(periodEnd),
        )) {
      throw const FormatException('Conflicting half-year statement titles');
    }
    BigInt? numeric(String value) {
      final v = value.trim();
      if (v.isEmpty || v == '-') return null;
      if (!RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$|^-?\d+$').hasMatch(v) ||
          v.startsWith('(') != v.endsWith(')')) {
        throw const FormatException('Malformed current monetary cell');
      }
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final result = <Map<String, dynamic>>[];
    final values = <String, BigInt>{};
    var tableIndex = 0;
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(scope)) {
      final index = tableIndex++;
      final rawFirstCell = RegExp(
        r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(table.group(1)!);
      if (rawFirstCell == null ||
          _compact(_text(rawFirstCell.group(1)!)) != '과목') {
        continue;
      }
      final grid = _FinancialHtmlGrid.parse(table.group(1)!);
      if (grid.isEmpty ||
          grid.first.isEmpty ||
          _compact(grid.first.first?.text ?? '') != '과목') {
        continue;
      }
      final headers = grid.first
          .whereType<_FinancialHtmlCell>()
          .where(
            (c) =>
                _compact(c.text) == '제$term기반기' ||
                _compact(c.text) == '제$term기반기말',
          )
          .toSet();
      if (headers.length != 1) {
        throw const FormatException('Ambiguous current half-year header');
      }
      final header = headers.single;
      if (header.colspan != 2 || header.column != 2 || grid.first.length != 6) {
        throw const FormatException('Unsupported half-year header layout');
      }
      final labels = grid
          .map((r) => r.isEmpty ? '' : _compact(r.first?.text ?? ''))
          .toSet();
      final String kind;
      final Set<String> wanted;
      if (labels.contains('자산총계') && labels.contains('부채총계')) {
        kind = 'BS';
        wanted = {'자산총계', '부채총계', '자본총계'};
      } else if (labels.contains('매출액') && labels.contains('영업이익')) {
        kind = 'CIS';
        wanted = {'매출액', '영업이익', '반기순이익'};
      } else if (labels.contains('영업활동으로인한현금흐름')) {
        kind = 'CF';
        wanted = {'영업활동으로인한현금흐름', '유형자산의취득'};
      } else {
        continue;
      }
      final preceding = _compact(_text(scope.substring(0, table.start)));
      final units = RegExp(r'\(단위:([^)]*)\)').allMatches(preceding).toList();
      if (units.isEmpty || units.last.group(1) != '원') {
        throw const FormatException('Unknown half-year unit');
      }
      if (kind == 'CIS' &&
          (grid.length < 2 ||
              !_compact(grid[1][2]?.text ?? '').startsWith('3개월') ||
              _compact(grid[1][3]?.text ?? '') != '누적')) {
        throw const FormatException('Ambiguous three-month/cumulative columns');
      }
      for (final row in grid) {
        if (row.isEmpty || !wanted.contains(_compact(row.first?.text ?? ''))) {
          continue;
        }
        if (row.length != 6 || row.any((c) => c == null)) {
          throw const FormatException('Incomplete half-year row grid');
        }
        if (row[2]!.rowspan != 1 ||
            row[3]!.rowspan != 1 ||
            row[2]!.colspan != 1 ||
            row[3]!.colspan != 1) {
          throw const FormatException('Spanning current monetary cells');
        }
        final label = _compact(row.first!.text);
        if (values.containsKey(label)) {
          throw const FormatException('Duplicate half-year core row');
        }
        final amount = kind == 'CIS' ? numeric(row[2]!.text) : null;
        final cumulative = kind == 'CIS' ? numeric(row[3]!.text) : null;
        final BigInt value;
        if (kind == 'CIS') {
          if (amount == null || cumulative == null) {
            throw const FormatException('Missing half-year income amount');
          }
          value = cumulative;
        } else {
          final group = row.sublist(2, 4).toSet();
          if (group.any((c) => c!.rowspan != 1 || c.colspan != 1)) {
            throw const FormatException('Spanning current amount');
          }
          final amounts = group
              .map((c) => numeric(c!.text))
              .whereType<BigInt>()
              .toList();
          if (amounts.length != 1) {
            throw const FormatException('Ambiguous current amount group');
          }
          value = amounts.single;
        }
        values[label] = value;
        result.add({
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '${periodEnd.year}',
          'reprt_code': '11012',
          'account_id': null,
          'account_nm': row.first!.text,
          'account_detail': '-',
          'sj_div': kind,
          'thstrm_nm': kind == 'CIS'
              ? '제$term기 반기 3개월'
              : kind == 'BS'
              ? periodEnd.toIso8601String().substring(0, 10)
              : '${periodStart.toIso8601String().substring(0, 10)}~${periodEnd.toIso8601String().substring(0, 10)}',
          'thstrm_amount': (amount ?? value).toString(),
          if (kind == 'CIS') 'thstrm_add_amount': cumulative.toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource.toString(),
            'tableIndex': index,
            'printedLabel': row.first!.text,
            'currentTerm': header.text,
            'basis': 'OFS',
            'periodStart': periodStart.toIso8601String().substring(0, 10),
            'periodEnd': periodEnd.toIso8601String().substring(0, 10),
            'quarterColumn': kind == 'CIS' ? row[2]!.column : null,
            'cumulativeColumn': kind == 'CIS' ? row[3]!.column : null,
            'printedCurrentCells': row
                .sublist(2, 4)
                .map((c) => c!.text)
                .toList(),
          },
        });
      }
    }
    if (!{
          '자산총계',
          '부채총계',
          '자본총계',
          '매출액',
          '영업이익',
          '반기순이익',
          '영업활동으로인한현금흐름',
        }.every(values.containsKey) ||
        values['자산총계'] != values['부채총계']! + values['자본총계']!) {
      throw const FormatException('Half-year core missing or balance mismatch');
    }
    return result;
  }

  /// Standard annual layouts verified against five primary CFS/OFS examples.
  /// Requires current-term monetary groups, whole-income rows and printed units.
  /// This intentionally does not accept arbitrary financial prose or notes.
  static List<Map<String, dynamic>> parseStandardAnnual({
    required String coverHtml,
    required String statementHtml,
    required Uri coverSource,
    required Uri statementSource,
    required String receipt,
    required String corpCode,
    required String companyName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    _source(coverSource, receipt);
    _source(statementSource, receipt);
    if (coverSource.queryParameters['dcmNo'] !=
            statementSource.queryParameters['dcmNo'] ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Annual document identity mismatch');
    }
    String legalName(String name) =>
        _compact(name)
            .replaceFirst(RegExp(r'^(?:주식회사|\(주\)|㈜)'), '')
            .replaceFirst(RegExp(r'(?:주식회사|\(주\)|㈜)$'), '');
    DateTime? sourceDate(String text) {
      final m = RegExp(r'^(\d{4})년(\d{1,2})월(\d{1,2})일$').firstMatch(text);
      if (m == null) return null;
      final year = int.parse(m.group(1)!),
          month = int.parse(m.group(2)!),
          day = int.parse(m.group(3)!);
      final date = DateTime.utc(year, month, day);
      return date.year == year && date.month == month && date.day == day
          ? date
          : null;
    }

    final cover = _compact(_text(coverHtml));
    final company = RegExp(r'회사명:(.*?)대표이사:').firstMatch(cover)?.group(1);
    final terms = RegExp(r'\(제(\d+)기\)').allMatches(cover).toList();
    final periods = RegExp(
      r'사업연도(\d{4}년\d{1,2}월\d{1,2}일)부터(\d{4}년\d{1,2}월\d{1,2}일)까지',
    ).allMatches(cover).toList();
    if (!cover.contains('사업보고서') ||
        company == null ||
        legalName(company) != legalName(companyName) ||
        terms.length != 1 ||
        periods.length != 1 ||
        sourceDate(periods.single.group(1)!) != periodStart ||
        sourceDate(periods.single.group(2)!) != periodEnd ||
        periodEnd.difference(periodStart).inDays < 0 ||
        periodEnd.difference(periodStart).inDays + 1 > 367) {
      throw const FormatException('Exact annual company/period cover mismatch');
    }
    final term = terms.single.group(1)!;
    final expected = consolidated ? '2.연결재무제표' : '4.재무제표';
    final next = consolidated ? '3.연결재무제표주석' : '5.재무제표주석';
    final headings = RegExp(
      r'<P\b[^>]*class=["\x27]section-2["\x27][^>]*>.*?</P>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).toList();
    final starts = headings
        .where((m) => _compact(_text(m.group(0)!)) == expected)
        .toList();
    if (starts.length != 1) {
      throw const FormatException('Annual statement basis scope mismatch');
    }
    final after = headings.where((m) => m.start > starts.single.start).toList();
    if (after.isNotEmpty && _compact(_text(after.first.group(0)!)) != next) {
      throw const FormatException('Unexpected annual statement boundary');
    }
    final scope = statementHtml.substring(
      starts.single.start,
      after.isEmpty ? statementHtml.length : after.first.start,
    );
    final text = _compact(_text(scope));
    final titlePattern = RegExp(
      '제$term(?:\\(당\\))?(?:당기|기)(?:기말|말)?:?(\\d{4}년\\d{1,2}월\\d{1,2}일)(현재|부터(\\d{4}년\\d{1,2}월\\d{1,2}일)까지)',
    );
    final titles = titlePattern.allMatches(text).toList();
    if (titles.length < 3 ||
        !titles.any((m) => m.group(2) == '현재') ||
        titles.any(
          (m) => m.group(2) == '현재'
              ? sourceDate(m.group(1)!) != periodEnd
              : sourceDate(m.group(1)!) != periodStart ||
                    sourceDate(m.group(3)!) != periodEnd,
        )) {
      throw const FormatException(
        'Annual current statement title period mismatch',
      );
    }
    String label(String raw) =>
        _compact(raw)
            .replaceFirst(RegExp(r'^[Ⅰ-ⅫIVXLCDM\d]+[.)]'), '')
            .replaceFirst(RegExp(r'\(주(?:석)?\d+(?:,\d+)*\)$'), '');
    const accounts = {
      '자산총계': ('assets', 'BS'),
      '부채총계': ('liabilities', 'BS'),
      '자본총계': ('equity', 'BS'),
      '매출액': ('revenue', 'CIS'),
      '영업수익': ('revenue', 'CIS'),
      '영업이익': ('operating', 'CIS'),
      '영업손익': ('operating', 'CIS'),
      '영업손실': ('operating', 'CIS'),
      '영업이익(손실)': ('operating', 'CIS'),
      '당기순이익': ('profit', 'CIS'),
      '당기순손익': ('profit', 'CIS'),
      '당기순손실': ('profit', 'CIS'),
      '당기순이익(손실)': ('profit', 'CIS'),
      '영업활동으로인한현금흐름': ('cfo', 'CF'),
      '영업활동현금흐름': ('cfo', 'CF'),
      '영업활동으로인한현금흐름(순액)': ('cfo', 'CF'),
      '유형자산취득': ('capex', 'CF'),
      '유형자산의취득': ('capex', 'CF'),
    };
    BigInt? money(String text) {
      final v = text.trim();
      if (v.isEmpty || v == '-') return null;
      if (!RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$|^-?\d+$').hasMatch(v) ||
          v.startsWith('(') != v.endsWith(')')) {
        throw const FormatException('Malformed annual current amount');
      }
      return BigInt.parse(
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    final result = <Map<String, dynamic>>[];
    final values = <String, BigInt>{};
    final seenKinds = <String>{};
    var tableIndex = 0;
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(scope)) {
      final index = tableIndex++;
      final first = RegExp(
        r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(table.group(1)!);
      if (first == null ||
          !{'과목', '구분', '계정과목'}.contains(_compact(_text(first.group(1)!)))) {
        continue;
      }
      final grid = _FinancialHtmlGrid.parse(table.group(1)!);
      if (grid.isEmpty) continue;
      final labels = grid
          .map((r) => r.isEmpty ? '' : label(r.first?.text ?? ''))
          .toSet();
      final String kind;
      if (labels.contains('자산총계') &&
          labels.contains('부채총계') &&
          labels.contains('자본총계')) {
        kind = 'BS';
      } else if ((labels.contains('매출액') || labels.contains('영업수익')) &&
          (['영업이익', '영업이익(손실)', '영업손익', '영업손실'].any(labels.contains))) {
        kind = 'CIS';
      } else if (labels.contains('영업활동으로인한현금흐름') ||
          labels.contains('영업활동으로인한현금흐름(순액)') ||
          labels.contains('영업활동현금흐름')) {
        kind = 'CF';
      } else {
        continue;
      }
      if (!seenKinds.add(kind)) {
        throw const FormatException('Duplicate annual primary statement');
      }
      final headers = grid.first
          .whereType<_FinancialHtmlCell>()
          .where(
            (c) =>
                RegExp('^제$term(?:\\(당\\))?기(?:기말|말)?\$')
                    .hasMatch(_compact(c.text)),
          )
          .toSet();
      if (headers.length != 1) {
        throw const FormatException('Ambiguous annual current header');
      }
      final current = headers.single;
      if (current.column < 1 || current.colspan > 2 || current.rowspan != 1) {
        throw const FormatException('Unsupported annual current group');
      }
      final preceding = _compact(_text(scope.substring(0, table.start)));
      final statementTitles = {
        '재무상태표': 'BS',
        '손익계산서': 'CIS',
        '자본변동표': 'CE',
        '현금흐름표': 'CF',
      };
      var sectionStart = -1;
      String? sectionKind;
      for (final title in statementTitles.entries) {
        final at = preceding.lastIndexOf(title.key);
        if (at > sectionStart) {
          sectionStart = at;
          sectionKind = title.value;
        }
      }
      if (sectionStart < 0 || sectionKind != kind) {
        throw const FormatException('Annual primary statement heading missing');
      }
      final localPrefix = preceding.substring(sectionStart);
      final localTitles = titlePattern.allMatches(localPrefix).toList();
      if (localTitles.isEmpty ||
          (kind == 'BS') != (localTitles.last.group(2) == '현재')) {
        throw const FormatException('Annual primary statement title mismatch');
      }
      final units = RegExp(r'\(단위:([^)]*)\)').allMatches(localPrefix).toList();
      final printedUnit = units.isEmpty ? null : units.last.group(1);
      final multiplier = switch (printedUnit) {
        '원' => BigInt.one,
        '천원' => BigInt.from(1000),
        '백만원' => BigInt.from(1000000),
        _ => throw const FormatException('Unsupported annual monetary unit'),
      };
      // A second logical header row must bind current term to actual year/month.
      if (grid.first.first?.rowspan == 2) {
        if (grid.length < 2 || current.colspan != 1) {
          throw const FormatException('Unsupported annual multirow header');
        }
        final expectedPeriod =
            '(${(periodStart.year % 100).toString().padLeft(2, '0')}.${periodStart.month.toString().padLeft(2, '0')}~${(periodEnd.year % 100).toString().padLeft(2, '0')}.${periodEnd.month.toString().padLeft(2, '0')})';
        if (_compact(grid[1][current.column]?.text ?? '') != expectedPeriod) {
          throw const FormatException(
            'Annual current subheader period mismatch',
          );
        }
      }
      for (final row in grid.skip(1)) {
        if (row.isEmpty) continue;
        final account = accounts[label(row.first?.text ?? '')];
        if (account == null || account.$2 != kind) continue;
        if (values.containsKey(account.$1)) {
          throw const FormatException(
            'Duplicate annual whole-company core row',
          );
        }
        if (row.length != grid.first.length ||
            row.any((c) => c == null) ||
            current.column + current.colspan > row.length) {
          throw const FormatException('Incomplete annual current row');
        }
        final cells = row
            .sublist(current.column, current.column + current.colspan)
            .toSet();
        if (cells.any((c) => c!.rowspan != 1 || c.colspan != 1)) {
          throw const FormatException('Spanning annual current monetary cell');
        }
        final amounts = cells
            .map((c) => money(c!.text))
            .whereType<BigInt>()
            .toList();
        if (amounts.length != 1) {
          throw const FormatException(
            'Ambiguous annual current monetary group',
          );
        }
        final printedValue = amounts.single;
        final lossLabel = const {
          '영업손실',
          '당기순손실',
        }.contains(label(row.first!.text));
        final value =
            (lossLabel ? -printedValue.abs() : printedValue) * multiplier;
        values[account.$1] = value;
        result.add({
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '${periodEnd.year}',
          'reprt_code': '11011',
          'account_id': null,
          'account_nm': row.first!.text,
          'account_detail': '-',
          'sj_div': kind,
          'thstrm_nm': kind == 'BS'
              ? periodEnd.toIso8601String().substring(0, 10)
              : '${periodStart.toIso8601String().substring(0, 10)}~${periodEnd.toIso8601String().substring(0, 10)}',
          'thstrm_amount': value.toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': statementSource.toString(),
            'tableIndex': index,
            'printedLabel': row.first!.text,
            'signRule': lossLabel
                ? 'printed-loss-label-negative-absolute'
                : 'printed-numeric-sign',
            'printedAmountBeforeSignRule': printedValue.toString(),
            'printedCurrentCells': cells.map((c) => c!.text).toList(),
            'currentColumn': current.column,
            'currentColumnSpan': current.colspan,
            'currentHeader': current.text,
            'basis': consolidated ? 'CFS' : 'OFS',
            'unit': printedUnit,
            'unitMultiplier': multiplier.toString(),
            'printedAmount': printedValue.toString(),
            'normalizedUnit': '원',
            'periodStart': periodStart.toIso8601String().substring(0, 10),
            'periodEnd': periodEnd.toIso8601String().substring(0, 10),
          },
        });
      }
    }
    if (!{
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operating',
          'profit',
          'cfo',
        }.every(values.containsKey) ||
        values['assets'] != values['liabilities']! + values['equity']!) {
      throw const FormatException(
        'Annual primary core missing or balance mismatch',
      );
    }
    return result;
  }
}

class _FinancialHtmlCell {
  _FinancialHtmlCell(this.text, this.column, this.rowspan, this.colspan);
  final String text;
  final int column, rowspan, colspan;
}

abstract final class _FinancialHtmlGrid {
  static List<List<_FinancialHtmlCell?>> parse(String html) {
    final rows = RegExp(
      r'<TR\b[^>]*>(.*?)</TR>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html).toList();
    if (rows.length > 300) {
      throw const FormatException('Oversize financial grid');
    }
    final grid = <List<_FinancialHtmlCell?>>[];
    for (var r = 0; r < rows.length; r++) {
      while (grid.length <= r) {
        grid.add([]);
      }
      var column = 0;
      for (final cell in RegExp(
        r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(rows[r].group(1)!)) {
        int span(String name) {
          final matches = RegExp(
            '$name\\s*=\\s*["\x27]?(\\d+)',
            caseSensitive: false,
          ).allMatches(cell.group(1)!).toList();
          if (matches.length > 1) {
            throw const FormatException('Duplicate cell span');
          }
          final n = matches.isEmpty ? 1 : int.parse(matches.single.group(1)!);
          if (n < 1 || n > (name == 'rowspan' ? 2 : 6)) {
            throw const FormatException('Unsupported cell span');
          }
          return n;
        }

        while (column < grid[r].length && grid[r][column] != null) {
          column++;
        }
        final rs = span('rowspan'), cs = span('colspan');
        if (column + cs > 10 || r + rs > rows.length) {
          throw const FormatException('Out-of-bounds financial grid');
        }
        final parsed = _FinancialHtmlCell(
          PublicFinancialHtml._text(cell.group(2)!),
          column,
          rs,
          cs,
        );
        for (var y = r; y < r + rs; y++) {
          while (grid.length <= y) {
            grid.add([]);
          }
          while (grid[y].length < column + cs) {
            grid[y].add(null);
          }
          for (var x = column; x < column + cs; x++) {
            if (grid[y][x] != null) {
              throw const FormatException('Overlapping financial cells');
            }
            grid[y][x] = parsed;
          }
        }
        column += cs;
      }
    }
    return grid;
  }
}
