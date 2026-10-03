import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/search/search_catalog.dart';

void main() {
  test('financial intent links retain filter contracts', () {
    expect(searchDestinations('배당').first.location, '/screen?div=3');
    expect(searchDestinations('매출 성장').first.location, '/screen?rgrow=10');
  });
  test('indicator aliases link to specific series', () {
    expect(searchDestinations('wti').first.location, contains('DCOILWTICO'));
    expect(searchDestinations('원 달러').first.location, contains('EXIM_USDKRW'));
  });
  test('empty and unknown terms do not manufacture results', () {
    expect(searchDestinations('   '), isEmpty);
    expect(searchDestinations('없는검색어123'), isEmpty);
    expect(searchDestinations('테마'), isEmpty);
  });
}
