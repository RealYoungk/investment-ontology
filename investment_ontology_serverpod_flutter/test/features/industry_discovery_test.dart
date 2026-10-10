import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/data_panel.dart';

import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/company_logo.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/industry_discovery_cache.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/features/screen/company_discovery_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/industry_discovery_page.dart';

IndustryActivity activity(String code, String product, String target) =>
    IndustryActivity(
      corpCode: code,
      companyName: '기업$code',
      market: 'kosdaq',
      industryCode: '29271',
      productKey: product,
      productName: product,
      role: 'equipment',
      process: '검사·계측',
      target: target,
      method: '광학',
      evidence: '$target $product | 100',
      bsnsYear: 2025,
      rceptNo: '20260301000001',
    );

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'company labels use one line without vertical clipping at 2x text size at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const name = '아주긴기업이름반도체설계테크놀로지';
        final data = IndustryDiscovery(
          activities: [
            activity('00000001', '검사', '웨이퍼').copyWith(companyName: name),
          ],
          listedCompanyCount: 1,
          documentCompanyCount: 1,
          classifiedCompanyCount: 1,
          ruleVersion: 1,
          computedAt: DateTime(2026),
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, state) => Scaffold(
                body: IndustryDiscoveryPage(
                  query: {
                    'industry': 'semiconductor',
                    ...state.uri.queryParameters,
                  },
                  fetch: () async => data,
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp.router(
              theme: buildAppTheme(ledgerBrand),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        void expectFullText(String label) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          expect(
            paragraph.size.height + 0.5,
            greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicHeight(paragraph.size.width),
            ),
            reason: label,
          );
        }

        final nameParagraph = tester.renderObject<RenderParagraph>(
          find.text(name),
        );
        expect(nameParagraph.maxLines, 1);
        expect(nameParagraph.overflow, TextOverflow.ellipsis);
        expect(
          nameParagraph.size.height + 0.5,
          greaterThanOrEqualTo(
            nameParagraph.getMaxIntrinsicHeight(nameParagraph.size.width),
          ),
        );
        if (width < 1000) {
          await tester.ensureVisible(find.text('사업 선택 · 전체 사업'));
          await tester.tap(find.text('사업 선택 · 전체 사업'));
          await tester.pumpAndSettle();
        }
        expectFullText('웨이퍼 제조 서비스');
        expectFullText('패키징·테스트 서비스');
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('sector reads share pending work, retain visits and invalidate on data change', () async {
    final cache = IndustryDiscoveryCache();
    final done = Completer<IndustryDiscovery>();
    var calls = 0;
    Future<IndustryDiscovery> fetch() {
      calls++;
      return done.future;
    }

    final first = cache.read('semiconductor', 0, fetch);
    expect(identical(first, cache.read('semiconductor', 0, fetch)), isTrue);
    done.complete(
      IndustryDiscovery(
        activities: [],
        listedCompanyCount: 0,
        documentCompanyCount: 0,
        classifiedCompanyCount: 0,
        ruleVersion: 1,
        computedAt: DateTime.now(),
      ),
    );
    await first;
    await cache.read('semiconductor', 0, fetch);
    expect(calls, 1);
    await cache.read('pharma', 0, fetch);
    await cache.read('semiconductor', 1, fetch);
    expect(calls, 3);
  });
  test('failed sector reads can retry', () async {
    final cache = IndustryDiscoveryCache();
    for (var i = 0; i < 2; i++) {
      await expectLater(
        cache.read('pharma', 0, () async => throw StateError('offline')),
        throwsStateError,
      );
    }
  });
  testWidgets('directory is immediately usable without any server request', (
    tester,
  ) async {
    var calls = 0;
    final router = GoRouter(
      initialLocation: '/industries',
      routes: [
        GoRoute(
          path: '/industries',
          builder: (_, state) => Scaffold(
            body: IndustryDiscoveryPage(
              query: state.uri.queryParameters,
              fetch: () {
                calls++;
                return Completer<IndustryDiscovery>().future;
              },
            ),
          ),
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
    expect(calls, 0);
    expect(find.text('반도체'), findsOneWidget);
    expect(find.byType(ShadProgress), findsNothing);
    await tester.tap(find.text('반도체'));
    await tester.pump();
    expect(calls, 1);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['industry'],
      'semiconductor',
    );
  });
  test('filters do not join different products of the same company', () {
    final items = [
      activity('00000001', '검사', '웨이퍼'),
      activity('00000001', '수리', '패키지기판'),
    ];
    expect(
      filterIndustryActivities(items, {'product': '검사', 'target': '패키지기판'}),
      isEmpty,
    );
  });
  test('legacy design links retain both IP and design service and ignore old search', () {
    final items = [
      activity('00000001', 'ip', '').copyWith(role: 'design_ip'),
      activity('00000002', 'service', '').copyWith(role: 'design_service'),
      activity('00000003', 'chip', '').copyWith(role: 'chip'),
    ];
    expect(
      filterIndustryActivities(items, {
        'role': 'design',
        'q': 'unmatched',
      }).map((a) => a.corpCode),
      ['00000001', '00000002'],
    );
  });
  test('legacy pharma links preserve their product scope', () {
    final items = [
      activity('00000001', 'drug_license', '').copyWith(role: 'drug'),
      activity('00000002', 'biosimilar', '').copyWith(role: 'drug'),
    ];
    expect(
      filterIndustryActivities(items, {
        'role': 'business:신약 개발·기술이전',
      }).map((a) => a.corpCode),
      ['00000001'],
    );
  });
  for (final width in [320.0, 640.0, 900.0, 1280.0, 1920.0]) {
    testWidgets('URL filters, deduplication, compare selection at $width', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final data = IndustryDiscovery(
          activities: [
            activity('00000001', '검사', '웨이퍼'),
            activity('00000001', '수리', '기판'),
            activity('00000002', '검사', '웨이퍼'),
            activity('00000003', '등록 업종', '').copyWith(
              classificationBasis: 'ksic',
              role: 'ksic:261',
              productKey: 'ksic:261',
              groupName: '반도체 소자',
              rceptNo: '',
              bsnsYear: 0,
            ),
          ],
          listedCompanyCount: 20,
          documentCompanyCount: 18,
          classifiedCompanyCount: 2,
          ruleVersion: 1,
          computedAt: DateTime.utc(2026, 10),
        );
        final router = GoRouter(
          initialLocation: '/industries?industry=semiconductor&q=unmatched',
          routes: [
            GoRoute(
              path: '/screen',
              builder: (_, _) => const Scaffold(
                body: CompanyDiscoveryNavigation(discovery: false),
              ),
            ),
            GoRoute(
              path: '/industries',
              pageBuilder: (_, state) => NoTransitionPage(
                key: const ValueKey('industries'),
                child: Scaffold(
                  body: IndustryDiscoveryPage(
                    query: state.uri.queryParameters,
                    fetch: () async => data,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/compare',
              builder: (_, state) => Scaffold(
                body: Text('비교 ${state.uri.queryParameters['codes']}'),
              ),
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
        expect(find.text('업종으로 찾기'), findsOneWidget);
        expect(find.text('2개 기업'), findsOneWidget);
        expect(find.byType(ShadInput), findsNothing);
        expect(find.text('기업00000001'), findsOneWidget);
        expect(find.byType(CompanyLogo), findsNWidgets(2));
        expect(find.text('비교에 추가'), findsNothing);
        expect(find.text('근거 보기'), findsNothing);
        expect(find.bySemanticsLabel('근거 보기'), findsNWidgets(2));
        final firstCardBounds = tester.getRect(
          find.ancestor(
            of: find.text('기업00000001'),
            matching: find.byType(DataPanel),
          ),
        );
        final actionBounds = tester.getRect(
          find.bySemanticsLabel('근거 보기').first,
        );
        final logoBounds = tester.getRect(find.byType(CompanyLogo).first);
        expect(actionBounds.center.dy, closeTo(logoBounds.center.dy, 1));
        expect(actionBounds.right, lessThanOrEqualTo(firstCardBounds.right));
        final firstCompany = tester.getTopLeft(find.text('기업00000001'));
        final secondCompany = tester.getTopLeft(find.text('기업00000002'));
        final firstCard = find.ancestor(
          of: find.text('기업00000001'),
          matching: find.byType(DataPanel),
        );
        final secondCard = find.ancestor(
          of: find.text('기업00000002'),
          matching: find.byType(DataPanel),
        );
        expect(
          tester.widget(firstCard),
          isNot(same(tester.widget(secondCard))),
        );
        if (width >= 900) {
          expect(secondCompany.dy, closeTo(firstCompany.dy, 1));
          expect(secondCompany.dx, greaterThan(firstCompany.dx));
        } else {
          expect(secondCompany.dy, greaterThan(firstCompany.dy));
        }
        expect(find.text('기업00000003'), findsNothing);
        if (width >= 1000) {
          expect(
            tester.getTopLeft(find.text('2개 기업')).dx,
            greaterThan(tester.getTopLeft(find.text('전체 사업')).dx),
          );
          expect(
            (tester.getTopLeft(find.text('2개 기업')).dy -
                    tester.getTopLeft(find.text('사업 선택')).dy)
                .abs(),
            lessThan(2),
          );
        }
        await tester.ensureVisible(find.text('아직 사업 분류가 없는 기업 · 1곳'));
        await tester.tap(find.text('아직 사업 분류가 없는 기업 · 1곳'));
        await tester.pumpAndSettle();
        expect(find.text('기업00000003'), findsOneWidget);
        expect(find.textContaining('선택한 사업을 하지 않는다는 뜻은 아니에요.'), findsOneWidget);
        await tester.tap(find.text('아직 사업 분류가 없는 기업 · 1곳'));
        await tester.pumpAndSettle();
        expect(find.textContaining('등록 업종으로 보기'), findsNothing);
        if (width < 1000) {
          await tester.ensureVisible(find.text('사업 선택 · 전체 사업'));
          await tester.tap(find.text('사업 선택 · 전체 사업'));
          await tester.pumpAndSettle();
        }
        final equipment = find.byKey(const ValueKey('industry-role-equipment'));
        await tester.ensureVisible(equipment);
        await tester.tap(equipment);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.queryParameters['role'],
          'equipment',
        );
        expect(
          router.routeInformationProvider.value.uri.queryParameters['q'],
          isNull,
        );
        expect(find.text('세부 분야'), findsNothing);
        await tester.ensureVisible(find.bySemanticsLabel('비교에 추가').first);
        await tester.tap(find.bySemanticsLabel('비교에 추가').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.bySemanticsLabel('비교에 추가').first);
        await tester.tap(find.bySemanticsLabel('비교에 추가').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('2개 기업 비교 →'));
        await tester.tap(find.text('2개 기업 비교 →'));
        await tester.pumpAndSettle();
        expect(find.text('비교 00000001,00000002'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('2개 기업 비교 →'), findsOneWidget);
        await tester.ensureVisible(find.text('조건으로 찾기'));
        await tester.tap(find.text('조건으로 찾기'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/screen');
        await tester.tap(find.text('업종으로 찾기'));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.queryParameters['role'],
          'equipment',
        );
        expect(
          router.routeInformationProvider.value.uri.queryParameters['q'],
          isNull,
        );
        expect(find.text('2개 기업 비교 →'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
