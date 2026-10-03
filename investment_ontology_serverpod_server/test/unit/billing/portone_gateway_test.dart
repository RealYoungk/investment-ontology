import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/portone_gateway.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';

Map<String, Object?> proof({
  String status = 'PAID',
  String customer = 'customer',
  int amount = 4900,
}) => {
  'id': 'order',
  'storeId': 'store',
  'version': 'V2',
  'currency': 'KRW',
  'channel': {'key': 'channel'},
  'billingKey': 'key',
  'customer': {'id': customer},
  'method': {'type': 'CARD'},
  'transactionId': 'transaction',
  'status': status,
  'amount': {
    'total': amount,
    'paid': status == 'FAILED' ? 0 : amount,
    'cancelled': status == 'CANCELLED' ? amount : 0,
    'discount': 0,
  },
};
PortOneGateway gateway(Future<http.Response> Function(http.Request) handler) =>
    PortOneGateway(
      secret: 'isolated-secret',
      storeId: 'store',
      channelKey: 'channel',
      isTest: true,
      client: MockClient(handler),
    );
Future<SandboxPayment> charge(PortOneGateway value) => value.charge(
  billingKey: 'key',
  customerKey: 'customer',
  orderId: 'order',
  idempotencyKey: 'attempt',
  amountKrw: 4900,
);
void main() {
  test(
    'charge uses card billing, quoted idempotency and provider GET proof',
    () async {
      final requests = <http.Request>[];
      final result = await charge(
        gateway((r) async {
          requests.add(r);
          return http.Response(jsonEncode(proof()), 200);
        }),
      );
      expect(requests.map((r) => r.method), ['POST', 'GET']);
      expect(jsonDecode(requests.first.body)['amount'], {'total': 4900});
      expect(requests.first.headers['Idempotency-Key'], '"attempt"');
      expect(requests.last.url.queryParameters['storeId'], 'store');
      expect(result.amount, 4900);
    },
  );
  test('lost POST response still checks customer identity', () async {
    await expectLater(
      charge(
        gateway(
          (r) async => r.method == 'POST'
              ? http.Response('{}', 500)
              : http.Response(jsonEncode(proof(customer: 'foreign')), 200),
        ),
      ),
      throwsA(
        isA<SandboxPaymentException>().having(
          (e) => e.uncertain,
          'uncertain',
          true,
        ),
      ),
    );
  });
  test('only provider-confirmed FAILED is a definite decline', () async {
    await expectLater(
      charge(
        gateway((r) async {
          final value = proof(status: 'FAILED');
          value.remove('method');
          return http.Response(jsonEncode(value), 200);
        }),
      ),
      throwsA(
        isA<SandboxPaymentException>().having(
          (e) => e.uncertain,
          'uncertain',
          false,
        ),
      ),
    );
  });
  for (final field in ['storeId', 'id', 'currency', 'billingKey']) {
    test('foreign $field cannot settle', () async {
      await expectLater(
        charge(
          gateway((r) async {
            final value = proof();
            value[field] = 'foreign';
            return http.Response(jsonEncode(value), 200);
          }),
        ),
        throwsA(isA<SandboxPaymentException>()),
      );
    });
  }
  test(
    'key is bound to checkout issue, account and configured channel',
    () async {
      final value = gateway(
        (r) async => http.Response(
          jsonEncode({
            'status': 'ISSUED',
            'billingKey': 'key',
            'storeId': 'store',
            'issueId': 'foreign',
            'customer': {'id': 'customer'},
            'channels': [
              {'key': 'channel'},
            ],
            'methods': [
              {'type': 'CARD'},
            ],
          }),
          200,
        ),
      );
      await expectLater(
        value.issueBillingKey(
          authKey: 'key',
          customerKey: 'customer',
          idempotencyKey: 'attempt',
          issueId: 'checkout',
        ),
        throwsA(isA<SandboxPaymentException>()),
      );
    },
  );
  test(
    'refund reads original amount and verifies transaction before cancel',
    () async {
      var canceled = false;
      final value = gateway((r) async {
        if (r.method == 'POST') {
          expect(jsonDecode(r.body)['currentCancellableAmount'], 2900);
          canceled = true;
        }
        return http.Response(
          jsonEncode(
            proof(status: canceled ? 'CANCELLED' : 'PAID', amount: 2900),
          ),
          200,
        );
      });
      final result = await value.refund(
        paymentKey: 'transaction',
        orderId: 'order',
        idempotencyKey: 'refund',
      );
      expect(result.amount, 2900);
      expect(result.balance, 0);
    },
  );
}
