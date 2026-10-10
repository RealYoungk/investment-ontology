/// Precision-first matching of search snippets. A search hit is not proof of
/// company identity. Ambiguous snippets are omitted, never promoted by AI.
abstract final class NewsCompanyMatcher {
  static String normalizeName(String value) =>
      value.replaceAll(RegExp(r'주식회사|\(주\)|㈜'), '').trim();

  static bool matches({
    required String name,
    required String title,
    required String excerpt,
    String? stockCode,
    String? ceoName,
  }) {
    final issuer = normalizeName(name);
    if (issuer.isEmpty) return false;
    final text = '$title $excerpt';
    // ACRYL's common noun also describes plastic. Require an issuer-specific
    // anchor around an actual name mention, not broad AI/market keywords.
    final ambiguous =
        {'아크릴', '대상', '디딤', '신세계', '깨끗한나라'}.contains(issuer) ||
        issuer.runes.length <= 2;
    final mention = RegExp(
      '(?:^|[^가-힣a-zA-Z0-9])${RegExp.escape(issuer)}'
      r'''(?=\s|[,.·:;!?…()\[\]"']|[은는이가의를와과]|$)''',
      caseSensitive: false,
    );
    // A group reference is explicit; arbitrary company-name prefixes are not.
    final groupMention = RegExp(
      '(?:^|[^가-힣a-zA-Z0-9])${RegExp.escape(issuer)}\\s*그룹'
      r'(?=\s|[,.·:;!?]|$)',
      caseSensitive: false,
    );
    if (groupMention.hasMatch(text)) return true;
    if (!mention.hasMatch(text)) return false;
    if (!ambiguous) return true;
    if (stockCode != null &&
        RegExp('(?<![0-9])${RegExp.escape(stockCode)}(?![0-9])')
            .hasMatch(text)) {
      return true;
    }
    for (final hit in mention.allMatches(text)) {
      final start = hit.start < 45 ? 0 : hit.start - 45;
      final end = hit.end + 65 > text.length ? text.length : hit.end + 65;
      final window = text.substring(start, end);
      if (RegExp(r'반도체|연료전지|발전설비|인수|영업이익|매출액|공급계약|유상증자|전환사채')
          .hasMatch(window)) {
        return true;
      }
      if (ceoName != null &&
          ceoName
              .split(RegExp(r'[,/·]'))
              .any((n) => n.trim().length >= 2 && window.contains(n.trim()))) {
        return true;
      }
      if (issuer == '아크릴' &&
          RegExp(
            r'조나단|Jonathan|박외진|(?:인공지능|AI)\s*(?:전문\s*)?(?:기업|회사)\s*[“\"㈜]*아크릴',
            caseSensitive: false,
          ).hasMatch(window)) {
        return true;
      }
      if (RegExp(
            '${RegExp.escape(issuer)}(?:은|는|이|가|의)?\\s*(?:대표|주가|주식|상장|공모|영업이익|실적|유상증자|전환사채|공시|IPO)',
          ).hasMatch(window) ||
          RegExp('(?:상장사|코스닥|코스피|㈜|주식회사)\\s*${RegExp.escape(issuer)}')
              .hasMatch(window)) {
        return true;
      }
    }
    return false;
  }
}
