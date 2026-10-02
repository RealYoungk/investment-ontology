import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Corroborates literal current columns with dated primary statements and the
/// same basis' explicit whole equity total. Supplies no inferred amount.
abstract final class DatedCurrentHeaderProof {
  static Map<String, dynamic>? verify({
    required String coverHtml,
    required String statementHtml,
    required Uri coverSource,
    required Uri statementSource,
    required String receipt,
    required String companyName,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    try {
      _source(coverSource, receipt);
      _source(statementSource, receipt);
      if (coverSource.queryParameters['dcmNo'] !=
              statementSource.queryParameters['dcmNo'] ||
          start != DateTime.utc(end.year, 1, 1) ||
          end != DateTime.utc(end.year, 12, 31)) {
        return null;
      }
      final cover = _text(coverHtml);
      final metadata = RegExp(
        r'사업연도(\d{4})년(\d{1,2})월(\d{1,2})일부터(\d{4})년(\d{1,2})월(\d{1,2})일까지',
      ).allMatches(cover).toList();
      final terms = RegExp(r'사업보고서\(제(\d+)기\)').allMatches(cover).toList();
      final names = RegExp(r'회사명[:：]([^:：]*?)대표이사').allMatches(cover).toList();
      if (metadata.length != 1 ||
          terms.length != 1 ||
          names.length != 1 ||
          _name(names.single[1]!) != _name(companyName)) {
        return null;
      }
      final dates = metadata.single;
      if (_date(dates, 1) != start || _date(dates, 4) != end) return null;
      final term = terms.single[1]!;
      final body = _text(statementHtml);
      final own = consolidated ? '2.연결재무제표' : '4.재무제표';
      if (!body.startsWith(own) ||
          (consolidated
              ? body.contains('4.재무제표')
              : body.contains('2.연결재무제표')) ||
          body.contains('재무제표주석')) {
        return null;
      }
      final proofs = <String, Map<String, dynamic>>{};
      final amounts = <String, BigInt>{};
      Map<String, dynamic>? equity;
      var tableIndex = 0;
      for (final table in RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(statementHtml)) {
        final index = tableIndex++;
        final prefix = _text(statementHtml.substring(0, table.start));
        final heading = _heading(prefix);
        if (heading == null) continue;
        final local = prefix.substring(heading.$2);
        final rows = _grid(table[1]!, equity: heading.$1 == 'CE');
        if (rows.isEmpty || !{'과목', '구분'}.contains(rows.first.first.text)) {
          continue;
        }
        final kind = heading.$1;
        final labels = rows.map((r) => _label(r.first.text)).toSet();
        if (kind == 'BS' && !labels.containsAll({'자산총계', '부채총계', '자본총계'})) {
          continue;
        }
        if (kind == 'CIS' &&
            !labels.any((v) => _accounts['revenue']!.contains(v))) {
          continue;
        }
        if (kind == 'CF' && !labels.any((v) => _accounts['cfo']!.contains(v))) {
          continue;
        }
        if (!_caption(local, kind, term, start, end)) return null;
        final unit = RegExp(r'\(단위[:：](원|천원|백만원)\)').allMatches(local).toList();
        if (unit.length != 1) return null;
        final scale = switch (unit.single[1]!) {
          '원' => BigInt.one,
          '천원' => BigInt.from(1000),
          _ => BigInt.from(1000000),
        };
        if (kind == 'CE') {
          if (equity != null) return null;
          equity = _equity(rows, start, end, scale, consolidated, index);
          if (equity == null) return null;
          continue;
        }
        if (proofs.containsKey(kind)) return null;
        final accepted = kind == 'BS'
            ? {
                '당기말',
                '제$term기',
                '제$term(당)기말',
                '${end.year}년(제$term기)',
                '${end.year}년제$term(당)기말',
                '${end.year}연도',
                '${end.year}년도(제$term기말)',
                '제$term기(당)기말',
              }
            : {
                '당기',
                '제$term기',
                '제$term(당)기',
                '${end.year}연도',
                '${end.year}년',
                '${end.year}년제$term기',
                '${end.year}년도(제$term기말)',
                '${end.year}년도(제$term(당)기말)',
                '제$term기(당)기',
              };
        if (kind == 'BS') accepted.add('${end.year}년');
        final candidates = rows.first
            .toSet()
            .where((c) => accepted.contains(c.text))
            .toList();
        if (candidates.length != 1 ||
            (candidates.single.span != 1 &&
                !(kind == 'CF' && candidates.single.span == 2))) {
          return null;
        }
        final current = candidates.single;
        String? currentSubheader;
        if (rows.first.first.height == 2) {
          if (rows.length < 2 || rows[1].length <= current.column) return null;
          final sub = rows[1][current.column];
          if (sub.span != 1 || !{'제$term기', '(제$term기)'}.contains(sub.text)) {
            return null;
          }
          currentSubheader = sub.text;
        }
        final expected = switch (kind) {
          'BS' => ['assets', 'liabilities', 'equity'],
          'CIS' => ['revenue', 'operating', 'profit'],
          _ => ['cfo'],
        };
        for (final key in expected) {
          final matching = rows
              .where((r) => _accounts[key]!.contains(_label(r.first.text)))
              .toList();
          if (matching.length != 1 ||
              matching.single.length <= current.column) {
            return null;
          }
          final currentCells = matching.single
              .skip(current.column)
              .take(current.span)
              .toSet()
              .toList();
          if (currentCells.length != current.span ||
              currentCells.any((c) => c.span != 1 || c.height != 1)) {
            return null;
          }
          final numeric = currentCells.where((c) => c.text.isNotEmpty).toList();
          if (numeric.length != 1) return null;
          final money = _amount(numeric.single.text);
          if (money == null) return null;
          amounts[key] = money * scale;
        }
        proofs[kind] = {
          'tableIndex': index,
          'column': current.column,
          'header': current.text,
          'unit': unit.single[1],
          'subheader': ?currentSubheader,
        };
      }
      if (proofs.length != 3 ||
          equity == null ||
          amounts.length != 7 ||
          amounts['assets'] != amounts['liabilities']! + amounts['equity']! ||
          amounts['equity'] != equity['closingEquity'] ||
          amounts['profit'] != equity['currentProfit']) {
        return null;
      }
      return {
        'mode': 'dated-current-column-whole-equity-v1',
        'currentTerm': term,
        'periodStart': start.toIso8601String(),
        'periodEnd': end.toIso8601String(),
        'basis': consolidated ? 'CFS' : 'OFS',
        'receipt': receipt,
        'coverUri': coverSource.toString(),
        'statementUri': statementSource.toString(),
        'coverSha256': sha256.convert(utf8.encode(coverHtml)).toString(),
        'statementSha256': sha256
            .convert(utf8.encode(statementHtml))
            .toString(),
        'tables': proofs,
        'equityTableIndex': equity['tableIndex'],
        'wholeTotalColumn': equity['column'],
        'core': amounts.map((k, v) => MapEntry(k, v.toString())),
      };
    } on FormatException {
      return null;
    }
  }

  static const _accounts = {
    'assets': {'자산총계'},
    'liabilities': {'부채총계'},
    'equity': {'자본총계'},
    'revenue': {'매출액', '매출', '영업수익', '수익(매출액)'},
    'operating': {'영업이익', '영업이익(손실)', '영업손실'},
    'profit': {'당기순이익', '당기순이익(손실)', '당기순손실', '연결당기순손익'},
    'cfo': {'영업활동으로인한현금흐름', '영업활동현금흐름'},
  };
  static String _name(String v) =>
      _text(v).replaceAll('주식회사', '').replaceAll('(주)', '').replaceAll('㈜', '');
  static String _text(String v) => v
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', '')
      .replaceAll('&#160;', '')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), '');
  static String _label(String v) => v
      .replaceFirst(RegExp(r'^(?:[IVXⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]+[.．]|[0-9]+[.．])'), '')
      .replaceAll('[', '')
      .replaceAll(']', '');
  static BigInt? _amount(String v) {
    if (!RegExp(r'^(?:-?\d+|-?\d{1,3}(?:,\d{3})*|\(\d{1,3}(?:,\d{3})*\))$')
        .hasMatch(v)) {
      return null;
    }
    return BigInt.parse(
      v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
    );
  }

  static DateTime? _date(RegExpMatch m, int offset) {
    final y = int.parse(m[offset]!),
        month = int.parse(m[offset + 1]!),
        day = int.parse(m[offset + 2]!);
    final d = DateTime.utc(y, month, day);
    return d.year == y && d.month == month && d.day == day ? d : null;
  }

  static void _source(Uri u, String receipt) {
    if (u.scheme != 'https' ||
        u.host != 'dart.fss.or.kr' ||
        u.hasPort ||
        u.path != '/report/viewer.do' ||
        u.fragment.isNotEmpty ||
        u.queryParameters.length != 6 ||
        u.queryParameters['rcpNo'] != receipt ||
        !RegExp(r'^\d{14}$').hasMatch(receipt)) {
      throw const FormatException('source');
    }
    for (final key in ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd']) {
      final v = u.queryParametersAll[key];
      if (v == null ||
          v.length != 1 ||
          !(key == 'dtd'
              ? {'dart3.xsd', 'dart4.xsd'}.contains(v.single)
              : RegExp(r'^\d+$').hasMatch(v.single))) {
        throw const FormatException('source');
      }
    }
  }

  static (String, int)? _heading(String prefix) {
    final entries = {
      'BS': '재무상태표',
      'CIS': '손익계산서',
      'CE': '자본변동표',
      'CF': '현금흐름표',
    };
    (String, int)? found;
    for (final entry in entries.entries) {
      final pos = prefix.lastIndexOf(entry.value);
      if (pos >= 0 && (found == null || pos > found.$2)) {
        found = (entry.key, pos);
      }
    }
    return found;
  }

  static bool _caption(
    String local,
    String kind,
    String term,
    DateTime start,
    DateTime end,
  ) {
    final expected = RegExp(
      '^(?:재무상태표|손익계산서|자본변동표|현금흐름표)제$term(?:\\(당\\))?기(?:말)?[:：]?',
    );
    if (!expected.hasMatch(local)) return false;
    final dates = RegExp(r'(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?')
        .allMatches(local)
        .toList();
    if (kind == 'BS') return dates.isNotEmpty && _date(dates.first, 1) == end;
    return dates.length >= 2 &&
        _date(dates[0], 1) == start &&
        _date(dates[1], 1) == end &&
        local.substring(dates[0].end, dates[1].start) == '부터' &&
        local.substring(dates[1].end).startsWith('까지');
  }

  static Map<String, dynamic>? _equity(
    List<List<_Cell>> rows,
    DateTime start,
    DateTime end,
    BigInt scale,
    bool consolidated,
    int index,
  ) {
    final total = rows.first
        .toSet()
        .where((c) => {'총계', '합계', '자본총계', '총자본'}.contains(c.text))
        .toList();
    if (total.length != 1 ||
        total.single.span != 1 ||
        total.single.column != rows.first.length - 1) {
      return null;
    }
    final col = total.single.column;
    if (consolidated &&
        rows.first.any((c) => c.text == '비지배지분') &&
        !rows.first.any(
          (c) => {'지배기업소유주지분', '지배기업소유주', '지배기업의소유주에게귀속되는자본'}.contains(c.text),
        )) {
      return null;
    }
    bool labelDate(String v, DateTime d, String suffix) {
      final m = RegExp(
        r'^(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일)?\((당기초|당기말|보고금액)\)(?:\(감사받지아니한재무제표\)|\(감사받지아니함\))?$',
      ).firstMatch(v);
      return m != null &&
          _date(m, 1) == d &&
          (m[4] == suffix || (suffix == '당기초' && m[4] == '보고금액'));
    }

    final begins = <int>[], ends = <int>[];
    for (var i = 1; i < rows.length; i++) {
      if (labelDate(rows[i].first.text, start, '당기초')) begins.add(i);
      if (labelDate(rows[i].first.text, end, '당기말')) ends.add(i);
    }
    if (begins.length != 1 ||
        ends.length != 1 ||
        begins.single >= ends.single) {
      return null;
    }
    final profitRows = rows
        .sublist(begins.single + 1, ends.single)
        .where(
          (r) => {
            '당기순이익',
            '당기순손실',
            '당기순손익',
            '당기순이익(손실)',
          }.contains(_label(r.first.text)),
        )
        .toList();
    if (profitRows.length != 1 ||
        profitRows.single.length <= col ||
        rows[ends.single].length <= col) {
      return null;
    }
    final p = profitRows.single[col], e = rows[ends.single][col];
    final profit = _amount(p.text), equity = _amount(e.text);
    if (p.span != 1 || e.span != 1 || profit == null || equity == null) {
      return null;
    }
    return {
      'tableIndex': index,
      'column': col,
      'currentProfit': profit * scale,
      'closingEquity': equity * scale,
    };
  }

  static List<List<_Cell>> _grid(String html, {bool equity = false}) {
    final result = <List<_Cell>>[];
    final occupied = <String, _Cell>{};
    var row = 0;
    for (final tr in RegExp(
      r'<TR\b[^>]*>(.*?)</TR>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      // Exclude only literal CE section headings in one declared full-width
      // cell. This supplies no money and leaves the numeric span cap at six.
      if (equity && result.isNotEmpty) {
        final cells = RegExp(
          r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(tr[1]!).toList();
        const sectionLabels = {'총포괄이익:', '기타포괄손익', '소유주와의거래:'};
        if (cells.isNotEmpty &&
            sectionLabels.contains(_text(cells.first[2]!)) &&
            (cells.length == 1 ||
                cells.first[1]!.toLowerCase().contains('colspan'))) {
          final fullWidth = RegExp(
            'colspan=["\x27]${result.first.length}["\x27]',
            caseSensitive: false,
          ).hasMatch(cells.first[1]!);
          if (cells.length != 1 ||
              !fullWidth ||
              cells.first[1]!.toLowerCase().contains('rowspan') ||
              occupied.keys.any((k) => k.startsWith('$row:'))) {
            throw const FormatException('CE section heading shape');
          }
          continue;
        }
      }
      var col = 0;
      for (final td in RegExp(
        r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(tr[1]!)) {
        while (occupied.containsKey('$row:$col')) {
          col++;
        }
        int span(String key) {
          final m = RegExp(
            '$key\\s*=\\s*["\x27]?(\\d+)',
            caseSensitive: false,
          ).firstMatch(td[1]!);
          return m == null ? 1 : int.parse(m[1]!);
        }

        final width = span('colspan'), height = span('rowspan');
        if (width < 1 ||
            width > 6 ||
            height < 1 ||
            height > 2 ||
            col + width > 12) {
          throw const FormatException('span');
        }
        final cell = _Cell(_text(td[2]!), col, width, height);
        for (var y = row; y < row + height; y++) {
          for (var x = col; x < col + width; x++) {
            if (occupied.containsKey('$y:$x')) {
              throw const FormatException('overlap');
            }
            occupied['$y:$x'] = cell;
          }
        }
        col += width;
      }
      final columns = occupied.keys
          .where((k) => k.startsWith('$row:'))
          .map((k) => int.parse(k.split(':')[1]))
          .toList();
      if (columns.isEmpty) throw const FormatException('empty row');
      final width = columns.reduce((a, b) => a > b ? a : b) + 1;
      final cells = <_Cell>[];
      for (var x = 0; x < width; x++) {
        final cell = occupied['$row:$x'];
        if (cell == null) throw const FormatException('gap');
        cells.add(cell);
      }
      result.add(cells);
      row++;
    }
    return result;
  }
}

class _Cell {
  const _Cell(this.text, this.column, this.span, this.height);
  final String text;
  final int column;
  final int span;
  final int height;
}
