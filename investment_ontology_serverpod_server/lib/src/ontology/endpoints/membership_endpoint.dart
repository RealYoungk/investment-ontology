import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../billing/subscription_pricing.dart';
import '../billing/membership_ledger.dart';
import '../billing/billing_provider_config.dart';

/// Personal, server-derived status and guarded checkout.
class MembershipEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<List<BillingPaymentView>> paymentsForAccount(
    Session session,
    String userId,
  ) async {
    OntologyAccess.requireAdmin(session);
    final sub = await BillingSubscription.db.findFirstRow(
      session,
      where: (t) => t.ownerId.equals(UuidValue.fromString(userId)),
    );
    if (sub == null) return [];
    final rows = await BillingPaymentAttempt.db.find(
      session,
      where: (t) => t.subscriptionId.equals(sub.id!),
      orderBy: (t) => t.period.desc(),
      limit: 60,
    );
    return [
      for (final row in rows)
        BillingPaymentView(
          attemptId: row.id!,
          orderId: row.orderId,
          status: row.status,
          amountKrw: row.amountKrw,
          paidFromUtc: row.paidFromUtc,
          paidThroughUtc: row.paidThroughUtc,
        ),
    ];
  }

  Future<void> refundPayment(
    Session session,
    int attemptId,
    String expectedOrderId,
  ) async {
    OntologyAccess.requireAdmin(session);
    final client = http.Client();
    try {
      final row = await BillingPaymentAttempt.db.findById(session, attemptId);
      final sub = row == null
          ? null
          : await BillingSubscription.db.findById(session, row.subscriptionId);
      final service = sub == null
          ? null
          : BillingSandboxConfig.service(
              session,
              client,
              provider: row!.provider,
            );
      if (service == null) {
        throw StateError('Payment operations are not enabled');
      }
      final subscription = await MembershipLedger.requestRefund(
        session,
        attemptId,
        expectedOrderId,
      );
      await service.reconcileRefunds(session, subscription);
    } finally {
      client.close();
    }
  }

  Future<MembershipView> status(Session session) async {
    final view = await MembershipLedger.status(session);
    final client = http.Client();
    try {
      final sub = await BillingSubscription.db.findFirstRow(
        session,
        where: (t) => t.ownerId.equals(MembershipLedger.owner(session)),
      );
      final service = BillingSandboxConfig.checkout(
        session,
        client,
        provider: view.priceProtected ? sub?.provider : null,
      );
      return view.copyWith(
        paymentAvailable: service != null,
        termsVersion: service?.termsVersion,
        isTest: !BillingSandboxConfig.isLive(session),
        currentPriceKrw: SubscriptionPricing.currentAmount,
      );
    } finally {
      client.close();
    }
  }

  Future<BillingCheckoutView> beginCheckout(
    Session session,
    String acceptedTestTerms, {
    int? expectedAmountKrw,
  }) async {
    final client = http.Client();
    try {
      final service = BillingSandboxConfig.checkout(session, client);
      if (service == null) throw StateError('Checkout is not enabled');
      return await service.begin(
        session,
        acceptedTestTerms: acceptedTestTerms,
        expectedAmountKrw: expectedAmountKrw,
      );
    } finally {
      client.close();
    }
  }

  Future<BillingCheckoutView> beginCardReplacement(
    Session session,
    String acceptedTestTerms,
  ) async {
    final client = http.Client();
    try {
      final sub = await BillingSubscription.db.findFirstRow(
        session,
        where: (t) => t.ownerId.equals(MembershipLedger.owner(session)),
      );
      final service = BillingSandboxConfig.checkout(
        session,
        client,
        provider: sub?.provider,
      );
      if (service == null) throw StateError('Checkout is not enabled');
      return await service.begin(
        session,
        acceptedTestTerms: acceptedTestTerms,
        replaceCard: true,
      );
    } finally {
      client.close();
    }
  }

  Future<void> resumeRenewal(Session session) =>
      MembershipLedger.resume(session);

  Future<MembershipView> completeCheckout(
    Session session,
    String state,
    String authKey,
  ) async {
    final client = http.Client();
    try {
      final sub = await BillingSubscription.db.findFirstRow(
        session,
        where: (t) => t.ownerId.equals(MembershipLedger.owner(session)),
      );
      final service = BillingSandboxConfig.checkout(
        session,
        client,
        provider: sub?.provider,
      );
      if (service == null) throw StateError('Checkout is not enabled');
      return await service.complete(session, state: state, authKey: authKey);
    } finally {
      client.close();
    }
  }

  Future<void> abortCheckout(Session session, String state) async {
    final client = http.Client();
    try {
      final service = BillingSandboxConfig.checkout(session, client);
      if (service == null) throw StateError('Checkout is not enabled');
      await service.abort(session, state);
    } finally {
      client.close();
    }
  }

  Future<void> cancelRenewal(Session session) =>
      MembershipLedger.cancel(session);
}
