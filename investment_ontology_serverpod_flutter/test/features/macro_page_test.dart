import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/read_failure_notice.dart';
import 'package:investment_ontology_serverpod_flutter/features/macro/macro_page.dart';

final theme = buildAppTheme(
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
MacroSeriesView sample(
  String id,
  String name, {
  bool rate = false,
  String status = 'ready',
}) => MacroSeriesView(
  seriesId: id,
  name: name,
  group: rate ? '금리' : '원자재',
  unit: rate ? '%' : '달러/배럴',
  rate: rate,
  status: status,
  message: status == 'stale' ? '갱신에 실패해 이전 자료를 표시합니다.' : null,
  points: [
    IndexPoint(date: DateTime.utc(2026, 9, 1), value: 4),
    IndexPoint(date: DateTime.utc(2026, 10, 1), value: 5),
  ],
);
Future<GoRouter> pump(
  WidgetTester tester,
  Future<List<MacroSeriesView>> Function() load, {
  double width = 1200,
  String initial = '/market/indicators',
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/market/indicators',
        builder: (_, state) => Scaffold(
          body: MacroPage(query: state.uri.queryParameters, load: load),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: theme, routerConfig: router),
  );
  return router;
}

void main() {
  testWidgets(
    'Manual retry is disabled in flight and available after failure',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ReadFailureNotice(
              subject: '시장 정보',
              retry: () {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('다시 불러오기'));
      await tester.pump();
      expect(find.text('다시 불러오는 중…'), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      expect(calls, 1);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('다시 불러오기'), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Loading, retry and empty states are distinct', (tester) async {
    final pending = Completer<List<MacroSeriesView>>();
    var calls = 0;
    await pump(tester, () {
      calls++;
      return calls == 1 ? pending.future : Future.value([]);
    });
    expect(find.text('공식 지표 불러오는 중…'), findsOneWidget);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('시장 지표를 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('표시할 지표 자료가 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Desktop selection preserves company and period in URL', (
    tester,
  ) async {
    final router = await pump(
      tester,
      () async => [
        sample('DCOILBRENTEU', '브렌트 원유'),
        sample('DGS10', '미국 국채 10년', rate: true),
      ],
      initial: '/market/indicators?company=00126380',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('미국 국채 10년 금리').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['series'],
      'DGS10',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['company'],
      '00126380',
    );
    await tester.tap(find.text('1개월').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['days'],
      '30',
    );
    expect(find.text('선택 기간 +1.00%p'), findsOneWidget);
    expect(find.text('어떤 지표인가요?'), findsOneWidget);
    expect(find.text('금리와 채권 가격은 반대로 움직여요'), findsOneWidget);
    expect(find.textContaining('기준금리나 기존 채권의 약정 이자율과는 다릅니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('390px selector shows dated stale data without overflow', (
    tester,
  ) async {
    await pump(
      tester,
      () async => [sample('DCOILBRENTEU', '브렌트 원유', status: 'stale')],
      width: 390,
    );
    await tester.pumpAndSettle();
    expect(find.text('지표'), findsOneWidget);
    expect(find.textContaining('북해 원유에서 출발한'), findsOneWidget);
    expect(find.text('금리와 채권 가격은 반대로 움직여요'), findsNothing);
    expect(find.text('관측 기준 2026.10.01'), findsOneWidget);
    expect(find.text('갱신에 실패해 이전 자료를 표시합니다.'), findsOneWidget);
    expect(find.text('전체 지표 비교'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
