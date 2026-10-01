import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/filing_offering_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/product_offering_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_taxonomy.dart';

void main() {
  Set<String> groups(String products, String sector) =>
      ProductOfferingRules.match(products, sector).map((r) => r.$2).toSet();
  test(
    'every rule has a valid sector, stable unique id and nonempty regex',
    () {
      final ids = <String>{};
      for (final r in ProductOfferingRules.definitions) {
        expect(ids.add(r['id']), isTrue, reason: r['id']);
        expect(DiscoveryTaxonomy.categories, contains(r['industry']));
        expect(r['pattern'], isNotEmpty);
        expect(
          RegExp(r['pattern'], caseSensitive: false).hasMatch(''),
          isFalse,
        );
      }
    },
  );
  test('medical roles distinguish diagnosis, orthopedics and dentistry', () {
    expect(groups('면역진단 시약', 'pharma'), contains('체외진단'));
    expect(groups('척추 임플란트', 'medical'), contains('정형외과·재활'));
    expect(groups('척추 임플란트', 'medical'), isNot(contains('치과')));
    expect(groups('치과용 임플란트', 'medical'), contains('치과'));
  });
  test('components and equipment do not become finished products', () {
    expect(groups('카메라모듈 제조검사용 장비', 'instruments'), isNot(contains('광학 부품')));
    expect(groups('카메라 모듈 부품', 'electronics'), contains('광학 부품'));
    expect(groups('세탁기, 에어컨 및 LCD 부품', 'electronics'), isNot(contains('생활가전')));
    expect(groups('자동차 차체 부품', 'auto'), contains('차체·내외장 부품'));
    expect(groups('OLED 소재', 'chemicals'), contains('디스플레이 부품·소재'));
    expect(groups('OLED 소재', 'chemicals'), isNot(contains('디스플레이')));
    expect(groups('CHILLER', 'electronics'), isNot(contains('디스플레이 부품·소재')));
    expect(groups('의약품 유통', 'retail'), contains('의약품·의료기기 유통'));
    expect(
      ProductOfferingRules.match(
        '의약품 유통',
        'retail',
      ).every((r) => r.$1 == 'retail'),
      isTrue,
    );
  });
  test('future and closed businesses never become current offerings', () {
    expect(groups('체외진단사업 추진 예정', 'medical'), isEmpty);
    expect(groups('OLED 소재 사업 중단', 'chemicals'), isEmpty);
  });
  List<((String, String, String, String), String)> parse(
    String text, {
    String sector = 'electronics',
    String name = '본사',
  }) => FilingOfferingRules.parse(
    text,
    sector: sector,
    companyName: name,
    year: 2025,
  );
  test('only named product column and positive current year qualify', () {
    const text = '''## 2. 주요 제품 및 서비스
품목 | 용도 | 2025년 | 2024년
카메라 모듈 | 스마트폰 | 100 | 10
LCD 패널 | 모니터 | 0 | 900
''';
    final result = parse(text);
    expect(result.map((r) => r.$1.$2), contains('광학 부품'));
    for (final r in result) {
      expect(text, contains(r.$2));
    }
    expect(
      parse(text.replaceFirst('카메라 모듈 | 스마트폰', '스마트폰 | 카메라 모듈'))
          .map((r) => r.$1.$2),
      isNot(contains('광학 부품')),
    );
  });
  test('paired year headers and own legal entity remain aligned', () {
    const text = '''## 2. 주요 제품 및 서비스
지배회사 및 주요 종속회사 | 주요 제품, 서비스 | 2025년 | 2024년
매출액 | 비율 | 매출액 | 비율
(주)본사 | 카메라 모듈 | 100 | 100 | 50 | 100
(주)본사FNS | 광학필름 | 200 | 100 | 100 | 100
''';
    final result = parse(text);
    expect(result, isNotEmpty);
    expect(result.every((r) => r.$1.$2 == '광학 부품'), isTrue);
    for (final r in result) {
      expect(text, contains(r.$2));
    }
  });
  test('company headings, purchases and closed rows cannot leak', () {
    const text = '''## 2. 주요 제품 및 서비스
(1) (주)본사
구분 | 제품 | 2025년
계속사업 | 카메라 모듈 | 100
중단 영업 | 광학필름 | 200
(2) (주)본사FNS
제품 | 2025년
광학필름 | 300
## 3. 원재료 및 생산설비
제품 | 2025년
배터리 | 500
''';
    final result = parse(text);
    expect(result, isNotEmpty);
    expect(result.every((r) => r.$1.$2 == '광학 부품'), isTrue);
  });
  test(
    'English product names and numbered fiscal periods use current revenue',
    () {
      const text = """## 2. 주요 제품 및 서비스
사업부문 | 매출유형 | 품 목 | 제38기 매출액(비율) | 제37기 매출액(비율)
광학 | 제품 | Camera Module | 100(80.0) | 20(60.0)
패널 | 제품 | LCD 패널 | 0(0.0) | 30(40.0)
""";
      expect(parse(text).map((r) => r.$1.$2), contains('광학 부품'));
      expect(parse(text).map((r) => r.$1.$2), isNot(contains('디스플레이')));
    },
  );
  test('ascending years with paired columns still use the current year', () {
    const text = """## 2. 주요 제품 및 서비스
제품 | 2023년 | 2024년 | 2025년
매출액 | 비율 | 매출액 | 비율 | 매출액 | 비율
Camera Module | 0 | 0 | 0 | 0 | 100 | 100
LCD 패널 | 100 | 100 | 100 | 100 | 0 | 0
""";
    expect(parse(text).map((r) => r.$1.$2), contains('광학 부품'));
    expect(parse(text).map((r) => r.$1.$2), isNot(contains('디스플레이')));
  });
  test('shielding materials retain their actual component role', () {
    expect(groups('전자파 차폐소재', 'electronics'), contains('전자파 차폐·방열'));
  });
  test('a holding company cannot inherit subsidiary products', () {
    const text =
        '당사는 외국기업의 사업을 지배하는 지주회사로서, 주요 수익원은 자회사로부터의 배당금입니다.\n## 2. 주요 제품\n제품 | 2025년\n카메라 모듈 | 100';
    final result = parse(text, sector: 'holdings');
    expect(result.single.$1.$2, '지주회사');
  });
}
