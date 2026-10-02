import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_checkout_flow.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_key_vault.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_renewal_service.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/membership_ledger.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Account-bound billing callback',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, endpoints) {
      late Session owned;
      late BillingCheckoutService checkout;
      late List<http.Request> requests;
      late DateTime now;
      setUp(() async {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('isolated-checkout-test-signing-secret'),
              ),
              refreshTokenHashPepper: 'isolated-checkout-pepper',
            ),
          ],
          identityProviderBuilders: [],
        );
        final user = await const AuthUsers().create(builder.build());
        owned = builder
            .copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                user.id.toString(),
                {},
              ),
            )
            .build();
        now = DateTime.now().toUtc();
        requests = [];
        checkout = BillingCheckoutService(
          clientKey: 'test_ck_fixture',
          worker: BillingRenewalService(
            vault: BillingKeyVault(List.generate(32, (i) => i)),
            gateway: TossSandboxGateway(
              secretKey: 'test_sk_fixture',
              client: MockClient((r) async {
                requests.add(r);
                if (r.method == 'DELETE') return http.Response('', 204);
                final body = jsonDecode(r.body) as Map<String, dynamic>;
                if (r.url.path.endsWith('/issue')) {
                  return http.Response(
                    jsonEncode({
                      'customerKey': body['customerKey'],
                      'billingKey': 'opaque+/key-${requests.length}==',
                    }),
                    200,
                  );
                }
                return http.Response(
                  jsonEncode({
                    'orderId': body['orderId'],
                    'paymentKey': 'payment-${body['orderId']}',
                    'type': 'BILLING',
                    'currency': 'KRW',
                    'status': 'DONE',
                    'totalAmount': 2900,
                    'balanceAmount': 2900,
                  }),
                  200,
                );
              }),
            ),
          ),
        );
      });
      test(
        'terms confirmation required; production checkout stays unavailable',
        () async {
          await expectLater(
            checkout.begin(owned, acceptedTestTerms: ''),
            throwsStateError,
          );
          final user = MembershipLedger.owner(owned);
          final signed = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              user.toString(),
              {},
            ),
          );
          await expectLater(
            endpoints.membership.beginCheckout(signed, 'sandbox-v1'),
            throwsStateError,
          );
          expect(requests, isEmpty);
        },
      );
      test(
        'foreign account or modified state cannot authenticate billing',
        () async {
          final view = await checkout.begin(
            owned,
            acceptedTestTerms: 'sandbox-v1',
            at: now,
          );
          final other = await const AuthUsers().create(builder.build());
          final otherSession = builder
              .copyWith(
                authentication: AuthenticationOverride.authenticationInfo(
                  other.id.toString(),
                  {},
                ),
              )
              .build();
          await expectLater(
            checkout.complete(
              otherSession,
              state: view.state,
              authKey: 'fixture-auth',
              at: now,
            ),
            throwsStateError,
          );
          await expectLater(
            checkout.complete(
              owned,
              state: 'modified',
              authKey: 'fixture-auth',
              at: now,
            ),
            throwsStateError,
          );
          expect(requests, isEmpty);
          expect((await MembershipLedger.status(owned)).adFree, false);
        },
      );
      test('expired callback rejected before external request', () async {
        final view = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          at: now,
        );
        await expectLater(
          checkout.complete(
            owned,
            state: view.state,
            authKey: 'fixture-auth',
            at: now.add(const Duration(minutes: 30)),
          ),
          throwsStateError,
        );
        expect(requests, isEmpty);
      });
      test('successful authorization is encrypted, granted once, replay does not bill again', () async {
        final view = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          at: now,
        );
        final result = await checkout.complete(
          owned,
          state: view.state,
          authKey: 'fixture-auth',
          at: now,
        );
        expect(result.adFree, true);
        expect(result.paymentAvailable, false);
        expect(requests.length, 2);
        final owner = MembershipLedger.owner(owned);
        final sub = (await BillingSubscription.db.findFirstRow(
          owned,
          where: (t) => t.ownerId.equals(owner),
        ))!;
        expect(sub.encryptedBillingKey!.contains('opaque'), false);
        await checkout.complete(
          owned,
          state: view.state,
          authKey: 'fixture-auth',
          at: now,
        );
        expect(requests.length, 2);
        await expectLater(
          checkout.begin(owned, acceptedTestTerms: 'sandbox-v1', at: now),
          throwsStateError,
        );
      });
      test(
        'expired membership starts a new cycle without reusing its old order',
        () async {
          final first = await checkout.begin(
            owned,
            acceptedTestTerms: 'sandbox-v1',
            at: now,
          );
          final paid = await checkout.complete(
            owned,
            state: first.state,
            authKey: 'fixture-first',
            at: now,
          );
          await MembershipLedger.cancel(owned);
          final restartAt = paid.paidThroughUtc!.add(const Duration(days: 3));
          final second = await checkout.begin(
            owned,
            acceptedTestTerms: 'sandbox-v1',
            at: restartAt,
          );
          final restarted = await checkout.complete(
            owned,
            state: second.state,
            authKey: 'fixture-second',
            at: restartAt,
          );
          expect(restarted.adFree, true);
          expect(restarted.cancelAtPeriodEnd, false);
          final charges = requests
              .where(
                (r) => r.method == 'POST' && !r.url.path.endsWith('/issue'),
              )
              .toList();
          expect(charges.length, 2);
          expect(
            jsonDecode(charges[0].body)['orderId'],
            isNot(jsonDecode(charges[1].body)['orderId']),
          );
          final subscription = (await BillingSubscription.db.findFirstRow(
            owned,
            where: (t) => t.ownerId.equals(MembershipLedger.owner(owned)),
          ))!;
          final attempts = await BillingPaymentAttempt.db.find(
            owned,
            where: (t) => t.subscriptionId.equals(subscription.id!),
            orderBy: (t) => t.period,
          );
          expect(attempts.last.paidFromUtc, restartAt);
          expect(attempts.map((r) => r.status), everyElement('paid'));
          // Refunding an older purchase must not cancel the new independent cycle.
          await MembershipLedger.fullRefund(
            owned,
            attempts.first.id!,
            SandboxPayment(
              key: attempts.first.paymentKey!,
              orderId: attempts.first.orderId,
              status: 'CANCELED',
              amount: 2900,
              balance: 0,
            ),
          );
          final afterHistoricalRefund = await MembershipLedger.status(
            owned,
            at: restartAt,
          );
          expect(afterHistoricalRefund.adFree, true);
          expect(afterHistoricalRefund.cancelAtPeriodEnd, false);
        },
      );
      test('card replacement retains expiry and canceled renewal without another charge', () async {
        final first = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          at: now,
        );
        final paid = await checkout.complete(
          owned,
          state: first.state,
          authKey: 'fixture-first',
          at: now,
        );
        await MembershipLedger.cancel(owned);
        final changed = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          replaceCard: true,
          at: now,
        );
        final status = await checkout.complete(
          owned,
          state: changed.state,
          authKey: 'fixture-changed',
          at: now,
        );
        expect(status.adFree, true);
        expect(status.paidThroughUtc, paid.paidThroughUtc);
        expect(status.cancelAtPeriodEnd, true);
        expect(
          requests
              .where(
                (r) => r.method == 'POST' && !r.url.path.endsWith('/issue'),
              )
              .length,
          1,
        );
        expect(requests.where((r) => r.method == 'DELETE').length, 1);
        await MembershipLedger.resume(owned, at: now);
        expect(
          (await MembershipLedger.status(owned, at: now)).cancelAtPeriodEnd,
          false,
        );
        await expectLater(
          MembershipLedger.resume(owned, at: paid.paidThroughUtc),
          throwsStateError,
        );
      });
      test('canceled card registration can retry without charging', () async {
        final first = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          at: now,
        );
        await checkout.abort(owned, first.state);
        final retry = await checkout.begin(
          owned,
          acceptedTestTerms: 'sandbox-v1',
          at: now,
        );
        expect(retry.state, isNot(first.state));
        await expectLater(
          checkout.complete(
            owned,
            state: first.state,
            authKey: 'fixture',
            at: now,
          ),
          throwsStateError,
        );
        expect(requests, isEmpty);
      });
      test(
        'concurrent duplicate callback has one authorization and one order',
        () async {
          final view = await checkout.begin(
            owned,
            acceptedTestTerms: 'sandbox-v1',
            at: now,
          );
          Future<bool> complete() async {
            try {
              await checkout.complete(
                owned,
                state: view.state,
                authKey: 'fixture-auth',
                at: now,
              );
              return true;
            } on StateError {
              return false;
            }
          }

          final results = await Future.wait([complete(), complete()]);
          expect(results, contains(true));
          expect(
            requests.where((r) => r.url.path.endsWith('/issue')).length,
            1,
          );
          expect(
            requests.where((r) => !r.url.path.endsWith('/issue')).length,
            1,
          );
        },
      );
    },
  );
}
