import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/industry_discovery_page.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('all industries use common business navigation at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = IndustryDiscovery(
        activities: [
          for (final c in [
            ('pharma', '제약·바이오 의약품', '00000001'),
            ('software', '소프트웨어·IT 서비스', '00000002'),
          ])
            IndustryActivity(
              corpCode: c.$3,
              companyName: '기업${c.$3}',
              market: 'kosdaq',
              industryKey: c.$1,
              industryName: c.$2,
              groupName: '사업군',
              role: 'ksic:group',
              productKey: 'ksic:product',
              productName: '세부 사업',
              process: '',
              evidence: '공식 업종 근거',
              classificationBasis: 'ksic',
              bsnsYear: 0,
              rceptNo: '',
            ),
        ],
        listedCompanyCount: 2,
        documentCompanyCount: 0,
        classifiedCompanyCount: 2,
        ruleVersion: 3,
        computedAt: DateTime(2026),
      );
      final router = GoRouter(
        initialLocation: '/industries',
        routes: [
          GoRoute(
            path: '/industries',
            builder: (_, state) => Scaffold(
              body: IndustryDiscoveryPage(
                query: state.uri.queryParameters,
                fetch: () async => data,
              ),
            ),
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
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('제약·바이오 의약품'));
      await tester.tap(find.text('제약·바이오 의약품'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/industries');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['industry'],
        'pharma',
      );
      expect(find.textContaining('등록 업종으로 보기'), findsNothing);
      expect(find.text('0개 기업'), findsOneWidget);
      expect(find.text('기업00000001'), findsNothing);
      // Existing registered links must not leave an invisible KSIC filter active.
      router.go('/industries?industry=pharma&basis=registered&role=ksic:group');
      await tester.pumpAndSettle();
      expect(find.text('전체 사업'), findsOneWidget);
      expect(find.text('사업군 · 1개사'), findsNothing);
      await tester.ensureVisible(find.text('전체 사업'));
      await tester.tap(find.text('전체 사업'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.queryParameters, {
        'industry': 'pharma',
      });
      await tester.ensureVisible(find.text('아직 사업 분류가 없는 기업 · 1곳'));
      await tester.tap(find.text('아직 사업 분류가 없는 기업 · 1곳'));
      await tester.pumpAndSettle();
      expect(find.text('기업00000001'), findsOneWidget);
      expect(find.text('기업00000002'), findsNothing);

      expect(tester.takeException(), isNull);
    });
  }
}
