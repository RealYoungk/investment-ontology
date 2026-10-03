import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/overview_metrics.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/overview_catalog.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_model_guide.dart';

void main() {
  test('financial header differs from a manufacturing or holding company', () {
    expect(usesFinancialOverviewMetrics('64992', '(주)KB금융지주'), isTrue);
    expect(usesFinancialOverviewMetrics('64992', '(주)농심홀딩스'), isFalse);
    expect(usesFinancialOverviewMetrics('65110', '삼성생명'), isTrue);
    expect(usesFinancialOverviewMetrics('64121', '기업은행'), isTrue);
    expect(usesFinancialOverviewMetrics('264', '삼성전자'), isFalse);
    expect(showOverviewMetric('fcfYield', financial: true), isFalse);
    expect(showOverviewMetric('roe', financial: true), isTrue);
    expect(isAssetInvestmentVehicle('신한알파위탁관리부동산투자회사'), isTrue);
    expect(
      showOverviewMetric('fcfYield', financial: false, assetVehicle: true),
      isFalse,
    );
    expect(
      showOverviewMetric('debtRatio', financial: false, assetVehicle: true),
      isTrue,
    );
  });
  final json = jsonDecode(
    File('assets/overview/companies.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final catalog = OverviewCatalog.fromJson(json);
  test('every exported issuer resolves to complete lessons', () {
    for (final code in (json['companies'] as Map).keys) {
      final lesson = catalog.forCompany(code as String)!;
      expect(lesson.models, isNotEmpty, reason: code);
      for (final model in lesson.models) {
        expect(model.flow.length, 3, reason: code);
        expect(model.driver, isNotEmpty, reason: code);
      }
    }
    expect(catalog.forCompany('not-an-issuer'), isNull);
  });
  test('different business models and conglomerates stay distinct', () {
    expect(catalog.forCompany('00989619')!.models.single.label, '신약·바이오 기술');
    expect(catalog.forCompany('00877059')!.models.single.label, '의약품 위탁개발·생산');
    expect(catalog.forCompany('00688996')!.models.single.label, '금융지주');
    expect(catalog.forCompany('00126256')!.models.single.label, '보험');
    expect(catalog.forCompany('00126380')!.models.length, 2);
    expect(catalog.forCompany('00435297')!.hasDocument, isFalse);
  });
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets('all model flows fit $width and text scaling', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final value in (json['models'] as Map).values) {
        final model = OverviewModel.fromJson(value as Map<String, dynamic>);
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1100),
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BusinessModelGuide(
                        key: ValueKey(model.label),
                        lesson: CompanyOverviewLesson(
                          summary: '',
                          products: const [],
                          models: [model],
                          hasDocument: true,
                          year: 2025,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '${model.label} at $width',
        );
      }
    });
  }
  testWidgets(
    'switching businesses changes flow and growth explanation together',
    (tester) async {
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessModelGuide(
                  lesson: catalog.forCompany('00126380')!,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(ShadToggle, '반도체'));
      await tester.pumpAndSettle();
      expect(find.text('반도체의 성장 동력'), findsOneWidget);
      expect(find.text('사업 구조 · 반도체'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
