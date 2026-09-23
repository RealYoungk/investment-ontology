import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/app/router.dart';

void main() {
  test('기업 상세·보고서 주소', () {
    expect(AppRoutes.company('00126380'), '/company/00126380');
    expect(
      AppRoutes.company('00126380', tab: 'financials'),
      '/company/00126380?tab=financials',
    );
    expect(AppRoutes.report(42), '/financial-reports/42');
    expect(AppRoutes.person(7), '/person/7');
  });
}
