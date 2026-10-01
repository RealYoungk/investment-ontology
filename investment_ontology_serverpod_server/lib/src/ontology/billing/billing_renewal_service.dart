import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'billing_key_vault.dart';
import 'membership_ledger.dart';
import 'toss_sandbox_gateway.dart';

/// Provider worker; activation and credentials are guarded by server config.
/// Shared by FutureCall and isolated tests; provider calls never hold DB locks.
class BillingRenewalService {
  BillingRenewalService({required this.gateway, required this.vault});
  final TossPaymentsGateway gateway;
  final BillingKeyVault vault;

  Future<void> reconcileKeyDeletion(Session session, int subscriptionId) async {
    final sub = await BillingSubscription.db.findById(session, subscriptionId);
    if (sub == null || sub.encryptedKeyPendingDeletion == null) return;
    final envelope = sub.encryptedKeyPendingDeletion!;
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
        if (current?.encryptedKeyPendingDeletion == envelope) {
          current!.encryptedKeyPendingDeletion = null;
          await BillingSubscription.db.updateRow(
            session,
            current,
            transaction: tx,
          );
        }
      });
    } on SandboxPaymentException {
      // Retain encrypted cleanup material until provider deletion is confirmed.
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
      }
    }
    await reconcileRefunds(session, subscriptionId);
  }

  Future<void> reconcileRefunds(Session session, int subscriptionId) async {
    final rows = await BillingPaymentAttempt.db.find(
      session,
      where: (t) =>
          t.subscriptionId.equals(subscriptionId) &
          t.status.equals('refundRequired'),
    );
    for (final row in rows) {
      if (row.paymentKey == null) continue;
      try {
        final refund = await gateway.refund(
          paymentKey: row.paymentKey!,
          orderId: row.orderId,
          idempotencyKey: 'refund-${row.idempotencyKey}',
        );
        await MembershipLedger.fullRefund(session, row.id!, refund);
      } on SandboxPaymentException {
        // Durable refundRequired remains queued for reconciliation.
      }
    }
  }

  Future<void> run(Session session, int subscriptionId, {DateTime? at}) async {
    await reconcileUnknowns(session, subscriptionId);
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
    }
  }
}
