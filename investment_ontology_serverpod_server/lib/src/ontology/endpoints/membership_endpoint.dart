import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../billing/membership_ledger.dart';
import '../billing/billing_sandbox_config.dart';

/// Personal, server-derived status and guarded checkout.
class MembershipEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<MembershipView> status(Session session) async {
    final view = await MembershipLedger.status(session);
    final client = http.Client();
    try {
      final service = BillingSandboxConfig.checkout(session, client);
      return view.copyWith(
        paymentAvailable: service != null,
        termsVersion: service?.termsVersion,
        isTest: !BillingSandboxConfig.isLive(session),
      );
    } finally {
      client.close();
    }
  }

  Future<BillingCheckoutView> beginCheckout(
    Session session,
    String acceptedTestTerms,
  ) async {
    final client = http.Client();
    try {
      final service = BillingSandboxConfig.checkout(session, client);
      if (service == null) throw StateError('Checkout is not enabled');
      return await service.begin(session, acceptedTestTerms: acceptedTestTerms);
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
      final service = BillingSandboxConfig.checkout(session, client);
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
      final service = BillingSandboxConfig.checkout(session, client);
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
