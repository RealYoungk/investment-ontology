import 'package:shad/shad.dart';

import 'support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/billing_checkout_page.dart';

void main() {
  Future<void> pump(WidgetTester tester, BillingCheckoutPage page) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unavailable checkout never shows payment action', (
    tester,
  ) async {
    await pump(
      tester,
      BillingCheckoutPage(
        checkoutEnabled: true,
        loadStatus: () async =>
            MembershipView(adFree: false, cancelAtPeriodEnd: false),
      ),
    );
    expect(find.text('이용권 출시를 준비하고 있습니다. 아직 결제할 수 없습니다.'), findsOneWidget);
    expect(find.widgetWithText(ShadButton, '카드 등록'), findsNothing);
    expect(find.widgetWithText(ShadButton, '테스트 카드 등록'), findsNothing);
  });
  testWidgets(
    'unaccepted terms cannot launch; SDK failure releases pending state',
    (tester) async {
      final accepted = <String>[];
      final canceled = <String>[];
      await pump(
        tester,
        BillingCheckoutPage(
          checkoutEnabled: true,
          loadStatus: () async => MembershipView(
            adFree: false,
            cancelAtPeriodEnd: false,
            paymentAvailable: true,
            termsVersion: 'sandbox-v1',
            isTest: true,
          ),
          beginCheckout: (v) async {
            accepted.add(v);
            return BillingCheckoutView(
              state: 'fixture-state',
              clientKey: 'test_ck_fixture',
              customerKey: 'fixture-customer',
            );
          },
          launch: (_) async => throw StateError('SDK unavailable'),
          abortCheckout: (v) async => canceled.add(v),
        ),
      );
      final button = find.widgetWithText(ShadButton, '테스트 카드 등록');
      expect(tester.widget<ShadButton>(button).onPressed, isNull);
      expect(accepted, isEmpty);
      await tester.ensureVisible(find.byType(ShadCheckbox));
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pump();
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(accepted, ['sandbox-v1']);
      expect(canceled, ['fixture-state']);
      expect(find.text('카드 등록창을 열지 못했습니다. 잠시 후 다시 확인해 주세요.'), findsOneWidget);
    },
  );
  testWidgets(
    'callback grants only returned server state and refreshes account',
    (tester) async {
      var refreshed = 0;
      var completed = 0;
      await pump(
        tester,
        BillingCheckoutPage(
          checkoutEnabled: true,
          state: 'fixture-state',
          authKey: 'fixture-auth',
          completeCheckout: (s, a) async {
            expect(s, 'fixture-state');
            expect(a, 'fixture-auth');
            completed++;
            return MembershipView(
              adFree: true,
              paidThroughUtc: DateTime.now().toUtc().add(
                const Duration(days: 1),
              ),
              cancelAtPeriodEnd: false,
            );
          },
          refresh: () async => refreshed++,
        ),
      );
      expect(completed, 1);
      expect(refreshed, 1);
      expect(
        find.text('멤버십이 적용되었습니다. 관심기업을 20개까지 등록할 수 있습니다.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ShadButton, '카드 등록'), findsNothing);
      expect(find.widgetWithText(ShadButton, '테스트 카드 등록'), findsNothing);
    },
  );
  testWidgets('320px checkout remains usable without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      BillingCheckoutPage(
        checkoutEnabled: true,
        loadStatus: () async => MembershipView(
          adFree: false,
          cancelAtPeriodEnd: false,
          paymentAvailable: true,
          termsVersion: 'sandbox-v1',
          isTest: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('테스트 카드 등록'), findsOneWidget);
  });
}
