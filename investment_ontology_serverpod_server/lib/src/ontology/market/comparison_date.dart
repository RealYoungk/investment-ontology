/// 같은 날짜의 달력상 과거 월. 없는 날짜는 해당 월말로 제한한다.
DateTime comparisonMonth(DateTime date, int months) {
  final first = DateTime.utc(date.year, date.month - months);
  final end = DateTime.utc(first.year, first.month + 1, 0).day;
  return DateTime.utc(first.year, first.month, date.day.clamp(1, end));
}
