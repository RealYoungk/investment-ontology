import 'package:shad/shad.dart';

import 'support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/membership_plans_page.dart';

Future<MembershipView> offer() async => MembershipView(
  adFree: false,
  cancelAtPeriodEnd: false,
  paymentAvailable: true,
  currentPriceKrw: 4900,
);

void main() {
  testWidgets('launch gate keeps public upgrade button disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(body: MembershipPlansPage(loadOffer: offer)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(ShadButton, '멤버십 출시 준비 중');
    expect(button, findsOneWidget);
    expect(tester.widget<ShadButton>(button).onPressed, isNull);
  });

  testWidgets('prebuilt checkout remains disabled until server approval', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: MembershipPlansPage(
              checkoutEnabled: true,
              loadOffer: () async => MembershipView(
                adFree: false,
                cancelAtPeriodEnd: false,
                paymentAvailable: false,
                currentPriceKrw: 4900,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(ShadButton, '멤버십 출시 준비 중');
    expect(button, findsOneWidget);
    expect(tester.widget<ShadButton>(button).onPressed, isNull);
  });

  testWidgets(
    'mobile plan selection navigates to confirmation without starting payment',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/membership',
        routes: [
          GoRoute(
            path: '/membership',
            builder: (_, _) => Scaffold(
              body: MembershipPlansPage(
                checkoutEnabled: true,
                loadOffer: offer,
              ),
            ),
          ),
          GoRoute(
            path: '/membership/checkout',
            builder: (_, _) => const Scaffold(body: Text('confirmation')),
          ),
          GoRoute(
            path: '/watchlist',
            builder: (_, _) => const Scaffold(body: Text('watchlist')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp.router(
            theme: buildAppTheme(ledgerBrand),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('얼리버드 가격으로 시작하기'));
      await tester.tap(find.text('얼리버드 가격으로 시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('confirmation'), findsOneWidget);
    },
  );
}
