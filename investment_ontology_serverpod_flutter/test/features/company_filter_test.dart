import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/companies/company_filter.dart';

void main() {
  test('주소 검색어와 필터가 서로 오간다', () {
    const f = CompanyFilter(
      market: Market.kospi,
      section: 'C',
      division: '26',
      query: '삼성',
      sort: CompanySort.stockCode,
      page: 3,
    );
    final uri = Uri.parse(f.location);
    expect(uri.path, '/companies');
    expect(CompanyFilter.fromQuery(uri.queryParameters), f);
  });

  test('기본값은 주소에 남기지 않는다', () {
    expect(const CompanyFilter().location, '/companies');
  });

  test('잘못된 값은 무시하고, 대분류 없는 중분류는 버린다', () {
    final f = CompanyFilter.fromQuery({
      'market': 'nasdaq',
      'division': '26',
      'sort': 'x',
      'page': '-2',
    });
    expect(f, const CompanyFilter());
  });

  test('필터를 바꾸면 첫 페이지로, 대분류가 바뀌면 중분류가 풀린다', () {
    const f = CompanyFilter(section: 'C', division: '26', page: 4);
    expect(f.copyWith(query: '전자').page, 1);
    expect(f.copyWith(query: '전자').division, '26');
    final g = f.copyWith(section: () => 'G');
    expect((g.section, g.division), ('G', null));
    expect(f.copyWith(section: () => null).division, isNull);
    expect(f.copyWith(page: 2).page, 2);
  });
}
