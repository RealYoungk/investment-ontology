import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/presentation/company_presentation.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/company_endpoint.dart';

void main() {
  test(
    'familiar issuer label preserves legal source and all search spellings',
    () {
      final company = Company(
        corpCode: '00164779',
        name: '에스케이하이닉스 주식회사',
        stockName: '에스케이하이닉스',
        stockCode: '000660',
      );
      expect(company.displayName, 'SK하이닉스');
      expect(company.name, '에스케이하이닉스 주식회사');
      for (final query in ['SK하이닉스', '에스케이하이닉스', '000660']) {
        expect(CompanySearch.rank(company, query), isNotNull, reason: query);
      }
    },
  );
  test('stock names are searchable even when unrelated to legal spelling', () {
    final company = Company(
      corpCode: 'test',
      name: '테스트주식회사',
      stockName: '브랜드',
      stockCode: '123456',
    );
    expect(company.displayName, '브랜드');
    expect(CompanySearch.rank(company, '브랜드'), 0);
    expect(CompanySearch.rank(company, '브랜'), 1);
    expect(CompanySearch.rank(company, '테스트'), isNotNull);
  });
  test('no arbitrary phonetic changes and empty stock names fall back', () {
    for (final stockName in [null, '', ' ', '-']) {
      final company = Company(
        corpCode: 'test',
        name: '(주) 에스케이테스트',
        stockName: stockName,
      );
      expect(company.displayName, '에스케이테스트');
      expect(company.name, '(주) 에스케이테스트');
    }
  });
}
