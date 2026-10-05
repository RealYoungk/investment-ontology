import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/watchlist/update_destination.dart';

void main() {
  test('only canonical authored posts open within the app', () {
    expect(
      investmentNotePath('https://alfinder.kr/insights/12'),
      '/insights/12',
    );
    for (final url in [
      'https://alfinder.kr.evil.test/insights/12',
      'http://alfinder.kr/insights/12',
      'https://alfinder.kr:8443/insights/12',
      'https://other@alfinder.kr/insights/12',
      'https://alfinder.kr/insights/0',
      'https://alfinder.kr/insights/12?preview=true',
      'https://alfinder.kr/insights/12#body',
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=123',
    ]) {
      expect(investmentNotePath(url), isNull, reason: url);
    }
    expect(updateSourceLabel('https://alfinder.kr/insights/12'), '투자 관점');
    expect(updateSourceLabel('https://dart.fss.or.kr/dsaf001/main.do'), 'DART');
  });
}
