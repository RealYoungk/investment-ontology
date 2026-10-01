import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../auth/app_viewer.dart';

/// Refreshes personal membership without trusting a permanent login token for
/// subscription expiry. Discards results from earlier accounts or requests.
class MembershipMonitor {
  MembershipMonitor({
    required this.source,
    required this.fetch,
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc()) {
    source.addListener(_sync);
    _sync();
  }
  final ValueListenable<AppViewer?> source;
  final Future<MembershipView> Function() fetch;
  final DateTime Function() clock;
  final viewer = ValueNotifier<AppViewer?>(null);
  Timer? _poll;
  Timer? _expiry;
  int _generation = 0;
  bool _disposed = false;

  void _sync() {
    ++_generation;
    _poll?.cancel();
    _expiry?.cancel();
    viewer.value = source.value == null ? null : _unresolved(source.value!);
    if (source.value == null) return;
    unawaited(refresh());
    _poll = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(refresh()),
    );
  }

  Future<void> refresh() async {
    final account = source.value;
    if (_disposed || account == null) return;
    final request = ++_generation;
    try {
      final status = await fetch();
      if (_disposed ||
          request != _generation ||
          source.value?.userId != account.userId) {
        return;
      }
      _expiry?.cancel();
      final end = status.paidThroughUtc;
      final paid = status.adFree && end != null && end.isAfter(clock());
      viewer.value = AppViewer(
        userId: account.userId,
        isAdmin: account.isAdmin,
        isAdFree: account.isAdFree || paid,
        paidThroughUtc: paid ? end : null,
        cancelAtPeriodEnd: status.cancelAtPeriodEnd,
        paymentAvailable: status.paymentAvailable,
        isTestMembership: status.isTest,
      );
      if (paid) {
        _scheduleExpiry(account, end);
      }
    } catch (_) {
      if (!_disposed &&
          request == _generation &&
          source.value?.userId == account.userId) {
        viewer.value = _unresolved(viewer.value ?? account);
      }
      // Existing expiry timer still removes access if a refresh is unavailable.
      // No client-side purchase flag or local storage grants paid membership.
    }
  }

  AppViewer _unresolved(AppViewer account) => AppViewer(
    userId: account.userId,
    isAdmin: account.isAdmin,
    isAdFree: account.isAdFree,
    membershipResolved: false,
    paidThroughUtc: account.paidThroughUtc,
    cancelAtPeriodEnd: account.cancelAtPeriodEnd,
    paymentAvailable: account.paymentAvailable,
    isTestMembership: account.isTestMembership,
  );

  void _scheduleExpiry(AppViewer account, DateTime end) {
    final remaining = end.difference(clock());
    // Browser timers overflow beyond ~24.8 days. Re-arm a bounded timer
    // without removing paid access until the actual server expiry arrives.
    final delay = remaining > const Duration(days: 1)
        ? const Duration(days: 1)
        : remaining;
    _expiry = Timer(delay, () {
      if (_disposed || source.value?.userId != account.userId) return;
      if (end.isAfter(clock())) {
        _scheduleExpiry(account, end);
        return;
      }
      viewer.value = _unresolved(account);
      unawaited(refresh());
    });
  }

  void dispose() {
    _disposed = true;
    ++_generation;
    source.removeListener(_sync);
    _poll?.cancel();
    _expiry?.cancel();
    viewer.dispose();
  }
}
