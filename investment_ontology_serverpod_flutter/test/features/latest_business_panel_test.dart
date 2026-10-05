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
  setUp(() => fixture.disclosure.status = 'ready');
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
}
