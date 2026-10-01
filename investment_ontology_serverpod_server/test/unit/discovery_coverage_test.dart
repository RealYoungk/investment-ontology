import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_coverage.dart';

IndustryActivity row(String code, String basis) => IndustryActivity(
  corpCode: code,
  companyName: code,
  market: 'kosdaq',
  industryKey: 'electronics',
  role: 'ksic:262',
  productKey: 'ksic:26299',
  productName: '전자부품',
  classificationBasis: basis,
  process: '',
  evidence: '공식 등록 업종 근거',
  bsnsYear: 0,
  rceptNo: '',
);
void main() {
  test('explicit business does not regain obsolete registered sector', () {
    final result = DiscoveryCoverage.complete([
      row('1', 'ksic'),
      row('1', 'filing').copyWith(industryKey: 'semiconductor'),
    ]);
    expect(
      result.where((a) => a.classificationBasis == 'registered_activity'),
      isEmpty,
    );
    expect(DiscoveryCoverage.complete(result).length, result.length);
  });
  test('equivalent offerings share role but retain source', () {
    for (final sample in [
      ('semiconductor', '29271', 'equipment'),
      ('pharma', '21210', 'drug'),
      ('pharma', '21101', 'ingredient'),
      ('software', '58222', 'software_product'),
    ]) {
      final a = DiscoveryCoverage.complete([
        row(
          '1',
          'ksic',
        ).copyWith(industryKey: sample.$1, productKey: 'ksic:${sample.$2}'),
      ]).last;
      expect(a.role, sample.$3);
      expect(a.classificationBasis, 'registered_activity');
      expect(a.evidence, '공식 등록 업종 근거');
    }
  });

  test(
    'minimum coverage uses official evidence without upgrading its provenance',
    () {
      final official = row('1', 'ksic');
      final result = DiscoveryCoverage.complete([
        official,
        row('2', 'ksic'),
        row('2', 'filing'),
      ]);
      final added = result
          .where((a) => a.classificationBasis == 'registered_activity')
          .single;
      expect(added.corpCode, '1');
      expect(added.evidence, official.evidence);
      expect(added.rceptNo, isEmpty);
      expect(added.role, 'business:전자부품');
      expect(
        result
            .where((a) => a.classificationBasis != 'ksic')
            .map((a) => a.corpCode)
            .toSet(),
        {'1', '2'},
      );
      expect(DiscoveryCoverage.complete(result).length, result.length);
    },
  );
  test('missing official information is never invented', () {
    expect(
      DiscoveryCoverage.complete([row('3', 'unclassified')]),
      hasLength(1),
    );
  });
}
