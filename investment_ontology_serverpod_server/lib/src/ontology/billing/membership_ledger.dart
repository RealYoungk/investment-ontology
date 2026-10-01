import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import 'subscription_rules.dart';
import 'billing_key_vault.dart';
import 'toss_sandbox_gateway.dart';

/// Durable payment ledger. No client RPC can claim or settle a payment.
/// Provider calls must run outside these transactions and use the stored order
/// and idempotency key. Unknown attempts must be reconciled, never replaced.
abstract final class MembershipLedger {
  static UuidValue owner(Session session) {
    final auth = session.authenticated;
    if (auth == null) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
    return UuidValue.fromString(auth.userIdentifier);
  }

  static Future<void> _lockUser(
    Session session,
    UuidValue id,
    Transaction tx,
  ) async {
    final user = await AuthUser.db.findById(
      session,
      id,
      transaction: tx,
      lockMode: LockMode.forUpdate,
    );
    if (user == null || user.blocked) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
  }

  static Future<BillingSubscription?> _subscription(
    Session session,
    UuidValue id,
    Transaction tx,
  ) => BillingSubscription.db.findFirstRow(
    session,
    where: (t) => t.ownerId.equals(id),
    transaction: tx,
    lockMode: LockMode.forUpdate,
  );

  static Future<MembershipView> status(Session session, {DateTime? at}) async {
    final id = owner(session);
    final now = at ?? DateTime.now().toUtc();
    return session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      final sub = await _subscription(session, id, tx);
      if (sub == null || sub.deleted) {
        return MembershipView(adFree: false, cancelAtPeriodEnd: false);
      }
      final payments = await BillingPaymentAttempt.db.find(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.equals('paid') &
            (t.paidFromUtc <= now) &
            (t.paidThroughUtc > now),
        orderBy: (t) => t.paidThroughUtc.desc(),
        limit: 1,
        transaction: tx,
      );
      return MembershipView(
        adFree: payments.isNotEmpty,
        paidThroughUtc: payments.firstOrNull?.paidThroughUtc,
        cancelAtPeriodEnd: sub.cancelAtPeriodEnd,
      );
    });
  }

  static Future<void> cancel(Session session) async {
    final id = owner(session);
    await session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      final sub = await _subscription(session, id, tx);
      if (sub == null) return;
      sub.cancelAtPeriodEnd = true;
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  /// Internal orchestration only. Server-owned order and period, no client amount.
  static Future<BillingPaymentAttempt?> claim(
    Session session, {
    required int period,
    DateTime? at,
  }) async {
    return _claimOwner(session, owner(session), period: period, at: at);
  }

  static Future<BillingPaymentAttempt?> claimRenewal(
    Session session,
    int subscriptionId, {
    DateTime? at,
  }) async {
    final sub = await BillingSubscription.db.findById(session, subscriptionId);
    if (sub == null ||
        sub.encryptedBillingKey == null ||
        sub.customerKey == null) {
      return null;
    }
    return _claimOwner(session, sub.ownerId, period: sub.nextPeriod, at: at);
  }

  static Future<BillingPaymentAttempt?> _claimOwner(
    Session session,
    UuidValue id, {
    required int period,
    DateTime? at,
  }) async {
    if (period < 0) throw ArgumentError('Invalid period');
    final now = at ?? DateTime.now().toUtc();
    return session.db.transaction((tx) async {
      await _lockUser(
        session,
        id,
        tx,
      ); // Serializes even concurrent first inserts.
      var sub = await _subscription(session, id, tx);
      if (sub == null) {
        if (period != 0) return null;
        sub = await BillingSubscription.db.insertRow(
          session,
          BillingSubscription(
            ownerId: id,
            originUtc: now,
            customerKey: 'alfinder-${Uuid().v4()}',
          ),
          transaction: tx,
        );
      }
      if (sub.deleted || sub.cancelAtPeriodEnd) return null;
      final prior = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub!.id!) & t.period.equals(period),
        transaction: tx,
      );
      if (prior != null) return prior; // Stable identity for every retry.
      final from = SubscriptionRules.boundary(sub.originUtc, period);
      final through = SubscriptionRules.boundary(sub.originUtc, period + 1);
      if (now.isBefore(from) || !now.isBefore(through)) return null;
      final nonce = Uuid().v4();
      return BillingPaymentAttempt.db.insertRow(
        session,
        BillingPaymentAttempt(
          subscriptionId: sub.id!,
          period: period,
          orderId: 'alfinder-$nonce',
          idempotencyKey: 'charge-$nonce',
          status: 'pending',
          paidFromUtc: from,
          paidThroughUtc: through,
        ),
        transaction: tx,
      );
    });
  }

  /// Takes a validated provider result, never a browser redirect alone.
  static Future<void> settle(
    Session session,
    int attemptId,
    SandboxPayment payment,
  ) async {
    await session.db.transaction((tx) async {
      final first = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
      );
      if (first == null) throw StateError('Unknown attempt');
      final firstSub = await BillingSubscription.db.findById(
        session,
        first.subscriptionId,
        transaction: tx,
      );
      if (firstSub == null) throw StateError('Unknown subscription');
      // Same lock order as claim/cancel/account deletion.
      final user = await AuthUser.db.findById(
        session,
        firstSub.ownerId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      final sub = await BillingSubscription.db.findById(
        session,
        first.subscriptionId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      final row = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row == null ||
          sub == null ||
          payment.orderId != row.orderId ||
          payment.amount != SubscriptionRules.amountKrw ||
          payment.balance != SubscriptionRules.amountKrw ||
          payment.status != 'DONE' ||
          payment.key.isEmpty) {
        throw StateError('Payment proof does not match attempt');
      }
      if (row.paymentKey != null && row.paymentKey != payment.key) {
        throw StateError('Conflicting payment');
      }
      if (row.status == 'paid' ||
          row.status == 'refunded' ||
          row.status == 'refundRequired') {
        return;
      }
      row.paymentKey = payment.key;
      row.status = sub.deleted || user == null || user.blocked
          ? 'refundRequired'
          : 'paid';
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      if (row.status == 'paid' && sub.nextPeriod <= row.period) {
        sub.nextPeriod = row.period + 1;
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
    });
  }

  /// Internal only, after the gateway verifies the billing response customer.
  static Future<void> storeBillingReference(
    Session session,
    String customerKey,
    String reference,
    BillingKeyVault vault,
  ) async {
    final id = owner(session);
    final encrypted = await vault.seal(id.toString(), reference);
    await session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      final sub = await _subscription(session, id, tx);
      if (sub == null ||
          sub.deleted ||
          sub.cancelAtPeriodEnd ||
          sub.customerKey != customerKey) {
        throw StateError('Subscription cannot accept billing reference');
      }
      sub.encryptedBillingKey = encrypted;
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  static Future<void> markUnknown(Session session, int attemptId) async {
    await session.db.transaction((tx) async {
      final row = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row == null) throw StateError('Unknown attempt');
      if (row.status == 'pending') {
        row.status = 'unknown';
        await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      }
    });
  }

  static Future<void> fullRefund(
    Session session,
    int attemptId,
    SandboxPayment payment,
  ) async {
    await session.db.transaction((tx) async {
      final row = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row == null ||
          (row.paymentKey != null && row.paymentKey != payment.key) ||
          payment.key.isEmpty ||
          row.orderId != payment.orderId ||
          payment.amount != SubscriptionRules.amountKrw ||
          payment.balance != 0 ||
          payment.status != 'CANCELED') {
        throw StateError('Refund proof does not match attempt');
      }
      row.paymentKey = payment.key;
      row.status = 'refunded';
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
    });
  }

  /// Called only after account password verification, in its deletion transaction.
  static Future<void> beforeDelete(
    Session session,
    UuidValue id,
    Transaction tx,
  ) async {
    final sub = await _subscription(session, id, tx);
    if (sub == null) return;
    sub.deleted = true;
    sub.encryptedKeyPendingDeletion = sub.encryptedBillingKey;
    sub.encryptedBillingKey = null;
    sub.cancelAtPeriodEnd = true;
    await BillingSubscription.db.updateRow(session, sub, transaction: tx);
  }
}
