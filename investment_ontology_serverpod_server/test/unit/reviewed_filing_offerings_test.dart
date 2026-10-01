import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/reviewed_filing_offerings.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_taxonomy.dart';

void main() {
  test('every reviewed mapping is grounded in a dated identifiable filing', () {
    final keys = <String>{};
    for (final r in ReviewedFilingOfferings.rows) {
      expect(DiscoveryTaxonomy.categories, contains(r['industry']));
      expect(RegExp(r'^\d{14}$').hasMatch(r['rceptNo']), isTrue);
      expect(r['evidence'], isNotEmpty);
      expect(
        keys.add('${r['corpCode']}:${r['industry']}:${r['group']}'),
        isTrue,
      );
      expect(r['method'], 'current_filing_span_review');
    }
  });
  test(
    'correction, year change and missing quote invalidate reviewed records',
    () {
      final r = ReviewedFilingOfferings.rows.first;
      List matches(String receipt, int year, String text) =>
          ReviewedFilingOfferings.match(
            corpCode: r['corpCode'],
            receipt: receipt,
            year: year,
            text: text,
          );
      expect(matches(r['rceptNo'], r['year'], r['evidence']), isNotEmpty);
      expect(matches('20990101000000', r['year'], r['evidence']), isEmpty);
      expect(matches(r['rceptNo'], r['year'] + 1, r['evidence']), isEmpty);
      expect(matches(r['rceptNo'], r['year'], '다른 회사의 내용'), isEmpty);
    },
  );
}
