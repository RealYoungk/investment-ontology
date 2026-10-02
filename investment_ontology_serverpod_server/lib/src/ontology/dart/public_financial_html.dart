import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'same_receipt_audit_source.dart';
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
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
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
  /// Exact raw CE cells corroborate a dated period only. No CE currency,
  /// monetary scale or FinancialFact is assigned by this source profile.
  static Map<String, dynamic>? _suntechRawCePeriod({
    required String receipt,
    required String corpCode,
    required String coverHtml,
    required String statementHtml,
    required Uri coverSource,
    required Uri statementSource,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    if (receipt != '20260317000808' || corpCode != '00963000') return null;
    void guard(bool ok, String reason) {
      if (!ok) throw FormatException('Suntech exact raw CE period: $reason');
    }

    final expectedSource = consolidated
        ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=19&offset=329146&length=114169&dtd=dart4.xsd'
        : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=21&offset=518605&length=97424&dtd=dart4.xsd';
    guard(
      start == DateTime.utc(2025, 1, 1) && end == DateTime.utc(2025, 12, 31),
      'actual annual interval mismatch',
    );
    guard(
      coverSource.toString() ==
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=1&offset=965&length=4492&dtd=dart4.xsd' &&
          sha256.convert(utf8.encode(coverHtml)).toString() == '0c5c9784d78f754e8509079d4b2e479288c1cef7def0e357ec1d2a6e39c729c4',
      'cover identity mismatch',
    );
    guard(
      statementSource.toString() == expectedSource &&
          sha256.convert(utf8.encode(statementHtml)).toString() ==
              (consolidated
                  ? 'dcb53fe25355b082817de8530aa548c674603b88c72edcbd64cb64d0ce311de3'
                  : '77af198724aa9d4a8ff849d35b172d37bbc44853e71c43f1c19191ac734555d8'),
      'immutable whole source mismatch',
    );
    final tables = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).toList();
    guard(tables.length > 7, 'primary tables missing');
    final local = _compact(_text(statementHtml.substring(0, tables[5].start)))
        .split('자본변동표')
        .last;
    guard(
      local == '제30기2025년01월01일부터2025년12월31일까지제29기2024년01월01일부터2024년12월31일까지' &&
          !local.contains('단위'),
      'explicit CE annual dates or unit evidence changed',
    );
    final grid = _FinancialHtmlGrid.parse(tables[5].group(1)!);
    final header = grid.first.map((c) => _compact(c?.text ?? '')).toList();
    guard(
      header.join('|') ==
              (consolidated
                  ? '과목|자본금|자본잉여금|자본조정|기타포괄손익누계액|이익잉여금|비지배주주지분|총계'
                  : '과목|자본금|자본잉여금|자본조정|기타포괄손익누계액|이익잉여금|총계') &&
          grid.first.every(
            (c) => c != null && c.colspan == 1 && c.rowspan == 1,
          ),
      'whole CE hierarchy mismatch',
    );
    int one(String label) {
      final found = [
        for (var r = 1; r < grid.length; r++)
          if (_compact(grid[r].first?.text ?? '') == label) r,
      ];
      guard(found.length == 1, 'actual current date ambiguous');
      return found.single;
    }

    final a = one('2025.01.01(당기초)'), b = one('2025.12.31(당기말)');
    guard(a < b, 'actual dates reversed');
    final profits = [
      for (var r = a + 1; r < b; r++)
        if (_compact(grid[r].first?.text ?? '') == '당기순이익') r,
    ];
    guard(profits.length == 1, 'current whole profit ambiguous');
    String raw(int r) {
      guard(
        grid[r].length == header.length &&
            grid[r].last != null &&
            grid[r].last!.colspan == 1 &&
            grid[r].last!.rowspan == 1,
        'whole CE total column mismatch',
      );
      final v = grid[r].last!.text.trim();
      guard(
        RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$').hasMatch(v) &&
            v.startsWith('(') == v.endsWith(')'),
        'raw whole numeric cell unavailable',
      );
      return v;
    }

    final rawProfit = raw(profits.single), rawEquity = raw(b);
    guard(
      rawProfit == (consolidated ? '(2,164,078,292)' : '(1,757,381,648)') &&
          rawEquity == (consolidated ? '3,483,092,950' : '3,233,567,289'),
      'raw CE whole values changed',
    );
    String rawNumeric(String v) =>
        v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', '');
    return {
      'mode': 'exact-suntech-unscaled-raw-ce-period-corroboration',
      'source': expectedSource,
      'periodStart': '2025-01-01',
      'periodEnd': '2025-12-31',
      'currentTerm': '30',
      'startRow': a,
      'endRow': b,
      'profitRow': profits.single,
      'currentProfit': rawNumeric(rawProfit),
      'closingEquity': rawNumeric(rawEquity),
      'printedRawProfit': rawProfit,
      'printedRawClosingEquity': rawEquity,
      'unit': null,
      'unitStatus': 'not-printed-unknown',
      'currencyAssigned': false,
      'multiplierAssigned': false,
      'financialValuesStoredFromCE': false,
      'note': '단위 미기재 CE의 raw 전체 숫자와 날짜를 원 단위 primary 표와 직접 교차검증. 단위 차용·배율 변환·CE 값 저장 없음.',
    };
  }

  // This source prints current dates in separate title tables and the term
  // only in each monetary table's current column. No dates are inferred.
  static Map<String, dynamic> _jilgyungyiDatedPeriod(
    String scope,
    Uri source,
    DateTime start,
    DateTime end,
  ) {
    void guard(bool ok, String message) {
      if (!ok) throw FormatException('Jilgyungyi dated source $message');
    }

    final matches = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(scope).toList();
    final seen = <String>{};
    Map<String, dynamic>? proof;
    for (var index = 0; index < matches.length; index++) {
      final table = matches[index];
      final first = RegExp(
        r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(table.group(1)!);
      if (first == null || !{'과목', '구분'}.contains(_compact(_text(first[1]!)))) {
        continue;
      }
      final prefix = _compact(_text(scope.substring(0, table.start)));
      var at = -1;
      String? kind;
      for (final title in {
        '재무상태표': 'BS',
        '손익계산서': 'CIS',
        '자본변동표': 'CE',
        '현금흐름표': 'CF',
      }.entries) {
        final found = prefix.lastIndexOf(title.key);
        if (found > at) {
          at = found;
          kind = title.value;
        }
      }
      guard(
        at >= 0 && kind != null && seen.add(kind),
        'statement absent or duplicated',
      );
      final local = prefix.substring(at);
      final dates = RegExp(
        r'당기(말)?:((\d{4})년(\d{1,2})월(\d{1,2})일)(현재|부터(\d{4})년(\d{1,2})월(\d{1,2})일까지)',
      ).allMatches(local).toList();
      guard(dates.length == 1, 'current date ambiguous');
      final date = dates.single;
      final firstDate = DateTime.utc(
        int.parse(date[3]!),
        int.parse(date[4]!),
        int.parse(date[5]!),
      );
      guard(
        firstDate.year == int.parse(date[3]!) &&
            firstDate.month == int.parse(date[4]!) &&
            firstDate.day == int.parse(date[5]!),
        'invalid printed calendar date',
      );
      guard(
        kind == 'BS'
            ? date[1] == '말' && date[6] == '현재' && firstDate == end
            : date[1] == null &&
                  date[6] != '현재' &&
                  firstDate == start &&
                  int.parse(date[7]!) == end.year &&
                  int.parse(date[8]!) == end.month &&
                  int.parse(date[9]!) == end.day,
        'printed period conflict',
      );
      guard(
        local.contains('주식회사질경이와그종속기업'),
        'printed consolidated company missing',
      );
      final units = RegExp(r'\(단위:([^)]*)\)').allMatches(local).toList();
      guard(units.length == 1 && units.single[1] == '원', 'unit conflict');
      final grid = _FinancialHtmlGrid.parse(table.group(1)!);
      guard(grid.isNotEmpty, 'empty monetary table');
      if (kind != 'CE') {
        final headers = grid.first
            .whereType<_FinancialHtmlCell>()
            .where((c) => _compact(c.text) == '제10(당)기')
            .toSet();
        final markedCurrent = grid.first
            .whereType<_FinancialHtmlCell>()
            .where((c) => _compact(c.text).contains('(당)'))
            .toSet();
        guard(
          markedCurrent.length == 1 &&
              markedCurrent.single ==
                  (headers.length == 1 ? headers.single : null),
          'conflicting explicitly current term',
        );
        guard(headers.length == 1, 'current term ambiguous');
        final current = headers.single;
        guard(
          current.column == 2 &&
              current.rowspan == 1 &&
              current.colspan == (kind == 'CIS' ? 1 : 2),
          'current column shape conflict',
        );
        continue;
      }
      guard(
        grid.first.length == 7 &&
            grid.first.map((c) => _compact(c?.text ?? '')).join('|') ==
                '구분|주석|자본금|기타자본항목|결손금|비지배지분|합계' &&
            grid.first.every(
              (c) => c != null && c.rowspan == 1 && c.colspan == 1,
            ),
        'whole CE header mismatch',
      );
      int one(String label) {
        final found = [
          for (var r = 1; r < grid.length; r++)
            if (_compact(grid[r].first?.text ?? '') == label) r,
        ];
        guard(found.length == 1, 'CE date ambiguous');
        return found.single;
      }

      for (final marker in ['(당기초)', '(당기말)']) {
        guard(
          grid
                  .skip(1)
                  .where((r) => _compact(r.first?.text ?? '').endsWith(marker))
                  .length ==
              1,
          'contradictory current CE dates',
        );
      }
      final a = one('2022.1.1(당기초)'), b = one('2022.12.31(당기말)');
      guard(a < b, 'CE date order');
      final profits = [
        for (var r = a + 1; r < b; r++)
          if (_compact(grid[r].first?.text ?? '') == '당기순손실') r,
      ];
      guard(profits.length == 1, 'whole current CE profit ambiguous');
      String total(int r) {
        guard(
          grid[r].length == 7 &&
              grid[r].last != null &&
              grid[r].last!.colspan == 1 &&
              grid[r].last!.rowspan == 1,
          'whole CE total shape',
        );
        final v = _compact(grid[r].last!.text);
        guard(
          RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$').hasMatch(v) &&
              v.startsWith('(') == v.endsWith(')'),
          'whole CE amount missing',
        );
        return BigInt.parse(
          v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
        ).toString();
      }

      proof = {
        'mode': 'exact-jilgyungyi-independent-dated-title-current-term',
        'tableIndex': index,
        'source': source.toString(),
        'periodStart': '2022-01-01',
        'periodEnd': '2022-12-31',
        'currentTerm': '10',
        'currentProfit': total(profits.single),
        'closingEquity': total(b),
        'wholeTotalColumn': 6,
        'nonControllingColumn': 5,
        'startRow': a,
        'endRow': b,
        'profitRow': profits.single,
        'unit': '원',
      };
    }
    guard(
      seen.length == 4 && proof != null,
      'four dated statements/CE evidence missing',
    );
    return proof!;
  }

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
    final linkedAudit = SameReceiptAuditSource.bound(
      receipt: receipt,
      corpCode: corpCode,
      consolidated: consolidated,
      start: periodStart,
      end: periodEnd,
      coverSource: coverSource,
      coverHtml: coverHtml,
      statementSource: statementSource,
      statementHtml: statementHtml,
    );
    if ((!linkedAudit &&
            coverSource.queryParameters['dcmNo'] !=
                statementSource.queryParameters['dcmNo']) ||
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
    final printedTerm = terms.single.group(1)!;
    final term =
        receipt == '20230308000311' &&
            corpCode == '01476219' &&
            printedTerm == '03'
        ? '3'
        : printedTerm;
    final expected = linkedAudit
        ? (consolidated ? '(첨부)연결재무제표' : '(첨부)재무제표')
        : consolidated
        ? '2.연결재무제표'
        : '4.재무제표';
    final next = linkedAudit
        ? '주석'
        : consolidated
        ? '3.연결재무제표주석'
        : '5.재무제표주석';
    final headings = RegExp(
      linkedAudit
          ? r'<P\b[^>]*class=["\x27]section-[12]["\x27][^>]*>.*?</P>'
          : r'<P\b[^>]*class=["\x27]section-2["\x27][^>]*>.*?</P>',
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
    final medysseyScope =
        receipt == '20260327001807' &&
        corpCode == '01018617' &&
        consolidated &&
        term == '23' &&
        periodStart == DateTime.utc(2025) &&
        periodEnd == DateTime.utc(2025, 12, 31) &&
        coverSource.queryParameters['dcmNo'] == '11192320' &&
        coverSource.queryParameters['eleId'] == '3' &&
        coverSource.queryParameters['offset'] == '22330' &&
        coverSource.queryParameters['length'] == '4506' &&
        statementSource.queryParameters['eleId'] == '21' &&
        statementSource.queryParameters['offset'] == '428967' &&
        statementSource.queryParameters['length'] == '78464' &&
        coverSource.queryParameters['dtd'] == 'dart4.xsd' &&
        statementSource.queryParameters['dtd'] == 'dart4.xsd';
    final kiwoomRepeatedTermScope =
        receipt == '20230320001037' &&
        corpCode == '00296290' &&
        consolidated &&
        term == '24' &&
        coverSource.queryParameters['dcmNo'] == '9077489' &&
        coverSource.queryParameters['eleId'] == '1' &&
        coverSource.queryParameters['offset'] == '796' &&
        coverSource.queryParameters['length'] == '4038' &&
        statementSource.queryParameters['dcmNo'] == '9077489' &&
        statementSource.queryParameters['eleId'] == '17' &&
        statementSource.queryParameters['offset'] == '905295' &&
        statementSource.queryParameters['length'] == '107240' &&
        periodStart == DateTime.utc(2022) &&
        periodEnd == DateTime.utc(2022, 12, 31);
    final spacMissingRevenue =
        !consolidated &&
        periodStart == DateTime.utc(2022) &&
        periodEnd == DateTime.utc(2022, 12, 31) &&
        ((receipt == '20230315000997' &&
                corpCode == '01601222' &&
                term == '2' &&
                statementSource.toString() ==
                    'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000997&dcmNo=9059566&eleId=21&offset=123918&length=36101&dtd=dart3.xsd') ||
            (receipt == '20230308000311' &&
                corpCode == '01476219' &&
                term == '3' &&
                statementSource.toString() ==
                    'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230308000311&dcmNo=9041541&eleId=21&offset=99116&length=33528&dtd=dart3.xsd'));
    if (spacMissingRevenue && declaredIssuer == null) {
      throw const FormatException(
        'SPAC partial source requires official issuer declaration',
      );
    }
    final titleTerm = kiwoomRepeatedTermScope
        ? '제$term기\\(당\\)기'
        : '제$term(?:\\(당\\))?(?:당기|기)';
    final titlePattern = RegExp(
      '$titleTerm${spacMissingRevenue ? '(?:말)?' : '(?:기말|말)?'}:?\\(?($titleDate)(현재|(?:부터(?=$titleDate까지)|~)($titleDate)(?:까지)?)\\)?',
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
    final cronexScope =
        receipt == '20260709000504' &&
        corpCode == '01034730' &&
        !consolidated &&
        term == '14' &&
        coverSource.queryParameters['dcmNo'] == '11470809' &&
        coverSource.queryParameters['eleId'] == '3' &&
        statementSource.queryParameters['dcmNo'] == '11470809' &&
        statementSource.queryParameters['eleId'] == '23' &&
        periodStart == DateTime.utc(2025, 1, 1) &&
        periodEnd == DateTime.utc(2025, 12, 31);
    final rootlocScope =
        receipt == '20260323000661' &&
        corpCode == '01262023' &&
        !consolidated &&
        term == '12' &&
        coverSource.queryParameters['dcmNo'] == '11163088' &&
        coverSource.queryParameters['eleId'] == '1' &&
        statementSource.queryParameters['dcmNo'] == '11163088' &&
        statementSource.queryParameters['eleId'] == '21' &&
        statementSource.queryParameters['offset'] == '200508' &&
        statementSource.queryParameters['length'] == '78783' &&
        periodStart == DateTime.utc(2025) &&
        periodEnd == DateTime.utc(2025, 12, 31);
    final jilgyungyiScope =
        receipt == '20230321000972' &&
        corpCode == '01063556' &&
        consolidated &&
        term == '10' &&
        periodStart == DateTime.utc(2022) &&
        periodEnd == DateTime.utc(2022, 12, 31) &&
        coverSource.queryParameters['dcmNo'] == '9082268' &&
        coverSource.queryParameters['eleId'] == '1' &&
        coverSource.queryParameters['offset'] == '798' &&
        coverSource.queryParameters['length'] == '4073' &&
        statementSource.queryParameters['dcmNo'] == '9082268' &&
        statementSource.queryParameters['eleId'] == '19' &&
        statementSource.queryParameters['offset'] == '142981' &&
        statementSource.queryParameters['length'] == '42001' &&
        coverSource.queryParameters['dtd'] == 'dart3.xsd' &&
        statementSource.queryParameters['dtd'] == 'dart3.xsd';
    Map<String, dynamic>? cnsPeriodProof;
    if (jilgyungyiScope) {
      cnsPeriodProof = _jilgyungyiDatedPeriod(
        scope,
        statementSource,
        periodStart,
        periodEnd,
      );
    }
    if (rootlocScope && titles.isEmpty) {
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
        if (RegExp(r'\(단위:([^)]*)\)')
                .allMatches(prefix.substring(ce))
                .map((m) => m.group(1))
                .toList()
                .join('|') !=
            '천원') {
          throw const FormatException('Rootloc CE unit mismatch');
        }
        final rawRows = RegExp(
          r'<TR\b[^>]*>(.*?)</TR>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(table.group(1)!).toList();
        if (rawRows.isEmpty) {
          throw const FormatException('Rootloc CE rows missing');
        }
        List<RegExpMatch> cells(int row) => RegExp(
          r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(rawRows[row].group(1)!).toList();
        final header = cells(0)
            .map((c) => _compact(_text(c.group(2)!)))
            .join('|');
        if (header != '구분|과목|자본금|자본잉여금|자본조정|기타포괄손익누계액|이익잉여금|총계') {
          throw const FormatException('Rootloc CE whole header mismatch');
        }
        final startRows = [
          for (var i = 1; i < rawRows.length; i++)
            if (cells(i).length == 8 &&
                _compact(_text(cells(i)[0].group(2)!)) == '2025년도(제12기)')
              i,
        ];
        if (startRows.length != 1) {
          throw const FormatException('Rootloc CE current block ambiguous');
        }
        final start = startRows.single;
        final first = cells(start);
        if (!RegExp(
              r'''^\s*[^>]*rowspan=['"]7['"][^>]*$''',
              caseSensitive: false,
            ).hasMatch(first[0].group(1)!) ||
            _compact(_text(first[1].group(2)!)) != '2025.1.1(기초)' ||
            start + 6 >= rawRows.length) {
          throw const FormatException('Rootloc CE start mismatch');
        }
        final end = start + 6;
        if (cells(end).length != 7 ||
            _compact(_text(cells(end)[0].group(2)!)) != '2025.12.31(기말)') {
          throw const FormatException('Rootloc CE end mismatch');
        }
        for (var i = start + 1; i <= end; i++) {
          if (cells(i).length != 7 ||
              cells(i).any(
                (c) => RegExp(
                  r'(?:rowspan|colspan)\s*=',
                  caseSensitive: false,
                ).hasMatch(c.group(1)!),
              )) {
            throw const FormatException(
              'Rootloc CE current block shape mismatch',
            );
          }
        }
        for (final date in ['2025.1.1(기초)', '2025.12.31(기말)']) {
          if (rawRows
                  .where((r) => _compact(_text(r.group(1)!)).contains(date))
                  .length !=
              1) {
            throw const FormatException('Rootloc CE current dates ambiguous');
          }
        }
        final profits = [
          for (var i = start + 1; i < end; i++)
            if (cells(i).length == 7 &&
                _compact(_text(cells(i)[0].group(2)!)) == '당기순손실')
              i,
        ];
        if (profits.length != 1) {
          throw const FormatException('Rootloc CE whole profit ambiguous');
        }
        String total(int row) {
          final cs = cells(row);
          if (cs.length != 7 ||
              cs.any(
                (c) => RegExp(
                  r'(?:rowspan|colspan)\s*=',
                  caseSensitive: false,
                ).hasMatch(c.group(1)!),
              )) {
            throw const FormatException(
              'Rootloc CE whole monetary span ambiguous',
            );
          }
          final value = _text(cs.last.group(2)!).trim();
          if (!RegExp(r'^(?:-?\d{1,3}(?:,\d{3})*|\(\d{1,3}(?:,\d{3})*\))$')
              .hasMatch(value)) {
            throw const FormatException('Rootloc CE whole amount invalid');
          }
          final amount = value.startsWith('(')
              ? -BigInt.parse(
                  value.substring(1, value.length - 1).replaceAll(',', ''),
                )
              : BigInt.parse(value.replaceAll(',', ''));
          return (amount * BigInt.from(1000)).toString();
        }

        proofs.add({
          'mode': 'exact-rootloc-year-term-whole-ce-period',
          'tableIndex': index,
          'currentTerm': term,
          'currentHeader': '2025년도(제12기)',
          'periodStart': '2025-01-01',
          'periodEnd': '2025-12-31',
          'startRow': start,
          'endRow': end,
          'profitRow': profits.single,
          'totalColumn': 7,
          'unit': '천원',
          'unitMultiplier': '1000',
          'closingEquity': total(end),
          'currentProfit': total(profits.single),
          'source': statementSource.toString(),
        });
      }
      if (proofs.length != 1) {
        throw const FormatException('Rootloc CE source ambiguous');
      }
      cnsPeriodProof = proofs.single;
    }
    if ((cnsScope || cronexScope) && titles.isEmpty) {
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
        final startRow = uniqueRow(
          cronexScope ? '2025년01월01일(당기초)' : '2025.1.1(당기초)',
        );
        final endRow = uniqueRow(
          cronexScope ? '2025년12월31일(당기말)' : '2025.12.31(당기말)',
        );
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
          if (!(cronexScope
                  ? RegExp(r'^(?:-?\d{1,3}(?:,\d{3})*|\(\d{1,3}(?:,\d{3})*\))$')
                  : RegExp(r'^-?\d{1,3}(?:,\d{3})*$'))
              .hasMatch(v)) {
            throw const FormatException('CNS supporting amount invalid');
          }
          return (v.startsWith('(')
                  ? -BigInt.parse(
                      v.substring(1, v.length - 1).replaceAll(',', ''),
                    )
                  : BigInt.parse(v.replaceAll(',', '')))
              .toString();
        }

        candidates.add({
          'mode': cronexScope
              ? 'exact-cronex-undated-title-equity-period-corroboration'
              : 'same-document-equity-change-period-corroboration',
          'tableIndex': index,
          'currentTerm': term,
          'currentHeader': cronexScope ? '제14(당)기' : '2025년도(제26기)',
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
            .replaceFirst(
              RegExp(r'(?:\(주(?:석)?[0-9]+(?:,[0-9]+)*\)|<주석[0-9]+>)$'),
              '',
            );
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
      '연결당기순손익': ('profit', 'CIS'),
      '연결당기순이익': ('profit', 'CIS'),
      '연결당기순이익(손실)': ('profit', 'CIS'),
      '연결당기순손실': ('profit', 'CIS'),
      '당기순이익(손실)': ('profit', 'CIS'),
      '영업활동으로인한현금흐름(1+2+3)': ('cfo', 'CF'),
      '영업활동으로인한현금흐름': ('cfo', 'CF'),
      '영업활동현금흐름': ('cfo', 'CF'),
      '영업활동순현금흐름': ('cfo', 'CF'),
      '영업활동으로인한순현금흐름': ('cfo', 'CF'),
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

    // A term(year) header is one group, not two independent current columns.
    // Require a full printed annual interval and independent whole CE totals.
    final termYearHeaderCandidate =
        periodEnd.difference(periodStart).inDays >= 364 &&
        periodEnd.difference(periodStart).inDays <= 365 &&
        text.contains('제$term기(${periodEnd.year}년)');
    final exactInnovexOfs =
        receipt == '20250320001369' &&
        corpCode == '01353848' &&
        !consolidated &&
        term == '12' &&
        periodStart == DateTime.utc(2024) &&
        periodEnd == DateTime.utc(2024, 12, 31) &&
        coverSource.queryParameters['dcmNo'] == '10439334' &&
        coverSource.queryParameters['eleId'] == '1' &&
        coverSource.queryParameters['offset'] == '955' &&
        coverSource.queryParameters['length'] == '4504' &&
        statementSource.queryParameters['dcmNo'] == '10439334' &&
        statementSource.queryParameters['eleId'] == '21' &&
        statementSource.queryParameters['offset'] == '203049' &&
        statementSource.queryParameters['length'] == '51955';
    final exactPimCfs =
        receipt == '20250321001900' &&
        corpCode == '00765897' &&
        consolidated &&
        term == '24' &&
        periodStart == DateTime.utc(2024) &&
        periodEnd == DateTime.utc(2024, 12, 31) &&
        coverSource.queryParameters['dcmNo'] == '10450768' &&
        coverSource.queryParameters['eleId'] == '1' &&
        statementSource.queryParameters['dcmNo'] == '10450768' &&
        statementSource.queryParameters['eleId'] == '19' &&
        statementSource.queryParameters['offset'] == '204544' &&
        statementSource.queryParameters['length'] == '68462';
    Map<String, dynamic>? datedPunctuationProof = _suntechRawCePeriod(
      receipt: receipt,
      corpCode: corpCode,
      coverHtml: coverHtml,
      statementHtml: statementHtml,
      coverSource: coverSource,
      statementSource: statementSource,
      start: periodStart,
      end: periodEnd,
      consolidated: consolidated,
    );
    if (datedPunctuationProof == null &&
        (exactInnovexOfs ||
            parenthesizedTitles.isNotEmpty ||
            bsDurationCandidate ||
            termYearHeaderCandidate)) {
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
        // Only this source's literal, nonnumeric CE separator rows may span seven.
        // Headers and numeric rows still use the unchanged bounded grid parser.
        var equityHtml = table.group(1)!;
        if (exactInnovexOfs) {
          equityHtml = equityHtml.replaceAllMapped(
            RegExp(
              r'<TR\b[^>]*>(.*?)</TR>',
              caseSensitive: false,
              dotAll: true,
            ),
            (row) {
              final cells = RegExp(
                r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
                caseSensitive: false,
                dotAll: true,
              ).allMatches(row.group(1)!).toList();
              if (cells.length == 1 &&
                  RegExp(
                    r'''colspan\s*=\s*['"]?7(?:['"]|\s|$)''',
                    caseSensitive: false,
                  ).hasMatch(cells.single.group(1)!)) {
                if (RegExp(
                          r'colspan',
                          caseSensitive: false,
                        ).allMatches(cells.single.group(1)!).length !=
                        1 ||
                    !{
                      '총포괄손익:',
                      '자본에직접반영된소유주와의거래등:',
                    }.contains(_compact(_text(cells.single.group(2)!))) ||
                    RegExp(
                      r'rowspan',
                      caseSensitive: false,
                    ).hasMatch(cells.single.group(1)!)) {
                  throw const FormatException('Innovex CE separator mismatch');
                }
                return '';
              }
              return row.group(0)!;
            },
          );
        }
        final grid = _FinancialHtmlGrid.parse(equityHtml);
        final innovexWholeHeader =
            exactInnovexOfs &&
            grid.length >= 2 &&
            grid[0].length == 7 &&
            grid[1].length == 7 &&
            _compact(grid[0][0]?.text ?? '') == '과목' &&
            grid[0][0]?.rowspan == 2 &&
            grid[0][0]?.colspan == 1 &&
            identical(grid[0][0], grid[1][0]) &&
            _compact(grid[0][1]?.text ?? '') == '자본' &&
            grid[0][1]?.rowspan == 1 &&
            grid[0][1]?.colspan == 6 &&
            [for (var c = 1; c <= 6; c++) identical(grid[0][1], grid[0][c])]
                .every((v) => v) &&
            [for (var c = 1; c <= 6; c++) _compact(grid[1][c]?.text ?? '')]
                    .join('|') ==
                '자본금|자본잉여금|자본조정|기타자본|이익잉여금(결손금)|합계' &&
            [
              for (var c = 1; c <= 6; c++)
                grid[1][c]?.rowspan == 1 && grid[1][c]?.colspan == 1,
            ].every((v) => v);
        if (exactInnovexOfs && !innovexWholeHeader) {
          throw const FormatException('Innovex CE whole header mismatch');
        }

        if (grid.isEmpty ||
            !{'과목', '구분'}.contains(_compact(grid.first.first?.text ?? ''))) {
          continue;
        }
        final pimWholeHeader =
            exactPimCfs &&
            grid.length >= 2 &&
            grid[0].length == 9 &&
            grid[1].length == 9 &&
            _compact(grid[0][0]?.text ?? '') == '구분' &&
            grid[0][0]?.rowspan == 2 &&
            grid[0][0]?.colspan == 1 &&
            identical(grid[0][0], grid[1][0]) &&
            _compact(grid[0][1]?.text ?? '') == '지배기업소유주지분' &&
            grid[0][1]?.colspan == 6 &&
            grid[0][1]?.rowspan == 1 &&
            [for (var c = 1; c <= 6; c++) identical(grid[0][1], grid[0][c])]
                .every((v) => v) &&
            _compact(grid[0][7]?.text ?? '') == '비지배지분' &&
            _compact(grid[0][8]?.text ?? '') == '합계' &&
            [7, 8].every(
              (c) =>
                  grid[0][c]?.rowspan == 2 &&
                  grid[0][c]?.colspan == 1 &&
                  identical(grid[0][c], grid[1][c]),
            ) &&
            [for (var c = 1; c <= 6; c++) _compact(grid[1][c]?.text ?? '')]
                    .join('|') ==
                '자본금|자본잉여금|기타자본|기타포괄손익누계액|이익잉여금|합계' &&
            [
              for (var c = 1; c <= 6; c++)
                grid[1][c]?.rowspan == 1 && grid[1][c]?.colspan == 1,
            ].every((v) => v);
        if (!pimWholeHeader &&
            !innovexWholeHeader &&
            (grid.first.length < 3 ||
                !{
                  '총계',
                  '합계',
                  '자본합계',
                }.contains(_compact(grid.first.last?.text ?? '')) ||
                grid.first.any(
                  (c) => c == null || c.rowspan != 1 || c.colspan != 1,
                ) ||
                grid.first.any(
                  (c) => _compact(c?.text ?? '').contains('비지배'),
                ))) {
          throw const FormatException(
            'Dated punctuation supporting whole equity header mismatch',
          );
        }
        final units = RegExp(r'\(단위:([^)]*)\)').allMatches(local).toList();
        final unit = units.isEmpty ? null : units.last.group(1);
        if ((pimWholeHeader || innovexWholeHeader) && unit != '원') {
          throw const FormatException('PIM whole equity unit mismatch');
        }
        final multiplier = switch (unit) {
          '원' => BigInt.one,
          '천원' => BigInt.from(1000),
          '백만원' => BigInt.from(1000000),
          _ => throw const FormatException(
            'Unsupported supporting equity unit',
          ),
        };
        DateTime? rowDate(String text) {
          final m =
              RegExp(
                r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?(?:\(보고금액\)|\(당기초\)|\(당기말\)|\(기초자본\)|\(기말자본\)|잔액)$',
              ).firstMatch(
                innovexWholeHeader
                    ? _compact(text).replaceFirst(
                        RegExp(r'^Ⅲ\.(?=\d{4}\.\d{2}\.\d{2}\(기말자본\)$)'),
                        '',
                      )
                    : _compact(text),
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
                }.contains(_compact(grid[r].first?.text ?? '')) ||
                (termYearHeaderCandidate &&
                    _compact(grid[r].first?.text ?? '') == '당기순손익'))
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
          'mode': innovexWholeHeader
              ? 'exact-innovex-ofs-whole-equity-corroboration'
              : pimWholeHeader
              ? 'exact-pim-cfs-span-whole-equity-corroboration'
              : termYearHeaderCandidate
              ? 'full-annual-term-year-whole-equity-corroboration'
              : bsDurationCandidate
              ? 'primary-bs-duration-equity-corroboration'
              : 'fully-dated-parentheses-equity-corroboration',
          'tableIndex': index,
          if (innovexWholeHeader) 'wholeTotalColumn': 6,
          if (innovexWholeHeader) 'literalSeparatorRowsExcluded': true,
          if (pimWholeHeader) 'wholeTotalColumn': 8,
          if (pimWholeHeader) 'parentSubtotalColumn': 6,
          if (pimWholeHeader) 'nonControllingColumn': 7,
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
    final novmetaHeading =
        receipt == '20260320000871' &&
        corpCode == '01065785' &&
        !consolidated &&
        term == '16' &&
        periodStart == DateTime.utc(2025) &&
        periodEnd == DateTime.utc(2025, 12, 31) &&
        statementSource.queryParameters['dcmNo'] == '11157401' &&
        statementSource.queryParameters['eleId'] == '21' &&
        statementSource.queryParameters['offset'] == '429403' &&
        statementSource.queryParameters['length'] == '46142';
    final imgtMissingRevenue =
        receipt == '20260330001850' &&
        corpCode == '01579020' &&
        term == '16' &&
        periodStart == DateTime.utc(2025) &&
        periodEnd == DateTime.utc(2025, 12, 31) &&
        statementSource.queryParameters['dcmNo'] == '11198920' &&
        statementSource.queryParameters['eleId'] ==
            (consolidated ? '19' : '21') &&
        statementSource.queryParameters['offset'] ==
            (consolidated ? '354048' : '739348') &&
        statementSource.queryParameters['length'] ==
            (consolidated ? '51356' : '45486');
    Map<String, dynamic>? missingRevenue;
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
      } else if (labels.contains('영업활동으로인한현금흐름(1+2+3)') ||
          labels.contains('영업활동으로인한현금흐름') ||
          labels.contains('영업활동으로인한현금흐름(순액)') ||
          labels.contains('영업활동현금흐름') ||
          labels.contains('영업활동순현금흐름') ||
          (spacMissingRevenue && labels.contains('영업활동으로인한순현금흐름'))) {
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
                (termYearHeaderCandidate &&
                    _compact(c.text) == '제$term기(${periodEnd.year}년)') ||
                (medysseyScope &&
                    kind == 'CF' &&
                    _compact(c.text) == '제23당)기말') ||
                (kiwoomRepeatedTermScope &&
                    kind == 'CF' &&
                    _compact(c.text) == '제24기(당)기') ||
                (konasolScope && kind == 'CF' && _compact(c.text) == '2025년') ||
                (datedPunctuationProof?['mode'] ==
                        'exact-suntech-unscaled-raw-ce-period-corroboration' &&
                    consolidated &&
                    ((kind == 'BS' && _compact(c.text) == '제30(당)기(연결)') ||
                        (kind == 'CF' && _compact(c.text) == '제30(당)'))),
          )
          .toSet();
      if (headers.length != 1) {
        throw const FormatException('Ambiguous annual current header');
      }
      final current = headers.single;
      if (medysseyScope &&
          (current.column != 2 ||
              current.colspan != 2 ||
              current.rowspan != 1 ||
              grid.first.length != 8 ||
              _compact(grid.first[0]?.text ?? '') != '과목' ||
              _compact(grid.first[1]?.text ?? '') != '주석' ||
              _compact(grid.first[4]?.text ?? '') != '제22(전)기말' ||
              _compact(grid.first[6]?.text ?? '') != '제21(전전)기말')) {
        throw const FormatException('Medyssey primary current column mismatch');
      }
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
              (jilgyungyiScope
                  ? (current.column != 2 ||
                        current.rowspan != 1 ||
                        current.colspan != (kind == 'CIS' ? 1 : 2) ||
                        _compact(current.text) != '제10(당)기')
                  : cronexScope
                  ? (current.column != 1 ||
                        current.colspan != 2 ||
                        _compact(current.text) !=
                            (kind == 'BS' ? '제14(당)기말' : '제14(당)기'))
                  : (rootlocScope
                        ? (current.column != 3 ||
                              current.colspan != 1 ||
                              _compact(current.text) != '2025년도(제12기)')
                        : _compact(current.text) != '2025년도(제26기)')))) {
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
        final account =
            novmetaHeading &&
                kind == 'CF' &&
                label(row.first?.text ?? '') == '영업활동으로부터의순현금유출'
            ? ('cfo', 'CF')
            : accounts[label(row.first?.text ?? '')];
        if (account == null || account.$2 != kind) continue;
        // This exact source has a section caption with all three year cells
        // empty, followed by a separately printed whole-company CFO total.
        if (novmetaHeading &&
            kind == 'CF' &&
            label(row.first?.text ?? '') == '영업활동현금흐름') {
          final totals = grid
              .where(
                (r) =>
                    r.isNotEmpty &&
                    label(r.first?.text ?? '') == '영업활동으로부터의순현금유출',
              )
              .toList();
          if (row.length != 4 ||
              current.column != 1 ||
              current.colspan != 1 ||
              row.any((c) => c == null || c.rowspan != 1 || c.colspan != 1) ||
              row.skip(1).any((c) => c!.text.trim().isNotEmpty) ||
              totals.length != 1 ||
              grid.indexOf(totals.single) <= grid.indexOf(row)) {
            throw const FormatException(
              'Novmeta empty CF section caption mismatch',
            );
          }
          continue;
        }

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
        if ((imgtMissingRevenue || spacMissingRevenue) &&
            account.$1 == 'revenue' &&
            kind == 'CIS' &&
            label(row.first!.text) == '영업수익') {
          if (missingRevenue != null ||
              current.column != 2 ||
              current.colspan != (spacMissingRevenue ? 2 : 1) ||
              cells.length != (spacMissingRevenue ? 2 : 1) ||
              cells.where((c) => c!.text.trim() == '-').length != 1 ||
              cells.any(
                (c) => c!.text.trim().isNotEmpty && c.text.trim() != '-',
              )) {
            throw const FormatException(
              'IMGT explicit missing revenue cell mismatch',
            );
          }
          missingRevenue = {
            'rcept_no': receipt,
            'corp_code': corpCode,
            'bsns_year': '${periodEnd.year}',
            'reprt_code': '11011',
            'account_id': null,
            'account_nm': row.first!.text,
            'account_detail': '-',
            'sj_div': 'CIS',
            'thstrm_nm': '${periodEnd.year}-01-01~${periodEnd.year}-12-31',
            'thstrm_amount': null,
            'currency': 'KRW',
            'html_provenance': {
              if (linkedAudit)
                'sameReceiptAuditSource': SameReceiptAuditSource.evidence(
                  receipt,
                ),
              'source': statementSource.toString(),
              'tableIndex': index,
              'printedLabel': row.first!.text,
              'currentColumn': 2,
              'currentColumnSpan': current.colspan,
              'currentHeader': current.text,
              'printedCurrentCells': [for (final c in cells) c!.text.trim()],
              'basis': consolidated ? 'CFS' : 'OFS',
              'unit': printedUnit,
              'periodStart': '${periodEnd.year}-01-01',
              'periodEnd': '${periodEnd.year}-12-31',
              'explicitMissingAmount': 'printed-dash-no-zero-or-prior',
              'missingRequiredAccount': 'revenue',
              'partialCoreRule': spacMissingRevenue
                  ? 'spac-explicit-revenue-null-v1'
                  : 'imgt-explicit-revenue-null-v1',
            },
          };
          continue;
        }
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
            if (linkedAudit)
              'sameReceiptAuditSource': SameReceiptAuditSource.evidence(
                receipt,
              ),
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
        }.every(
          (key) =>
              key == 'revenue' &&
                  (imgtMissingRevenue || spacMissingRevenue) &&
                  missingRevenue != null ||
              values.containsKey(key),
        ) ||
        values['assets'] != values['liabilities']! + values['equity']!) {
      throw const FormatException(
        'Annual primary core missing or balance mismatch',
      );
    }
    if (spacMissingRevenue) {
      if (missingRevenue == null) {
        throw const FormatException('SPAC revenue missing printed dash');
      }
      final proofs = <Map<String, dynamic>>[];
      for (final t in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final prefix = _compact(_text(scope.substring(0, t.start)));
        final ce = prefix.lastIndexOf('자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => prefix.lastIndexOf(h) > ce)) {
          continue;
        }
        final g = _FinancialHtmlGrid.parse(t[1]!);
        if (g.isEmpty || _compact(g.first.first?.text ?? '') != '과목') {
          continue;
        }
        final local = prefix.substring(ce);
        final ts = titlePattern.allMatches(local).toList();
        if (ts.length != 1 ||
            ts.single.group(2) == '현재' ||
            sourceDate(ts.single.group(1)!) != periodStart ||
            sourceDate(ts.single.group(3)!) != periodEnd ||
            !local.endsWith('(단위:원)') ||
            !local.contains(company)) {
          throw const FormatException('SPAC CE issuer period unit mismatch');
        }
        final cp = receipt == '20230315000997';
        final expected = cp
            ? '과목|자본금|기타불입자본|기타불입자본|이익잉여금(결손금)|총계'
            : '과목|주석|자본금|자본잉여금|기타자본항목|이익잉여금|총계';
        if (g.first.map((c) => _compact(c?.text ?? '')).join('|') != expected) {
          throw const FormatException('SPAC CE whole header mismatch');
        }
        final startLabel = cp ? '2022.01.01(당기초)' : '2022년01월01일(당기초)';
        final endLabel = cp ? '2022.12.31(당기말)' : '2022년12월31일(당기말)';
        int one(String v) {
          final rows = [
            for (var i = 1; i < g.length; i++)
              if (_compact(g[i].first?.text ?? '') == v) i,
          ];
          if (rows.length != 1) {
            throw const FormatException('SPAC CE date ambiguous');
          }
          return rows.single;
        }

        final start = one(startLabel), end = one(endLabel);
        final marked = [
          for (var i = 1; i < g.length; i++)
            if (_compact(g[i].first?.text ?? '').contains('당기초') ||
                _compact(g[i].first?.text ?? '').contains('당기말'))
              i,
        ];
        if (marked.length != 2 || start >= end) {
          throw const FormatException('SPAC CE current range conflict');
        }
        final ps = [
          for (var i = start + 1; i < end; i++)
            if (_compact(g[i].first?.text ?? '') ==
                (cp ? '당기순이익' : '당기순이익(손실)'))
              i,
        ];
        if (ps.length != 1) {
          throw const FormatException('SPAC CE whole profit ambiguous');
        }
        BigInt whole(int r) {
          if (g[r].length != g.first.length ||
              g[r].any((c) => c == null || c.rowspan != 1 || c.colspan != 1)) {
            throw const FormatException('SPAC CE row shape mismatch');
          }
          final v = money(g[r].last!.text);
          if (v == null) {
            throw const FormatException('SPAC CE current amount missing');
          }
          return v;
        }

        if (whole(end) != values['equity'] ||
            whole(ps.single) != values['profit']) {
          throw const FormatException('SPAC CE whole net equity conflict');
        }
        proofs.add({
          'mode': 'spac-explicit-revenue-null-v1',
          'wholeTotalColumn': g.first.length - 1,
          'source': statementSource.toString(),
          'periodStart': '2022-01-01',
          'periodEnd': '2022-12-31',
          'unit': '원',
          'currentProfit': whole(ps.single).toString(),
          'closingEquity': whole(end).toString(),
        });
      }
      if (proofs.length != 1) {
        throw const FormatException('SPAC CE proof absent or ambiguous');
      }
      result.add(missingRevenue);
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            proofs.single;
      }
    }
    if (imgtMissingRevenue) {
      if (missingRevenue == null) {
        throw const FormatException(
          'IMGT revenue must be explicitly unavailable',
        );
      }
      final proofs = <Map<String, dynamic>>[];
      for (final t in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final prefix = _compact(_text(scope.substring(0, t.start)));
        final ce = prefix.lastIndexOf('자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => prefix.lastIndexOf(h) > ce)) {
          continue;
        }
        final g = _FinancialHtmlGrid.parse(t[1]!);
        if (g.isEmpty ||
            g.first.isEmpty ||
            _compact(g.first.first?.text ?? '') != '과목') {
          continue;
        }
        final local = prefix.substring(ce);
        if (!local.contains('제16(당)기2025년1월1일부터2025년12월31일까지') ||
            !local.endsWith('(단위:원)') ||
            !local.contains(consolidated ? '주식회사아이엠지티와그종속기업' : '주식회사아이엠지티')) {
          throw const FormatException('IMGT CE issuer period unit mismatch');
        }
        final header = consolidated
            ? '과목|자본금|자본잉여금|기타자본구성요소|결손금|지배기업소유주지분|비지배지분|총계'
            : '과목|자본금|자본잉여금|기타자본구성요소|결손금|총계';
        if (g.first.map((c) => _compact(c?.text ?? '')).join('|') != header ||
            g.first.any((c) => c == null || c.rowspan != 1 || c.colspan != 1)) {
          throw const FormatException('IMGT CE whole header mismatch');
        }
        int one(String label) {
          final rows = [
            for (var i = 1; i < g.length; i++)
              if (_compact(g[i].first?.text ?? '') == label) i,
          ];
          if (rows.length != 1) {
            throw const FormatException('IMGT CE explicit date ambiguous');
          }
          return rows.single;
        }

        final before = one('2025년1월1일(당기초,수정전)');
        final restated = one('2025년1월1일(당기초,재작성)');
        final end = one('2025년12월31일(당기말)');
        final marked = [
          for (var i = 1; i < g.length; i++)
            if (_compact(g[i].first?.text ?? '').contains('당기초') ||
                _compact(g[i].first?.text ?? '').contains('당기말'))
              i,
        ];
        if (marked.length != 3 || before >= restated || restated >= end) {
          throw const FormatException('IMGT CE restatement sequence mismatch');
        }
        final profit = [
          for (var i = restated + 1; i < end; i++)
            if (_compact(g[i].first?.text ?? '') ==
                (consolidated ? '당기순이익(손실)' : '당기순손실'))
              i,
        ];
        if (profit.length != 1) {
          throw const FormatException('IMGT CE current whole profit ambiguous');
        }
        BigInt whole(int r) {
          if (g[r].length != g.first.length ||
              g[r].any((c) => c == null || c.rowspan != 1 || c.colspan != 1)) {
            throw const FormatException('IMGT CE current row shape mismatch');
          }
          final v = money(g[r].last!.text);
          if (v == null) {
            throw const FormatException('IMGT CE whole amount unavailable');
          }
          return v;
        }

        if (whole(end) != values['equity'] ||
            whole(profit.single) != values['profit']) {
          throw const FormatException('IMGT CE whole profit equity conflict');
        }
        proofs.add({
          'mode': 'imgt-explicit-revenue-null-v1',
          'wholeTotalColumn': g.first.length - 1,
          'currentProfit': whole(profit.single).toString(),
          'closingEquity': whole(end).toString(),
          'restatementStartLabels': [
            '2025년1월1일(당기초,수정전)',
            '2025년1월1일(당기초,재작성)',
          ],
          'source': statementSource.toString(),
        });
      }
      if (proofs.length != 1) {
        throw const FormatException('IMGT CE proof absent or ambiguous');
      }
      result.add(missingRevenue);
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            proofs.single;
      }
    }
    if (medysseyScope) {
      final proofs = <Map<String, dynamic>>[];
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final preceding = _compact(_text(scope.substring(0, table.start)));
        final ce = preceding.lastIndexOf('연결자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((h) => preceding.lastIndexOf(h) > ce)) {
          continue;
        }
        final grid = _FinancialHtmlGrid.parse(table[1]!);
        if (grid.isEmpty ||
            grid.first.isEmpty ||
            _compact(grid.first.first?.text ?? '') != '과목') {
          continue;
        }
        final local = preceding.substring(ce);
        if (!local.contains('제23(당)기:2025년01월01일부터2025년12월31일까지') ||
            !local.endsWith('주식회사메디쎄이와그종속기업(단위:원)') ||
            grid.first.length != 8 ||
            grid.first.map((c) => _compact(c?.text ?? '')).join('|') !=
                '과목|주석|자본금|자본잉여금|기타자본구성요소|기타포괄손익누계액|이익잉여금|총계' ||
            grid.first.any(
              (c) => c == null || c.colspan != 1 || c.rowspan != 1,
            )) {
          throw const FormatException(
            'Medyssey whole CE header/period/unit mismatch',
          );
        }
        int unique(String label) {
          final found = [
            for (var i = 1; i < grid.length; i++)
              if (_compact(grid[i].first?.text ?? '') == label) i,
          ];
          if (found.length != 1) {
            throw const FormatException('Medyssey CE date ambiguous');
          }
          return found.single;
        }

        final start = unique('2025.01.01(당기초)'),
            end = unique('2025.12.31(당기말)');
        final profits = [
          for (var i = start + 1; i < end; i++)
            if (_compact(grid[i].first?.text ?? '') == '당기순이익') i,
        ];
        if (start >= end || profits.length != 1) {
          throw const FormatException(
            'Medyssey CE current whole profit ambiguous',
          );
        }
        BigInt whole(int i) {
          if (grid[i].length != 8 ||
              grid[i][7] == null ||
              grid[i][7]!.colspan != 1 ||
              grid[i][7]!.rowspan != 1) {
            throw const FormatException('Medyssey CE whole column mismatch');
          }
          final v = money(grid[i][7]!.text);
          if (v == null) {
            throw const FormatException('Medyssey CE money missing');
          }
          return v;
        }

        proofs.add({
          'mode': 'exact-medyssey-CF-current-header-whole-CE',
          'receipt': receipt,
          'corpCode': corpCode,
          'source': statementSource.toString(),
          'rawHeader': '제 23당) 기말',
          'currentTerm': term,
          'periodStart': '2025-01-01',
          'periodEnd': '2025-12-31',
          'totalColumn': 7,
          'currentProfit': whole(profits.single).toString(),
          'closingEquity': whole(end).toString(),
        });
      }
      if (proofs.length != 1 ||
          proofs.single['currentProfit'] != values['profit'].toString() ||
          proofs.single['closingEquity'] != values['equity'].toString()) {
        throw const FormatException(
          'Medyssey CE whole profit/equity contradiction',
        );
      }
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            proofs.single;
      }
    }
    if (kiwoomRepeatedTermScope) {
      final ceProofs = <Map<String, dynamic>>[];
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(scope)) {
        final preceding = _compact(_text(scope.substring(0, table.start)));
        final ce = preceding.lastIndexOf('연결자본변동표');
        if (ce < 0 ||
            [
              '재무상태표',
              '손익계산서',
              '현금흐름표',
            ].any((t) => preceding.lastIndexOf(t) > ce)) {
          continue;
        }
        var body = table.group(1)!;
        // Explicit nonnumeric category captions occupy all nine CE columns.
        body = body.replaceAllMapped(
          RegExp(r'<TR\b[^>]*>.*?</TR>', caseSensitive: false, dotAll: true),
          (m) {
            final cells = RegExp(
              r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
              caseSensitive: false,
              dotAll: true,
            ).allMatches(m[0]!).toList();
            return cells.length == 1 &&
                    {
                      '총포괄이익:',
                      '기타포괄손익:',
                      '자본에인식된주주거래:',
                    }.contains(_compact(_text(cells.single[2]!)))
                ? ''
                : m[0]!;
          },
        );
        final grid = _FinancialHtmlGrid.parse(body);
        if (grid.length < 3 ||
            grid.first.isEmpty ||
            _compact(grid.first.first?.text ?? '') != '과목') {
          continue;
        }
        if (grid.first.length != 9 ||
            grid[1].length != 9 ||
            grid[0][0]?.rowspan != 2 ||
            grid[0][1]?.colspan != 6 ||
            _compact(grid[0][1]?.text ?? '') != '지배주주지분' ||
            _compact(grid[0][7]?.text ?? '') != '비지배지분' ||
            _compact(grid[0][8]?.text ?? '') != '총계' ||
            _compact(grid[1][6]?.text ?? '') != '합계') {
          throw const FormatException(
            'Kiwoom supporting whole CE header mismatch',
          );
        }
        final local = preceding.substring(ce);
        final localDates = titlePattern.allMatches(local).toList();
        if (localDates.length != 1 ||
            localDates.single[2] == '현재' ||
            sourceDate(localDates.single[1]!) != periodStart ||
            sourceDate(localDates.single[3]!) != periodEnd ||
            !local.endsWith('(단위:원)')) {
          throw const FormatException(
            'Kiwoom supporting CE period/unit mismatch',
          );
        }
        int uniqueLabel(String label) {
          final found = [
            for (var i = 2; i < grid.length; i++)
              if (_compact(grid[i].first?.text ?? '') == label) i,
          ];
          if (found.length != 1) {
            throw const FormatException('Kiwoom supporting CE date ambiguous');
          }
          return found.single;
        }

        final start = uniqueLabel('2022년1월1일(당기초)');
        final end = uniqueLabel('2022년12월31일(당기말)');
        final profit = [
          for (var i = start + 1; i < end; i++)
            if (_compact(grid[i].first?.text ?? '') == '당기순이익') i,
        ];
        if (start >= end || profit.length != 1) {
          throw const FormatException(
            'Kiwoom supporting CE current profit ambiguous',
          );
        }
        BigInt whole(int i) {
          if (grid[i].length != 9 ||
              grid[i][8] == null ||
              grid[i][8]!.colspan != 1 ||
              grid[i][8]!.rowspan != 1) {
            throw const FormatException('Kiwoom supporting CE total ambiguous');
          }
          final v = money(grid[i][8]!.text);
          if (v == null) {
            throw const FormatException(
              'Kiwoom supporting CE whole amount missing',
            );
          }
          return v;
        }

        ceProofs.add({
          'mode': 'exact-repeated-term-CFS-whole-CE',
          'receipt': receipt,
          'corpCode': corpCode,
          'source': statementSource.toString(),
          'currentTerm': term,
          'periodStart': '2022-01-01',
          'periodEnd': '2022-12-31',
          'totalColumn': 8,
          'currentProfit': whole(profit.single).toString(),
          'closingEquity': whole(end).toString(),
        });
      }
      if (ceProofs.length != 1 ||
          ceProofs.single['currentProfit'] != values['profit'].toString() ||
          ceProofs.single['closingEquity'] != values['equity'].toString()) {
        throw const FormatException(
          'Kiwoom supporting whole CE profit/equity contradiction',
        );
      }
      for (final row in result) {
        (row['html_provenance']
                as Map<String, dynamic>)['supportingPeriodEvidence'] =
            ceProofs.single;
      }
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
