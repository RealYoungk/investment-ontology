import 'package:test/test.dart';

import '../support/financial_html_test_clock.dart';

void main() {
  test(
    'annual reservations retain one second across caller boundaries',
    () async {
      final clock = VirtualFinancialHtmlClock();
      final start = clock.now;
      await clock.timing.beforeRequest(exactAnnual: true, requested: false);
      expect(clock.waits, isEmpty);
      await clock.timing.beforeRequest(exactAnnual: true, requested: false);
      await clock.timing.beforeRequest(exactAnnual: true, requested: true);
      expect(clock.waits, [
        const Duration(seconds: 1),
        const Duration(seconds: 1),
      ]);
      expect(clock.now.difference(start), const Duration(seconds: 2));
    },
  );

  test('elapsed idle time does not incur an extra annual delay', () async {
    final clock = VirtualFinancialHtmlClock();
    await clock.timing.beforeRequest(exactAnnual: true, requested: false);
    clock.now = clock.now.add(const Duration(seconds: 5));
    await clock.timing.beforeRequest(exactAnnual: true, requested: false);
    expect(clock.waits, isEmpty);
  });

  test('attachment requests wait only after the first request', () async {
    final clock = VirtualFinancialHtmlClock();
    await clock.timing.beforeRequest(exactAnnual: false, requested: false);
    expect(clock.waits, isEmpty);
    await clock.timing.beforeRequest(exactAnnual: false, requested: true);
    expect(clock.waits, [const Duration(seconds: 1)]);
  });
}
