/// Position of the newest explicitly printed period, independent of ordering.
/// Returns null when the header does not identify multiple periods.
int? newestPrintedPeriod(List<String> cells) {
  final years = RegExp(r'(?:19|20)\d{2}');
  final terms = RegExp(r'제\s*(\d+)\s*기');
  final periods = <int>[];
  for (final cell in cells) {
    final year = years.firstMatch(cell);
    final term = terms.firstMatch(cell);
    if (year != null) {
      periods.add(int.parse(year.group(0)!));
    } else if (term != null) {
      periods.add(int.parse(term.group(1)!));
    }
  }
  if (periods.length < 2 || periods.toSet().length != periods.length) {
    return null;
  }
  var newest = 0;
  for (var i = 1; i < periods.length; i++) {
    if (periods[i] > periods[newest]) newest = i;
  }
  return newest;
}
