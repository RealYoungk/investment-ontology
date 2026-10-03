import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/membership_ledger.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_key_vault.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Grandfathered monthly subscription',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, _) {
      late Session owner;
      late DateTime now;
      late BillingSubscription sub;
      late BillingPaymentAttempt first;
      final vault = BillingKeyVault(List.generate(32, (i) => i));
      SandboxPayment paid(BillingPaymentAttempt row) => SandboxPayment(
        key: 'proof-${row.id}',
        orderId: row.orderId,
        status: 'DONE',
        amount: row.amountKrw,
        balance: row.amountKrw,
      );
      setUp(() async {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('isolated-price-test-secret'),
              ),
              refreshTokenHashPepper: 'isolated-price-test-pepper',
            ),
          ],
          identityProviderBuilders: [],
        );
        final user = await const AuthUsers().create(builder.build());
        owner = builder
            .copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                user.id.toString(),
                {},
              ),
            )
            .build();
        now = DateTime.now().toUtc();
        sub = await MembershipLedger.prepareCheckout(
          owner,
          priceKrw: 4900,
          priceVersion: 'launch',
          provider: 'portone',
          at: now,
        );
        first = (await MembershipLedger.claim(owner, period: 0, at: now))!;
        await MembershipLedger.storeBillingReference(
          owner,
          sub.customerKey!,
          'isolated-card',
          vault,
        );
        await MembershipLedger.settle(owner, first.id!, paid(first), at: now);
      });
      test('renewal and card change retain accepted price; wrong-price proof rejected', () async {
        final renewed = (await MembershipLedger.claimRenewal(
          owner,
          sub.id!,
          at: first.paidThroughUtc,
        ))!;
        expect(renewed.orderId.length, lessThanOrEqualTo(40));
        expect(renewed.orderId, matches(RegExp(r'^[a-zA-Z0-9]+$')));
        expect(renewed.amountKrw, 4900);
        expect(renewed.priceVersion, 'launch');
        final same = await MembershipLedger.prepareCheckout(
          owner,
          replaceCard: true,
          priceKrw: 19900,
          priceVersion: 'later',
          at: now,
        );
        expect(same.priceKrw, 4900);
        await expectLater(
          MembershipLedger.settle(
            owner,
            renewed.id!,
            SandboxPayment(
              key: 'wrong',
              orderId: renewed.orderId,
              status: 'DONE',
              amount: 19900,
              balance: 19900,
            ),
          ),
          throwsStateError,
        );
        expect(
          (await BillingPaymentAttempt.db.findById(
            owner,
            first.id!,
          ))!.amountKrw,
          4900,
        );
      });
      test('cancel then resume before expiry retains price; expired rejoin gets new price', () async {
        await MembershipLedger.cancel(owner);
        await MembershipLedger.resume(owner, at: now);
        expect(
          (await MembershipLedger.status(owner, at: now)).appliedPriceKrw,
          4900,
        );
        await MembershipLedger.cancel(owner);
        final rejoined = await MembershipLedger.prepareCheckout(
          owner,
          priceKrw: 9900,
          priceVersion: 'later',
          provider: 'portone',
          at: first.paidThroughUtc,
        );
        expect(rejoined.priceKrw, 9900);
        final next = (await MembershipLedger.claim(
          owner,
          period: rejoined.nextPeriod,
          at: first.paidThroughUtc,
        ))!;
        expect(next.amountKrw, 9900);
        expect(next.orderId, isNot(first.orderId));
        expect(
          (await BillingPaymentAttempt.db.findById(
            owner,
            first.id!,
          ))!.amountKrw,
          4900,
        );
      });
      test('declined renewal keeps grace for seven days and retries confirmed failures only', () async {
        final boundary = first.paidThroughUtc;
        final renewal = (await MembershipLedger.claimRenewal(
          owner,
          sub.id!,
          at: boundary,
        ))!;
        final sent = (await MembershipLedger.dispatch(
          owner,
          renewal.id!,
          boundary,
        ))!;
        expect(
          await MembershipLedger.dispatch(owner, renewal.id!, boundary),
          isNull,
        );
        await MembershipLedger.decline(owner, sent.id!, boundary);
        final grace = await MembershipLedger.status(owner, at: boundary);
        expect(grace.adFree, true);
        expect(grace.priceProtected, true);
        expect(grace.appliedPriceKrw, 4900);
        expect(
          await MembershipLedger.dispatch(owner, renewal.id!, boundary),
          isNull,
        );
        for (final day in [1, 3, 6]) {
          final retryAt = boundary.add(Duration(days: day));
          final retry = (await MembershipLedger.dispatch(
            owner,
            renewal.id!,
            retryAt,
          ))!;
          expect(retry.orderId, isNot(sent.orderId));
          await MembershipLedger.decline(owner, renewal.id!, retryAt);
        }
        expect(
          (await MembershipLedger.status(
            owner,
            at: boundary.add(const Duration(days: 6)),
          )).adFree,
          true,
        );
        await MembershipLedger.dispatch(
          owner,
          renewal.id!,
          boundary.add(const Duration(days: 7)),
        );
        final ended = await MembershipLedger.status(
          owner,
          at: boundary.add(const Duration(days: 7)),
        );
        expect(ended.adFree, false);
        expect(ended.priceProtected, false);
        expect(
          (await BillingPaymentAttempt.db.findById(
            owner,
            renewal.id!,
          ))!.failedOrderIds!.length,
          3,
        );
      });
      test('late unknown approval grants one recovered month at the original price', () async {
        final renewal = (await MembershipLedger.claimRenewal(
          owner,
          sub.id!,
          at: first.paidThroughUtc,
        ))!;
        await MembershipLedger.markUnknown(owner, renewal.id!);
        final delayed = renewal.paidThroughUtc.add(const Duration(days: 5));
        await MembershipLedger.settle(
          owner,
          renewal.id!,
          paid(renewal),
          at: delayed,
        );
        final result = await MembershipLedger.status(owner, at: delayed);
        expect(result.adFree, true);
        expect(result.appliedPriceKrw, 4900);
        expect(
          (await BillingPaymentAttempt.db.findById(
            owner,
            renewal.id!,
          ))!.paidFromUtc,
          delayed,
        );
      });
      test(
        'explicit server pause freezes grace without raising the locked price',
        () async {
          final boundary = first.paidThroughUtc;
          final renewal = (await MembershipLedger.claimRenewal(
            owner,
            sub.id!,
            at: boundary,
          ))!;
          await MembershipLedger.dispatch(owner, renewal.id!, boundary);
          await MembershipLedger.decline(owner, renewal.id!, boundary);
          await MembershipLedger.updatePause(
            owner,
            sub.id!,
            true,
            boundary.add(const Duration(days: 2)),
          );
          final pausedAt = boundary.add(const Duration(days: 12));
          final paused = await MembershipLedger.status(owner, at: pausedAt);
          expect(paused.adFree, true);
          expect(paused.appliedPriceKrw, 4900);
          await MembershipLedger.updatePause(owner, sub.id!, false, pausedAt);
          expect(
            (await MembershipLedger.status(owner, at: pausedAt)).priceProtected,
            true,
          );
          expect(
            (await BillingSubscription.db.findById(
              owner,
              sub.id!,
            ))!.graceThroughUtc,
            boundary.add(const Duration(days: 17)),
          );
        },
      );
      test('system delay preserves price and starts one fresh month without back-billing', () async {
        final delayed = first.paidThroughUtc.add(const Duration(days: 40));
        final view = await MembershipLedger.status(owner, at: delayed);
        expect(view.priceProtected, true);
        expect(view.adFree, false);
        await expectLater(
          MembershipLedger.prepareCheckout(owner, priceKrw: 19900, at: delayed),
          throwsStateError,
        );
        final renewal = (await MembershipLedger.claimRenewal(
          owner,
          sub.id!,
          at: delayed,
        ))!;
        expect(renewal.amountKrw, 4900);
        expect(renewal.paidFromUtc, delayed);
      });
    },
  );
}
