/// Shared business rules only. Persistent ledger/RPC integration remains gated.
/// Month boundaries use the original UTC anniversary, preventing Jan31→Feb28→Mar28 drift.
abstract final class SubscriptionRules {
  static const amountKrw = 2900;
  static DateTime boundary(DateTime origin, int month) {
    if (!origin.isUtc || month < 0) throw ArgumentError('UTC origin required');
    final first = DateTime.utc(origin.year, origin.month + month);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(
      first.year,
      first.month,
      origin.day > lastDay ? lastDay : origin.day,
      origin.hour,
      origin.minute,
      origin.second,
      origin.millisecond,
      origin.microsecond,
    );
  }

  static bool adFree({
    required DateTime now,
    required DateTime? paidFrom,
    required DateTime? paidThrough,
    required bool refunded,
    required bool deleted,
  }) =>
      !deleted &&
      !refunded &&
      paidFrom != null &&
      paidThrough != null &&
      !now.isBefore(paidFrom) &&
      now.isBefore(paidThrough);
}

/// Domain snapshot only. Requires authenticated RPCs and transactional durable
/// persistence before sales. Late approval after deletion needs a refund.
class SubscriptionSnapshot {
  SubscriptionSnapshot({required this.ownerId, required this.origin}) {
    if (ownerId.isEmpty || !origin.isUtc) {
      throw ArgumentError('Invalid owner/origin');
    }
  }
  final String ownerId;
  final DateTime origin;
  final Map<int, PaidPeriod> _periods = {};
  bool cancelAtPeriodEnd = false;
  bool deleted = false;
  bool adFree(DateTime now) =>
      !deleted &&
      _periods.values.any(
        (p) => !p.refunded && !now.isBefore(p.from) && now.isBefore(p.through),
      );
  bool canStartCharge(int period, DateTime now) =>
      period >= 0 &&
      !deleted &&
      !cancelAtPeriodEnd &&
      !_periods.containsKey(period) &&
      !now.isBefore(SubscriptionRules.boundary(origin, period)) &&
      now.isBefore(SubscriptionRules.boundary(origin, period + 1));
  void cancel() => cancelAtPeriodEnd = true;
  void delete() {
    deleted = true;
    cancelAtPeriodEnd = true;
  }

  /// Must only receive a server-validated payment; never a client callback alone.
  void recordPaid({
    required int period,
    required String orderId,
    required String paymentKey,
  }) {
    if (period < 0 || orderId.isEmpty || paymentKey.isEmpty) {
      throw ArgumentError('Invalid period');
    }
    final existing = _periods[period];
    if (existing != null) {
      if (existing.orderId != orderId || existing.paymentKey != paymentKey) {
        throw StateError('Conflicting payment');
      }
      return; // Replay cannot extend access or undo refund.
    }
    if (_periods.values.any(
      (p) => p.orderId == orderId || p.paymentKey == paymentKey,
    )) {
      throw StateError('Reused payment');
    }
    _periods[period] = PaidPeriod(
      orderId: orderId,
      paymentKey: paymentKey,
      from: SubscriptionRules.boundary(origin, period),
      through: SubscriptionRules.boundary(origin, period + 1),
    );
  }

  void recordFullRefund(String orderId, String paymentKey) {
    final matches = _periods.values.where(
      (p) => p.orderId == orderId && p.paymentKey == paymentKey,
    );
    if (matches.length != 1) throw StateError('Unknown refund identity');
    matches.single.refunded = true;
  }
}

class PaidPeriod {
  PaidPeriod({
    required this.orderId,
    required this.paymentKey,
    required this.from,
    required this.through,
  });
  final String orderId;
  final String paymentKey;
  final DateTime from;
  final DateTime through;
  bool refunded = false;
}
