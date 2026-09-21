import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_filter.dart';

void main() {
  test('조건이 주소와 오간다', () {
    const filter = ScreenFilter(
      market: Market.kospi,
      perMax: 10,
      roeMin: 15.5,
      sort: ScreenSort.per,
      ascending: true,
    );
    expect(
      filter.location,
      '/screen?market=kospi&per=10&roe=15.5&sort=per&asc=1',
    );
    expect(
      ScreenFilter.fromQuery({
        'market': 'kospi',
        'per': '10',
        'roe': '15.5',
        'sort': 'per',
        'asc': '1',
      }),
      filter,
    );
  });

  test('조건이 없으면 주소도 깨끗하다', () {
    expect(const ScreenFilter().location, '/screen');
    expect(ScreenFilter.fromQuery(const {}), const ScreenFilter());
    // 0이나 빈 값은 조건으로 치지 않는다.
    expect(
      ScreenFilter.fromQuery(const {'per': '0', 'pbr': ''}).hasCondition,
      isFalse,
    );
  });
}
