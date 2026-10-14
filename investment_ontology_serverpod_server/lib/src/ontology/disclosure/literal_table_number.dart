/// A scalar filing cell, not concatenated amounts from a merged HTML row.
double? literalTableNumber(String input) {
  var text = input
      .trim()
      .replaceAll('△', '-')
      .replaceAll('▲', '-')
      .replaceAll('−', '-');
  if (RegExp(r'^\([\d,.]+\)$').hasMatch(text)) {
    text = '-${text.substring(1, text.length - 1)}';
  }
  if (!RegExp(r'^[+-]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?%?$')
      .hasMatch(text)) {
    return null;
  }
  final value = double.tryParse(text.replaceAll(',', '').replaceAll('%', ''));
  return value != null && value.isFinite ? value : null;
}
