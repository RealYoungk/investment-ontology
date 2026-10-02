import 'public_issuer_legal_name.dart';
import 'bnk_six_core_profile.dart';
import 'verified_historical_company_identity.dart';

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
        [
          'rcpNo',
          'dcmNo',
          'eleId',
          'offset',
          'length',
          'dtd',
        ].any((key) => uri.queryParametersAll[key]?.length != 1) ||
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
    PublicIssuerLegalName? issuerProof,
  }) {
    if (receipt == BnkSixCoreProfile.receipt) {
      return BnkSixCoreProfile.parse(
        targetReceipt: receipt,
        companyCode: corpCode,
        companyName: companyName,
        consolidated: consolidated,
        start: periodStart,
        end: periodEnd,
        coverSource: coverSource,
        coverHtml: coverHtml,
        statementSource: statementSource,
        statementHtml: statementHtml,
      );
    }
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
      final m =
          RegExp(r'^(\d{4})년(\d{1,2})월(\d{1,2})일$').firstMatch(text) ??
          RegExp(r'^(\d{4})\.(\d{2})\.(\d{2})$').firstMatch(text);
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
    final company = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .firstMatch(cover)
        ?.group(1);
    final declaredIssuer = company == null
        ? null
        : issuerProof?.verify(
            receipt: receipt,
            corpCode: corpCode,
            masterName: companyName,
            printedName: company,
            coverSource: coverSource,
            coverHtml: coverHtml,
            periodStart: periodStart,
            periodEnd: periodEnd,
          );
    if (issuerProof != null && declaredIssuer == null) {
      throw const FormatException('Invalid raw official issuer evidence');
    }
    final terms = RegExp(r'\(제(\d+)기(?:사업보고서)?\)').allMatches(cover).toList();
    final periods = RegExp(
      r'사업연도((?:\d{4}년\d{1,2}월\d{1,2}일|\d{4}\.\d{2}\.\d{2}))부터((?:\d{4}년\d{1,2}월\d{1,2}일|\d{4}\.\d{2}\.\d{2}))까지',
    ).allMatches(cover).toList();
    if (!cover.contains('사업보고서') ||
        company == null ||
        (legalName(company) != legalName(companyName) &&
            declaredIssuer == null &&
            VerifiedHistoricalCompanyIdentity.evidence(
                  receipt: receipt,
                  corpCode: corpCode,
                  currentName: companyName,
                  printedName: company,
                  periodEnd: periodEnd,
                  consolidated: consolidated,
                  coverSource: coverSource,
                  coverHtml: coverHtml,
                ) ==
                null) ||
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
    const titleDate = r'(?:\d{4}년\d{1,2}월\d{1,2}일|\d{4}\.\d{2}\.\d{2})';
    final titlePattern = RegExp(
      '제$term(?:\\(당\\))?(?:당기|기)(?:기말|말)?:?\\(?($titleDate)(현재|(?:부터(?=$titleDate까지)|~)($titleDate)(?:까지)?)\\)?',
    );
    final titles = titlePattern.allMatches(text).toList();
    final parenthesizedTitles = titles
        .where(
          (m) =>
              (m.group(0)!.replaceAll('(당)', '').contains('(') ||
              m.group(0)!.replaceAll('(당)', '').contains(')')),
        )
        .toList();
    if (parenthesizedTitles.any((m) {
      final t = m.group(0)!.replaceAll('(당)', '');
      return '('.allMatches(t).length != 1 || ')'.allMatches(t).length != 1;
    })) {
      throw const FormatException('Unbalanced annual dated title punctuation');
    }

    final cnsScope =
        receipt == '20260319000677' &&
        corpCode == '01116380' &&
        !consolidated &&
        term == '26' &&
        statementSource.queryParameters['dcmNo'] == '11148548' &&
        statementSource.queryParameters['eleId'] == '21' &&
        periodStart == DateTime.utc(2025, 1, 1) &&
        periodEnd == DateTime.utc(2025, 12, 31);
    final konasolScope =
        receipt == '20260331004755' &&
        corpCode == '00666329' &&
        !consolidated &&
        term == '29' &&
        statementSource.queryParameters['dcmNo'] == '11215244' &&
        statementSource.queryParameters['eleId'] == '21' &&
        periodStart == DateTime.utc(2025, 1, 1) &&
        periodEnd == DateTime.utc(2025, 12, 31);
    Map<String, dynamic>? cnsPeriodProof;
    if (cnsScope && titles.isEmpty) {
      final candidates = <Map<String, dynamic>>[];
      var supportingIndex = 0;
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final index = supportingIndex++;
        final preceding = _compact(_text(scope.substring(0, table.start)));
        final ce = preceding.lastIndexOf('자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => preceding.lastIndexOf(h) > ce)) {
          continue;
        }
        final grid = _FinancialHtmlGrid.parse(table.group(1)!);
        if (grid.isEmpty || _compact(grid.first.first?.text ?? '') != '과목') {
          continue;
        }
        if (grid.first.length != 6 ||
            _compact(grid.first.last?.text ?? '') != '총계' ||
            !preceding.substring(ce).contains('(단위:원)')) {
          throw const FormatException('CNS supporting equity table mismatch');
        }
        int uniqueRow(String printed) {
          final positions = [
            for (var i = 1; i < grid.length; i++)
              if (_compact(grid[i].first?.text ?? '') == printed) i,
          ];
          if (positions.length != 1) {
            throw const FormatException('CNS supporting date ambiguous');
          }
          return positions.single;
        }

        for (final marker in ['(당기초)', '(당기말)']) {
          if (grid
                  .skip(1)
                  .where((r) => _compact(r.first?.text ?? '').endsWith(marker))
                  .length !=
              1) {
            throw const FormatException(
              'CNS supporting current dates conflict',
            );
          }
        }
        final startRow = uniqueRow('2025.1.1(당기초)');
        final endRow = uniqueRow('2025.12.31(당기말)');
        if (startRow >= endRow) {
          throw const FormatException('CNS supporting dates reversed');
        }
        final profitRows = [
          for (var i = startRow + 1; i < endRow; i++)
            if (_compact(grid[i].first?.text ?? '') == '당기순이익(손실)') i,
        ];
        if (profitRows.length != 1) {
          throw const FormatException('CNS supporting profit ambiguous');
        }
        String total(int row) {
          if (grid[row].length != 6 ||
              grid[row].last == null ||
              grid[row].last!.colspan != 1 ||
              grid[row].last!.rowspan != 1) {
            throw const FormatException(
              'CNS supporting monetary cell ambiguous',
            );
          }
          final v = grid[row].last!.text.trim();
          if (!RegExp(r'^-?\d{1,3}(?:,\d{3})*$').hasMatch(v)) {
            throw const FormatException('CNS supporting amount invalid');
          }
          return BigInt.parse(v.replaceAll(',', '')).toString();
        }

        candidates.add({
          'mode': 'same-document-equity-change-period-corroboration',
          'tableIndex': index,
          'currentTerm': term,
          'currentHeader': '2025년도(제26기)',
          'periodStart': '2025-01-01',
          'periodEnd': '2025-12-31',
          'startRow': startRow,
          'endRow': endRow,
          'profitRow': profitRows.single,
          'closingEquity': total(endRow),
          'currentProfit': total(profitRows.single),
          'source': statementSource.toString(),
          'unit': '원',
        });
      }
      if (candidates.length != 1) {
        throw const FormatException(
          'CNS supporting period absent or ambiguous',
        );
      }
      cnsPeriodProof = candidates.single;
    }
    if (konasolScope && titles.isEmpty) {
      final proofs = <Map<String, dynamic>>[];
      var tableIndex = 0;
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final index = tableIndex++;
        final prefix = _compact(_text(scope.substring(0, table.start)));
        final ce = prefix.lastIndexOf('자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => prefix.lastIndexOf(h) > ce)) {
          continue;
        }
        final grid = _FinancialHtmlGrid.parse(table.group(1)!);
        if (grid.isEmpty || _compact(grid.first.first?.text ?? '') != '과목') {
          continue;
        }
        if (grid.first.length != 7 ||
            _compact(grid.first.last?.text ?? '') != '총계' ||
            !prefix.substring(ce).contains('(단위:원)')) {
          throw const FormatException(
            'Konasol supporting equity table mismatch',
          );
        }
        int unique(String label) {
          final matches = [
            for (var r = 1; r < grid.length; r++)
              if (_compact(grid[r].first?.text ?? '') == label) r,
          ];
          if (matches.length != 1) {
            throw const FormatException('Konasol supporting date ambiguous');
          }
          return matches.single;
        }

        final start = unique('2025년01월01일(보고금액)');
        final end = unique('2025년12월31일(당기말)');
        if (start >= end ||
            grid
                    .skip(1)
                    .where(
                      (r) => _compact(r.first?.text ?? '').endsWith('(당기말)'),
                    )
                    .length !=
                1) {
          throw const FormatException('Konasol current dates conflict');
        }
        final profit = [
          for (var r = start + 1; r < end; r++)
            if (_compact(grid[r].first?.text ?? '') == '당기순이익') r,
        ];
        if (profit.length != 1) {
          throw const FormatException('Konasol supporting profit ambiguous');
        }
        String total(int r) {
          final cell = grid[r].last;
          if (grid[r].length != 7 ||
              cell == null ||
              cell.colspan != 1 ||
              cell.rowspan != 1 ||
              !RegExp(r'^-?\d{1,3}(?:,\d{3})*$').hasMatch(cell.text.trim())) {
            throw const FormatException('Konasol supporting total ambiguous');
          }
          return BigInt.parse(cell.text.trim().replaceAll(',', '')).toString();
        }

        proofs.add({
          'mode': 'same-document-split-header-equity-period-corroboration',
          'tableIndex': index,
          'currentTerm': term,
          'currentHeader': '제29기/(2025년);2025년/(제29기)',
          'periodStart': '2025-01-01',
          'periodEnd': '2025-12-31',
          'startRow': start,
          'endRow': end,
          'profitRow': profit.single,
          'closingEquity': total(end),
          'currentProfit': total(profit.single),
          'source': statementSource.toString(),
          'unit': '원',
        });
      }
      if (proofs.length != 1) {
        throw const FormatException(
          'Konasol supporting period absent or ambiguous',
        );
      }
      cnsPeriodProof = proofs.single;
    }
    // A BS duration requires independently printed CE dates and totals.
    final bsDurationCandidate =
        periodEnd.difference(periodStart).inDays >= 364 &&
        periodEnd.difference(periodStart).inDays <= 365 &&
        titles.length >= 3 &&
        titles.every(
          (m) =>
              m.group(2) != '현재' &&
              sourceDate(m.group(1)!) == periodStart &&
              sourceDate(m.group(3)!) == periodEnd,
        );
    if (cnsPeriodProof == null &&
        (titles.length < 3 ||
            (!bsDurationCandidate && !titles.any((m) => m.group(2) == '현재')) ||
            titles.any(
              (m) => m.group(2) == '현재'
                  ? sourceDate(m.group(1)!) != periodEnd
                  : sourceDate(m.group(1)!) != periodStart ||
                        sourceDate(m.group(3)!) != periodEnd,
            ))) {
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
      '매출': ('revenue', 'CIS'),
      '수익(매출액)': ('revenue', 'CIS'),
      '영업수익': ('revenue', 'CIS'),
      '영업이익': ('operating', 'CIS'),
      '영업손익': ('operating', 'CIS'),
      '영업손익(손실)': ('operating', 'CIS'),
      '영업손실': ('operating', 'CIS'),
      '영업이익(손실)': ('operating', 'CIS'),
      '당기순이익': ('profit', 'CIS'),
      '당기순손익': ('profit', 'CIS'),
      '당기순손익(손실)': ('profit', 'CIS'),
      '당기순손실': ('profit', 'CIS'),
      '연결당기순이익': ('profit', 'CIS'),
      '연결당기순이익(손실)': ('profit', 'CIS'),
      '연결당기순손실': ('profit', 'CIS'),
      '당기순이익(손실)': ('profit', 'CIS'),
      '영업활동으로인한현금흐름': ('cfo', 'CF'),
      '영업활동현금흐름': ('cfo', 'CF'),
      '영업활동순현금흐름': ('cfo', 'CF'),
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

    Map<String, dynamic>? datedPunctuationProof;
    if (parenthesizedTitles.isNotEmpty || bsDurationCandidate) {
      final candidates = <Map<String, dynamic>>[];
      var supportingIndex = 0;
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final index = supportingIndex++;
        final prefix = _compact(_text(scope.substring(0, table.start)));
        final ceAt = prefix.lastIndexOf('자본변동표');
        if (ceAt < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => prefix.lastIndexOf(h) > ceAt)) {
          continue;
        }
        final local = prefix.substring(ceAt);
        final ceTitles = titlePattern.allMatches(local).toList();
        if (ceTitles.length != 1 ||
            ceTitles.single.group(2) == '현재' ||
            sourceDate(ceTitles.single.group(1)!) != periodStart ||
            sourceDate(ceTitles.single.group(3)!) != periodEnd) {
          continue;
        }
        final grid = _FinancialHtmlGrid.parse(table.group(1)!);
        if (grid.isEmpty ||
            !{'과목', '구분'}.contains(_compact(grid.first.first?.text ?? ''))) {
          continue;
        }
        if (grid.first.length < 3 ||
            !{
              '총계',
              '합계',
              '자본합계',
            }.contains(_compact(grid.first.last?.text ?? '')) ||
            grid.first.any(
              (c) => c == null || c.rowspan != 1 || c.colspan != 1,
            ) ||
            grid.first.any((c) => _compact(c?.text ?? '').contains('비지배'))) {
          throw const FormatException(
            'Dated punctuation supporting whole equity header mismatch',
          );
        }
        final units = RegExp(r'\(단위:([^)]*)\)').allMatches(local).toList();
        final unit = units.isEmpty ? null : units.last.group(1);
        final multiplier = switch (unit) {
          '원' => BigInt.one,
          '천원' => BigInt.from(1000),
          '백만원' => BigInt.from(1000000),
          _ => throw const FormatException(
            'Unsupported supporting equity unit',
          ),
        };
        DateTime? rowDate(String text) {
          final m = RegExp(
            r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?(?:\(보고금액\)|\(당기초\)|\(당기말\)|\(기초자본\)|\(기말자본\)|잔액)$',
          ).firstMatch(_compact(text));
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

        int uniqueDate(DateTime date) {
          final found = [
            for (var r = 1; r < grid.length; r++)
              if (rowDate(grid[r].first?.text ?? '') == date) r,
          ];
          if (found.length != 1) {
            throw const FormatException(
              'Dated punctuation supporting actual date ambiguous',
            );
          }
          return found.single;
        }

        final start = uniqueDate(periodStart), end = uniqueDate(periodEnd);
        if (start >= end) {
          throw const FormatException(
            'Dated punctuation supporting date order mismatch',
          );
        }
        final profit = [
          for (var r = start + 1; r < end; r++)
            if ({
              '당기순이익',
              '당기순이익(손실)',
              '당기순손실',
            }.contains(_compact(grid[r].first?.text ?? '')))
              r,
        ];
        if (profit.length != 1) {
          throw const FormatException(
            'Dated punctuation supporting current profit ambiguous',
          );
        }
        String whole(int r) {
          final cell = grid[r].last;
          if (grid[r].length != grid.first.length ||
              cell == null ||
              cell.colspan != 1 ||
              cell.rowspan != 1) {
            throw const FormatException(
              'Dated punctuation supporting total ambiguous',
            );
          }
          final v = money(cell.text);
          if (v == null) {
            throw const FormatException(
              'Dated punctuation supporting total unavailable',
            );
          }
          return (v * multiplier).toString();
        }

        candidates.add({
          'mode': bsDurationCandidate
              ? 'primary-bs-duration-equity-corroboration'
              : 'fully-dated-parentheses-equity-corroboration',
          'tableIndex': index,
          'currentTerm': term,
          'periodStart': periodStart.toIso8601String().substring(0, 10),
          'periodEnd': periodEnd.toIso8601String().substring(0, 10),
          'startRow': start,
          'endRow': end,
          'profitRow': profit.single,
          'closingEquity': whole(end),
          'currentProfit': whole(profit.single),
          'source': statementSource.toString(),
          'unit': unit,
        });
      }
      if (candidates.length != 1) {
        throw const FormatException(
          'Dated punctuation supporting equity absent or ambiguous',
        );
      }
      datedPunctuationProof = candidates.single;
    }
    // The exact TXR source prints one blank label header before three terms.
    // This profile changes no statement, period, unit or numeric checks.
    final txrBlankHeader =
        receipt == '20250526000504' &&
        corpCode == '01458161' &&
        !consolidated &&
        periodStart == DateTime.utc(2024) &&
        periodEnd == DateTime.utc(2024, 12, 31) &&
        statementSource.queryParameters['dcmNo'] == '10659954' &&
        statementSource.queryParameters['eleId'] == '23' &&
        statementSource.queryParameters['offset'] == '583619' &&
        statementSource.queryParameters['length'] == '51351';
    final result = <Map<String, dynamic>>[];
    final values = <String, BigInt>{};
    final missingOptional = <Map<String, dynamic>>[];
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
          (!{'과목', '구분', '계정과목'}.contains(_compact(_text(first.group(1)!))) &&
              !(txrBlankHeader && _compact(_text(first.group(1)!)).isEmpty))) {
        continue;
      }
      // A dated primary equity-change table is outside this core-row scope.
      // Exclude it before numeric-grid parsing; ambiguous headings still fail
      // through the original grid/statement checks below.
      final prefix = _compact(_text(scope.substring(0, table.start)));
      final equityAt = prefix.lastIndexOf('자본변동표');
      final otherAt = [
        prefix.lastIndexOf('재무상태표'),
        prefix.lastIndexOf('손익계산서'),
        prefix.lastIndexOf('현금흐름표'),
      ].reduce((a, b) => a > b ? a : b);
      if (equityAt >= 0 && equityAt > otherAt) {
        if (cnsPeriodProof != null && index == cnsPeriodProof['tableIndex']) {
          continue;
        }
        final datedEquity = titlePattern
            .allMatches(prefix.substring(equityAt))
            .toList();
        if (datedEquity.isNotEmpty &&
            datedEquity.last.group(2) != '현재' &&
            sourceDate(datedEquity.last.group(1)!) == periodStart &&
            sourceDate(datedEquity.last.group(3)!) == periodEnd) {
          continue;
        }
      }
      if (konasolScope &&
          cnsPeriodProof != null &&
          cnsPeriodProof['tableIndex'] == index) {
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
      } else if ((labels.contains('매출액') ||
              labels.contains('매출') ||
              labels.contains('영업수익') ||
              labels.contains('수익(매출액)')) &&
          ([
            '영업이익',
            '영업이익(손실)',
            '영업손익',
            '영업손익(손실)',
            '영업손실',
          ].any(labels.contains))) {
        kind = 'CIS';
      } else if (labels.contains('영업활동으로인한현금흐름') ||
          labels.contains('영업활동으로인한현금흐름(순액)') ||
          labels.contains('영업활동현금흐름') ||
          labels.contains('영업활동순현금흐름')) {
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
                RegExp(
                  '^(?:제$term(?:\\(당\\))?기(?:기말|말)?|${periodEnd.year}(?:년도|연도)\\(제$term기\\))\$',
                ).hasMatch(_compact(c.text)) ||
                (konasolScope && kind == 'CF' && _compact(c.text) == '2025년'),
          )
          .toSet();
      if (headers.length != 1) {
        throw const FormatException('Ambiguous annual current header');
      }
      final current = headers.single;
      if (txrBlankHeader && _compact(grid.first.first?.text ?? '').isEmpty) {
        if (grid.first.length != 4 ||
            current.column != 1 ||
            grid.first.any(
              (c) => c == null || c.colspan != 1 || c.rowspan != 1,
            ) ||
            grid.first.map((c) => _compact(c!.text)).join('|') !=
                '|제8기|제7기|제6기') {
          throw const FormatException('TXR blank header profile mismatch');
        }
      }
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
      if (konasolScope &&
          cnsPeriodProof != null &&
          (current.column != 1 ||
              grid.first.first?.rowspan != 2 ||
              _compact(current.text) != (kind == 'CF' ? '2025년' : '제29기'))) {
        throw const FormatException('Konasol split current header mismatch');
      }
      final localPrefix = preceding.substring(sectionStart);
      final localTitles = titlePattern.allMatches(localPrefix).toList();
      if ((cnsPeriodProof == null &&
              (localTitles.isEmpty ||
                  ((kind == 'BS') != (localTitles.last.group(2) == '현재') &&
                      !(kind == 'BS' &&
                          bsDurationCandidate &&
                          datedPunctuationProof != null)))) ||
          (cnsPeriodProof != null &&
              !konasolScope &&
              _compact(current.text) != '2025년도(제26기)')) {
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
        final expectedPeriod = konasolScope
            ? (kind == 'CF' ? '(제29기)' : '(2025년)')
            : '(${(periodStart.year % 100).toString().padLeft(2, '0')}.${periodStart.month.toString().padLeft(2, '0')}~${(periodEnd.year % 100).toString().padLeft(2, '0')}.${periodEnd.month.toString().padLeft(2, '0')})';
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
        if (values.containsKey(account.$1) ||
            missingOptional.any((m) => m['accountKey'] == account.$1)) {
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
        if (account.$1 == 'capex' &&
            amounts.isEmpty &&
            cells.every(
              (c) => c!.text.trim().isEmpty || c.text.trim() == '-',
            )) {
          // An optional printed dash is unavailable, not inferred zero.
          // Mandatory core rows and malformed/ambiguous numeric cells still fail.
          missingOptional.add({
            'accountKey': account.$1,
            'printedLabel': row.first!.text,
            'printedCurrentCells': cells.map((c) => c!.text).toList(),
            'tableIndex': index,
            'source': statementSource.toString(),
            'reason': 'Printed optional amount unavailable; no zero or prior amount inferred',
          });
          continue;
        }
        if (amounts.length != 1) {
          throw const FormatException(
            'Ambiguous annual current monetary group',
          );
        }
        final printedValue = amounts.single;
        final lossLabel = const {
          '영업손실',
          '당기순손실',
          '연결당기순손실',
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
    if (cnsPeriodProof != null) {
      if (values['equity'].toString() != cnsPeriodProof['closingEquity'] ||
          values['profit'].toString() != cnsPeriodProof['currentProfit']) {
        throw const FormatException(
          'CNS supporting equity/profit contradiction',
        );
      }
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            cnsPeriodProof;
      }
    }

    if (datedPunctuationProof != null) {
      if (values['equity'].toString() !=
              datedPunctuationProof['closingEquity'] ||
          values['profit'].toString() !=
              datedPunctuationProof['currentProfit']) {
        throw const FormatException(
          'Dated punctuation supporting equity/profit contradiction',
        );
      }
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            datedPunctuationProof;
      }
    }
    if (missingOptional.isNotEmpty) {
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['unavailableOptionalAccounts'] =
            missingOptional;
      }
    }
    final historicalIdentity = VerifiedHistoricalCompanyIdentity.evidence(
      receipt: receipt,
      corpCode: corpCode,
      currentName: companyName,
      printedName: company,
      periodEnd: periodEnd,
      consolidated: consolidated,
      coverSource: coverSource,
      coverHtml: coverHtml,
    );
    if (historicalIdentity != null) {
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['historicalCompanyIdentity'] =
            historicalIdentity;
      }
    }
    if (declaredIssuer != null) {
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['historicalCompanyIdentity'] =
            declaredIssuer;
      }
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
