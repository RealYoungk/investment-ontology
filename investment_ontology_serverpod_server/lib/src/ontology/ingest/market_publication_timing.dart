/// A bounded recheck estimate, never proof of publication or no data.
/// FSC says next business day after 13:00 KST. Only independently read public
/// holidays enter this partial calendar: KRX-only May1/yearend are NOT used.
abstract final class MarketPublicationTiming {
  static const providerUrl = 'https://www.data.go.kr/data/15094808/openapi.do';
  static const governmentCalendarUrl =
      'https://www.kasi.re.kr/publication/post/newsMaterial/32031';
  static const knownPublicHolidays = {
    '2026-02-16',
    '2026-02-17',
    '2026-02-18',
    '2026-03-02',
    '2026-05-25',
    '2026-08-17',
    '2026-09-24',
    '2026-09-25',
    '2026-10-05',
    '2026-10-09',
    '2026-12-25',
  };
  static String date(DateTime d) => d.toIso8601String().substring(0, 10);
  static DateTime estimateUtc(DateTime baseDate) {
    var next = DateTime.utc(baseDate.year, baseDate.month, baseDate.day + 1);
    while (next.weekday == DateTime.saturday ||
        next.weekday == DateTime.sunday ||
        knownPublicHolidays.contains(date(next))) {
      next = next.add(const Duration(days: 1));
    }
    return next.add(const Duration(hours: 4)); // 13:00 KST, expected only.
  }

  static bool withinExpectedResponseWindow(DateTime baseDate, DateTime now) =>
      !now.toUtc().isAfter(estimateUtc(baseDate).add(const Duration(days: 1)));
  static DateTime retryAt(DateTime now, Iterable<DateTime> dates) {
    final hour = now.toUtc().add(const Duration(hours: 1));
    final times = dates.map(estimateUtc).toList()..sort();
    return times.isNotEmpty && times.first.isAfter(hour) ? times.first : hour;
  }

  static String estimateMessage(DateTime now, Iterable<DateTime> dates) {
    final sorted = dates.toList()..sort();
    final checked = now.toUtc().add(const Duration(hours: 9)).toIso8601String();
    final estimates = sorted
        .map((d) {
          final at = estimateUtc(d).add(const Duration(hours: 9));
          final passed = !estimateUtc(d).isAfter(now.toUtc());
          return '${date(d)} 공개 재확인 예상 ${date(at)} 13:00 KST${passed ? "(예상시각 경과)" : ""}';
        })
        .join(', ');
    return '조회 시각 ${checked.substring(0, 16)} KST · $estimates · 제공기관 안내와 확인한 관공서 공휴일 기준 추정 · 실제 공개/입수 보장 아님 · 일정 근거 $providerUrl · 관공서 달력 근거 $governmentCalendarUrl';
  }
}
