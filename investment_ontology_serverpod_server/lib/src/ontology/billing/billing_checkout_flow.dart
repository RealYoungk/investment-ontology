import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import 'billing_renewal_service.dart';
import 'membership_ledger.dart';

/// The caller is authenticated; checkout state is account-bound,
/// short-lived and atomically consumed before the external authorization call.
class BillingCheckoutService {
  BillingCheckoutService({
    required this.worker,
    required this.clientKey,
    this.termsVersion = 'sandbox-v1',
    bool allowLive = false,
    this.amountKrw = 2900,
    this.priceVersion = 'legacy-2900',
    this.storeId,
    this.channelKey,
  }) {
    if (worker.gateway.provider == 'portone') return;
    if (!RegExp(r'^test_ck_[A-Za-z0-9]+$').hasMatch(clientKey) &&
        !(allowLive && RegExp(r'^live_ck_[A-Za-z0-9]+$').hasMatch(clientKey))) {
      throw ArgumentError('Test client key required');
    }
  }
  final BillingRenewalService worker;
  final String clientKey;
  final String termsVersion;
  final int amountKrw;
  final String priceVersion;
  final String? storeId;
  final String? channelKey;
  Future<String> _hash(String state) async =>
      base64Encode((await Sha256().hash(utf8.encode(state))).bytes);

  Future<String> _issueId(String state) async =>
      'af${(await Sha256().hash(utf8.encode(state))).bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

  Future<BillingCheckoutView> begin(
    Session session, {
    required String acceptedTestTerms,
    DateTime? at,
    bool replaceCard = false,
    int? expectedAmountKrw,
  }) async {
    if (acceptedTestTerms != termsVersion) {
      throw StateError('Test terms confirmation required');
    }
    if (!replaceCard &&
        ((worker.gateway.provider == 'portone' && expectedAmountKrw == null) ||
            (expectedAmountKrw != null && expectedAmountKrw != amountKrw))) {
      throw StateError('Price changed; review the new offer');
    }
    final owner = MembershipLedger.owner(session);
    final now = at ?? DateTime.now().toUtc();
    final prepared = await MembershipLedger.prepareCheckout(
      session,
      replaceCard: replaceCard,
      priceKrw: amountKrw,
      priceVersion: priceVersion,
      provider: worker.gateway.provider,
      at: now,
    );
    if (!replaceCard) {
      final attempt = await MembershipLedger.claim(
        session,
        period: prepared.nextPeriod,
        at: now,
      );
      if (attempt == null || attempt.status != 'pending') {
        throw StateError('Checkout is unavailable');
      }
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
        prepared.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (sub == null ||
          sub.deleted ||
          (!replaceCard &&
              (sub.cancelAtPeriodEnd || sub.encryptedBillingKey != null))) {
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
          expiresUtc: now.add(const Duration(minutes: 30)),
          amountKrw: sub.priceKrw,
          priceVersion: sub.priceVersion,
          provider: sub.provider,
          status: 'waiting',
          replaceCard: replaceCard,
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
        provider: worker.gateway.provider,
        storeId: storeId,
        channelKey: channelKey,
        issueId: await _issueId(state),
        amountKrw: sub.priceKrw,
        priceVersion: sub.priceVersion,
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
          (!challenge.replaceCard && sub.cancelAtPeriodEnd) ||
          sub.customerKey == null) {
        throw StateError('Subscription unavailable');
      }
      if (sub.provider != worker.gateway.provider ||
          challenge.provider != sub.provider ||
          challenge.amountKrw != sub.priceKrw) {
        throw StateError('Checkout provider or price mismatch');
      }
      issued = await worker.gateway.issueBillingKey(
        authKey: authKey,
        issueId: await _issueId(state),
        customerKey: sub.customerKey!,
        idempotencyKey: challenge.issueIdempotencyKey,
      );
      await MembershipLedger.storeBillingReference(
        session,
        sub.customerKey!,
        issued,
        worker.vault,
        replaceCard: challenge.replaceCard,
      );
      challenge.status = 'completed';
      await BillingCheckout.db.updateRow(session, challenge);
      await worker.reconcileKeyDeletion(session, sub.id!);
      if (!challenge.replaceCard) await worker.run(session, sub.id!, at: at);
      return await MembershipLedger.status(session, at: at);
    } catch (_) {
      challenge.status = 'unknown';
      await BillingCheckout.db.updateRow(session, challenge);
      // If authorization succeeded but the account changed before storage,
      // queue the unused provider reference for durable cleanup.
      if (issued != null) {
        await MembershipLedger.queueUnconfirmedReference(
          session,
          challenge.subscriptionId,
          issued,
          worker.vault,
        );
        await worker.reconcileKeyDeletion(session, challenge.subscriptionId);
      }
      throw StateError(
        'Test checkout could not be confirmed; inspect durable state',
      );
    }
  }
}
