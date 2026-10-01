/// Validated strict subset of receipt-bound annual DART HTML statements.
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
}
