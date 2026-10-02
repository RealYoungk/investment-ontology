import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../billing/billing_provider_config.dart';
import '../billing/subscription_pricing.dart';

/// Public pricing only; account entitlements stay on MembershipEndpoint.
class MembershipOfferEndpoint extends Endpoint {
  Future<MembershipView> offer(Session session) async {
    final transport = http.Client();
    try {
      final checkout = BillingSandboxConfig.checkout(session, transport);
      return MembershipView(
        adFree: false,
        cancelAtPeriodEnd: false,
        currentPriceKrw: SubscriptionPricing.currentAmount,
        paymentAvailable: checkout != null,
        termsVersion: checkout?.termsVersion,
        isTest: !BillingSandboxConfig.isLive(session),
      );
    } finally {
      transport.close();
    }
  }
}
