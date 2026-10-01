import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/business_activity_rules.dart';

Set<String> keys(String text) => BusinessActivityRules.parse(
  '## 1. 사업의 개요\n$text',
  companyName: '테스트',
).map((a) => a.$1.key).toSet();

void main() {
  test(
    'SPAC sole merger purpose survives negation of unrelated operations',
    () {
      expect(
        keys(
          '당사는 코스닥시장에 상장한 후 다른 회사와 합병하는 것을 유일한 사업목적으로 하고 있으며, 그 외 별도의 사업을 영위하지 않습니다.',
        ),
        contains('spac'),
      );
      expect(
        keys('당사는 다른 회사와 합병하는 것이 아닌 의약품 제조를 유일한 사업목적으로 하고 있습니다.'),
        isNot(contains('spac')),
      );
    },
  );

  test('financial services distinguish payments and legal SPAC purpose', () {
    expect(
      keys('당사는 전자금융 및 결제 플랫폼을 제공하는 핀테크 기업입니다.'),
      contains('payment_service'),
    );
    expect(
      keys('당사는 기업인수목적회사로서 다른 법인과 합병하는 것을 유일한 사업목적으로 하는 회사입니다.'),
      contains('spac'),
    );
    expect(
      keys('당사는 전자결제 플랫폼을 도입하여 사용하고 있습니다.'),
      isNot(contains('payment_service')),
    );
  });

  test('explicit products exclude application markets and components', () {
    final a = keys('당사의 주요 생산 제품은 스마트폰 및 태블릿에 적용되는 카메라 모듈과 3D 깊이 인식 센싱 모듈입니다.');
    expect(a, contains('camera_module'));
    expect(a, isNot(contains('smartphone')));
    expect(
      keys('당사는 스마트폰, 전장용, PC, 디스플레이, TV 부품 등을 생산, 판매하고 있습니다.'),
      isNot(contains('smartphone')),
    );
    expect(
      keys('당사의 주요 제품은 스마트폰, 스마트워치 및 자동차 전장, BMS용 FPCA 모듈입니다.'),
      isNot(contains('smartphone')),
    );
    expect(keys('당사의 주요 제품은 정수기 필터입니다.'), isNot(contains('appliance')));
    expect(keys('당사의 주요 제품은 스마트폰 케이스입니다.'), isNot(contains('smartphone')));
  });
  test('new main product section resumes own statement', () {
    final result = BusinessActivityRules.parse(
      '## 1. 사업의 개요\n주요종속회사\n당사는 카메라 모듈을 생산하고 있습니다.\n'
      '## 2. 주요 제품 및 서비스\n당사는 TV, 냉장고, 세탁기, 에어컨, 스마트폰 등 완제품과 DRAM, NAND Flash, 모바일AP 등 반도체 부품 및 스마트폰용 OLED 패널 등을 생산ㆍ판매하고 있습니다.',
      companyName: '테스트',
    ).map((a) => a.$1.key).toSet();
    expect(result, containsAll(['tv', 'appliance', 'smartphone']));
    expect(result, isNot(contains('camera_module')));
  });

  test('offering expansion rejects inputs, customer industries and discontinued products', () {
    final cases = {
      'synthetic_resin': '당사는 합성수지 또는 고무의 발포에 사용되는 발포제를 생산, 판매하고 있습니다.',
      'dairy': '당사는 섬유제품 제조 및 판매를 주 사업으로 영위합니다.',
      'furniture': '당사는 원가구조를 개선하고 생산 안정성을 확보하였습니다.',
      'confectionery': '당사는 국제과학비즈니스벨트에서 의약품을 생산하고 있습니다.',
      'switch': '당사는 SMPS(Switching Mode Power Supply)를 제조하고 있습니다.',
      'tire': '당사는 타이어 제조업체를 고객사로 확보하고 있습니다.',
      'capacitor': '당사는 MLCC 분야의 Cutter 장비를 개발/공급하고 있습니다.',
      'network_equipment': '당사는 글로벌 통신장비 공급사에 제품을 공급하고 있습니다.',
      'appliance': '당사는 정수기 필터를 제조 및 판매하고 있습니다.',
      'construction_machine': '당사는 건설기계 시뮬레이터 시스템을 개발하여 공급하고 있습니다.',
      'audio_device': '당사는 이어폰을 제조, 판매하였으나 사업종료 및 영업정지를 공시하였습니다.',
      'general_construction': '당사는 건축공사를 영위하고 있지 않으므로 해당사항이 없습니다.',
      'textile': '당사는 골판지 원단 및 상자를 생산, 판매하고 있습니다.',
    };
    for (final sample in cases.entries) {
      expect(
        keys(sample.value),
        isNot(contains(sample.key)),
        reason: sample.value,
      );
    }
  });

  test('classifies actual products independently in one operating sentence', () {
    const text =
        '당사는 수동소자(MLCC, Inductor)를 생산하는 사업부문, 반도체패키지기판을 생산하는 사업부문, 카메라모듈을 생산하는 사업부문으로 구성되어 있습니다.';
    expect(
      keys(text),
      containsAll([
        'capacitor',
        'inductor',
        'package_substrate',
        'camera_module',
      ]),
    );
    expect(keys('가. 주요 제품 현황당사는 커넥터를 제조 및 판매하고 있습니다.'), contains('connector'));
    expect(keys('가. 종속회사 현황당사는 커넥터를 제조 및 판매하고 있습니다.'), isEmpty);
    expect(keys('당사는 전문의약품을 생산 및 판매하고 있습니다.'), contains('drug_product'));
  });

  test('Protina protein analysis is separate from own drug discovery', () {
    const evidence =
        "당사는 단백질-단백질 상호작용(이하 'PPI')을 정제없이 단일분자 수준까지 고속ㆍ대량으로분석할 는 PPI 빅데이터 기업입니다.";
    expect(keys(evidence), contains('protein_analysis'));
    expect(keys(evidence), isNot(contains('drug_discovery')));
    expect(keys('단백질 상호작용을 분석하는 빅데이터 기업이 늘고 있습니다.'), isEmpty);
  });
  test('does not confuse products with their inputs or operating context', () {
    final samples = {
      'display': '당사의 주력제품인 T-Con IC는 디스플레이 패널을 제조하는 데 있어서 핵심 시스템 반도체에 해당합니다.',
      'power_supply': '당사는 전기자전거의 생산 및 판매를 주요사업으로 하고 있습니다.',
      'banking': '당사는 투자은행업무를 영위하고 있습니다.',
      'securities': '당사는 자본시장과 금융투자업에 관한 법률에 따른 신용평가업을 영위합니다.',
      'robot': '당사는 협동로봇 기반 기술을 제조 현장에 적용하고 있습니다.',
      'interior_construction': '당사는 인테리어가구 제조 및 판매 사업을 영위하고 있습니다.',
      'advertising': '당사는 서비스를 종합광고대행사에 제공하고 있습니다.',
      'hotel_service': '당사는 종속기업을 통해 호텔사업을 영위합니다.',
    };
    for (final item in samples.entries) {
      expect(keys(item.value), isNot(contains(item.key)), reason: item.value);
    }
  });
  test('operating service rules retain direct own statements', () {
    expect(
      keys('당사는 PC, 모바일 게임 개발 및 퍼블리싱 사업을 영위하고 있습니다.'),
      contains('game_service'),
    );
    expect(keys('당사는 손해보험업을 영위하고 있습니다.'), contains('nonlife_insurance'));
    expect(keys('당사는 고객에게 물류 서비스를 제공하고 있습니다.'), contains('logistics_service'));
  });

  test('recognizes refinery and lubricant makers with exact evidence', () {
    const soil =
        '당사는 1976년 1월에 설립되고 하루 66만 9천배럴의 원유정제능력을 보유한 정유사로, 정유뿐 아니라 석유화학ㆍ윤활기유 등으로 다각화된 사업 포트폴리오를 보유하고 있습니다.';
    expect(keys(soil), contains('petroleum_refining'));
    expect(keys('당사는 윤활유, 그리스의 제조 및 판매사업을 영위하고 있습니다.'), contains('lubricants'));
    final matches = BusinessActivityRules.parse(
      '## 1. 사업의 개요\n$soil',
      companyName: 'S-Oil(주)',
    );
    expect(matches.single.$2, soil);
  });
  test('excludes refinery customers subsidiaries plans and equipment', () {
    for (final statement in [
      '국내 업체는 원유정제능력을 보유한 정유사입니다.',
      '당사는 자회사를 통해 정유 사업을 영위합니다.',
      '당사는 정유 사업을 영위할 계획입니다.',
      '당사는 원유를 정제하여 생산하는 장비를 공급합니다.',
      '당사는 윤활유 생산 장비를 제조합니다.',
      '당사는 윤활유를 구매하여 사용하고 있습니다.',
    ]) {
      expect(keys(statement), isEmpty, reason: statement);
    }
  });

  test('retains direct product and business model evidence', () {
    final samples = {
      'bio_cdmo': '당사는 송도공장 및 오송공장에서 바이오의약품 CDMO 서비스 사업을 영위하고 있습니다.',
      'cathode': '당사는 리튬이온 이차전지의 핵심소재인 양극소재(양극재, 양극활물질)를 개발 및 생산하는 전지재료 사업을 영위하고 있습니다.',
      'cosmetics_odm': '당사는 화장품 ODM, 전문의약품 및 H&B, 화장품 용기제조(패키징) 사업을 영위하고 있습니다.',
      'pcb': '당사는 연성인쇄회로기판(FPCB) 제조 사업부문으로 구성되어 있습니다.',
      'erp': '당사는 ERP(Enterprise Resource Planning) 개발 및 판매 기업입니다.',
    };
    for (final sample in samples.entries) {
      expect(keys(sample.value), contains(sample.key));
      expect(
        BusinessActivityRules.parse(
          '## 1. 사업의 개요\n${sample.value}',
          companyName: '테스트',
        ).first.$2,
        sample.value,
      );
    }
  });
  test('does not confuse acronyms inside English words', () {
    expect(
      keys('당사는 Micro Design Enterprise 솔루션 서비스를 제공하는 전문 기업입니다.'),
      isEmpty,
    );
  });
  test('distinguishes makers from equipment, ingredients and customers', () {
    final samples = {
      'display': '당사는 OLED 패널 제조 장비를 생산하는 회사입니다.',
      'pcb': '당사는 PCB 검사 장비를 제조 및 판매하고 있습니다.',
      'cathode': '당사는 이차전지 양극소재 주요 원료인 황산코발트를 제조 및 판매합니다.',
      'transformer': '당사는 변압기 생산에 필요한 구리 소재를 공급하고 있습니다.',
      'cosmetics_odm': '당사는 화장품 유리용기 분야 ODM 전문 생산 기업입니다.',
      'bio_cdmo': '당사는 건강기능식품 CDMO 서비스를 제공하고 있습니다.',
      'drug_license': '당사는 바이오 3D 프린팅 기술이전 계약을 체결하여 판매하는 사업을 영위합니다.',
    };
    for (final sample in samples.entries) {
      expect(
        keys(sample.value),
        isNot(contains(sample.key)),
        reason: sample.value,
      );
    }
  });
  test('stops implicit own-company statements at subsidiary boundaries', () {
    expect(
      keys('나. 주요종속회사의 개요\n[ ㈜나노엔텍 ]\n당사는 체외진단 의료기기를 제조 및 판매하고 있습니다.'),
      isEmpty,
    );
  });
  test('does not turn plans or former businesses into current products', () {
    expect(keys('당사는 과거 이차전지를 직접 생산하고 판매한 경험이 있습니다.'), isEmpty);
    expect(keys('당사는 바이오의약품 CDMO 서비스를 제공할 계획입니다.'), isEmpty);
  });
}
