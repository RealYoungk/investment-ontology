import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import 'subscription_rules.dart';
import 'subscription_pricing.dart';
import 'billing_key_vault.dart';
import 'toss_sandbox_gateway.dart';

/// Durable payment ledger. No client RPC can claim or settle a payment.
/// Provider calls must run outside these transactions and use the stored order
/// and idempotency key. Unknown attempts must be reconciled, never replaced.
abstract final class MembershipLedger {
  static List<String> pendingKeys(String? encoded) {
    if (encoded == null) return [];
    if (!encoded.startsWith('[')) return [encoded];
    return (jsonDecode(encoded) as List).cast<String>();
  }

  static String? encodePendingKeys(Iterable<String> values) {
    final keys = values.toSet().toList();
    return keys.isEmpty
        ? null
        : keys.length == 1
        ? keys.single
        : jsonEncode(keys);
  }

  static Future<void> queueUnconfirmedReference(
    Session session,
    int subscriptionId,
    String reference,
    BillingKeyVault vault,
  ) async {
    final first = await BillingSubscription.db.findById(
      session,
      subscriptionId,
    );
    if (first == null) throw StateError('Missing cleanup owner');
    final encrypted = await vault.seal(first.ownerId.toString(), reference);
    await session.db.transaction((tx) async {
      final sub = await BillingSubscription.db.findById(
        session,
        subscriptionId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (sub == null) throw StateError('Missing cleanup subscription');
      final pending = pendingKeys(sub.encryptedKeyPendingDeletion);
      for (final existing in pending) {
        if (await vault.open(sub.ownerId.toString(), existing) == reference) {
          return;
        }
      }
      if (sub.encryptedBillingKey != null &&
          await vault.open(sub.ownerId.toString(), sub.encryptedBillingKey!) ==
              reference) {
        sub.encryptedBillingKey = null;
        sub.cancelAtPeriodEnd = true;
      }
      sub.encryptedKeyPendingDeletion = encodePendingKeys([
        ...pending,
        encrypted,
      ]);
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

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

  static DateTime? _graceEnd(BillingSubscription sub, DateTime now) =>
      sub.graceThroughUtc?.add(
        sub.billingPausedUtc != null && now.isAfter(sub.billingPausedUtc!)
            ? now.difference(sub.billingPausedUtc!)
            : Duration.zero,
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
            t.status.inSet({'paid', 'refundRequested'}) &
            (t.paidFromUtc <= now) &
            (t.paidThroughUtc > now),
        orderBy: (t) => t.paidThroughUtc.desc(),
        limit: 1,
        transaction: tx,
      );
      final graceEnd = _graceEnd(sub, now);
      final grace =
          !sub.cancelAtPeriodEnd && graceEnd != null && graceEnd.isAfter(now);
      final entitled = payments.isNotEmpty || grace;
      final protected =
          entitled ||
          (!sub.cancelAtPeriodEnd &&
              sub.priceLocked &&
              (graceEnd == null || graceEnd.isAfter(now)));
      return MembershipView(
        adFree: entitled,
        paidThroughUtc:
            payments.firstOrNull?.paidThroughUtc ?? (grace ? graceEnd : null),
        cancelAtPeriodEnd: sub.cancelAtPeriodEnd,
        currentPriceKrw: SubscriptionPricing.currentAmount,
        appliedPriceKrw: protected ? sub.priceKrw : null,
        priceProtected: protected,
        nextChargeUtc: sub.cancelAtPeriodEnd || !entitled
            ? null
            : SubscriptionRules.boundary(
                sub.originUtc,
                sub.nextPeriod - sub.cycleStartPeriod,
              ),
        graceThroughUtc: grace ? graceEnd : null,
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
      sub.graceThroughUtc = null;
      sub.retryAfterUtc = null;
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  /// Prepare a new cycle only after all earlier charges have a known outcome.
  static Future<BillingSubscription> prepareCheckout(
    Session session, {
    bool replaceCard = false,
    int priceKrw = 2900,
    String priceVersion = 'legacy-2900',
    String provider = 'toss',
    DateTime? at,
  }) async {
    final id = owner(session);
    final now = at ?? DateTime.now().toUtc();
    return session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      var sub = await _subscription(session, id, tx);
      if (sub == null) {
        if (replaceCard) throw StateError('No active membership');
        return BillingSubscription.db.insertRow(
          session,
          BillingSubscription(
            ownerId: id,
            originUtc: now,
            priceKrw: priceKrw,
            priceVersion: priceVersion,
            provider: provider,
            customerKey: 'alfinder-${Uuid().v4()}',
          ),
          transaction: tx,
        );
      }
      if (sub.deleted) throw StateError('Account unavailable');
      final unresolved = await BillingCheckout.db.findFirstRow(
        session,
        where: (t) =>
            t.ownerId.equals(id) &
            (t.status.inSet({'processing', 'unknown'}) |
                (t.status.equals('waiting') & (t.expiresUtc > now))),
        transaction: tx,
      );
      if (unresolved != null) throw StateError('Checkout already pending');
      final paid = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.equals('paid') &
            (t.paidFromUtc <= now) &
            (t.paidThroughUtc > now),
        transaction: tx,
      );
      final refund = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.inSet({'refundRequested', 'refundRequired'}),
        transaction: tx,
      );
      if (refund != null) throw StateError('Refund pending');
      if (replaceCard) {
        if ((paid == null &&
                !(sub.graceThroughUtc?.isAfter(now) ?? false) &&
                (sub.cancelAtPeriodEnd || !sub.priceLocked)) ||
            sub.encryptedKeyPendingDeletion != null) {
          throw StateError('Card replacement is unavailable');
        }
        return sub;
      }
      if (sub.graceThroughUtc?.isAfter(now) ?? false) {
        throw StateError('Use card replacement during grace');
      }
      if (paid != null ||
          (!sub.cancelAtPeriodEnd &&
              sub.priceLocked &&
              sub.graceThroughUtc == null)) {
        throw StateError(
          'Membership is already active or renewal delayed; use card replacement',
        );
      }
      final rows = await BillingPaymentAttempt.db.find(
        session,
        where: (t) => t.subscriptionId.equals(sub.id!),
        orderBy: (t) => t.period.desc(),
        transaction: tx,
      );
      if (rows.any(
        (row) =>
            row.status == 'unknown' ||
            row.status == 'refundRequired' ||
            row.status == 'refundRequested' ||
            (row.status == 'pending' && sub.encryptedBillingKey != null),
      )) {
        throw StateError('An earlier charge must be reconciled');
      }
      if (rows.isNotEmpty &&
          rows.first.status == 'pending' &&
          rows.first.paidThroughUtc.isAfter(now) &&
          !sub.cancelAtPeriodEnd &&
          sub.priceKrw == priceKrw &&
          sub.priceVersion == priceVersion &&
          sub.provider == provider) {
        return sub;
      }
      if (sub.encryptedKeyPendingDeletion != null) {
        throw StateError('Key cleanup pending');
      }
      for (final row in rows.where((r) => r.status == 'pending')) {
        row.status = 'abandoned';
        await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      }
      sub.encryptedKeyPendingDeletion = sub.encryptedBillingKey;
      sub.encryptedBillingKey = null;
      sub.nextPeriod = rows.isEmpty ? 0 : rows.first.period + 1;
      sub.cycleStartPeriod = sub.nextPeriod;
      if (sub.provider != provider && sub.encryptedKeyPendingDeletion != null) {
        throw StateError('Previous provider key cleanup required');
      }
      sub.provider = provider;
      sub.priceLocked = false;
      sub.priceKrw = priceKrw;
      sub.priceVersion = priceVersion;
      sub.graceThroughUtc = null;
      sub.retryAfterUtc = null;
      sub.billingPausedUtc = null;
      sub.originUtc = now;
      sub.cancelAtPeriodEnd = false;
      return BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  static Future<void> resume(Session session, {DateTime? at}) async {
    final id = owner(session);
    final now = at ?? DateTime.now().toUtc();
    await session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      final sub = await _subscription(session, id, tx);
      if (sub == null || sub.deleted || sub.encryptedBillingKey == null) {
        throw StateError('No renewable membership');
      }
      final paid = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.equals('paid') &
            (t.paidFromUtc <= now) &
            (t.paidThroughUtc > now),
        transaction: tx,
      );
      if (paid == null) throw StateError('Start a new membership after expiry');
      final refund = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.inSet({'refundRequested', 'refundRequired'}),
        transaction: tx,
      );
      if (refund != null) throw StateError('Refund pending');
      sub.cancelAtPeriodEnd = false;
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
      final scheduledThrough = SubscriptionRules.boundary(
        sub.originUtc,
        period - sub.cycleStartPeriod + 1,
      );
      if (!scheduledThrough.isAfter(now) &&
          period == sub.nextPeriod &&
          sub.priceLocked) {
        // System delay does not back-bill a missed month or discard the price.
        sub.originUtc = now;
        sub.cycleStartPeriod = period;
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
      final from = SubscriptionRules.boundary(
        sub.originUtc,
        period - sub.cycleStartPeriod,
      );
      final through = SubscriptionRules.boundary(
        sub.originUtc,
        period - sub.cycleStartPeriod + 1,
      );
      if (now.isBefore(from) || !now.isBefore(through)) return null;
      final nonce = Uuid().v4();
      return BillingPaymentAttempt.db.insertRow(
        session,
        BillingPaymentAttempt(
          subscriptionId: sub.id!,
          period: period,
          orderId: 'af${nonce.replaceAll('-', '')}',
          idempotencyKey: 'charge-$nonce',
          status: 'pending',
          amountKrw: sub.priceKrw,
          priceVersion: sub.priceVersion,
          provider: sub.provider,
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
    SandboxPayment payment, {
    DateTime? at,
  }) async {
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
          payment.amount != row.amountKrw ||
          payment.balance != row.amountKrw ||
          payment.status != 'DONE' ||
          payment.key.isEmpty) {
        throw StateError('Payment proof does not match attempt');
      }
      if (row.paymentKey != null && row.paymentKey != payment.key) {
        throw StateError('Conflicting payment');
      }
      if (row.status == 'paid' ||
          row.status == 'refunded' ||
          row.status == 'refundRequired' ||
          row.status == 'refundRequested') {
        return;
      }
      final refund = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            (t.period >= sub.cycleStartPeriod) &
            t.status.inSet({'refundRequested', 'refundRequired', 'refunded'}),
        transaction: tx,
      );
      row.paymentKey = payment.key;
      final confirmedAt = at ?? DateTime.now().toUtc();
      final graceEnd = _graceEnd(sub, confirmedAt);
      row.status =
          sub.deleted ||
              refund != null ||
              user == null ||
              user.blocked ||
              row.period < sub.cycleStartPeriod ||
              (graceEnd != null && !graceEnd.isAfter(confirmedAt))
          ? 'refundRequired'
          : 'paid';
      if (row.status == 'paid' &&
          !sub.cancelAtPeriodEnd &&
          !row.paidThroughUtc.isAfter(confirmedAt)) {
        // A delayed confirmation provides a full paid month from recovery,
        // instead of charging again for an already elapsed access period.
        sub.originUtc = confirmedAt;
        sub.cycleStartPeriod = row.period;
        row.paidFromUtc = confirmedAt;
        row.paidThroughUtc = SubscriptionRules.boundary(confirmedAt, 1);
      }
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      if (row.status == 'paid' && sub.nextPeriod <= row.period) {
        sub.nextPeriod = row.period + 1;
        sub.priceLocked = true;
        sub.graceThroughUtc = null;
        sub.retryAfterUtc = null;
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
    });
  }

  /// Internal only, after the gateway verifies the billing response customer.
  static Future<void> storeBillingReference(
    Session session,
    String customerKey,
    String reference,
    BillingKeyVault vault, {
    bool replaceCard = false,
  }) async {
    final id = owner(session);
    final encrypted = await vault.seal(id.toString(), reference);
    await session.db.transaction((tx) async {
      await _lockUser(session, id, tx);
      final sub = await _subscription(session, id, tx);
      if (sub == null ||
          sub.deleted ||
          (!replaceCard && sub.cancelAtPeriodEnd) ||
          sub.customerKey != customerKey) {
        throw StateError('Subscription cannot accept billing reference');
      }
      final refund = await BillingPaymentAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.subscriptionId.equals(sub.id!) &
            t.status.inSet({'refundRequested', 'refundRequired'}),
        transaction: tx,
      );
      if (refund != null) throw StateError('Refund pending');
      if (sub.encryptedBillingKey != null) {
        if (!replaceCard || sub.encryptedKeyPendingDeletion != null) {
          throw StateError('Existing reference cannot be replaced');
        }
        sub.encryptedKeyPendingDeletion = sub.encryptedBillingKey;
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

  /// Suspend grace time while the server explicitly pauses charging.
  static Future<void> updatePause(
    Session session,
    int id,
    bool paused,
    DateTime now,
  ) async {
    await session.db.transaction((tx) async {
      final sub = await BillingSubscription.db.findById(
        session,
        id,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (sub == null || sub.deleted || sub.cancelAtPeriodEnd) return;
      if (paused && sub.billingPausedUtc == null) {
        if (sub.graceThroughUtc == null || sub.graceThroughUtc!.isAfter(now)) {
          sub.billingPausedUtc = now;
        }
      } else if (!paused && sub.billingPausedUtc != null) {
        final duration = now.difference(sub.billingPausedUtc!);
        if (!duration.isNegative) {
          sub.graceThroughUtc = sub.graceThroughUtc?.add(duration);
          sub.retryAfterUtc = sub.retryAfterUtc?.add(duration);
        }
        sub.billingPausedUtc = null;
      } else {
        return;
      }
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  /// Claim one dispatch before network I/O. A crash leaves an unknown order
  /// for GET reconciliation, never an unbounded second POST.
  static Future<BillingPaymentAttempt?> dispatch(
    Session session,
    int attemptId,
    DateTime now,
  ) async {
    return session.db.transaction((tx) async {
      final first = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
      );
      if (first == null) return null;
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
      if (sub == null ||
          row == null ||
          sub.deleted ||
          sub.cancelAtPeriodEnd ||
          !{'pending', 'declined'}.contains(row.status) ||
          row.chargeStartedUtc != null ||
          (sub.retryAfterUtc?.isAfter(now) ?? false)) {
        return null;
      }
      if (sub.graceThroughUtc != null && !sub.graceThroughUtc!.isAfter(now)) {
        row.status = 'expired';
        sub.cancelAtPeriodEnd = true;
        await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
        return null;
      }
      if (row.status == 'declined') {
        // A confirmed FAILED order gets a new permanent provider identity.
        // Unknown orders never reach this branch and never receive a new ID.
        row.failedOrderIds = [...?row.failedOrderIds, row.orderId];
        row.orderId = 'af${Uuid().v4().replaceAll('-', '')}';
      }
      if (!row.paidThroughUtc.isAfter(now)) {
        sub.originUtc = now;
        sub.cycleStartPeriod = row.period;
        row.paidFromUtc = now;
        row.paidThroughUtc = SubscriptionRules.boundary(now, 1);
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
      row.chargeStartedUtc = now;
      row.status = 'unknown';
      return BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
    });
  }

  static Future<void> decline(
    Session session,
    int attemptId,
    DateTime now,
  ) async {
    await session.db.transaction((tx) async {
      final first = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
      );
      if (first == null) return;
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
      if (sub == null ||
          row == null ||
          !{'pending', 'unknown', 'declined'}.contains(row.status)) {
        return;
      }
      if (row.status == 'declined') {
        return; // Replayed failure does not consume a retry.
      }
      row.chargeStartedUtc = null;
      final renewal = sub.priceLocked;
      if (!renewal || sub.cancelAtPeriodEnd || sub.deleted) {
        row.status = 'expired';
        sub.cancelAtPeriodEnd = true;
      } else {
        sub.graceThroughUtc ??= row.paidFromUtc.add(SubscriptionPricing.grace);
        const days = [1, 3, 6];
        if (!_graceEnd(sub, now)!.isAfter(now)) {
          row.status = 'expired';
          sub.cancelAtPeriodEnd = true;
        } else {
          row.status = 'declined';
          sub.retryAfterUtc = row.retryCount >= days.length
              ? sub.graceThroughUtc
              : row.paidFromUtc.add(Duration(days: days[row.retryCount++]));
        }
      }
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      await BillingSubscription.db.updateRow(session, sub, transaction: tx);
    });
  }

  /// Admin request is durable before any provider call. An unconfirmed refund
  /// retains paid access until its original expiry, but stops future renewals.
  static Future<int> requestRefund(
    Session session,
    int attemptId,
    String expectedOrderId,
  ) async {
    OntologyAccess.requireAdmin(session);
    return session.db.transaction((tx) async {
      await _lockUser(session, owner(session), tx);
      final actor = await const AuthUsers().get(
        session,
        authUserId: owner(session),
        transaction: tx,
      );
      if (!actor.scopes.contains(Scope.admin)) {
        throw StateError('Administrator access revoked');
      }
      final first = await BillingPaymentAttempt.db.findById(
        session,
        attemptId,
        transaction: tx,
      );
      if (first == null) throw StateError('Unknown payment');
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
          row.orderId != expectedOrderId ||
          row.paymentKey == null ||
          !{'paid', 'refundRequested', 'refunded'}.contains(row.status)) {
        throw StateError('Payment cannot be refunded');
      }
      if (row.status == 'refunded') return sub.id!;
      row.status = 'refundRequested';
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      // Historical refunds must not interrupt a separately purchased cycle.
      if (row.period >= sub.cycleStartPeriod) {
        sub.cancelAtPeriodEnd = true;
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
      session.log(
        'Refund requested: actor=${owner(session)} attempt=$attemptId',
      );
      return sub.id!;
    });
  }

  static Future<void> fullRefund(
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
      if (first == null) throw StateError('Unknown refund attempt');
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
          (row.paymentKey != null && row.paymentKey != payment.key) ||
          payment.key.isEmpty ||
          row.orderId != payment.orderId ||
          payment.amount != row.amountKrw ||
          payment.balance != 0 ||
          payment.status != 'CANCELED') {
        throw StateError('Refund proof does not match attempt');
      }
      row.paymentKey = payment.key;
      row.status = 'refunded';
      await BillingPaymentAttempt.db.updateRow(session, row, transaction: tx);
      // A refund of this cycle's latest payment ends future billing as well.
      // A historical refund must not cancel a later independently purchased cycle.
      if (sub != null &&
          row.period >= sub.cycleStartPeriod &&
          row.period == sub.nextPeriod - 1) {
        sub.cancelAtPeriodEnd = true;
        sub.encryptedKeyPendingDeletion = encodePendingKeys([
          ...pendingKeys(sub.encryptedKeyPendingDeletion),
          if (sub.encryptedBillingKey != null) sub.encryptedBillingKey!,
        ]);
        sub.encryptedBillingKey = null;
        await BillingSubscription.db.updateRow(session, sub, transaction: tx);
      }
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
    sub.encryptedKeyPendingDeletion = encodePendingKeys([
      ...pendingKeys(sub.encryptedKeyPendingDeletion),
      if (sub.encryptedBillingKey != null) sub.encryptedBillingKey!,
    ]);
    sub.encryptedBillingKey = null;
    sub.cancelAtPeriodEnd = true;
    await BillingSubscription.db.updateRow(session, sub, transaction: tx);
  }
}
