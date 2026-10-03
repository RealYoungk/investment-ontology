import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import 'billing_checkout_flow.dart';
import 'billing_key_vault.dart';
import 'billing_renewal_service.dart';
import 'toss_sandbox_gateway.dart';
import 'portone_gateway.dart';
import 'subscription_pricing.dart';

abstract final class BillingSandboxConfig {
  static bool enabledInMode(String mode, Map<String, String> environment) {
    if (const {'development', 'test', 'staging'}.contains(mode)) {
      return environment['ALFINDER_BILLING_SANDBOX_ENABLED'] == 'true';
    }
    final provider = environment['ALFINDER_BILLING_PROVIDER'];
    final approvedChannel =
        provider == 'toss' ||
        (provider == 'portone' &&
            environment['PORTONE_CONTRACT_PG'] == 'kcp_v2' &&
            environment['PORTONE_LIVE_CHANNEL_VERIFIED'] == 'true');
    return mode == 'production' &&
        approvedChannel &&
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

  static BillingRenewalService? service(
    Session session,
    http.Client client, {
    String? provider,
  }) {
    if (!enabled(session)) return null;
    try {
      final live = isLive(session);
      final chosen =
          provider ??
          Platform.environment['ALFINDER_BILLING_PROVIDER'] ??
          'portone';
      if (chosen == 'portone') {
        final mode = live ? 'LIVE' : 'TEST';
        final secret =
            session.passwords[live
                ? 'portoneLiveApiSecret'
                : 'portoneTestApiSecret'] ??
            Platform.environment['PORTONE_${mode}_API_SECRET'];
        final store = Platform.environment['PORTONE_${mode}_STORE_ID'];
        final channel = Platform.environment['PORTONE_${mode}_CHANNEL_KEY'];
        final encryption =
            session.passwords['billingEncryptionKey'] ??
            Platform.environment['BILLING_ENCRYPTION_KEY'];
        if (secret == null ||
            store == null ||
            channel == null ||
            encryption == null) {
          return null;
        }
        return BillingRenewalService(
          allowCharges: chargesEnabled(session),
          gateway: PortOneGateway(
            secret: secret,
            storeId: store,
            channelKey: channel,
            client: client,
            isTest: !live,
          ),
          vault: BillingKeyVault(base64Decode(encryption)),
        );
      }
      if (chosen != 'toss') return null;
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

  static BillingCheckoutService? checkout(
    Session session,
    http.Client client, {
    String? provider,
  }) {
    if (!chargesEnabled(session)) return null;
    final worker = service(session, client, provider: provider);
    final live = isLive(session);
    if (worker?.gateway is PortOneGateway) {
      final gateway = worker!.gateway as PortOneGateway;
      return BillingCheckoutService(
        worker: worker,
        clientKey: 'portone',
        storeId: gateway.storeId,
        channelKey: gateway.channelKey,
        amountKrw: SubscriptionPricing.currentAmount,
        priceVersion: SubscriptionPricing.currentVersion,
        termsVersion: termsVersion(session),
      );
    }
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
        amountKrw: SubscriptionPricing.currentAmount,
        priceVersion: SubscriptionPricing.currentVersion,
      );
    } catch (_) {
      return null;
    }
  }
}
