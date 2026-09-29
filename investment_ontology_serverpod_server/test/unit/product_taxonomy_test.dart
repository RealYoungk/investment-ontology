import 'package:investment_ontology_serverpod_server/src/ontology/peers/peer_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/product_taxonomy.dart';
import 'package:test/test.dart';

void main() {
  String table(String product, {String use = '일반'}) =>
      '## 2. 주요 제품 및 서비스\n사업부문 | 주요 제품 | 구체적용도 | 매출액\n제품 | $product | $use | 100';
  for (final pair in const [
    ('DRAM', '디램'),
    ('라면', '유탕면'),
    ('타이어', 'Tire'),
    ('화장품', '스킨케어'),
    ('변압기', 'Transformer'),
    ('LNG 운반선', 'LNG선'),
  ]) {
    test('product aliases ${pair.$1}', () {
      final a = PeerRules.parse(table(pair.$1));
      final b = PeerRules.parse(table(pair.$2));
      expect(a, isNotEmpty);
      expect(
        PeerRules.match(a, b, anchorIndustry: '261', candidateIndustry: '262'),
        isNotNull,
      );
      expect(
        PeerRules.match(a, b, anchorIndustry: '261', candidateIndustry: '102'),
        isNull,
      );
    });
  }
  test('combined amount/share accepts composite cells without shifting merged rows', () {
    const header = '## 2. 주요 제품\n사업부문 | 매출유형 | 품목 | 구체적용도 | 상표 | 매출액(비율)\n';
    expect(
      PeerRules.parse(
        '$header반도체 | 제품 | DRAM, NAND Flash | 산업용 | 브랜드 | 100(100%)',
      ).map((s) => s.key),
      containsAll(['product/dram', 'product/nand']),
    );
    final parsed = PeerRules.parse(
      '$header타이어 | 제품 | 타이어 | 승용차 | 브랜드 | 100 | 90%\n상품 | 튜브 | 승용차 | 브랜드 | 10 | 10%',
    );
    expect(parsed.map((s) => s.label), ['타이어']);
    expect(ProductTaxonomy.match('NAND 프로브카드용 세라믹 STF'), isEmpty);
    expect(ProductTaxonomy.match('합 계'), isEmpty);
    expect(ProductTaxonomy.match('라 면').single.$1, 'product/ramen');
  });
  test('use columns and source materials do not become company products', () {
    final data = PeerRules.parse(table('카메라모듈', use: 'DRAM, 화장품, 타이어'));
    expect(data.map((s) => s.label), ['카메라 모듈']);
    expect(ProductTaxonomy.match('양극재 제조장비'), isEmpty);
    expect(ProductTaxonomy.match('화장품 원료'), isEmpty);
  });
  test('unknown concrete products match by normalized name, generic categories do not', () {
    final a = PeerRules.parse(table('냉장고'));
    final b = PeerRules.parse(table('냉장고 등'));
    expect(
      PeerRules.match(a, b, anchorIndustry: '28', candidateIndustry: '28'),
      isNotNull,
    );
    for (final s in ['기타제품', '소프트웨어', '제조 서비스', '장비', '합계']) {
      expect(ProductTaxonomy.match(s), isEmpty);
    }
  });
  test('ambiguous merged rows and price tables do not introduce products', () {
    expect(PeerRules.parse('## 2. 주요 제품\n구분 | 주요 제품 | 매출액\n라면 | 100'), isEmpty);
    expect(PeerRules.parse('## 2. 주요 제품\n나. 가격변동\n품목 | 가격\n라면 | 100'), isEmpty);
  });
}
