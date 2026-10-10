import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/app/route_not_found_page.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('잘못된 주소는 한국어 안내와 홈 복귀를 제공한다: $width', (tester) async {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/missing',
        errorBuilder: (_, _) => const RouteNotFoundPage(),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('홈 화면')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp.router(
            theme: buildAppTheme(researchDeskBrand),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('페이지를 찾을 수 없어요'), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('홈으로 돌아가기'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.text('홈 화면'), findsOneWidget);
    });
  }
}
