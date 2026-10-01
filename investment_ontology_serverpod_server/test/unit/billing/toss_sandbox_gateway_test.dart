import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';

Map<String, Object> payment([Map<String, Object> overrides = const {}]) => {
  'paymentKey': 'payment_123456',
  'orderId': 'order_123456',
  'type': 'BILLING',
  'currency': 'KRW',
  'totalAmount': 2900,
  'balanceAmount': 2900,
  'status': 'DONE',
  ...overrides,
};
void main() {
  late TossSandboxGateway gateway;
  Future<SandboxPayment> charge() => gateway.charge(
    billingKey: 'billing_123456',
    customerKey: 'customer_123456',
    orderId: 'order_123456',
    idempotencyKey: 'attempt_123456',
  );
  test('opaque base64 billing key is accepted and path escaped', () async {
    final opaqueKey = 'billing+/reference==';
    gateway = TossSandboxGateway(
      secretKey: 'test_sk_fixture',
      client: MockClient((r) async {
        expect(r.url.pathSegments.last, opaqueKey);
        expect(r.url.pathSegments.length, 3);
        return http.Response(jsonEncode(payment()), 200);
      }),
    );
    await gateway.charge(
      billingKey: opaqueKey,
      customerKey: 'customer_123456',
      orderId: 'order_123456',
      idempotencyKey: 'attempt_123456',
    );
  });
  test(
    'billing reference deletion accepts empty 204 and escapes opaque key',
    () async {
      gateway = TossSandboxGateway(
        secretKey: 'test_sk_fixture',
        client: MockClient((r) async {
          expect(r.method, 'DELETE');
          expect(r.url.pathSegments.last, 'opaque+/key==');
          return http.Response('', 204);
        }),
      );
      await gateway.deleteBillingKey('opaque+/key==');
    },
  );
  test('live credentials rejected before any network request', () {
    expect(
      () => TossSandboxGateway(
        secretKey: 'live_sk_rejected',
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      throwsArgumentError,
    );
  });
  test('server fixes amount and sends stable idempotency on retry', () async {
    final requests = <http.Request>[];
    gateway = TossSandboxGateway(
      secretKey: 'test_sk_fixture',
      client: MockClient((r) async {
        requests.add(r);
        return http.Response(jsonEncode(payment()), 200);
      }),
    );
    await charge();
    await charge();
    expect(
      requests.map((r) => r.headers['Idempotency-Key']),
      everyElement('attempt_123456'),
    );
    expect(jsonDecode(requests.first.body)['amount'], 2900);
    expect(requests.first.url.host, 'api.tosspayments.com');
    expect(requests.first.url.scheme, 'https');
    expect(
      requests.first.headers['Authorization'],
      'Basic ${base64Encode(utf8.encode('test_sk_fixture:'))}',
    );
  });
  for (final bad in [
    {'orderId': 'other_123456'},
    {'totalAmount': 1},
    {'currency': 'USD'},
    {'type': 'NORMAL'},
    {'status': 'WAITING_FOR_DEPOSIT'},
    {'paymentKey': ''},
    {'balanceAmount': 0},
    {'balanceAmount': -1},
  ]) {
    test('untrusted provider identity $bad cannot grant entitlement', () async {
      gateway = TossSandboxGateway(
        secretKey: 'test_sk_fixture',
        client: MockClient(
          (_) async => http.Response(jsonEncode(payment(bad)), 200),
        ),
      );
      await expectLater(
        charge(),
        throwsA(
          isA<SandboxPaymentException>().having(
            (e) => e.uncertain,
            'uncertain',
            true,
          ),
        ),
      );
    });
  }
  test(
    'timeout is unknown, exception never leaks secrets or provider body',
    () async {
      gateway = TossSandboxGateway(
        secretKey: 'test_sk_fixture',
        client: MockClient(
          (_) async => throw TimeoutException('billing_123456 auth secret'),
        ),
      );
      try {
        await charge();
        fail('expected unknown');
      } on SandboxPaymentException catch (e) {
        expect(e.uncertain, true);
        expect(e.toString(), isNot(contains('billing_123456')));
      }
    },
  );
  for (final status in [409, 500, 502]) {
    test('$status remains unknown for same-order reconciliation', () async {
      gateway = TossSandboxGateway(
        secretKey: 'test_sk_fixture',
        client: MockClient(
          (_) async => http.Response('secret provider response', status),
        ),
      );
      await expectLater(
        charge(),
        throwsA(
          isA<SandboxPaymentException>().having(
            (e) => e.uncertain,
            'uncertain',
            true,
          ),
        ),
      );
    });
  }
  test('lookup reconciles the original order without another charge', () async {
    gateway = TossSandboxGateway(
      secretKey: 'test_sk_fixture',
      client: MockClient((r) async {
        expect(r.method, 'GET');
        expect(r.url.path, '/v1/payments/orders/order_123456');
        return http.Response(jsonEncode(payment()), 200);
      }),
    );
    expect((await gateway.lookup('order_123456')).status, 'DONE');
  });
  test('billing key response must belong to requested customer', () async {
    gateway = TossSandboxGateway(
      secretKey: 'test_sk_fixture',
      client: MockClient(
        (_) async => http.Response(
          '{"billingKey":"billing_123456","customerKey":"someone_else"}',
          200,
        ),
      ),
    );
    await expectLater(
      gateway.issueBillingKey(
        authKey: 'auth_fixture',
        customerKey: 'customer_123456',
        idempotencyKey: 'issue_123456',
      ),
      throwsA(isA<SandboxPaymentException>()),
    );
  });
  test('full refund validates payment identity and zero balance', () async {
    gateway = TossSandboxGateway(
      secretKey: 'test_sk_fixture',
      client: MockClient((r) async {
        expect(r.url.path, '/v1/payments/payment_123456/cancel');
        return http.Response(
          jsonEncode(payment({'status': 'CANCELED', 'balanceAmount': 0})),
          200,
        );
      }),
    );
    expect(
      (await gateway.refund(
        paymentKey: 'payment_123456',
        orderId: 'order_123456',
        idempotencyKey: 'refund_123456',
      )).balance,
      0,
    );
  });
}
