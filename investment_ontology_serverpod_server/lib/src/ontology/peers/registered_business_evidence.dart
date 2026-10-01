import 'registered_offerings.dart';

/// Corroborates a registered broad activity with an explicit current own-company
/// operating statement. Never upgrades it to a product, technology or peer claim.
abstract final class RegisteredBusinessEvidence {
  static String? find(
    String text, {
    required String industry,
    required String code,
    String companyName = '',
  }) {
    final definition = RegisteredOfferings.definition(industry, code);
    if (definition == null) return null;
    final ownName = companyName.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
    var active = false;
    var subsidiary = false;
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        active = RegExp(r'사업의\s*개요|주요\s*제품|주요\s*서비스|영업의\s*현황').hasMatch(line);
        continue;
      }
      // A separate legal-entity heading changes the subject of subsequent prose.
      if (line.length < 100 &&
          !line.contains('|') &&
          RegExp(r'^\s*(?:\[|【|가\.|나\.|다\.)[^.]*?(?:종속회사|종속기업|㈜|주식회사|\(주\))')
              .hasMatch(line)) {
        final heading = line.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
        subsidiary = !_ownHeading(heading, ownName);
      }
      if (!active || subsidiary || line.contains('|')) continue;
      for (final raw in line.split(RegExp(r'(?<=다[.!?])\s*'))) {
        var sentence = raw.trim();
        final own = RegExp(r'(?:당사|회사)(?:는|의\s*(?:주요\s*)?(?:사업|제품)은)\s*')
            .firstMatch(sentence);
        final named = sentence
            .replaceFirst(RegExp(r'^지배회사인\s*'), '')
            .replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
        final namedOwn =
            ownName.isNotEmpty &&
            (named.startsWith('$ownName는') || named.startsWith('$ownName은'));
        if (!namedOwn) {
          if (own == null || own.start > 35) continue;
          final prefix = sentence.substring(0, own.start);
          if (RegExp(r'종속|자회사|고객|경쟁|[가-힣]{2,}').hasMatch(prefix)) continue;
          sentence = sentence.substring(own.start);
        }
        final semanticBody = sentence.replaceFirst(RegExp(r'^지배회사인\s*'), '');
        if (sentence.length > 500 ||
            RegExp(
              r'종속|자회사|계열사|지배회사|고객사|경쟁사|계획|예정|목표|추진|검토|중단|철수|과거|폐업|매각|양도|않|아닌|아니며|구매|매입|원재료|도입|납품받|공급받|사용하|사용되|적용되|설립목적',
            ).hasMatch(semanticBody)) {
          continue;
        }
        for (final term in (definition['terms'] as List).cast<String>()) {
          final match = RegExp(
            term.split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s*'),
            caseSensitive: false,
          ).firstMatch(sentence);
          if (match == null) continue;
          final suffix = sentence.substring(match.end);
          if (RegExp(r'^\s*(?:업체|회사|고객|용|부품|주물|소재|재료|원료|의\s*부품|용\s*부품)')
              .hasMatch(suffix)) {
            continue;
          }
          // The activity must bind to an operating verb; an industry outlook,
          // market size, product price or aspiration is not a company activity.
          if (RegExp(
            r'^.{0,70}(?:제조|생산|판매|개발|공급|제공|운영|운용|영위|수행|주력|주업무|주사업|주요사업|전문\s*(?:제약회사|기업|회사))',
          ).hasMatch(suffix)) {
            return sentence;
          }
        }
      }
    }
    return _revenueTable(text, definition, ownName);
  }

  static String? _revenueTable(
    String text,
    Map<String, dynamic> definition,
    String ownName,
  ) {
    var active = false;
    var subsidiary = false;
    var revenue = -1;
    var product = -1;
    var columns = 0;
    var headerOffset = -1;
    var offset = 0;
    for (final line in text.split('\n')) {
      final start = offset;
      offset += line.length + 1;
      if (line.startsWith('##')) {
        active = RegExp(r'주요\s*제품|주요\s*서비스').hasMatch(line);
        revenue = -1;
        continue;
      }
      if (!active) continue;
      if (RegExp(r'종속회사|종속기업|자회사|\[.*(?:㈜|주식회사|\(주\))').hasMatch(line)) {
        final heading = line.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
        subsidiary = !_ownHeading(heading, ownName);
      }
      if (subsidiary) continue;
      if (!line.contains('|')) {
        if (line.trim().isNotEmpty) revenue = -1;
        continue;
      }
      final cells = line.split('|').map((c) => c.trim()).toList();
      final normalized = cells
          .map((c) => c.replaceAll(RegExp(r'\s'), ''))
          .toList();
      final ri = normalized.indexWhere(
        (c) => RegExp(r'^매출액(?:\(비율\))?$').hasMatch(c),
      );
      if (ri >= 0) {
        // The source must explicitly name the product and a current revenue
        // column. Ambiguous merged cells, customer/usage columns and years-only
        // headers are intentionally unsupported.
        revenue = -1;
        if (normalized.any((c) => RegExp(r'회사|법인|매출처|고객').hasMatch(c))) {
          continue;
        }
        product = normalized.indexWhere(
          (c) => {'품목', '주요제품', '주요제품및서비스', '제품', '제품명'}.contains(c),
        );
        if (product < 0) product = normalized.indexOf('사업부문');
        if (product < 0 || product >= ri) continue;
        revenue = ri;
        columns = cells.length;
        headerOffset = start;
        continue;
      }
      if (revenue < 0 ||
          cells.length != columns ||
          start - headerOffset > 2400) {
        continue;
      }
      final value = double.tryParse(
        cells[revenue].replaceAll(',', '').split('(').first.trim(),
      );
      if (value == null || value <= 0) continue;
      final item = cells[product];
      if (RegExp(r'합계|총계|기타|원재료|용\s*부품|제조용').hasMatch(item)) continue;
      for (final term in (definition['terms'] as List).cast<String>()) {
        final match = RegExp(
          RegExp.escape(term),
          caseSensitive: false,
        ).firstMatch(item);
        if (match == null) continue;
        if (RegExp(r'^\s*(?:용|업체|회사|고객|부품|주물|소재|재료|원료|의\s*부품)')
            .hasMatch(item.substring(match.end))) {
          continue;
        }
        return text.substring(headerOffset, start + line.length);
      }
    }
    return null;
  }

  static bool _ownHeading(String heading, String ownName) =>
      ownName.isNotEmpty &&
      RegExp(
        r'(?<![가-힣A-Za-z0-9])' + RegExp.escape(ownName) + r'(?![가-힣A-Za-z0-9])',
      ).hasMatch(heading);
}
