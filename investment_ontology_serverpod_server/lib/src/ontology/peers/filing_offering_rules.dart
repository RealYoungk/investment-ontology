import 'product_offering_rules.dart';

/// Extracts offerings only from a current own-company operating statement or
/// a named product column with a positive current-year amount. Usage, customer,
/// purchase and subsidiary columns are never searched for product keywords.
abstract final class FilingOfferingRules {
  static List<((String, String, String, String), String)> parse(
    String text, {
    required String sector,
    required String companyName,
    required int year,
  }) {
    if (sector == 'holdings') {
      for (final line in text.split('\n')) {
        for (final sentence in line.split(RegExp(r'(?<=다[.!?])\s*'))) {
          final own = sentence.trim();
          if (RegExp(r'^당사는.{0,220}지주회사(?:로서|입니다|이며)').hasMatch(own)) {
            return [(('holdings', '지주회사', 'legal:holding', '지주회사'), own)];
          }
        }
      }
      return [];
    }
    final result = <((String, String, String, String), String)>[];
    final seen = <String>{};
    final ownName = _name(companyName);
    var active = false;
    var otherEntity = false;
    var product = -1, current = -1, entity = -1, width = 0;
    var yearColumns = 0, firstYear = -1;
    var headerOffset = 0;
    var offset = 0;
    void accept(String products, String evidence) {
      for (final match in ProductOfferingRules.match(products, sector)) {
        if (seen.add(match.$3)) result.add((match, evidence));
      }
    }

    for (final line in text.split('\n')) {
      final start = offset;
      offset += line.length + 1;
      if (line.startsWith('##')) {
        active = RegExp(r'사업의\s*개요|주요\s*제품|주요\s*서비스').hasMatch(line);
        product = current = -1;
        continue;
      }
      if (!active) continue;
      if (!line.contains('|') && RegExp(r'가격\s*변동|원재료|매입현황').hasMatch(line)) {
        active = false;
        continue;
      }
      if (!line.contains('|')) {
        product = current = -1;
        if (line.length < 200 &&
            RegExp(r'\[|【|\(\d+\)|[①②③④⑤]').hasMatch(line) &&
            RegExp(r'종속|자회사|㈜|\(주\)|주식회사').hasMatch(line)) {
          final heading = line.replaceAll(RegExp(r'\(주\)|㈜|주식회사'), ' ');
          otherEntity = !RegExp(
            r'(?<![가-힣A-Za-z0-9])' +
                ownName.split('').map(RegExp.escape).join(r'\s*') +
                r'(?![가-힣A-Za-z0-9])',
          ).hasMatch(heading);
        }
        if (otherEntity) continue;
        for (final raw in line.split(RegExp(r'(?<=다[.!?])\s*'))) {
          var sentence = raw.trim();
          // A separately introduced expansion clause does not change the
          // preceding explicit own-business clause; retain its verbatim span.
          final expansion = sentence.indexOf(', 현재');
          if (expansion > 0 &&
              sentence.substring(0, expansion).contains('주요사업으로 하고 있는')) {
            sentence = sentence.substring(0, expansion);
          }
          final own = sentence.indexOf('당사');
          if (own > 0 &&
              own < 70 &&
              RegExp(r'^(?:[가-힣0-9]+[.)]|[（(]?[0-9]+[)）])')
                  .hasMatch(sentence) &&
              !RegExp(r'종속|자회사|계열|고객|경쟁')
                  .hasMatch(sentence.substring(0, own))) {
            sentence = sentence.substring(own);
          }
          if (!RegExp(
                r'^(?:당사|회사)(?:는|의\s*(?:영위\s*|주요\s*)?(?:제품|사업|주력|중공업|물류))',
              ).hasMatch(sentence) ||
              sentence.length > 650 ||
              RegExp(
                r'종속|자회사|계열|연결회사|고객|경쟁|원재료|매입|구매|도입|사용|적용|계획|예정|목표|추진|검토|중단|철수|않|아닌|아니며|과거|설립목적',
              ).hasMatch(sentence) ||
              !RegExp(
                r'제조(?:하고|하는|업| 및)|생산(?:하고|하는| 및)|판매(?:하고|하는| 및)|공급(?:하고|하는)|제공(?:하고|하는)|영위|주력|전문.{0,12}기업|전문.{0,12}회사|사업부문을 운영|사업부문으로 구성|주요사업으로 하고 있는',
              ).hasMatch(sentence)) {
            continue;
          }
          accept(sentence, sentence);
        }
        continue;
      }
      final cells = line.split('|').map((c) => c.trim()).toList();
      final labels = cells.map((c) => c.replaceAll(RegExp(r'\s'), '')).toList();
      final pi = labels.indexWhere(
        (c) => {
          '제품',
          '제품명',
          '제품군',
          '품목',
          '주요제품',
          '주요제품등',
          '생산제품',
          '주요제품및서비스',
          '주요제품,서비스',
        }.contains(c),
      );
      if (pi >= 0) {
        if (labels.any((c) => RegExp(r'매입|매출처|고객|거래처').hasMatch(c))) continue;
        var ci = labels.indexWhere((c) => c.contains('$year'));
        if (ci < 0 &&
            !labels.any((c) => RegExp(r'20\d{2}|제\d+기|전기|전년').hasMatch(c))) {
          ci = labels.indexWhere((c) => c.contains('매출액'));
        }
        if (ci < 0) {
          final terms = labels
              .map(
                (c) => int.tryParse(
                  RegExp(r'제(\d+)기').firstMatch(c)?.group(1) ?? '',
                ),
              )
              .toList();
          final numbers = terms.whereType<int>().toList();
          if (numbers.length >= 2 && numbers.toSet().length == numbers.length) {
            final latest = numbers.reduce((a, b) => a > b ? a : b);
            ci = terms.indexOf(latest);
          }
        }
        if (ci > pi) {
          product = pi;
          current = ci;
          entity = labels.indexWhere(
            (c) => RegExp(r'회사|법인|종속').hasMatch(c),
          );
          width = cells.length;
          yearColumns = labels
              .where((c) => RegExp(r'20\d{2}|제\d+기').hasMatch(c))
              .length;
          firstYear = labels.indexWhere(
            (c) => RegExp(r'20\d{2}|제\d+기').hasMatch(c),
          );
          headerOffset = start;
          continue;
        }
      }
      // A second header expands year cells into amount/share pairs. Column
      // positions remain anchored to the named product and first current year.
      if (product >= 0 &&
          labels.isNotEmpty &&
          labels.every((c) => {'매출액', '비율', '비중'}.contains(c))) {
        if (yearColumns > 0 &&
            labels.length == yearColumns * 2 &&
            labels.first == '매출액') {
          width += yearColumns;
          if (firstYear >= 0) current += current - firstYear;
        }
        continue;
      }
      // Exact-width rows only: a merged cell can otherwise shift a usage field
      // into the product column, while still yielding a plausible number.
      if (product < 0 || current < 0 || cells.length != width) continue;
      if (entity >= 0) {
        if (_name(cells[entity]) != ownName) continue;
      } else if (otherEntity) {
        continue;
      }
      final rawAmount = cells[current]
          .replaceAll(',', '')
          .split('(')
          .first
          .trim();
      final amount = double.tryParse(rawAmount);
      if (amount == null || amount <= 0) continue;
      if (RegExp(r'중단\s*영업|사업\s*중단|사업\s*종료').hasMatch(line)) continue;
      final item = cells[product];
      if (RegExp(r'합계|총계|기타|원재료|사업중단').hasMatch(item)) continue;
      accept(item, text.substring(headerOffset, start + line.length));
    }
    return result;
  }

  static String _name(String value) =>
      value.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
}
