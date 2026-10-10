import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart' as app;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_guide_panel.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/overview_catalog.dart';

class DisclosureFixture implements EndpointDisclosure {
  String status = 'ready';
  @override
  Future<BusinessUnderstanding> understanding(String corpCode) async =>
      BusinessUnderstanding(
        status: status,
        products: status == 'ready'
            ? [
                BusinessProduct(
                  key: 'product/current/조나단',
                  name: '조나단 · GPUBase',
                  role: 'GPU 자원 관리 솔루션',
                  process: '',
                  benefit: '',
                  evidence: '조나단 | GPUBase | GPU 자원 관리 솔루션',
                  explanationKind: 'source_only',
                ),
              ]
            : [],
        bsnsYear: 2026,
        rceptNo: '20260814003765',
        ruleVersion: 40007,
        reportCode: FinancialReportCode.halfYear,
        reportName: '반기보고서 (2026.06)',
      );
  bool hasBody = false;
  bool fallback = false;
  @override
  Future<BusinessContent?> businessContent(
    String corpCode, {
    int? bsnsYear,
  }) async => hasBody
      ? BusinessContent(
          bsnsYear: 2026,
          rceptNo: '20260814003765',
          title: fallback
              ? '이전 저장 보고서 · 최신 반기보고서 (2026.06) 본문 수집 대기'
              : '사업의 내용',
          sections: [
            BusinessSection(title: '1. 사업의 개요', text: '당사는 검사 장비를 생산하고 판매합니다.'),
            BusinessSection(title: '3. 원재료 및 생산설비', text: '생산설비 원문 근거'),
          ],
          charCount: 50,
          years: [2026],
        )
      : null;
  @override
  Future<List<DocumentFact>> factTrends(
    String corpCode, {
    DocumentFactKind? kind,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class BusinessClientFixture implements Client {
  @override
  final DisclosureFixture disclosure = DisclosureFixture();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fixture = BusinessClientFixture();
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    app.client = fixture;
    await OverviewCatalog.load();
  });
  setUp(() {
    fixture.disclosure.status = 'ready';
    fixture.disclosure.hasBody = false;
    fixture.disclosure.fallback = false;
  });
  for (final width in [390.0, 1045.0]) {
    testWidgets(
      'API products and reporting period win over bundled legacy facts at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(researchDeskBrand),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: BusinessGuidePanel(corpCode: '01829819'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('조나단 · GPUBase'), findsWidgets);
        expect(find.text('GPU 자원 관리 솔루션'), findsOneWidget);
        expect(find.text('반기보고서 (2026.06) · 규칙 추출'), findsOneWidget);
        expect(find.text('에스더인펙스'), findsNothing);
        expect(find.text('더마에이전트'), findsNothing);
        expect(find.textContaining('AX 인프라 전문 기업'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('newer body pending does not resurrect old asset products', (
    tester,
  ) async {
    fixture.disclosure.status = 'pending';
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: BusinessGuidePanel(corpCode: '01829819'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('최신 정기보고서 본문 수집·제품 정보 갱신 대기 중입니다.'), findsOneWidget);
    expect(find.text('에스더디프렉스'), findsNothing);
    expect(find.text('조나단 · GPUBase'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'stored source remains readable while product results are pending',
    (tester) async {
      fixture.disclosure.status = 'pending';
      fixture.disclosure.hasBody = true;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(researchDeskBrand),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: BusinessGuidePanel(corpCode: '01829819'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('당사는 검사 장비를 생산하고 판매합니다.'), findsNothing);
      expect(find.text('1. 사업의 개요'), findsNothing);
      expect(find.text('원문 펼치기'), findsNothing);
      expect(find.text('DART ↗'), findsOneWidget);
      expect(find.text('본문은 수집됐으며 제품 표 추출 결과는 갱신 대기 중입니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'older stored body has an explicit latest-pending notice at 320px',
    (tester) async {
      fixture.disclosure.hasBody = true;
      fixture.disclosure.fallback = true;
      fixture.disclosure.status = 'pending';
      await tester.binding.setSurfaceSize(const Size(320, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(researchDeskBrand),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: BusinessGuidePanel(corpCode: '01829819'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.textContaining('이전 저장 보고서 · 최신 반기보고서 (2026.06)'),
        findsOneWidget,
      );
      expect(find.textContaining('아래 표는'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
