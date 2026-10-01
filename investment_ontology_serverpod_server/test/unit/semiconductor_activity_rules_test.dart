import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/semiconductor_activity_rules.dart';

String filing(String rows) => '## 2. 주요 제품 및 서비스\n주요 제품 | 매출액\n$rows';

void main() {
  test('sales type product cell is not mistaken for a new table header', () {
    final items = SemiconductorActivityRules.parse(
      '## 2. 주요 제품 및 서비스\n사업부문 | 매출유형 | 품 목 | 매출액\n반도체장비 | 제품 | 반도체 제조용 장비 外 | 100',
    );
    expect(items.single.product.id, 'equipment_unspecified');
  });
  test('parts and maintenance are not equipment manufacturing', () {
    for (final product in ['반도체 장비 부품', '반도체 장비 유지관리', '반도체 제조장비 부속품']) {
      expect(
        SemiconductorActivityRules.parse(filing('$product | 100')),
        isEmpty,
      );
    }
  });
  test(
    'equipment families use only an explicit same-row semiconductor scope',
    () {
      final items = SemiconductorActivityRules.parse(
        '## 2. 주요 제품 및 서비스\n구분 | 비고\n반도체 제조용 장비 | PECVD, ALD 등\nDisplay 제조용 장비 | PECVD',
      );
      expect(items.map((a) => a.product.id).toSet(), {'deposition'});
      expect(items.every((a) => a.evidence.startsWith('반도체')), isTrue);
    },
  );
  test('role and process come from the same product cell', () {
    final items = SemiconductorActivityRules.parse(
      filing('반도체 식각 장비 | 100\n반도체 포토레지스트 | 200'),
    );
    expect(items.map((a) => a.product.role), ['equipment', 'material']);
    expect(items.map((a) => a.product.process), ['식각', '노광']);
    expect(items.first.evidence, '반도체 식각 장비 | 100');
  });
  test('inspection and repair attributes cannot cross product rows', () {
    final items = SemiconductorActivityRules.parse(
      filing('웨이퍼 광학 검사 장비 | 100\n패키지기판 광학 수리 장비 | 100'),
    );
    expect(items.map((a) => a.product.id), [
      'wafer_optical',
      'substrate_repair',
    ]);
    expect(items.any((a) => a.product.id == 'substrate_optical'), isFalse);
  });
  test(
    'buyer, future product, subsidiary and non-product columns excluded',
    () {
      for (final row in [
        '도입한 반도체 식각 장비 | 100',
        '반도체 식각 장비 개발 중 | 100',
        '자회사 반도체 식각 장비 | 100',
        '부품 | 반도체 식각 장비',
      ]) {
        expect(
          SemiconductorActivityRules.parse(filing(row)),
          isEmpty,
          reason: row,
        );
      }
    },
  );
  test('merged rows and stale table headers excluded', () {
    expect(
      SemiconductorActivityRules.parse(filing('반도체 식각 장비 | 100 | 200')),
      isEmpty,
    );
    expect(
      SemiconductorActivityRules.parse(filing('## 3. 원재료\n반도체 식각 장비 | 100')),
      isEmpty,
    );
  });
  test('no inferred semiconductor use or target from adjacent cells', () {
    expect(SemiconductorActivityRules.parse(filing('식각 장비 | 반도체')), isEmpty);
    expect(
      SemiconductorActivityRules.parse(filing('광학 검사 장비 | 패키지기판')),
      isEmpty,
    );
  });
  test('same cell multiple products produce separate activities', () {
    final items = SemiconductorActivityRules.parse(
      filing('반도체 식각 장비, 반도체 증착 장비 | 100'),
    );
    expect(items.map((a) => a.product.id), ['etch', 'deposition']);
  });
}
