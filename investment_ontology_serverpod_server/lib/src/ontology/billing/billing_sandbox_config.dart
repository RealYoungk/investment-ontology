import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import 'billing_checkout_service.dart';
import 'billing_key_vault.dart';
import 'billing_renewal_service.dart';
import 'toss_sandbox_gateway.dart';

abstract final class BillingSandboxConfig {
  static bool enabledInMode(String mode, Map<String, String> environment) {
    if (const {'development', 'test', 'staging'}.contains(mode)) {
      return environment['ALFINDER_BILLING_SANDBOX_ENABLED'] == 'true';
    }
    return mode == 'production' &&
        environment['ALFINDER_BILLING_LIVE_ENABLED'] == 'true' &&
        environment['ALFINDER_PG_BILLING_APPROVED'] == 'true' &&
        environment['ALFINDER_BILLING_PRIVACY_READY'] == 'true' &&
        (environment['ALFINDER_BILLING_TERMS_VERSION']?.trim().isNotEmpty ??
            false);
  }

  static bool chargesEnabledInMode(
    String mode,
    Map<String, String> environment,
  ) =>
      enabledInMode(mode, environment) &&
      environment['ALFINDER_BILLING_CHARGES_PAUSED'] != 'true';

  static bool chargesEnabled(Session session) =>
      chargesEnabledInMode(session.serverpod.runMode, Platform.environment);

  static bool enabled(Session session) =>
      enabledInMode(session.serverpod.runMode, Platform.environment);
  static bool isLive(Session session) =>
      session.serverpod.runMode == 'production';
  static String termsVersion(Session session) => isLive(session)
      ? Platform.environment['ALFINDER_BILLING_TERMS_VERSION'] ?? ''
      : 'sandbox-v1';

  static BillingRenewalService? service(Session session, http.Client client) {
    if (!enabled(session)) return null;
    try {
      final live = isLive(session);
      final secret =
          session.passwords[live ? 'tossLiveSecretKey' : 'tossTestSecretKey'] ??
          Platform.environment[live
              ? 'TOSS_LIVE_SECRET_KEY'
              : 'TOSS_TEST_SECRET_KEY'];
      final encryption =
          session.passwords['billingEncryptionKey'] ??
          Platform.environment['BILLING_ENCRYPTION_KEY'];
      if (secret == null ||
          encryption == null ||
          !secret.startsWith(live ? 'live_sk_' : 'test_sk_')) {
        return null;
      }
      return BillingRenewalService(
        allowCharges: chargesEnabled(session),
        gateway: TossPaymentsGateway(
          secretKey: secret,
          client: client,
          allowLive: live,
        ),
        vault: BillingKeyVault(base64Decode(encryption)),
      );
    } catch (_) {
      return null;
    }
  }

  static BillingCheckoutService? checkout(Session session, http.Client client) {
    if (!chargesEnabled(session)) return null;
    final worker = service(session, client);
    final live = isLive(session);
    final key =
        session.passwords[live ? 'tossLiveClientKey' : 'tossTestClientKey'] ??
        Platform.environment[live
            ? 'TOSS_LIVE_CLIENT_KEY'
            : 'TOSS_TEST_CLIENT_KEY'];
    if (worker == null ||
        key == null ||
        !key.startsWith(live ? 'live_ck_' : 'test_ck_')) {
      return null;
    }
    try {
      return BillingCheckoutService(
        worker: worker,
        clientKey: key,
        allowLive: live,
        termsVersion: termsVersion(session),
      );
    } catch (_) {
      return null;
    }
  }
}
