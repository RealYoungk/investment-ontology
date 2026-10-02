import 'dart:io';

/// New offers are explicitly published by deploy configuration; existing
/// subscription/payment snapshots never read this value during renewal/refund.
abstract final class SubscriptionPricing {
  static const launchAmount = 4900;
  static const targetAmount = 19900;
  static const grace = Duration(days: 7);
  static int get currentAmount {
    final value = int.tryParse(
      Platform.environment['ALFINDER_NEW_SUBSCRIPTION_PRICE_KRW'] ?? '4900',
    );
    if (!{4900, 9900, 14900, 19900}.contains(value)) {
      throw StateError('Invalid published subscription price');
    }
    return value!;
  }

  static String get currentVersion => 'monthly-v1-$currentAmount';
}
