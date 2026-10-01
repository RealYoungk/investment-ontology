import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/membership_monitor.dart';

void main() {
  const account = AppViewer(userId: 'account-one', isAdmin: false);
  test('prior account response is discarded', () async {
    final source = ValueNotifier<AppViewer?>(account);
    final old = Completer<MembershipView>();
    final next = Completer<MembershipView>();
    var calls = 0;
    final monitor = MembershipMonitor(
      source: source,
      fetch: () => calls++ == 0 ? old.future : next.future,
    );
    source.value = const AppViewer(userId: 'account-two', isAdmin: false);
    old.complete(
      MembershipView(
        adFree: true,
        paidThroughUtc: DateTime.now().toUtc().add(const Duration(days: 1)),
        cancelAtPeriodEnd: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(monitor.viewer.value!.userId, 'account-two');
    expect(monitor.viewer.value!.isAdFree, false);
    next.complete(MembershipView(adFree: false, cancelAtPeriodEnd: false));
    await Future<void>.delayed(Duration.zero);
    monitor.dispose();
    source.dispose();
  });
  test('logout discards pending paid response', () async {
    final source = ValueNotifier<AppViewer?>(account);
    final pending = Completer<MembershipView>();
    final monitor = MembershipMonitor(
      source: source,
      fetch: () => pending.future,
    );
    source.value = null;
    pending.complete(
      MembershipView(
        adFree: true,
        paidThroughUtc: DateTime.now().toUtc().add(const Duration(days: 1)),
        cancelAtPeriodEnd: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(monitor.viewer.value, isNull);
    monitor.dispose();
    source.dispose();
  });
  test('exact expiry removes access despite failed refresh', () {
    fakeAsync((time) {
      final origin = DateTime.utc(2026, 10, 1);
      final source = ValueNotifier<AppViewer?>(account);
      var calls = 0;
      final monitor = MembershipMonitor(
        source: source,
        clock: () => origin.add(time.elapsed),
        fetch: () async {
          if (calls++ > 0) throw StateError('network unavailable');
          return MembershipView(
            adFree: true,
            paidThroughUtc: origin.add(const Duration(seconds: 10)),
            cancelAtPeriodEnd: false,
          );
        },
      );
      time.flushMicrotasks();
      expect(monitor.viewer.value!.isAdFree, true);
      time.elapse(const Duration(seconds: 9));
      expect(monitor.viewer.value!.isAdFree, true);
      time.elapse(const Duration(seconds: 1));
      expect(monitor.viewer.value!.isAdFree, false);
      monitor.dispose();
      source.dispose();
    });
  });
  test('month-long membership uses bounded timers and expires offline', () {
    fakeAsync((time) {
      final origin = DateTime.utc(2026, 10, 1);
      final end = origin.add(const Duration(days: 31));
      final source = ValueNotifier<AppViewer?>(account);
      var calls = 0;
      final monitor = MembershipMonitor(
        source: source,
        clock: () => origin.add(time.elapsed),
        fetch: () async {
          if (calls++ > 0) throw StateError('offline');
          return MembershipView(
            adFree: true,
            paidThroughUtc: end,
            cancelAtPeriodEnd: true,
          );
        },
      );
      time.flushMicrotasks();
      expect(
        time.pendingTimers.every(
          (timer) => timer.duration <= const Duration(days: 1),
        ),
        isTrue,
      );
      time.elapse(const Duration(days: 30));
      expect(monitor.viewer.value!.paidThroughUtc, end);
      expect(monitor.viewer.value!.isAdFree, true);
      time.elapse(const Duration(days: 1));
      expect(monitor.viewer.value!.isAdFree, false);
      monitor.dispose();
      source.dispose();
    });
  });
  test('latest same-account response wins', () async {
    final source = ValueNotifier<AppViewer?>(account);
    final old = Completer<MembershipView>();
    final next = Completer<MembershipView>();
    var calls = 0;
    final monitor = MembershipMonitor(
      source: source,
      fetch: () => calls++ == 0 ? old.future : next.future,
    );
    final refresh = monitor.refresh();
    next.complete(MembershipView(adFree: false, cancelAtPeriodEnd: true));
    await refresh;
    old.complete(
      MembershipView(
        adFree: true,
        paidThroughUtc: DateTime.now().toUtc().add(const Duration(days: 1)),
        cancelAtPeriodEnd: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(monitor.viewer.value!.isAdFree, false);
    expect(monitor.viewer.value!.cancelAtPeriodEnd, true);
    monitor.dispose();
    source.dispose();
  });
}
