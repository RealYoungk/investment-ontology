import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/membership_ledger.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/subscription_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Durable membership ledger',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, endpoints) {
      late TestSessionBuilder signed;
      late UuidValue user;
      late DateTime now;
      setUp(() async {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('isolated-membership-test-signing-secret'),
              ),
              refreshTokenHashPepper: 'isolated-membership-pepper',
            ),
          ],
          identityProviderBuilders: [],
        );
        user = (await const AuthUsers().create(builder.build())).id;
        signed = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user.toString(),
            {},
          ),
        );
        now = DateTime.now().toUtc();
      });
      SandboxPayment approved(BillingPaymentAttempt row, {String? key}) =>
          SandboxPayment(
            key: key ?? 'payment-${row.id}',
            orderId: row.orderId,
            status: 'DONE',
            amount: 2900,
            balance: 2900,
          );
      SandboxPayment refunded(BillingPaymentAttempt row) => SandboxPayment(
        key: 'payment-${row.id}',
        orderId: row.orderId,
        status: 'CANCELED',
        amount: 2900,
        balance: 0,
      );

      test(
        'anonymous cannot read or cancel; authenticated account starts free',
        () async {
          final anon = builder.copyWith(
            authentication: AuthenticationOverride.unauthenticated(),
          );
          await expectLater(
            endpoints.membership.status(anon),
            throwsA(isA<ServerpodUnauthenticatedException>()),
          );
          await expectLater(
            endpoints.membership.cancelRenewal(anon),
            throwsA(isA<ServerpodUnauthenticatedException>()),
          );
          final view = await endpoints.membership.status(signed);
          expect(view.adFree, false);
          expect(view.paymentAvailable, false);
        },
      );

      test(
        'concurrent first claims persist one stable order and period',
        () async {
          final rows = await Future.wait(
            List.generate(
              6,
              (_) => MembershipLedger.claim(signed.build(), period: 0, at: now),
            ),
          );
          expect(rows.map((r) => r!.id).toSet().length, 1);
          expect(rows.map((r) => r!.orderId).toSet().length, 1);
          final sub = await BillingSubscription.db.findFirstRow(
            builder.build(),
            where: (t) => t.ownerId.equals(user),
          );
          expect(
            await BillingPaymentAttempt.db.count(
              builder.build(),
              where: (t) => t.subscriptionId.equals(sub!.id!),
            ),
            1,
          );
        },
      );

      test('duplicate concurrent settlement does not extend period; expiry is exact', () async {
        final row = (await MembershipLedger.claim(
          signed.build(),
          period: 0,
          at: now,
        ))!;
        await Future.wait(
          List.generate(
            4,
            (_) => MembershipLedger.settle(
              builder.build(),
              row.id!,
              approved(row),
            ),
          ),
        );
        expect((await endpoints.membership.status(signed)).adFree, true);
        final end = SubscriptionRules.boundary(now, 1);
        expect(
          (await MembershipLedger.status(signed.build(), at: end)).adFree,
          false,
        );
        final stored = await BillingPaymentAttempt.db.findById(
          builder.build(),
          row.id!,
        );
        expect(stored!.paidThroughUtc, end);
        await expectLater(
          MembershipLedger.settle(
            builder.build(),
            row.id!,
            approved(row, key: 'foreign-payment'),
          ),
          throwsStateError,
        );
      });

      test('cancel keeps paid access, blocks subsequent claim, and affects only owner', () async {
        final row = (await MembershipLedger.claim(
          signed.build(),
          period: 0,
          at: now,
        ))!;
        await MembershipLedger.settle(builder.build(), row.id!, approved(row));
        final other = (await const AuthUsers().create(builder.build())).id;
        final otherSession = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            other.toString(),
            {},
          ),
        );
        await MembershipLedger.claim(otherSession.build(), period: 0, at: now);
        await endpoints.membership.cancelRenewal(signed);
        expect((await endpoints.membership.status(signed)).adFree, true);
        expect(
          (await endpoints.membership.status(signed)).cancelAtPeriodEnd,
          true,
        );
        expect(
          (await endpoints.membership.status(otherSession)).cancelAtPeriodEnd,
          false,
        );
        expect(
          await MembershipLedger.claim(
            signed.build(),
            period: 1,
            at: SubscriptionRules.boundary(now, 1),
          ),
          isNull,
        );
      });

      test(
        'unknown charge reuses same identity and cannot grant access',
        () async {
          final row = (await MembershipLedger.claim(
            signed.build(),
            period: 0,
            at: now,
          ))!;
          await MembershipLedger.markUnknown(builder.build(), row.id!);
          final retry = await MembershipLedger.claim(
            signed.build(),
            period: 0,
            at: now,
          );
          expect(retry!.status, 'unknown');
          expect(retry.orderId, row.orderId);
          expect(retry.idempotencyKey, row.idempotencyKey);
          expect((await endpoints.membership.status(signed)).adFree, false);
        },
      );

      test(
        'refund validates identity and replay never restores access',
        () async {
          final row = (await MembershipLedger.claim(
            signed.build(),
            period: 0,
            at: now,
          ))!;
          await MembershipLedger.settle(
            builder.build(),
            row.id!,
            approved(row),
          );
          await expectLater(
            MembershipLedger.fullRefund(
              builder.build(),
              row.id!,
              approved(row),
            ),
            throwsStateError,
          );
          await MembershipLedger.fullRefund(
            builder.build(),
            row.id!,
            refunded(row),
          );
          await MembershipLedger.fullRefund(
            builder.build(),
            row.id!,
            refunded(row),
          );
          await MembershipLedger.settle(
            builder.build(),
            row.id!,
            approved(row),
          );
          expect((await endpoints.membership.status(signed)).adFree, false);
        },
      );

      test(
        'deletion with pending payment marks late approval for refund',
        () async {
          final row = (await MembershipLedger.claim(
            signed.build(),
            period: 0,
            at: now,
          ))!;
          final session = builder.build();
          await session.db.transaction(
            (tx) => MembershipLedger.beforeDelete(session, user, tx),
          );
          await MembershipLedger.settle(session, row.id!, approved(row));
          expect(
            (await BillingPaymentAttempt.db.findById(session, row.id!))!.status,
            'refundRequired',
          );
          expect((await endpoints.membership.status(signed)).adFree, false);
          expect(
            await MembershipLedger.claim(
              signed.build(),
              period: 1,
              at: SubscriptionRules.boundary(now, 1),
            ),
            isNull,
          );
        },
      );

      test('blocked account cannot claim or obtain paid status', () async {
        final session = builder.build();
        final account = (await AuthUser.db.findById(session, user))!;
        account.blocked = true;
        await AuthUser.db.updateRow(session, account);
        await expectLater(
          MembershipLedger.claim(signed.build(), period: 0, at: now),
          throwsA(isA<NotAuthorizedException>()),
        );
        await expectLater(
          MembershipLedger.status(signed.build()),
          throwsA(isA<NotAuthorizedException>()),
        );
      });
    },
  );
}
