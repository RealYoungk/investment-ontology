/// Start boundary derived from the preceding annual filing's closing date.
/// Never assume January 1 or bridge a missing reporting year.
DateTime? ownershipPeriodStart(DateTime? end, Iterable<DateTime> previousEnds) {
  if (end == null) return null;
  final close = DateTime.utc(end.year, end.month, end.day);
  final candidates =
      previousEnds
          .map((d) => DateTime.utc(d.year, d.month, d.day))
          .where((d) => d.isBefore(close))
          .toList()
        ..sort();
  if (candidates.isEmpty) return null;
  final previous = candidates.last;
  final days = close.difference(previous).inDays;
  if (days > 366) return null;
  return previous.add(const Duration(days: 1));
}
