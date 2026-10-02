import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_checkout_flow.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_renewal_service.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_key_vault.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/portone_gateway.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'PortOne card checkout',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, _) {
      test(
        'accepted quote, bound issue identity, verified charge and replay',
        () async {
          AuthServices.set(
            tokenManagerBuilders: [
              JwtConfig(
                algorithm: JwtAlgorithm.hmacSha512(
                  SecretKey('isolated-portone-test-secret'),
                ),
                refreshTokenHashPepper: 'isolated-portone-test-pepper',
              ),
            ],
            identityProviderBuilders: [],
          );
          final user = await const AuthUsers().create(builder.build());
          final owner = builder
              .copyWith(
                authentication: AuthenticationOverride.authenticationInfo(
                  user.id.toString(),
                  {},
                ),
              )
              .build();
          late BillingCheckoutView quote;
          final calls = <http.Request>[];
          final gateway = PortOneGateway(
            secret: 'isolated-secret',
            storeId: 'store',
            channelKey: 'channel',
            isTest: true,
            client: MockClient((r) async {
              calls.add(r);
              if (r.url.pathSegments.first == 'billing-keys') {
                return http.Response(
                  jsonEncode({
                    'status': 'ISSUED',
                    'billingKey': 'key',
                    'storeId': 'store',
                    'issueId': quote.issueId,
                    'customer': {'id': quote.customerKey},
                    'channels': [
                      {'key': 'channel'},
                    ],
                    'methods': [
                      {'type': 'CARD'},
                    ],
                  }),
                  200,
                );
              }
              if (r.method == 'POST') {
                expect(jsonDecode(r.body)['amount'], {'total': 4900});
                return http.Response('{}', 200);
              }
              return http.Response(
                jsonEncode({
                  'id': r.url.pathSegments[1],
                  'storeId': 'store',
                  'version': 'V2',
                  'currency': 'KRW',
                  'channel': {'key': 'channel'},
                  'billingKey': 'key',
                  'customer': {'id': quote.customerKey},
                  'method': {'type': 'CARD'},
                  'transactionId': 'transaction',
                  'status': 'PAID',
                  'amount': {
                    'total': 4900,
                    'paid': 4900,
                    'cancelled': 0,
                    'discount': 0,
                  },
                }),
                200,
              );
            }),
          );
          final service = BillingCheckoutService(
            worker: BillingRenewalService(
              gateway: gateway,
              vault: BillingKeyVault(List.generate(32, (i) => i)),
            ),
            clientKey: 'portone',
            storeId: 'store',
            channelKey: 'channel',
            amountKrw: 4900,
            priceVersion: 'launch',
          );
          await expectLater(
            service.begin(owner, acceptedTestTerms: 'sandbox-v1'),
            throwsStateError,
          );
          await expectLater(
            service.begin(
              owner,
              acceptedTestTerms: 'sandbox-v1',
              expectedAmountKrw: 19900,
            ),
            throwsStateError,
          );
          expect(calls, isEmpty);
          quote = await service.begin(
            owner,
            acceptedTestTerms: 'sandbox-v1',
            expectedAmountKrw: 4900,
          );
          expect(quote.issueId!.length, lessThanOrEqualTo(40));
          expect(quote.issueId, matches(RegExp(r'^[a-zA-Z0-9]+$')));
          final result = await service.complete(
            owner,
            state: quote.state,
            authKey: 'key',
          );
          expect(result.adFree, true);
          expect(result.appliedPriceKrw, 4900);
          expect(result.priceProtected, true);
          expect(calls.map((r) => r.method), ['GET', 'POST', 'GET']);
          await service.complete(owner, state: quote.state, authKey: 'key');
          expect(calls.length, 3);
        },
      );
    },
  );
}
