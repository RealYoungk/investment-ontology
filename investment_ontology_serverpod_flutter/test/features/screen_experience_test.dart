import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_filter.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_page.dart';

ThemeData get theme => buildAppTheme(
  AppBrand(
    colors: ledgerBrand.colors,
    shape: ledgerBrand.shape,
    typography: const AppTypography(
      displayBase: TextStyle(),
      bodyBase: TextStyle(),
      numericBase: TextStyle(),
      labelBase: TextStyle(),
    ),
  ),
);

ScreenPage result(int total, {String name = '테스트기업'}) => ScreenPage(
  items: total == 0
      ? []
      : [
          ScreenRow(
            company: CompanyRef(
              id: 1,
              corpCode: '00000001',
              name: name,
              market: Market.kospi,
            ),
            bsnsYear: 2025,
            marketCap: BigInt.from(100000000000),
            per: 8,
            roe: 20,
            revenueGrowth: 25,
            operatingIncomeGrowth: 30,
          ),
        ],
  total: total,
  universe: 2000,
  baseDate: DateTime(2026, 9, 21),
);

Future<GoRouter> pumpScreen(
  WidgetTester tester,
  ScreenFetch fetch, {
  String location = '/screen',
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/screen',
        builder: (_, state) => Scaffold(
          body: ScreenerPage(
            filter: ScreenFilter.fromQuery(state.uri.queryParameters),
            fetch: fetch,
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: theme, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> click(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
String value(WidgetTester tester, String label) =>
    tester.widget<TextField>(field(label)).controller!.text;
Future<void> preset(WidgetTester tester, String title) async {
  await click(tester, find.byType(DropdownButtonFormField<String>));
  await tester.scrollUntilVisible(
    find.text(title),
    180,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 20,
  );
  await tester.scrollUntilVisible(
    find.text(title).last,
    160,
    scrollable: find.byType(Scrollable).last,
  );
  await click(tester, find.text(title).last);
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('입력칸을 유지하고 프리셋이 값을 채운다 ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requests = 0;
      final router = await pumpScreen(tester, (
        f, {
        offset = 0,
        limit = 100,
      }) async {
        requests++;
        return result(20);
      }, location: '/screen?market=kosdaq&sort=roe');
      expect(find.byType(TextField), findsNWidgets(18));
      expect(requests, 1); // No extra preset-count queries.
      await preset(tester, '이익 대비 저렴한 주식');
      expect(value(tester, 'PER 이하'), '12');
      expect(value(tester, 'ROE % 이상'), '10');
      expect(find.byType(TextField), findsNWidgets(18));
      expect(
        router.routeInformationProvider.value.uri.queryParameters['market'],
        'kosdaq',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['sort'],
        'roe',
      );
      await tester.ensureVisible(field('PER 이하'));
      await tester.enterText(field('PER 이하'), '15');
      await tester.pumpAndSettle(const Duration(milliseconds: 350));
      expect(
        router.routeInformationProvider.value.uri.queryParameters['per'],
        '15',
      );
      expect(value(tester, 'ROE % 이상'), '10');
      expect(find.text('프리셋 선택'), findsOneWidget);
      await preset(tester, '부채 부담 낮은 배당주');
      expect(value(tester, 'PER 이하'), '');
      expect(value(tester, 'ROE % 이상'), '');
      expect(value(tester, '배당수익률 % 이상'), '3');
      expect(value(tester, '부채비율 % 이하'), '100');
      await click(tester, find.text('조건 초기화'));
      expect(value(tester, '배당수익률 % 이상'), '');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('거래량 프리셋은 단위 그대로 채우고 유효 범위를 벗어난 입력은 적용하지 않는다', (tester) async {
    final router = await pumpScreen(
      tester,
      (f, {offset = 0, limit = 100}) async => result(2),
    );
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('volume-surge');
    await tester.pumpAndSettle();
    expect(value(tester, '기준일 거래량 만주 이상'), '10');
    expect(value(tester, '평소 대비 거래량 배 이상'), '2');
    expect(value(tester, '거래대금 억원 이상'), '10');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['volratio'],
      '2',
    );
    expect(find.text('거래량(배)'), findsOneWidget);
    await tester.ensureVisible(field('52주 가격 위치 % 이상'));
    await tester.enterText(field('52주 가격 위치 % 이상'), '101');
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(
      router.routeInformationProvider.value.uri.queryParameters['band'],
      isNull,
    );
    expect(find.text('입력 범위를 확인해 주세요'), findsOneWidget);
    await tester.enterText(field('52주 가격 위치 % 이상'), '90');
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(
      router.routeInformationProvider.value.uri.queryParameters['band'],
      '90',
    );
  });
  testWidgets('연속 배당 프리셋은 새 조건과 기준연도 열을 보여준다', (tester) async {
    await pumpScreen(tester, (f, {offset = 0, limit = 100}) async => result(2));
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('dividend-history');
    await tester.pumpAndSettle();
    expect(value(tester, '확인된 연속 배당 년 이상'), '3');
    expect(value(tester, '배당성향 % 이하'), '70');
    expect(find.text('배당 기준연도'), findsOneWidget);
    expect(find.text('연속 배당(년)'), findsOneWidget);
  });
  testWidgets('빠르게 여러 칸을 입력해도 앞의 값이 유실되지 않는다', (tester) async {
    final router = await pumpScreen(
      tester,
      (f, {offset = 0, limit = 100}) async => result(2),
    );
    await tester.enterText(field('PER 이하'), '9');
    await tester.enterText(field('ROE % 이상'), '13');
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(
      router.routeInformationProvider.value.uri.queryParameters['per'],
      '9',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['roe'],
      '13',
    );
  });
  testWidgets('입력 중 프리셋을 누르면 지연된 입력이 프리셋을 덮어쓰지 않는다', (tester) async {
    final router = await pumpScreen(
      tester,
      (f, {offset = 0, limit = 100}) async => result(2),
    );
    await tester.enterText(field('PER 이하'), '99');
    // Select directly without waiting for the debounce, as a quick user action.
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    dropdown.onChanged!('dividend');
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(
      router.routeInformationProvider.value.uri.queryParameters['per'],
      isNull,
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['div'],
      '3',
    );
    expect(value(tester, 'PER 이하'), '');
  });
  testWidgets('같은 프리셋을 다시 누르면 아직 적용 안 된 입력도 복원한다', (tester) async {
    await pumpScreen(
      tester,
      (f, {offset = 0, limit = 100}) async => result(2),
      location: '/screen?per=12&roe=10',
    );
    await tester.enterText(field('PER 이하'), '99');
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    dropdown.onChanged!('value');
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(value(tester, 'PER 이하'), '12');
  });
}
