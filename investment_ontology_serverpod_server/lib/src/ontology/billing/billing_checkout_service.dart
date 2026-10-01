import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import 'billing_renewal_service.dart';
import 'membership_ledger.dart';
import 'toss_sandbox_gateway.dart';

/// The caller is authenticated; checkout state is account-bound,
/// short-lived and atomically consumed before the external authorization call.
class BillingCheckoutService {
  BillingCheckoutService({
    required this.worker,
    required this.clientKey,
    this.termsVersion = 'sandbox-v1',
    bool allowLive = false,
  }) {
    if (!RegExp(r'^test_ck_[A-Za-z0-9]+$').hasMatch(clientKey) &&
        !(allowLive && RegExp(r'^live_ck_[A-Za-z0-9]+$').hasMatch(clientKey))) {
      throw ArgumentError('Test client key required');
    }
  }
  final BillingRenewalService worker;
  final String clientKey;
  final String termsVersion;
  Future<String> _hash(String state) async =>
      base64Encode((await Sha256().hash(utf8.encode(state))).bytes);

  Future<BillingCheckoutView> begin(
    Session session, {
    required String acceptedTestTerms,
    DateTime? at,
  }) async {
    if (acceptedTestTerms != termsVersion) {
      throw StateError('Test terms confirmation required');
    }
    final owner = MembershipLedger.owner(session);
    final now = at ?? DateTime.now().toUtc();
    final attempt = await MembershipLedger.claim(session, period: 0, at: now);
    if (attempt == null ||
        !const {'pending', 'unknown'}.contains(attempt.status)) {
      throw StateError('Checkout is unavailable');
    }
    final state = base64UrlEncode(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    );
    final hash = await _hash(state);
    return session.db.transaction((tx) async {
      final user = await AuthUser.db.findById(
        session,
        owner,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (user == null || user.blocked) throw StateError('Account unavailable');
      final sub = await BillingSubscription.db.findById(
        session,
        attempt.subscriptionId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (sub == null ||
          sub.deleted ||
          sub.cancelAtPeriodEnd ||
          sub.encryptedBillingKey != null) {
        throw StateError('Checkout is unavailable');
      }
      final unresolved = await BillingCheckout.db.findFirstRow(
        session,
        where: (t) =>
            t.ownerId.equals(owner) &
            (t.status.inSet({'processing', 'unknown'}) |
                (t.status.equals('waiting') & (t.expiresUtc > now))),
        transaction: tx,
      );
      if (unresolved != null) {
        throw StateError('An existing checkout must finish first');
      }
      await BillingCheckout.db.insertRow(
        session,
        BillingCheckout(
          ownerId: owner,
          subscriptionId: sub.id!,
          stateHash: hash,
          expiresUtc: now.add(const Duration(minutes: 10)),
          status: 'waiting',
          termsVersion: termsVersion,
          acceptedAtUtc: now,
          issueIdempotencyKey: 'issue-${Uuid().v4()}',
        ),
        transaction: tx,
      );
      return BillingCheckoutView(
        state: state,
        customerKey: sub.customerKey!,
        clientKey: clientKey,
      );
    });
  }

  Future<void> abort(Session session, String state) async {
    if (state.length > 100) throw ArgumentError('Invalid state');
    final owner = MembershipLedger.owner(session);
    final hash = await _hash(state);
    await session.db.transaction((tx) async {
      final row = await BillingCheckout.db.findFirstRow(
        session,
        where: (t) => t.ownerId.equals(owner) & t.stateHash.equals(hash),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row != null && row.status == 'waiting') {
        row.status = 'canceled';
        await BillingCheckout.db.updateRow(session, row, transaction: tx);
      }
    });
  }

  Future<MembershipView> complete(
    Session session, {
    required String state,
    required String authKey,
    DateTime? at,
  }) async {
    if (state.length > 100 || authKey.isEmpty || authKey.length > 300) {
      throw ArgumentError('Invalid callback');
    }
    final owner = MembershipLedger.owner(session);
    final hash = await _hash(state);
    final now = at ?? DateTime.now().toUtc();
    final challenge = await session.db.transaction((tx) async {
      final user = await AuthUser.db.findById(
        session,
        owner,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (user == null || user.blocked) throw StateError('Account unavailable');
      final row = await BillingCheckout.db.findFirstRow(
        session,
        where: (t) => t.stateHash.equals(hash) & t.ownerId.equals(owner),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row == null) {
        throw StateError('Callback state does not match account');
      }
      if (row.status == 'completed') return row;
      if (row.status != 'waiting' ||
          row.termsVersion != termsVersion ||
          row.acceptedAtUtc == null ||
          !row.expiresUtc.isAfter(now)) {
        throw StateError('Callback state is unavailable');
      }
      row.status = 'processing';
      return BillingCheckout.db.updateRow(session, row, transaction: tx);
    });
    if (challenge.status == 'completed') {
      return await MembershipLedger.status(session, at: at);
    }
    final sub = await BillingSubscription.db.findById(
      session,
      challenge.subscriptionId,
    );
    String? issued;
    try {
      if (sub == null ||
          sub.deleted ||
          sub.cancelAtPeriodEnd ||
          sub.customerKey == null) {
        throw StateError('Subscription unavailable');
      }
      issued = await worker.gateway.issueBillingKey(
        authKey: authKey,
        customerKey: sub.customerKey!,
        idempotencyKey: challenge.issueIdempotencyKey,
      );
      await MembershipLedger.storeBillingReference(
        session,
        sub.customerKey!,
        issued,
        worker.vault,
      );
      challenge.status = 'completed';
      await BillingCheckout.db.updateRow(session, challenge);
      await worker.run(session, sub.id!, at: at);
      return await MembershipLedger.status(session, at: at);
    } catch (_) {
      challenge.status = 'unknown';
      await BillingCheckout.db.updateRow(session, challenge);
      // If authorization succeeded but the account changed before storage,
      // disable the test billing reference instead of charging it.
      if (issued != null) {
        try {
          await worker.gateway.deleteBillingKey(issued);
        } on SandboxPaymentException {
          /* Operator reconciliation required. */
        }
      }
      throw StateError(
        'Test checkout could not be confirmed; inspect durable state',
      );
    }
  }
}
