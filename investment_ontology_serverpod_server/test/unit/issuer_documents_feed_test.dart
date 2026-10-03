import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/research_feed.dart';

void main() {
  Map<String, dynamic> row() => {
    'corpCode': '00600013',
    'title': '제20기 결산 감사보고서',
    'documentType': 'auditReport',
    'provider': 'officialIR',
    'providerReceipt': null,
    'providerDocumentId': null,
    'periodStart': '2026-01-01',
    'periodEnd': '2026-06-30',
    'publishedAt': '2026-09-30',
    'officialUrl': 'https://re1.miraeasset.com/upload/1790753607631.pdf',
    'sha256':
        'd1eecb3ce270eba3051280df4c1fa831922b940712d40cd1ef5ac75c71f8da3c',
    'issuerQuote': '미래에셋맵스리얼티부동산공모투자회사',
    'periodQuote': '제 20 기 2026년 1월 1일부터 2026년 6월 30일까지',
    'numericState': 'notExtracted',
    'financialValues': null,
    'publicContent': 'linkOnly',
  };
  test(
    'actual six-month metadata remains raw, no annual or numeric promotion',
    () {
      final result = ResearchFeed.validate('issuerDocuments', [row()]).single;
      expect(result['periodStart'], '2026-01-01');
      expect(result['periodEnd'], '2026-06-30');
      expect(result['financialValues'], isNull);
      expect(result.containsKey('reportCode'), isFalse);
      expect(result['providerReceipt'], isNull);
      expect(result['sha256'], row()['sha256']);
    },
  );
  final mutations = <String, void Function(Map<String, dynamic>)>{
    'foreign company host': (r) => r['corpCode'] = '01880801',
    'credentials': (r) =>
        r['officialUrl'] = 'https://user@re1.miraeasset.com/upload/a.pdf',
    'port': (r) =>
        r['officialUrl'] = 'https://re1.miraeasset.com:443/upload/a.pdf',
    'query': (r) =>
        r['officialUrl'] = 'https://re1.miraeasset.com/upload/a.pdf?key=1',
    'unknown date': (r) => r['periodEnd'] = '2026-02-30',
    'reversed date': (r) => r['periodStart'] = '2026-07-01',
    'publication before period': (r) => r['publishedAt'] = '2025-01-01',
    'future publication': (r) => r['publishedAt'] = '2099-01-01',
    'fabricated amount': (r) => r['financialValues'] = {'revenue': '100'},
    'unknown sha': (r) => r['sha256'] = 'a',
    'fabricated annual': (r) => r['reportCode'] = 'annual',
    'full text redistribution': (r) => r['publicContent'] = 'rawPdf',
    'IR receipt guessed': (r) => r['providerReceipt'] = '20260930000001',
    'provider without receipt': (r) => r['provider'] = 'KIND',
    'monthly promoted': (r) => r['documentType'] = 'annual',
  };
  for (final m in mutations.entries) {
    test(m.key, () {
      final r = row();
      m.value(r);
      expect(
        () => ResearchFeed.validate('issuerDocuments', [r]),
        throwsFormatException,
      );
    });
  }
  test('duplicate bytes/url rejected', () {
    expect(
      () => ResearchFeed.validate('issuerDocuments', [row(), row()]),
      throwsFormatException,
    );
  });
}
