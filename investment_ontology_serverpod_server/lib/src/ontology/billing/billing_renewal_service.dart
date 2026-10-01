import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'billing_key_vault.dart';
import 'membership_ledger.dart';
import 'toss_sandbox_gateway.dart';

/// Provider worker; activation and credentials are guarded by server config.
/// Shared by FutureCall and isolated tests; provider calls never hold DB locks.
class BillingRenewalService {
  BillingRenewalService({
    required this.gateway,
    required this.vault,
    this.allowCharges = true,
  });
  final bool allowCharges;
  final TossPaymentsGateway gateway;
  final BillingKeyVault vault;

  Future<void> reconcileKeyDeletion(Session session, int subscriptionId) async {
    final sub = await BillingSubscription.db.findById(session, subscriptionId);
    if (sub == null || sub.encryptedKeyPendingDeletion == null) return;
    for (final envelope in MembershipLedger.pendingKeys(
      sub.encryptedKeyPendingDeletion,
    )) {
      try {
        final reference = await vault.open(sub.ownerId.toString(), envelope);
        await gateway.deleteBillingKey(reference);
        await session.db.transaction((tx) async {
          final current = await BillingSubscription.db.findById(
            session,
            subscriptionId,
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          if (current == null) return;
          final pending = MembershipLedger.pendingKeys(
            current.encryptedKeyPendingDeletion,
          );
          pending.remove(envelope);
          current.encryptedKeyPendingDeletion =
              MembershipLedger.encodePendingKeys(pending);
          await BillingSubscription.db.updateRow(
            session,
            current,
            transaction: tx,
          );
        });
      } on SandboxPaymentException {
        // Retain only unconfirmed references, including late account-deletion races.
        session.log(
          'Billing key cleanup pending (subscription $subscriptionId)',
          level: LogLevel.warning,
        );
      }
    }
  }

  Future<void> reconcileUnknowns(Session session, int subscriptionId) async {
    final rows = await BillingPaymentAttempt.db.find(
      session,
      where: (t) =>
          t.subscriptionId.equals(subscriptionId) & t.status.equals('unknown'),
    );
    for (final row in rows) {
      try {
        final payment = await gateway.lookup(row.orderId);
        if (payment.status == 'DONE') {
          await MembershipLedger.settle(session, row.id!, payment);
        } else if (payment.status == 'CANCELED') {
          await MembershipLedger.fullRefund(session, row.id!, payment);
        }
      } on SandboxPaymentException {
        // Cancellation/deletion must not stop reconciliation of a past charge.
        session.log(
          'Billing result unknown (attempt ${row.id})',
          level: LogLevel.warning,
        );
      }
    }
    await reconcileRefunds(session, subscriptionId);
  }

  /// GET-only reconciliation of paid access. Provider-dashboard cancellations
  /// need no callback payload and must also be detected after auto-renewal stops.
  Future<void> reconcilePaid(
    Session session,
    int subscriptionId, {
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now().toUtc();
    final rows = await BillingPaymentAttempt.db.find(
      session,
      where: (t) =>
          t.subscriptionId.equals(subscriptionId) &
          t.status.equals('paid') &
          (t.paidFromUtc <= now) &
          (t.paidThroughUtc > now),
    );
    for (final row in rows) {
      try {
        final payment = await gateway.lookup(row.orderId);
        if (payment.key != row.paymentKey || payment.orderId != row.orderId) {
          throw const SandboxPaymentException(
            'reconcile_identity',
            uncertain: true,
          );
        }
        if (payment.status == 'CANCELED') {
          await MembershipLedger.fullRefund(session, row.id!, payment);
          await reconcileKeyDeletion(session, subscriptionId);
        }
      } on SandboxPaymentException {
        // Failed GET never invents a refund or changes existing paid access.
        session.log(
          'Paid billing reconciliation pending (attempt ${row.id})',
          level: LogLevel.warning,
        );
      }
    }
  }

  Future<void> reconcileRefunds(Session session, int subscriptionId) async {
    final rows = await BillingPaymentAttempt.db.find(
      session,
      where: (t) =>
          t.subscriptionId.equals(subscriptionId) &
          t.status.inSet({'refundRequired', 'refundRequested'}),
    );
    for (final row in rows) {
      if (row.paymentKey == null) continue;
      try {
        // Lookup first recovers a cancel whose response was lost, even after
        // the provider's idempotency window expired.
        final existing = await gateway.lookup(row.orderId);
        if (existing.key != row.paymentKey ||
            !{'DONE', 'CANCELED'}.contains(existing.status)) {
          throw const SandboxPaymentException(
            'refund_identity',
            uncertain: true,
          );
        }
        final refund = existing.status == 'CANCELED'
            ? existing
            : await gateway.refund(
                paymentKey: row.paymentKey!,
                orderId: row.orderId,
                idempotencyKey: 'refund-${row.idempotencyKey}',
              );
        await MembershipLedger.fullRefund(session, row.id!, refund);
        await reconcileKeyDeletion(session, subscriptionId);
      } on SandboxPaymentException {
        // Durable refundRequired remains queued for reconciliation.
        session.log(
          'Billing refund pending (attempt ${row.id})',
          level: LogLevel.warning,
        );
      }
    }
  }

  Future<void> run(Session session, int subscriptionId, {DateTime? at}) async {
    await reconcileUnknowns(session, subscriptionId);
    if (!allowCharges) return;
    final sub = await BillingSubscription.db.findById(session, subscriptionId);
    if (sub == null ||
        sub.cancelAtPeriodEnd ||
        sub.deleted ||
        sub.encryptedBillingKey == null ||
        sub.customerKey == null) {
      return;
    }
    final row = await MembershipLedger.claimRenewal(
      session,
      subscriptionId,
      at: at,
    );
    if (row == null || !const {'pending', 'unknown'}.contains(row.status)) {
      return;
    }
    try {
      SandboxPayment payment;
      if (row.status == 'unknown' ||
          (at ?? DateTime.now().toUtc()).difference(row.paidFromUtc) >
              const Duration(days: 14)) {
        // Idempotency expires after 15 days. Never POST an old unknown order.
        await MembershipLedger.markUnknown(session, row.id!);
        payment = await gateway.lookup(row.orderId);
      } else {
        final reference = await vault.open(
          sub.ownerId.toString(),
          sub.encryptedBillingKey!,
        );
        payment = await gateway.charge(
          billingKey: reference,
          customerKey: sub.customerKey!,
          orderId: row.orderId,
          idempotencyKey: row.idempotencyKey,
        );
      }
      if (payment.status == 'DONE') {
        await MembershipLedger.settle(session, row.id!, payment);
        await reconcileRefunds(session, subscriptionId);
      }
      // Canceled/partial results cannot grant access. Reconciliation remains
      // visible in the durable unknown state for operator handling.
      else {
        await MembershipLedger.markUnknown(session, row.id!);
      }
    } on SandboxPaymentException {
      await MembershipLedger.markUnknown(session, row.id!);
      session.log(
        'Billing result unknown (attempt ${row.id})',
        level: LogLevel.warning,
      );
    }
  }
}
