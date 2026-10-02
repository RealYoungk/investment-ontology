import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/membership_plans_page.dart';

void main() {
  testWidgets('launch gate keeps public upgrade button disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: const Scaffold(body: MembershipPlansPage()),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, '멤버십 출시 준비 중');
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
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
            builder: (_, _) => const Scaffold(
              body: MembershipPlansPage(checkoutEnabled: true),
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
        MaterialApp.router(
          theme: buildAppTheme(ledgerBrand),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('멤버십으로 업그레이드'));
      await tester.tap(find.text('멤버십으로 업그레이드'));
      await tester.pumpAndSettle();
      expect(find.text('confirmation'), findsOneWidget);
    },
  );
}
