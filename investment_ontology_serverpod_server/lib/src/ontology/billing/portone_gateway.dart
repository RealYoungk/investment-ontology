import 'dart:convert';

import 'package:http/http.dart' as http;

import 'billing_gateway.dart';
import 'toss_sandbox_gateway.dart';

/// PortOne V2 protocol verified against official server-sdk 0.19.0.
/// Browser callbacks are hints only: key ownership and payment proof are read
/// from the provider before storing a reference or granting access.
class PortOneGateway implements BillingGateway {
  PortOneGateway({
    required String secret,
    required this.storeId,
    required this.channelKey,
    required this.client,
    required this.isTest,
  }) : _authorization = 'PortOne $secret' {
    if (secret.isEmpty || storeId.isEmpty || channelKey.isEmpty) {
      throw ArgumentError('Missing PortOne configuration');
    }
  }
  final http.Client client;
  final String storeId;
  final String channelKey;
  final bool isTest;
  final String _authorization;
  @override
  String get provider => 'portone';
  @override
  Duration get safeReplayWindow => const Duration(hours: 2);

  Future<Map<String, dynamic>> _request(
    String method,
    List<String> path, {
    Map<String, Object>? body,
    String? idempotencyKey,
  }) async {
    final request = http.Request(
      method,
      Uri(
        scheme: 'https',
        host: 'api.portone.io',
        pathSegments: path,
        queryParameters: method == 'GET' || method == 'DELETE'
            ? {'storeId': storeId}
            : null,
      ),
    );
    request.headers.addAll({
      'Authorization': _authorization,
      'Content-Type': 'application/json',
      if (idempotencyKey != null) 'Idempotency-Key': '"$idempotencyKey"',
    });
    if (body != null) request.body = jsonEncode(body);
    http.Response response;
    try {
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 65));
    } catch (_) {
      throw const SandboxPaymentException('transport', uncertain: true);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // No error text containing customer/card data leaves this adapter.
      // Only a confirmed FAILED payment is treated as a card decline.
      throw SandboxPaymentException(
        'portone_http_${response.statusCode}',
        uncertain: true,
      );
    }
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const SandboxPaymentException('invalid_response', uncertain: true);
    }
  }

  bool _channel(dynamic channel) =>
      channel is Map && channel['key'] == channelKey;

  @override
  Future<String> issueBillingKey({
    required String authKey,
    required String customerKey,
    required String idempotencyKey,
    String? issueId,
  }) async {
    if (authKey.isEmpty || authKey.length > 300 || issueId == null) {
      throw ArgumentError('Missing key issue identity');
    }
    final value = await _request('GET', ['billing-keys', authKey]);
    final channels = value['channels'];
    if (value['status'] != 'ISSUED' ||
        value['billingKey'] != authKey ||
        value['storeId'] != storeId ||
        value['issueId'] != issueId ||
        value['customer'] is! Map ||
        value['customer']['id'] != customerKey ||
        channels is! List ||
        !channels.any(_channel) ||
        value['methods'] is! List ||
        !(value['methods'] as List).any(
          (m) => m is Map && m['type'] == 'CARD',
        )) {
      throw const SandboxPaymentException('billing_identity', uncertain: true);
    }
    return authKey;
  }

  SandboxPayment _payment(Map<String, dynamic> value, String orderId) {
    final amount = value['amount'];
    final status = value['status'];
    if (value['id'] != orderId ||
        value['storeId'] != storeId ||
        value['version'] != 'V2' ||
        value['currency'] != 'KRW' ||
        !_channel(value['channel']) ||
        value['billingKey'] is! String ||
        (status != 'FAILED' &&
            (value['method'] is! Map || value['method']['type'] != 'CARD')) ||
        value['transactionId'] is! String ||
        (value['transactionId'] as String).isEmpty ||
        amount is! Map ||
        amount['total'] is! int ||
        amount['paid'] is! int ||
        amount['cancelled'] is! int ||
        amount['discount'] != 0 ||
        (amount['total'] as int) <= 0 ||
        !{
          'PAID',
          'CANCELLED',
          'PARTIAL_CANCELLED',
          'FAILED',
        }.contains(status)) {
      throw const SandboxPaymentException('payment_identity', uncertain: true);
    }
    if (status == 'FAILED') {
      throw const SandboxPaymentException('declined');
    }
    final total = amount['total'] as int;
    final cancelled = amount['cancelled'] as int;
    if (amount['paid'] != total ||
        cancelled < 0 ||
        cancelled > total ||
        (status == 'PAID' && cancelled != 0) ||
        (status == 'CANCELLED' && cancelled != total)) {
      throw const SandboxPaymentException('payment_balance', uncertain: true);
    }
    return SandboxPayment(
      key: value['transactionId'] as String,
      orderId: orderId,
      status: status == 'PAID'
          ? 'DONE'
          : status == 'CANCELLED'
          ? 'CANCELED'
          : 'PARTIAL_CANCELED',
      amount: total,
      balance: total - cancelled,
    );
  }

  @override
  Future<SandboxPayment> charge({
    required String billingKey,
    required String customerKey,
    required String orderId,
    required String idempotencyKey,
    int amountKrw = 2900,
  }) async {
    if (amountKrw <= 0) throw ArgumentError('Invalid amount');
    // Persisted paymentId is the permanent identity; the 3-hour provider
    // idempotency window must never authorize resending an old unknown POST.
    try {
      await _request(
        'POST',
        ['payments', orderId, 'billing-key'],
        body: {
          'storeId': storeId,
          'channelKey': channelKey,
          'billingKey': billingKey,
          'orderName': '알파인더 월간 멤버십',
          'customer': {'id': customerKey},
          'amount': {'total': amountKrw},
          'currency': 'KRW',
          'productType': 'DIGITAL',
        },
        idempotencyKey: idempotencyKey,
      );
    } on SandboxPaymentException {
      // Query handles lost approvals and provider-declared declines safely.
      // Continue to the same authenticated GET and ownership checks.
      // Never skip customer validation after an uncertain POST.
    }
    final value = await _request('GET', ['payments', orderId]);
    if (value['customer'] is! Map ||
        value['customer']['id'] != customerKey ||
        value['billingKey'] != billingKey) {
      throw const SandboxPaymentException('customer_identity', uncertain: true);
    }
    return _payment(value, orderId);
  }

  @override
  Future<SandboxPayment> lookup(String orderId) async =>
      _payment(await _request('GET', ['payments', orderId]), orderId);

  @override
  Future<void> deleteBillingKey(String key) async {
    try {
      await _request('DELETE', ['billing-keys', key]);
    } on SandboxPaymentException {
      final current = await _request('GET', ['billing-keys', key]);
      if (current['status'] != 'DELETED' || current['storeId'] != storeId) {
        rethrow;
      }
    }
  }

  @override
  Future<SandboxPayment> refund({
    required String paymentKey,
    required String orderId,
    required String idempotencyKey,
  }) async {
    final current = await lookup(orderId);
    if (current.key != paymentKey) {
      throw const SandboxPaymentException('refund_identity', uncertain: true);
    }
    if (current.status != 'CANCELED') {
      await _request(
        'POST',
        ['payments', orderId, 'cancel'],
        body: {
          'storeId': storeId,
          'reason': '멤버십 전액 환불',
          'currentCancellableAmount': current.balance,
        },
        idempotencyKey: idempotencyKey,
      );
    }
    return lookup(orderId);
  }
}
