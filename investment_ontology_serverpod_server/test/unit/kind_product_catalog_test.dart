import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/kind_product_catalog.dart';

void main() {
  Set<String> keys(String text) =>
      KindProductCatalog.classify(text).map((r) => r.$3).toSet();
  test(
    'source identifiers are unique and retain original product descriptions',
    () {
      expect(KindProductCatalog.rows.length, 2759);
      expect(
        KindProductCatalog.rows['190510']!['products'],
        '스마트폰 카메라모듈, 노트북 카메라모듈',
      );
      expect(KindProductCatalog.source['sourceSha256'], hasLength(64));
    },
  );
  test('components and manufacturing tools do not become finished goods', () {
    expect(keys('스마트폰 카메라모듈, 노트북 카메라모듈'), {'camera_module'});
    expect(keys('타이어 금형, 타이어 제조설비'), isNot(contains('tire')));
    expect(keys('의약품 원료, 원료의약품'), isNot(contains('drug_product')));
    expect(keys('의약품 원료, 원료의약품'), contains('api_drug'));
    expect(keys('윤활유제품, 석유제품'), isNot(contains('dairy')));
    expect(keys('해상용 위성통신안테나(VSAT, TVRO)'), isNot(contains('tv')));
    expect(keys('카메라모듈 제조검사용 장비'), isNot(contains('camera_module')));
    expect(keys('정수기 필터'), isNot(contains('appliance')));
    expect(keys('세탁기, 자동차, 에어컨 및 LCD 부품'), isNot(contains('appliance')));
    expect(keys('전해액 공급시스템'), isNot(contains('battery_material')));
    expect(keys('타이어코드지'), isNot(contains('tire')));
    expect(keys('신약개발지원'), isNot(contains('drug_product')));
    expect(
      keys('석유제품,가스,윤활기유,윤활유,그리스,석유화학제품 제조,도매'),
      containsAll(['refining', 'lubricants']),
    );
    expect(keys('단백질간 상호작용 바이오마커 개발 및 분석서비스'), contains('protein_analysis'));
  });
  test('stock code controls join and retail keeps distribution role', () {
    final a = KindProductCatalog.forCompany(
      Company(
        corpCode: 'test',
        name: 'Renamed issuer',
        stockCode: '190510',
        industryCode: '26299',
        market: Market.kosdaq,
      ),
    );
    expect(a.single.companyName, 'Renamed issuer');
    expect(a.single.groupName, '광학 부품');
    expect(a.single.classificationBasis, 'kind_product');
    expect(a.single.evidence, contains('나무가 (190510)'));
    final merged = KindProductCatalog.forCompany(
      Company(
        corpCode: 'merged',
        name: '주식회사 모비데이즈',
        stockCode: '363260',
        industryCode: '71310',
        market: Market.kosdaq,
      ),
    );
    expect(merged.where((a) => a.productKey == 'spac'), isEmpty);
    final b = KindProductCatalog.forCompany(
      Company(
        corpCode: 'test',
        name: 'Test',
        stockCode: '190510',
        industryCode: '46599',
        market: Market.kosdaq,
      ),
    );
    expect(b.single.classificationBasis, 'kind_product');
    expect(b.single.groupName, '전자부품·IT 유통');
    expect(b.single.industryKey, 'retail');
    expect(
      KindProductCatalog.forCompany(
        Company(
          corpCode: 'x',
          name: '나무가',
          stockCode: 'XXXXXX',
          market: Market.kosdaq,
        ),
      ),
      isEmpty,
    );
  });
}
