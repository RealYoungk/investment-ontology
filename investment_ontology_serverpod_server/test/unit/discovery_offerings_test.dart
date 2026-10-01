import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_offerings.dart';

IndustryActivity activity(String product, String industry) => IndustryActivity(
  corpCode: '00000001',
  companyName: '표본',
  market: 'kosdaq',
  productKey: product,
  productName: product,
  role: 'design',
  process: '설계',
  evidence: '원문 근거',
  bsnsYear: 2025,
  rceptNo: '20260319000931',
  industryKey: industry,
  classificationBasis: 'filing',
);
void main() {
  test('protein analysis belongs to research support', () {
    final source = activity('protein_analysis', 'pharma');
    final result = DiscoveryOfferings.normalize(source);
    expect(result.role, 'research_service');
    expect(result.evidence, source.evidence);
  });

  test('offerings separate IP, design, foundry and outsourced testing without changing evidence', () {
    for (final e in {
      'interface_ip': 'design_ip',
      'design_house': 'design_service',
      'foundry': 'foundry',
      'test_service': 'osat',
    }.entries) {
      final source = activity(e.key, 'semiconductor');
      final result = DiscoveryOfferings.normalize(source);
      expect(result.role, e.value);
      expect(result.evidence, source.evidence);
      expect(result.productKey, source.productKey);
      expect(result.rceptNo, source.rceptNo);
    }
  });
  test(
    'drug modality and business model do not become parallel offering groups',
    () {
      expect(
        DiscoveryOfferings.normalize(activity('biosimilar', 'pharma')).role,
        'drug',
      );
      expect(
        DiscoveryOfferings.normalize(activity('drug_license', 'pharma')).role,
        'drug_discovery',
      );
      expect(
        DiscoveryOfferings.normalize(activity('bio_cdmo', 'pharma')).role,
        'cdmo',
      );
      expect(
        DiscoveryOfferings.normalize(activity('security', 'software')).role,
        'business:보안 소프트웨어·서비스',
      );
    },
  );
}
