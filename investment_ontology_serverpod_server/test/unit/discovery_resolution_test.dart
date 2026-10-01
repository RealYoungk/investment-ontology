import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_resolution.dart';

IndustryActivity row(String basis, String sector, String product) =>
    IndustryActivity(
      corpCode: '1',
      companyName: '기업',
      market: 'kosdaq',
      industryKey: sector,
      role: 'business:광학 부품',
      productKey: product,
      productName: '광학 부품',
      classificationBasis: basis,
      process: '',
      evidence: '$basis 원문',
      bsnsYear: 2025,
      rceptNo: '',
    );
void main() {
  test(
    'current filing replaces undated products only in its covered sector',
    () {
      final result = DiscoveryResolution.resolve([
        row('kind_product', 'electronics', 'old'),
        row('filing', 'electronics', 'current'),
        row('kind_product', 'software', 'other'),
        row('registered_activity', 'chemicals', 'registration'),
        row('ksic', 'chemicals', 'ksic:20'),
      ]);
      expect(result.map((r) => r.productKey).toSet(), {
        'current',
        'other',
        'ksic:20',
      });
      expect(result.first.evidence, 'filing 원문');
    },
  );
  test(
    'unsubstantiated registration is retained only without explicit business',
    () {
      expect(
        DiscoveryResolution.resolve([
          row('kind_registered', 'electronics', 'r'),
        ]),
        hasLength(1),
      );
      expect(
        DiscoveryResolution.resolve([
          row('kind_registered', 'electronics', 'r'),
          row('issuer_source', 'finance', 'source'),
        ]).single.classificationBasis,
        'issuer_source',
      );
    },
  );
  test('duplicate source resolution is idempotent and filing wins', () {
    final input = [
      row('kind_product', 'electronics', 'p'),
      row('filing', 'electronics', 'p'),
    ];
    final result = DiscoveryResolution.resolve(input);
    expect(result.single.classificationBasis, 'filing');
    expect(
      DiscoveryResolution.resolve(result).single.toJson(),
      result.single.toJson(),
    );
  });
}
