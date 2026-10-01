import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/home_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/about_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/explore_intent.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/daily_brief.dart';

// Avoid runtime font downloading in widget tests, preserving production colors.
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
final field = find.byKey(const ValueKey('home-company-search'));

Future<void> pumpHome(
  WidgetTester tester,
  CompanySearch search, {
  ExploreIntent intent = ExploreIntent.overview,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: HomePage(search: search, intent: intent, filings: () async => []),
      ),
    ),
  );
}

void main() {
  testWidgets('정정 필터는 실제 보고서명으로 구분하며 수집 대기를 유지한다', (tester) async {
    final rows = [
      FilingFeedItem(
        company: CompanyRef(id: 1, corpCode: '1', name: '원보고기업'),
        rceptNo: '1',
        reportName: '반기보고서',
        financialStored: true,
      ),
      FilingFeedItem(
        company: CompanyRef(id: 2, corpCode: '2', name: '정정기업'),
        rceptNo: '2',
        reportName: '[기재정정]반기보고서',
        financialStored: false,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyBrief(load: () async => rows),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('원보고기업'), findsOneWidget);
    await tester.tap(find.text('정정 보고서'));
    await tester.pumpAndSettle();
    expect(find.text('원보고기업'), findsNothing);
    expect(find.text('정정기업'), findsOneWidget);
    expect(find.textContaining('수집 대기'), findsOneWidget);
    expect(find.text('정정 공시 / 원문 재확인'), findsOneWidget);
  });
  testWidgets('소개 조회 실패는 기업 수와 공시 예시 수치를 만들어내지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: AboutPage(
          loadScope: () async => throw Exception('offline'),
          previewLoad: () async => throw Exception('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2,759'), findsNothing);
    expect(find.text('국내 상장사'), findsOneWidget);
    expect(find.text('연결 구조를 표현한 연출 · 실제 기업 관계가 아닙니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('검색하지 않은 홈은 API 호출 없이 사용 목적을 보여 준다', (tester) async {
    var calls = 0;
    await pumpHome(tester, (_) async {
      calls++;
      return [];
    });
    expect(calls, 0);
    expect(find.text('오늘의 리서치'), findsOneWidget);
    expect(field, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    ('자동차', '/companies?section=C&division=30'),
    ('매출이 늘어난 기업', '/screen?rgrow=10'),
    ('이익을 남기는 기업', '/screen?margin=10'),
    ('배당을 주는 기업', '/screen?div=3'),
  ]) {
    testWidgets('기업 이름 없이 ${entry.$1} 탐색을 시작한다', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => Scaffold(
              body: HomePage(search: (_) async => [], filings: () async => []),
            ),
          ),
          GoRoute(
            path: '/companies',
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
          GoRoute(
            path: '/screen',
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: theme, routerConfig: router),
      );
      final target = find.text(entry.$1);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
    });
  }

  testWidgets('늦게 도착한 이전 검색 결과와 지운 검색 결과는 표시하지 않는다', (tester) async {
    final first = Completer<List<CompanyListItem>>();
    final second = Completer<List<CompanyListItem>>();
    await pumpHome(tester, (q) => q == '삼성' ? first.future : second.future);
    await tester.ensureVisible(field);
    await tester.enterText(field, '삼성');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(field);
    await tester.enterText(field, '현대');
    await tester.pump(const Duration(milliseconds: 300));
    second.complete([CompanyListItem(corpCode: '2', name: '현대자동차')]);
    await tester.pump();
    first.complete([CompanyListItem(corpCode: '1', name: '삼성전자')]);
    await tester.pump();
    expect(find.byKey(const ValueKey('home-result-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-result-1')), findsNothing);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();
    expect(find.byKey(const ValueKey('home-result-2')), findsNothing);
  });

  testWidgets('실패 후 재시도와 결과 없음은 구분한다', (tester) async {
    var calls = 0;
    await pumpHome(tester, (_) async {
      if (++calls == 1) throw Exception('offline');
      return [];
    });
    await tester.ensureVisible(field);
    await tester.enterText(field, '검색');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('일치하는 기업이 없어요'), findsOneWidget);
  });

  for (final intent in ExploreIntent.values) {
    testWidgets('${intent.label} 선택 기업은 맞는 화면으로 이동하고 뒤로 검색이 남는다', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => Scaffold(
              body: HomePage(
                intent: intent,
                filings: () async => [],
                market: () async => [],
                search: (_) async => [
                  CompanyListItem(corpCode: '00126380', name: '삼성전자'),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/company/:code',
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
          GoRoute(
            path: '/compare',
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: theme, routerConfig: router),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '삼성전자');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final result = find.byKey(const ValueKey('home-result-00126380'));
      await tester.ensureVisible(result);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(find.text(intent.destination('00126380')), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '삼성전자');
    });
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('홈·소개 ${width}px, 큰 글자에서도 레이아웃 오류 없음', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in [
        HomePage(search: (_) async => [], filings: () async => []),
        AboutPage(
          previewLoad: () async => [],
          loadScope: () async =>
              Overview(totalListed: 2759, byMarket: [], bySection: []),
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: page),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('소개에서 질문 선택 후 해당 의도를 가진 홈으로 이동한다', (tester) async {
    final router = GoRouter(
      initialLocation: '/about',
      routes: [
        GoRoute(
          path: '/about',
          builder: (_, _) => AboutPage(
            previewLoad: () async => [],
            loadScope: () async =>
                Overview(totalListed: 2759, byMarket: [], bySection: []),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: theme, routerConfig: router),
    );
    await tester.pumpAndSettle();
    final start = find.text('재무 추이에서 시작');
    await tester.scrollUntilVisible(start, 400);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('/home?intent=financials'), findsOneWidget);
  });
}
