import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_product_rules.dart';

void main() {
  const support = """## 2. 주요 제품 및 서비스
(4) FA 설비 (자동화 설비)
기판 오염을 줄이는 FA(In-Line, Loader/Unloader 등) 자동화 설비입니다.
(5) 소프트웨어
당사의 AOI, VRS, AOR의 운영을 돕는 소프트웨어 제품으로 GVIS CAM, DTS가 있습니다.
## 4. 매출 및 수주상황
가. 매출 실적
용역매출은 제품 판매 후 사후 서비스(AS) 성격의 매출입니다. 공장부지 중 일부에 대한 임대 건이 임대료 수익으로 인식됩니다.
""";
  test('supporting revenue descriptions retain exact filing evidence', () {
    final result = BusinessProductRules.parse(support);
    expect(
      result.map((p) => p.key),
      containsAll([
        'support/fa',
        'support/software',
        'support/after_sales',
        'support/rental',
      ]),
    );
    expect(result.every((p) => support.contains(p.evidence)), isTrue);
  });
  test(
    'generic labels and unrelated sections do not imply supporting revenue',
    () {
      expect(
        BusinessProductRules.parse('## 주요 제품\nFA | 100\nSOFTWARE | 20')
            .where((p) => p.key.startsWith('support/')),
        isEmpty,
      );
      expect(
        BusinessProductRules.parse(
          support
              .replaceAll('주요 제품 및 서비스', '시장 현황')
              .replaceAll('매출 및 수주상황', '시장 현황'),
        ).where((p) => p.key.startsWith('support/')),
        isEmpty,
      );
      expect(
        BusinessProductRules.parse(support.replaceAll('기판 오염', '자회사 기판 오염'))
            .where((p) => p.key == 'support/fa'),
        isEmpty,
      );
    },
  );
  const aoi = '''## 2. 주요 제품 및 서비스
(1) 자동광학검사기 (AOI)
반도체 기판 제조 공정에서 회로형성 후 패턴의 결함을 검사하는 설비입니다.
구분 | 내용
''';
  test(
    'product heading plus operating evidence links a reusable explanation',
    () {
      final products = BusinessProductRules.parse(aoi);
      expect(products.single.key, 'substrate_aoi');
      expect(aoi, contains(products.single.evidence));
      expect(products.single.referenceUrl, startsWith('https://'));
    },
  );
  for (final phrase in ['경쟁사', '개발 중', '개발 예정', '출시 예정', '자회사']) {
    test('$phrase does not become current own-product attribution', () {
      expect(
        BusinessProductRules.parse(aoi.replaceFirst('반도체', '$phrase 반도체')),
        isEmpty,
      );
    });
  }
  test('industry discussion and revenue row alone do not imply a process', () {
    expect(
      BusinessProductRules.parse(aoi.replaceFirst('주요 제품 및 서비스', '시장 현황')),
      isEmpty,
    );
    expect(BusinessProductRules.parse('## 주요 제품\nAOI | 100 | 30%'), isEmpty);
  });
  test('does not borrow another product paragraph or another target', () {
    expect(
      BusinessProductRules.parse(
        '## 주요 제품\n(1) AOI\n웨이퍼 검사 설비입니다.\n(2) 기타\n기판 회로형성 후 검사합니다.',
      ),
      isEmpty,
    );
  });
  test(
    'repair description requires concrete defects and own product section',
    () {
      final valid = BusinessProductRules.parse(
        '## 주요 제품 및 서비스\n(3) AOR\n기판 불량(쇼트, 돌기)을 수리하는 설비입니다.',
      );
      expect(valid.single.key, 'substrate_aor');
      expect(
        BusinessProductRules.parse('## 주요 제품\n(3) AOR\n기판과 관련된 설비입니다.'),
        isEmpty,
      );
    },
  );
  test(
    'generic catalog products remain source-only, not invented process claims',
    () {
      final products = BusinessProductRules.parse(
        '## 주요 제품\n품목 | 매출액\n맥주 | 123',
      );
      expect(products.single.name, '맥주');
      expect(products.single.explanationKind, 'source_only');
      expect(products.single.process, isEmpty);
    },
  );
  test('shared product principles apply without company identifiers', () {
    final products = BusinessProductRules.parse(
      '## 주요 제품\n품목 | 매출액\nMLCC | 123\nFC-BGA | 456',
    );
    expect(products.length, 2);
    expect(
      products.every((p) => p.explanationKind == 'reference_and_filing'),
      isTrue,
    );
    expect(products.every((p) => p.referenceUrl != null), isTrue);
  });
}
