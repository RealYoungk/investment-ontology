import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart' as app;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_report_page.dart';

import '../support/shad_test_host.dart';

FinancialReport makeReport(int id) => FinancialReport(
  id: id,
  companyId: 1,
  rceptNo: '2026031000000$id',
  fsDiv: FsDiv.consolidated,
  bsnsYear: 2025,
  reportCode: FinancialReportCode.annual,
  reportName: id == 1 ? '최초 보고서' : '정정 보고서',
  factCount: 0,
  sourceId: id,
  supersededById: id == 1 ? 2 : null,
  fetchedAt: DateTime(2026, 3, 10),
);

class ReportsFixture implements EndpointFinancial {
  final calls = <int>[];
  @override
  Future<FinancialReportDetail?> report(int reportId) async {
    calls.add(reportId);
    return FinancialReportDetail(
      report: makeReport(reportId),
      facts: [],
      history: [makeReport(2), makeReport(1)],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReportClientFixture implements Client {
  @override
  final ReportsFixture financial = ReportsFixture();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('정정 이력 선택과 외부 주소 변경은 URL과 표시 보고서를 맞춘다', (tester) async {
    final fixture = ReportClientFixture();
    app.client = fixture;
    GoRouter.optionURLReflectsImperativeAPIs = true;
    final router = GoRouter(
      initialLocation: '/reports/2',
      routes: [
        GoRoute(
          path: '/reports/:id',
          builder: (_, state) => FinancialReportPage(
            reportId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp.router(
          theme: buildAppTheme(researchDeskBrand),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('최초 보고서 · 접수 20260310000001'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/reports/1');
    expect(find.text('최초 보고서'), findsOneWidget);
    expect(find.text('정정공시로 대체된 보고서입니다. 값은 지우지 않고 보존합니다.'), findsOneWidget);
    router.go('/reports/2');
    await tester.pumpAndSettle();
    expect(find.text('정정 보고서'), findsOneWidget);
    expect(fixture.financial.calls, [2, 1, 2]);
    expect(tester.takeException(), isNull);
  });
}
