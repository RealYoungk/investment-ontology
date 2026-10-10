/// Presentation names only. Never write these back to source records.
String companyDisplayName({
  required String name,
  String? stockName,
  String? stockCode,
}) {
  // Explicit issuer mappings, not global phonetic transliteration.
  final known = switch (stockCode) {
    '000660' => 'SK하이닉스',
    '035420' => 'NAVER',
    _ => null,
  };
  if (known != null) return known;
  final stock = stockName?.trim();
  if (stock != null && stock.isNotEmpty && stock != '-') return stock;
  final cleaned = name
      .trim()
      .replaceFirst(RegExp(r'^(?:주식회사\s*|\(주\)\s*|㈜\s*)'), '')
      .replaceFirst(RegExp(r'(?:\s*주식회사|\s*\(주\)|\s*㈜)$'), '')
      .trim();
  return cleaned.isEmpty ? name : cleaned;
}
