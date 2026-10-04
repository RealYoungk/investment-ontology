/// Conservative observation continuity; never an assertion of listing date.
bool canRecordObservation({
  required DateTime date,
  required DateTime? previousDate,
  required DateTime? latestKnownDate,
  required int previousCount,
  required int currentCount,
}) {
  if (previousDate == null || latestKnownDate == null || previousCount <= 0) {
    return false;
  }
  final gap = date.difference(previousDate).inDays;
  return !date.isBefore(latestKnownDate) &&
      gap > 0 &&
      gap <= 4 &&
      currentCount >= previousCount * .95;
}
