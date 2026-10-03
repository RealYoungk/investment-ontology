import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/company_endpoint.dart';
import 'package:test/test.dart';

void main() {
  final oil = Company(corpCode: '001', name: 'S-Oil(주)', stockCode: '010950');
  test('Latin, Korean pronunciation, punctuation and code find S-OIL', () {
    for (final q in [
      's',
      'S-OIL',
      'soil',
      's oil',
      '에스',
      '에스오일',
      '에스-오일',
      '010950',
    ]) {
      expect(CompanySearch.rank(oil, q), isNotNull, reason: q);
    }
    expect(CompanySearch.rank(oil, '삼성'), isNull);
  });
  test('name prefix precedes substring and CEO matches', () {
    final other = Company(corpCode: '002', name: '가나', nameEng: 'Industries');
    final ceo = Company(corpCode: '003', name: '가나', ceoName: 'Steve');
    expect(
      CompanySearch.rank(oil, 's'),
      lessThan(CompanySearch.rank(other, 's')!),
    );
    expect(
      CompanySearch.rank(oil, 's'),
      lessThan(CompanySearch.rank(ceo, 's')!),
    );
    expect(CompanySearch.rank(oil, 'soil'), 0);
  });
  test('shared matching rules cover mixed names in both directions', () {
    for (final (name, queries) in [
      ('SK하이닉스(주)', ['sk하이닉스', '에스케이하이닉스', '에스 케이']),
      ('에스케이하이닉스 주식회사', ['SK하이닉스', 'sk']),
      ('LG화학', ['엘지화학', 'lg 화학']),
      ('HD현대', ['에이치디현대', 'hd 현대']),
      ('DB하이텍', ['디비하이텍', 'db']),
      ('KT&G', ['ktg', '케이티지', '케이티앤지', '케이티앤드지', 'KT & G']),
      ('ABC바이오', ['에이비씨바이오', 'abc bio']),
      ('XYZ-Oil', ['엑스와이제트오일', 'xyz oil']),
      ('케이티앤지', ['KT&G', 'ktg', '케이티지']),
      ('삼성전자(주)', ['ㅅㅅㅈㅈ', '삼성 전자']),
      ('( 주 ) S－Oil', ['Ｓ－ＯＩＬ', '에스오일']),
    ]) {
      final company = Company(corpCode: 'fixture', name: name);
      for (final query in queries) {
        expect(
          CompanySearch.rank(company, query),
          isNotNull,
          reason: '$name / $query',
        );
      }
    }
  });
  test('empty punctuation and unrelated names do not expand results', () {
    for (final query in ['', ' ', '-', '㈜', '%', '_', '삼성', '오일텍']) {
      expect(CompanySearch.rank(oil, query), isNull, reason: query);
    }
  });
  test('bounded spelling correction stays behind literal matches', () {
    expect(CompanySearch.rank(oil, '애스'), 11);
    expect(CompanySearch.rank(oil, '애스오일'), 10);
    final literal = Company(corpCode: 'literal', name: '애스오일');
    expect(CompanySearch.rank(literal, '애스오일'), 0);
    expect(CompanySearch.rank(oil, '애'), isNull);
    expect(CompanySearch.rank(oil, '010951'), isNull);
  });
  test('two-set keyboard mistakes cover names and shared spoken aliases', () {
    for (final (name, keys) in [
      ('S-Oil(주)', 'dptmdhdlf'),
      ('S-Oil(주)', 'dotmdhdlf'),
      ('S-Oil(주)', 'DPTMDHDLF'),
      ('S-Oil(주)', 'dptm dhdlf'),
      ('S-Oil(주)', 'ｄｐｔｍｄｈｄｌｆ'),
      ('값꿰', 'rkqtRnp'),
      ('쌍용', 'Tkddyd'),
      ('삼성전자(주)', 'tkatjdwjswk'),
      ('LG화학', 'dpfwlghkgkr'),
      ('SK하이닉스', 'dptmzpdlgkdlslrtm'),
      ('케이티앤지', 'zpdlxldoswl'),
      ('ABC바이오', 'dpdlqlTlqkdldh'),
    ]) {
      expect(
        CompanySearch.rank(Company(corpCode: 'fixture', name: name), keys),
        10,
        reason: '$name / $keys',
      );
    }
    expect(CompanySearch.rank(oil, 'dptm'), 11);
    final literal = Company(corpCode: 'literal', name: 'dptmdhdlf');
    expect(CompanySearch.rank(literal, 'dptmdhdlf'), 0);
    for (final key in [
      's',
      'sk',
      'lg',
      'dp',
      '010950x',
      '%dptm',
      'zzzz',
      'dptm오일',
    ]) {
      expect(
        CompanySearch.rank(Company(corpCode: 'fixture', name: '삼성전자'), key),
        isNull,
        reason: key,
      );
    }
  });
}
