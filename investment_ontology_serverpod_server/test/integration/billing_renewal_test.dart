import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_key_vault.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_renewal_service.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/membership_ledger.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/subscription_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Test-key renewal orchestration',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, _) {
      late Session owned;
      late BillingSubscription sub;
      late BillingPaymentAttempt attempt;
      late DateTime now;
      final vault = BillingKeyVault(List.generate(32, (i) => i));
      setUp(() async {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('isolated-renewal-test-signing-secret'),
              ),
              refreshTokenHashPepper: 'isolated-renewal-pepper',
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
        attempt = (await MembershipLedger.claim(owned, period: 0, at: now))!;
        sub = (await BillingSubscription.db.findById(
          owned,
          attempt.subscriptionId,
        ))!;
        await MembershipLedger.storeBillingReference(
          owned,
          sub.customerKey!,
          'opaque+/reference==',
          vault,
        );
      });
      http.Response response({bool refund = false}) => http.Response(
        jsonEncode({
          'orderId': attempt.orderId,
          'paymentKey': 'payment-${attempt.id}',
          'type': 'BILLING',
          'currency': 'KRW',
          'totalAmount': 2900,
          'balanceAmount': refund ? 0 : 2900,
          'status': refund ? 'CANCELED' : 'DONE',
        }),
        200,
      );
      BillingRenewalService service(
        Future<http.Response> Function(http.Request) handler,
      ) => BillingRenewalService(
        gateway: TossSandboxGateway(
          secretKey: 'test_sk_fixture',
          client: MockClient(handler),
        ),
        vault: vault,
      );

      test(
        'concurrent workers reuse provider order and advance period once',
        () async {
          final requests = <http.Request>[];
          final worker = service((r) async {
            requests.add(r);
            return response();
          });
          await Future.wait([
            worker.run(builder.build(), sub.id!, at: now),
            worker.run(builder.build(), sub.id!, at: now),
          ]);
          expect(requests.map((r) => r.headers['Idempotency-Key']).toSet(), {
            attempt.idempotencyKey,
          });
          expect(requests.map((r) => jsonDecode(r.body)['orderId']).toSet(), {
            attempt.orderId,
          });
          expect(
            (await BillingSubscription.db.findById(owned, sub.id!))!.nextPeriod,
            1,
          );
          expect((await MembershipLedger.status(owned)).adFree, true);
          requests.clear();
          await worker.run(builder.build(), sub.id!, at: now);
          expect(requests, isEmpty);
        },
      );
      test(
        'unknown approval reconciles by GET and never sends another charge',
        () async {
          var calls = 0;
          final methods = <String>[];
          final worker = service((r) async {
            methods.add(r.method);
            if (calls++ == 0) throw TimeoutException('fixture');
            return response();
          });
          await worker.run(builder.build(), sub.id!, at: now);
          expect((await MembershipLedger.status(owned)).adFree, false);
          await worker.run(builder.build(), sub.id!, at: now);
          expect(methods, ['POST', 'GET']);
          expect((await MembershipLedger.status(owned)).adFree, true);
        },
      );
      test(
        'lost cancel response keeps access until GET confirms the refund',
        () async {
          final methods = <String>[];
          var canceled = false;
          final worker = service((r) async {
            methods.add(r.method);
            if (r.method == 'DELETE') return http.Response('', 204);
            if (r.url.path.endsWith('/cancel')) {
              canceled = true;
              throw TimeoutException('cancel succeeded but response was lost');
            }
            return response(refund: canceled);
          });
          await MembershipLedger.settle(
            builder.build(),
            attempt.id!,
            SandboxPayment(
              key: 'payment-${attempt.id}',
              orderId: attempt.orderId,
              status: 'DONE',
              amount: 2900,
              balance: 2900,
            ),
          );
          await const AuthUsers().update(
            builder.build(),
            authUserId: sub.ownerId,
            scopes: {Scope.admin},
          );
          final admin = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              sub.ownerId.toString(),
              {Scope.admin},
            ),
          );
          await MembershipLedger.requestRefund(
            admin.build(),
            attempt.id!,
            attempt.orderId,
          );
          await worker.reconcileRefunds(builder.build(), sub.id!);
          expect((await MembershipLedger.status(owned)).adFree, true);
          expect(
            (await BillingPaymentAttempt.db.findById(
              owned,
              attempt.id!,
            ))!.status,
            'refundRequested',
          );
          await worker.reconcileRefunds(builder.build(), sub.id!);
          expect(methods, ['GET', 'POST', 'GET', 'DELETE']);
          expect((await MembershipLedger.status(owned)).adFree, false);
          expect(
            (await BillingPaymentAttempt.db.findById(
              owned,
              attempt.id!,
            ))!.status,
            'refunded',
          );
        },
      );

      test(
        'partial cancellation stays pending without another cancel POST',
        () async {
          final methods = <String>[];
          final worker = service((r) async {
            methods.add(r.method);
            final value = jsonDecode(response().body) as Map<String, dynamic>;
            value['status'] = 'PARTIAL_CANCELED';
            value['balanceAmount'] = 1450;
            return http.Response(jsonEncode(value), 200);
          });
          await MembershipLedger.settle(
            builder.build(),
            attempt.id!,
            SandboxPayment(
              key: 'payment-${attempt.id}',
              orderId: attempt.orderId,
              status: 'DONE',
              amount: 2900,
              balance: 2900,
            ),
          );
          await const AuthUsers().update(
            builder.build(),
            authUserId: sub.ownerId,
            scopes: {Scope.admin},
          );
          final admin = builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              sub.ownerId.toString(),
              {Scope.admin},
            ),
          );
          await MembershipLedger.requestRefund(
            admin.build(),
            attempt.id!,
            attempt.orderId,
          );
          await worker.reconcileRefunds(builder.build(), sub.id!);
          expect(methods, ['GET']);
          expect((await MembershipLedger.status(owned)).adFree, true);
          expect(
            (await BillingPaymentAttempt.db.findById(
              owned,
              attempt.id!,
            ))!.status,
            'refundRequested',
          );
        },
      );

      test('cancel blocks a new renewal request', () async {
        var calls = 0;
        final worker = service((_) async {
          calls++;
          return response();
        });
        await worker.run(builder.build(), sub.id!, at: now);
        await MembershipLedger.cancel(owned);
        await worker.run(
          builder.build(),
          sub.id!,
          at: SubscriptionRules.boundary(now, 1),
        );
        expect(calls, 1);
      });
      test(
        'deletion during in-flight approval refunds and never grants access',
        () async {
          final paths = <String>[];
          final worker = service((r) async {
            paths.add(r.url.path);
            if (r.method == 'DELETE') return http.Response('', 204);
            if (r.url.path.endsWith('/cancel')) return response(refund: true);
            final session = builder.build();
            await session.db.transaction(
              (tx) => MembershipLedger.beforeDelete(session, sub.ownerId, tx),
            );
            return response();
          });
          await worker.run(builder.build(), sub.id!, at: now);
          expect(paths.length, 4);
          expect(paths.any((path) => path.endsWith('/cancel')), true);
          expect(
            (await BillingPaymentAttempt.db.findById(
              owned,
              attempt.id!,
            ))!.status,
            'refunded',
          );
          expect((await MembershipLedger.status(owned)).adFree, false);
          expect(
            (await BillingSubscription.db.findById(
              owned,
              sub.id!,
            ))!.encryptedBillingKey,
            isNull,
          );
        },
      );
      test(
        'unknown approval reconciles after cancellation without recharging',
        () async {
          var first = true;
          final methods = <String>[];
          final worker = service((r) async {
            methods.add(r.method);
            if (first) {
              first = false;
              throw TimeoutException('fixture');
            }
            return response();
          });
          await worker.run(builder.build(), sub.id!, at: now);
          await MembershipLedger.cancel(owned);
          await worker.run(builder.build(), sub.id!, at: now);
          expect(methods, ['POST', 'GET']);
          final view = await MembershipLedger.status(owned);
          expect(view.adFree, true);
          expect(view.cancelAtPeriodEnd, true);
        },
      );
      test(
        'deletion retains encrypted cleanup until provider confirms deletion',
        () async {
          await owned.db.transaction(
            (tx) => MembershipLedger.beforeDelete(owned, sub.ownerId, tx),
          );
          var fail = true;
          final worker = service((r) async {
            expect(r.method, 'DELETE');
            if (fail) return http.Response('{}', 500);
            return http.Response('', 204);
          });
          await worker.reconcileKeyDeletion(builder.build(), sub.id!);
          expect(
            (await BillingSubscription.db.findById(
              owned,
              sub.id!,
            ))!.encryptedKeyPendingDeletion,
            isNotNull,
          );
          fail = false;
          await worker.reconcileKeyDeletion(builder.build(), sub.id!);
          expect(
            (await BillingSubscription.db.findById(
              owned,
              sub.id!,
            ))!.encryptedKeyPendingDeletion,
            isNull,
          );
        },
      );
      test(
        'account deletion keeps both an old failed-cleanup key and current key',
        () async {
          final current = (await BillingSubscription.db.findById(
            owned,
            sub.id!,
          ))!;
          current.encryptedKeyPendingDeletion = await vault.seal(
            sub.ownerId.toString(),
            'old+/card==',
          );
          await BillingSubscription.db.updateRow(owned, current);
          await owned.db.transaction(
            (tx) => MembershipLedger.beforeDelete(owned, sub.ownerId, tx),
          );
          final deleted = (await BillingSubscription.db.findById(
            owned,
            sub.id!,
          ))!;
          expect(
            MembershipLedger.pendingKeys(deleted.encryptedKeyPendingDeletion)
                .length,
            2,
          );
          final keys = <String>[];
          final worker = service((r) async {
            keys.add(r.url.pathSegments.last);
            return http.Response('', 204);
          });
          await worker.reconcileKeyDeletion(builder.build(), sub.id!);
          expect(keys.toSet(), {'old+/card==', 'opaque+/reference=='});
          expect(
            (await BillingSubscription.db.findById(
              owned,
              sub.id!,
            ))!.encryptedKeyPendingDeletion,
            isNull,
          );
        },
      );
      test('foreign customer reference cannot be stored', () async {
        await expectLater(
          MembershipLedger.storeBillingReference(
            owned,
            'foreign-customer',
            'key',
            vault,
          ),
          throwsStateError,
        );
      });
    },
  );
}
