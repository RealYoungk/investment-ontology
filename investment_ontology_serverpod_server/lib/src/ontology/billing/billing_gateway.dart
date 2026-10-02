import 'toss_sandbox_gateway.dart';

abstract interface class BillingGateway {
  String get provider;
  Duration get safeReplayWindow;
  Future<String> issueBillingKey({
    required String authKey,
    required String customerKey,
    required String idempotencyKey,
    String? issueId,
  });
  Future<SandboxPayment> charge({
    required String billingKey,
    required String customerKey,
    required String orderId,
    required String idempotencyKey,
    int amountKrw = 2900,
  });
  Future<SandboxPayment> lookup(String orderId);
  Future<void> deleteBillingKey(String key);
  Future<SandboxPayment> refund({
    required String paymentKey,
    required String orderId,
    required String idempotencyKey,
  });
}
