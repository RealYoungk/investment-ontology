import '../support/shad_test_host.dart';

import 'package:shad/shad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';
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
  bool edit = true,
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
    shadTestHost(MaterialApp.router(theme: theme, routerConfig: router)),
  );
  await tester.pumpAndSettle();
  if (edit) await click(tester, find.text('조건 바꾸기'));
  return router;
}

Future<void> click(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is ShadInput && (w.top as Text?)?.data == label,
);
String value(WidgetTester tester, String label) =>
    tester.widget<ShadInput>(field(label)).controller!.text;
Future<void> preset(WidgetTester tester, String title) async {
  await click(tester, find.text(title).first);
}

void main() {
  testWidgets('10개씩 요청하고 다음 페이지와 조건 변경을 처리한다', (tester) async {
    final requests = <(int, int)>[];
    await pumpScreen(tester, (f, {offset = 0, limit = 100}) async {
      requests.add((offset, limit));
      final row = result(21).items.single;
      return result(21).copyWith(
        items: List.generate(
          offset == 20 ? 1 : 10,
          (i) => row.copyWith(
            company: row.company.copyWith(
              corpCode: '${offset + i}',
              name: '기업 ${offset + i + 1}',
            ),
          ),
        ),
      );
    }, edit: false);
    expect(requests.last, (0, 10));
    expect(find.byKey(const ValueKey('preset-volume-surge')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await click(tester, find.text('다음 10개'));
    expect(requests.last, (10, 10));
    await click(tester, find.text('다음 10개'));
    expect(requests.last, (20, 10));
    expect(
      tester
          .widget<ShadButton>(find.widgetWithText(ShadButton, '다음 10개'))
          .onPressed,
      isNull,
    );
    await click(tester, find.text('이전 10개'));
    expect(requests.last, (10, 10));
    await preset(tester, '돈 잘 버는 회사');
    expect(requests.last, (0, 10));
  });
  testWidgets('빠른 조건 선택 후 하나만 지워도 다른 조건은 남는다', (tester) async {
    final router = await pumpScreen(
      tester,
      (filter, {offset = 0, limit = 100}) async => result(1),
      edit: false,
    );
    await preset(tester, '돈 잘 버는 회사');
    expect(find.text('ROE 10% 이상'), findsOneWidget);
    expect(find.text('영업이익률 10% 이상'), findsOneWidget);
    final chip = find.widgetWithText(ShadBadge, 'ROE 10% 이상');
    await tester.ensureVisible(chip);
    await tester.tap(
      find.descendant(
        of: chip,
        matching: find.byWidgetPredicate(
          (w) => w is ShadIconButton && w.semanticLabel == 'ROE 조건 지우기',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['roe'],
      isNull,
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['margin'],
      '10',
    );
  });

  testWidgets('조건은 기본으로 접히고 펼쳐 수정한 뒤 접어도 유지된다', (tester) async {
    await pumpScreen(
      tester,
      (filter, {offset = 0, limit = 100}) async => result(1),
      edit: false,
    );
    expect(find.byType(ShadInput), findsNothing);
    await click(tester, find.text('조건 바꾸기'));
    expect(find.byType(ShadInput), findsNWidgets(18));
    await tester.enterText(field('PER 이하'), '12');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await click(tester, find.text('조건 접기'));
    expect(find.byType(ShadInput), findsNothing);
    await click(tester, find.text('조건 바꾸기'));
    expect(value(tester, 'PER 이하'), '12');
  });

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
      expect(find.byType(ShadInput), findsNWidgets(18));
      expect(requests, 1); // No extra preset-count queries.
      await preset(tester, '이익 대비 저렴한 주식');
      expect(value(tester, 'PER 이하'), '12');
      expect(value(tester, 'ROE % 이상'), '10');
      expect(find.byType(ShadInput), findsNWidgets(18));
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
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await preset(tester, '부채 부담 낮은 배당주');
      expect(value(tester, 'PER 이하'), '');
      expect(value(tester, 'ROE % 이상'), '');
      expect(value(tester, '배당수익률 % 이상'), '3');
      expect(value(tester, '부채비율 % 이하'), '100');
      await click(tester, find.text('조건 지우기'));
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
        .widget<ShadButton>(find.byKey(const ValueKey('preset-volume-surge')))
        .onPressed!();
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
        .widget<ShadButton>(
          find.byKey(const ValueKey('preset-dividend-history')),
        )
        .onPressed!();
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
    tester
        .widget<ShadButton>(find.byKey(const ValueKey('preset-dividend')))
        .onPressed!();
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
    tester
        .widget<ShadButton>(find.byKey(const ValueKey('preset-value')))
        .onPressed!();
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(value(tester, 'PER 이하'), '12');
  });
}
