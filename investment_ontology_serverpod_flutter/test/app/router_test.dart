import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/app/router.dart';

void main() {
  test('로그인 후 기업으로 복귀하고 외부 주소는 거부한다', () {
    const company = '/company/00317210';
    final login = Uri.parse(AppRoutes.login(next: company));
    expect(login.path, '/login');
    expect(AppRoutes.afterLogin(login.queryParameters['next']), company);
    expect(AppRoutes.afterLogin('/account'), '/account');
    for (final next in [
      null,
      '//evil.example/company/00317210',
      'https://evil.example/company/00317210',
      '/login',
      '/admin/accounts',
    ]) {
      expect(AppRoutes.afterLogin(next), '/home');
    }
  });
  test('기업 상세·보고서 주소', () {
    expect(AppRoutes.company('00126380'), '/company/00126380');
    expect(
      AppRoutes.company('00126380', tab: 'financials'),
      '/company/00126380?tab=financials',
    );
    expect(AppRoutes.report(42), '/reports/42');
    expect(AppRoutes.person(7), '/person/7');
  });
}
