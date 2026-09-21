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

  test('부채비율·배당·FCF 조건도 주소에 담긴다', () {
    const filter = ScreenFilter(debtMax: 100, dividendMin: 3, fcfMin: 5);
    expect(filter.location, '/screen?debt=100&div=3&fcf=5');
    expect(
      ScreenFilter.fromQuery({'debt': '100', 'div': '3', 'fcf': '5'}),
      filter,
    );
    expect(filter.hasCondition, isTrue);
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
