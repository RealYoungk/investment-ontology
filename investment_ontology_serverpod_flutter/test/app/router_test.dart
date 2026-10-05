import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/app/router.dart';

void main() {
  testWidgets('detail push and tab replacement expose URL and retain list', (
    tester,
  ) async {
    // Initialize the real application's routing policy.
    AppRoutes.router;
    final listKey = GlobalKey();
    final router = GoRouter(
      initialLocation: '/companies?q=아크릴',
      routes: [
        GoRoute(
          path: '/companies',
          builder: (_, _) => SizedBox(key: listKey),
        ),
        GoRoute(
          path: '/company/:corpCode',
          builder: (_, state) => Text(
            state.uri.queryParameters['tab'] ?? 'overview',
          ),
        ),
        GoRoute(path: '/person/:id', builder: (_, _) => const Text('person')),
      ],
    );
    addTearDown(router.dispose);
    Uri visibleUri() => router.routeInformationParser
        .restoreRouteInformation(router.routerDelegate.currentConfiguration)!
        .uri;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final listState = listKey.currentContext;
    router.push('/company/01829819');
    await tester.pumpAndSettle();
    expect(visibleUri().path, '/company/01829819');
    expect(listKey.currentContext, same(listState));
    router.replace('/company/01829819?tab=financials');
    await tester.pumpAndSettle();
    expect(visibleUri().queryParameters['tab'], 'financials');
    expect(find.text('financials'), findsOneWidget);
    expect(listKey.currentContext, same(listState));
    router.push('/person/7');
    await tester.pumpAndSettle();
    expect(visibleUri().path, '/person/7');
    router.pop();
    await tester.pumpAndSettle();
    expect(visibleUri().queryParameters['tab'], 'financials');
    router.pop();
    await tester.pumpAndSettle();
    expect(visibleUri().path, '/companies');
    expect(visibleUri().queryParameters['q'], '아크릴');
    expect(listKey.currentContext, same(listState));
  });

  test('로그인 후 기업으로 복귀하고 외부 주소는 거부한다', () {
    const company = '/company/00317210';
    final login = Uri.parse(AppRoutes.login(next: company));
    expect(login.path, '/login');
    expect(AppRoutes.afterLogin(login.queryParameters['next']), company);
    expect(AppRoutes.afterLogin('/account'), '/account');
    for (final next in [
      null,
      '//evil.example/company/00317210',
      'https://evil.example/company/00317210',
      '/login',
      '/admin/accounts',
    ]) {
      expect(AppRoutes.afterLogin(next), '/home');
    }
  });
  test('PG callback survives login without allowing external or duplicate values', () {
    const callback =
        '/membership/checkout?state=nonce&billingKey=opaque%2Bkey&card=replace';
    final login = Uri.parse(AppRoutes.login(next: callback));
    final restored = Uri.parse(
      AppRoutes.afterLogin(login.queryParameters['next']),
    );
    expect(restored.path, '/membership/checkout');
    expect(restored.queryParameters, {
      'state': 'nonce',
      'billingKey': 'opaque+key',
      'card': 'replace',
    });
    expect(
      AppRoutes.afterLogin('//evil.example/membership/checkout?state=x'),
      '/home',
    );
    expect(
      AppRoutes.afterLogin('/membership/checkout?state=a&state=b'),
      '/membership/checkout',
    );
    expect(
      Uri.parse(
        AppRoutes.afterLogin(
          '/membership/checkout?state=x&redirect=https://evil.example',
        ),
      ).queryParameters,
      {'state': 'x'},
    );
  });
  test('기업 상세·보고서 주소', () {
    expect(AppRoutes.company('00126380'), '/company/00126380');
    expect(
      AppRoutes.company('00126380', tab: 'financials'),
      '/company/00126380?tab=financials',
    );
    expect(AppRoutes.report(42), '/reports/42');
    expect(AppRoutes.person(7), '/person/7');
  });
}
