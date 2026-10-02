import 'dart:async';
import 'dart:convert';

import 'billing_gateway.dart';

import 'package:http/http.dart' as http;

/// Provider failures carry safe codes; activation is guarded by server config.
/// Never include provider bodies, URLs, auth keys or billing keys in errors/logs.
class SandboxPaymentException implements Exception {
  const SandboxPaymentException(this.code, {this.uncertain = false});
  final String code;
  final bool uncertain;
  @override
  String toString() => 'SandboxPaymentException($code, uncertain=$uncertain)';
}

class SandboxPayment {
  const SandboxPayment({
    required this.key,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.balance,
  });
  final String key;
  final String orderId;
  final String status;
  final int amount;
  final int balance;
}

class TossPaymentsGateway implements BillingGateway {
  @override
  String get provider => 'toss';
  @override
  Duration get safeReplayWindow => const Duration(days: 14);
  TossPaymentsGateway({
    required String secretKey,
    required this.client,
    bool allowLive = false,
  }) : _authorization = 'Basic ${base64Encode(utf8.encode('$secretKey:'))}' {
    if (!RegExp(r'^test_sk_[A-Za-z0-9]+$').hasMatch(secretKey) &&
        !(allowLive && RegExp(r'^live_sk_[A-Za-z0-9]+$').hasMatch(secretKey))) {
      throw ArgumentError('Credential mode is not authorized');
    }
  }
  static const monthlyAmount = 2900;
  final http.Client client;
  final String _authorization;

  void _identifier(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]{6,200}$').hasMatch(value)) {
      throw ArgumentError('Invalid opaque identifier');
    }
  }

  void _providerKey(String value) {
    // Provider tokens are opaque: billing keys can contain base64 + / =.
    // Uri.pathSegments performs path escaping; do not constrain them as IDs.
    if (value.isEmpty ||
        value.length > 300 ||
        value.codeUnits.any((c) => c < 33 || c > 126)) {
      throw ArgumentError('Invalid provider reference');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    List<String> path, {
    Map<String, Object>? body,
    String? idempotencyKey,
    bool allowEmpty = false,
  }) async {
    if (method == 'POST' &&
        (idempotencyKey == null ||
            !RegExp(r'^[A-Za-z0-9_-]{6,100}$').hasMatch(idempotencyKey))) {
      throw ArgumentError('A stable idempotency key is required');
    }
    final request =
        http.Request(
            method,
            Uri(
              scheme: 'https',
              host: 'api.tosspayments.com',
              pathSegments: path,
            ),
          )
          ..headers.addAll({
            'Authorization': _authorization,
            'Content-Type': 'application/json',
            'Idempotency-Key': ?idempotencyKey,
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
      // A 409 may be a still-processing idempotent request or duplicate order.
      // Query the same order; never generate another order to "fix" this.
      final uncertain =
          response.statusCode >= 500 || response.statusCode == 409;
      throw SandboxPaymentException(
        'http_${response.statusCode}',
        uncertain: uncertain,
      );
    }
    if (allowEmpty && response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const SandboxPaymentException('invalid_response', uncertain: true);
    }
  }

  @override
  Future<String> issueBillingKey({
    required String authKey,
    String? issueId,
    required String customerKey,
    required String idempotencyKey,
  }) async {
    _identifier(customerKey);
    if (authKey.isEmpty || authKey.length > 300) {
      throw ArgumentError('Invalid authorization reference');
    }
    final value = await _request(
      'POST',
      ['v1', 'billing', 'authorizations', 'issue'],
      body: {'authKey': authKey, 'customerKey': customerKey},
      idempotencyKey: idempotencyKey,
    );
    final key = value['billingKey'];
    if (value['customerKey'] != customerKey || key is! String || key.isEmpty) {
      throw const SandboxPaymentException('billing_identity', uncertain: true);
    }
    _providerKey(key);
    return key;
  }

  SandboxPayment _payment(Map<String, dynamic> value, String orderId) {
    if (value['orderId'] != orderId ||
        value['type'] != 'BILLING' ||
        value['currency'] != 'KRW' ||
        value['totalAmount'] is! int ||
        (value['totalAmount'] as int) <= 0 ||
        value['paymentKey'] is! String ||
        (value['paymentKey'] as String).isEmpty ||
        value['balanceAmount'] is! int ||
        !const {
          'DONE',
          'CANCELED',
          'PARTIAL_CANCELED',
        }.contains(value['status'])) {
      throw const SandboxPaymentException('payment_identity', uncertain: true);
    }
    final total = value['totalAmount'] as int;
    final balance = value['balanceAmount'] as int;
    if (balance < 0 ||
        balance > total ||
        (value['status'] == 'DONE' && balance != total) ||
        (value['status'] == 'CANCELED' && balance != 0)) {
      throw const SandboxPaymentException('payment_balance', uncertain: true);
    }
    return SandboxPayment(
      key: value['paymentKey'] as String,
      orderId: orderId,
      status: value['status'] as String,
      amount: total,
      balance: balance,
    );
  }

  @override
  Future<SandboxPayment> charge({
    required String billingKey,
    int amountKrw = monthlyAmount,
    required String customerKey,
    required String orderId,
    required String idempotencyKey,
  }) async {
    _providerKey(billingKey);
    _identifier(customerKey);
    _identifier(orderId);
    if (orderId.length > 64) throw ArgumentError('Order ID is too long');
    return _payment(
      await _request(
        'POST',
        ['v1', 'billing', billingKey],
        body: {
          'customerKey': customerKey,
          'amount': amountKrw,
          'orderId': orderId,
          'orderName': '알파인더 광고 제거 1개월',
        },
        idempotencyKey: idempotencyKey,
      ),
      orderId,
    );
  }

  @override
  Future<SandboxPayment> lookup(String orderId) async {
    _identifier(orderId);
    return _payment(
      await _request('GET', ['v1', 'payments', 'orders', orderId]),
      orderId,
    );
  }

  @override
  Future<void> deleteBillingKey(String key) async {
    _providerKey(key);
    await _request('DELETE', ['v1', 'billing', key], allowEmpty: true);
  }

  @override
  Future<SandboxPayment> refund({
    required String paymentKey,
    required String orderId,
    required String idempotencyKey,
  }) async {
    _identifier(paymentKey);
    _identifier(orderId);
    final result = _payment(
      await _request(
        'POST',
        ['v1', 'payments', paymentKey, 'cancel'],
        body: {'cancelReason': '광고 제거 이용권 결제 정리'},
        idempotencyKey: idempotencyKey,
      ),
      orderId,
    );
    if (result.key != paymentKey || result.status != 'CANCELED') {
      throw const SandboxPaymentException('refund_identity', uncertain: true);
    }
    return result;
  }
}

/// The provider verification runner never accepts a live key.
class TossSandboxGateway extends TossPaymentsGateway {
  TossSandboxGateway({required super.secretKey, required super.client});
}
