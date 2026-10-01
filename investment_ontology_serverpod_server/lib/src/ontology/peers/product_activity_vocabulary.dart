/// Product vocabulary applied only to direct own-company operating statements.
abstract final class ProductActivityVocabulary {
  static String pattern(String offering) =>
      r'(?<![가-힣A-Za-z])(?:' +
      offering +
      r')' +
      r'(?:(?!용|장비|공급사|메이커|시뮬레이터|로프|팩|용기|회사|제조사|업체|사용|적용|기술|바탕|통해|위한|위해|의\s*핵심|제조\s*장비|생산\s*장비|공정|산업|설비|원료|소재|부품|검사|고객|필터|첨가|케이스|샤프트|발포|충전|공급받|수급|판매가|기반).){0,50}(?:(?:제조|생산|판매|공급|제작)(?:하고|하는|하며|하여|합니다|한다|해|업(?!체)|을)|(?:제조|생산|제작)\s*(?:및|[,·ㆍ/])\s*(?:판매|공급|납품))';

  /// Only explicitly asserted own products, with a complete item boundary.
  /// Applied-to markets and component suffixes are not products of the filer.
  static Iterable<(String, String, String, String, String)> enumerated(
    String sentence,
  ) sync* {
    final declaration = RegExp(
      r'^당사의\s*(?:주요\s*)?(?:생산\s*|주력\s*)?제품은\s*(.+?)입니다[.!]?$',
    ).firstMatch(sentence);
    final operating = RegExp(
      r'^당사는\s+(.+?)\s*(?:을|를)?\s*생산[ㆍ·, ]*(?:및\s*)?판매하고\s*있습니다[.!]?$',
    ).firstMatch(sentence);
    var products = declaration?.group(1) ?? operating?.group(1);
    if (products == null) return;
    // Strip an application modifier BEFORE splitting: smartphones in
    // "스마트폰 및 태블릿에 적용되는 카메라 모듈" are customer markets.
    products = products.replaceAll(
      RegExp(r'[^,]+?(?:에\s*적용되는|에\s*사용되는)\s*'),
      '',
    );
    final finishedProducts = products.split('완제품과').first;
    for (final item in products.split(RegExp(r',|\s+및\s+|과\s+|와\s+'))) {
      for (final row in rows) {
        if ({'smartphone', 'tv'}.contains(row.$3) &&
            (RegExp(r'부품|모듈|소재|재료|용|에\s*응용|에\s*탑재')
                    .hasMatch(finishedProducts) ||
                products.indexOf(item) >= finishedProducts.length)) {
          continue;
        }
        final whole = RegExp(
          r'^\s*(?:' +
              row.$5 +
              r')(?:\s*\([^)]*\))?\s*(?:등\s*(?:완제품|제품)?)?\s*$',
          caseSensitive: false,
        );
        if (whole.hasMatch(item)) yield row;
      }
    }
  }

  static const rows = <(String, String, String, String, String)>[
    (
      'electronics',
      '기판',
      'package_substrate',
      '반도체 패키지 기판',
      r'반도체\s*패키지\s*기판|패키지기판|패키징기판',
    ),
    ('electronics', '수동·연결 부품', 'capacitor', '콘덴서·커패시터', r'콘덴서|캐패시터|커패시터|MLCC'),
    (
      'electronics',
      '수동·연결 부품',
      'inductor',
      '인덕터·자성 부품',
      r'인덕터|페라이트\s*코어|Inductor',
    ),
    ('electronics', '수동·연결 부품', 'connector', '커넥터', r'커넥터|Connector'),
    ('electronics', '수동·연결 부품', 'switch', '스위치·리모컨', r'리모컨|REMOCON|\bSWITCH\b'),
    ('electronics', '광학 부품', 'camera_module', '카메라 모듈', r'카메라\s*모듈'),
    ('electronics', '광학 부품', 'lens', '광학 렌즈', r'광학\s*렌즈|카메라\s*렌즈'),
    (
      'electronics',
      '디스플레이 부품·소재',
      'display_material',
      '디스플레이 소재',
      r'편광판|광학\s*필름|OLED\s*발광\s*소재',
    ),
    ('electronics', '디스플레이 부품·소재', 'backlight', '백라이트·도광판', r'백라이트|도광판'),
    (
      'electronics',
      '통신 장비·부품',
      'network_equipment',
      '통신 네트워크 장비',
      r'통신장비|통신\s*중계기|무선\s*접속\s*장비|정보통신장비',
    ),
    (
      'electronics',
      '통신 장비·부품',
      'optical_transceiver',
      '광통신 모듈',
      r'광트랜시버|광트랜시버|광증폭기|광통신\s*모듈',
    ),
    ('electronics', '통신 장비·부품', 'antenna', '안테나·RF 부품', r'안테나|RF\s*필터'),
    (
      'electronics',
      '전자 기기',
      'video_security',
      '영상 보안 기기',
      r'CCTV|영상보안\s*장비|영상\s*보안\s*제품',
    ),
    ('electronics', '전자 기기', 'settop_box', '셋톱박스', r'셋톱박스|셋탑박스'),
    ('electronics', '전자 기기', 'digital_signage', '디지털 사이니지', r'디지털\s*사이니지'),
    ('electronics', '전자 기기', 'audio_device', '음향 기기', r'스피커|이어폰|헤드폰|음향기기'),
    ('electronics', '전자 기기', 'printer', '프린터', r'프린터|인쇄기'),
    ('electronics', '전자 기기', 'smartphone', '스마트폰', r'스마트폰'),
    ('electronics', '전자 기기', 'tv', 'TV·모니터', r'TV|모니터'),
    ('electronics', '전자 기기', 'appliance', '생활 가전', r'냉장고|세탁기|공기청정기|정수기|생활가전'),
    (
      'electronics',
      '전원·충전 부품',
      'wireless_charging',
      '무선충전 모듈',
      r'무선충전\s*모듈|무선충전기',
    ),
    (
      'electronics',
      '전원·충전 부품',
      'power_module',
      '전원공급장치',
      r'전원공급장치|SMPS|평판형\s*트랜스',
    ),
    (
      'electronics',
      '기구 부품',
      'precision_enclosure',
      '전자기기 정밀 기구부품',
      r'정밀\s*기구부품|휴대폰\s*케이스|휴대폰용\s*힌지',
    ),
    ('auto', '차체·내장', 'auto_body', '자동차 차체 부품', r'자동차\s*차체|차체\s*부품'),
    ('auto', '구동·제동', 'auto_brake', '자동차 제동 부품', r'자동차.{0,8}브레이크|자동차\s*제동장치'),
    (
      'auto',
      '구동·제동',
      'auto_transmission',
      '변속기·구동 부품',
      r'자동차용\s*변속기|자동차\s*변속기|구동축',
    ),
    (
      'auto',
      '구동·제동',
      'auto_engine',
      '자동차 엔진 부품',
      r'자동차\s*엔진\s*부품|자동차용\s*피스톤링|자동차용\s*실린더\s*라이너',
    ),
    ('auto', '타이어', 'tire', '타이어', r'타이어'),
    ('auto', '차체·내장', 'auto_trim', '자동차 내장재', r'자동차\s*내장재|자동차용\s*내장재'),
    ('auto', '전장·열관리', 'auto_harness', '와이어하네스', r'와이어\s*하네스|와이어링\s*하네스'),
    ('machinery', '유공압·동력전달', 'industrial_pump', '산업용 펌프', r'산업용\s*펌프|진공\s*펌프'),
    ('machinery', '유공압·동력전달', 'industrial_valve', '밸브', r'산업용\s*밸브|밸브'),
    ('machinery', '유공압·동력전달', 'bearing', '베어링', r'베어링'),
    ('machinery', '열·에너지 설비', 'boiler', '보일러·열교환기', r'보일러|열교환기|증기발생기'),
    ('machinery', '산업용 기계', 'construction_machine', '건설기계', r'굴착기|지게차|건설기계'),
    (
      'machinery',
      '산업용 기계',
      'agricultural_machine',
      '농업 기계',
      r'농업용\s*트랙터|농기계|농업기계',
    ),
    (
      'machinery',
      '로봇·자동화',
      'automation_equipment',
      '공장 자동화 설비',
      r'공장자동화\s*장비|물류자동화\s*설비',
    ),
    ('electrical', '전선·케이블', 'electric_cable', '전선·전력 케이블', r'전력\s*케이블|전선'),
    ('electrical', '회전기기', 'electric_motor', '전동기·발전기', r'전동기|모터|발전기'),
    ('electrical', '조명', 'lighting', '조명 기기', r'LED\s*조명|조명기구'),
    (
      'medical',
      '진단 기기·시약',
      'diagnostic_reagent',
      '체외진단 시약·키트',
      r'체외진단\s*시약|진단\s*키트|진단시약',
    ),
    (
      'medical',
      '영상·검사 기기',
      'medical_imaging',
      '의료 영상 진단 장비',
      r'초음파\s*진단기|의료용\s*엑스레이|의료용\s*X.ray',
    ),
    (
      'medical',
      '치과 기기·재료',
      'dental_implant',
      '치과 임플란트',
      r'치과용\s*임플란트|치과\s*임플란트',
    ),
    ('medical', '치과 기기·재료', 'dental_material', '치과 재료', r'치과용\s*재료|치과\s*재료'),
    (
      'medical',
      '치료·미용 기기',
      'aesthetic_device',
      '의료용 미용 장비',
      r'피부미용\s*의료기기|피부과용\s*레이저|미용\s*의료기기',
    ),
    (
      'medical',
      '의료 소모품',
      'medical_consumable',
      '주사기·의료 소모품',
      r'주사기|주사침|수술용\s*봉합사',
    ),
    ('pharma', '의약품·치료제', 'drug_product', '의약품', r'전문의약품|완제의약품|일반의약품'),
    ('food', '가공식품', 'noodles', '면류', r'라면|면류'),
    ('food', '가공식품', 'confectionery', '과자·제과', r'과자|비스킷|초콜릿|제과'),
    ('food', '가공식품', 'seasoning', '조미료·식품 원료', r'조미료|장류|식품첨가물'),
    ('food', '음료·주류', 'beverage', '음료', r'탄산음료|비알콜음료|생수|음료'),
    ('food', '음료·주류', 'alcohol', '주류', r'소주|맥주|주류'),
    ('food', '유제품·육가공', 'dairy', '유제품', r'유제품|우유|분유'),
    ('food', '유제품·육가공', 'meat_processing', '육가공', r'육가공|햄|소시지'),
    ('agriculture', '농축산 투입재', 'animal_feed', '사료', r'배합사료|축산용\s*사료'),
    ('agriculture', '농축산 투입재', 'fertilizer', '비료', r'비료'),
    ('agriculture', '농축산 투입재', 'crop_protection', '작물보호제', r'작물보호제|농약'),
    (
      'chemicals',
      '고분자·합성수지',
      'synthetic_resin',
      '합성수지',
      r'합성수지|폴리프로필렌(?!글리콜)|폴리에틸렌',
    ),
    ('chemicals', '도료·접착제', 'paint', '도료', r'도료|페인트'),
    ('chemicals', '도료·접착제', 'adhesive', '접착제', r'접착제'),
    ('chemicals', '산업용 가스', 'industrial_gas', '산업용 가스', r'산업용\s*가스|특수가스'),
    (
      'chemicals',
      '기초 화학',
      'chemical_basic',
      '기초 화학 제품',
      r'가성소다|황산(?![가-힣])|탄산칼륨|탄산나트륨',
    ),
    ('metals', '비철금속', 'aluminium', '알루미늄 제품', r'알루미늄\s*압출|알루미늄\s*합금|알루미늄\s*판'),
    ('metals', '비철금속', 'copper_products', '동·동합금 제품', r'동합금|동관|동봉'),
    ('metals', '철강 제품', 'steel_pipe', '강관', r'강관'),
    ('metals', '철강 제품', 'steel_wire', '강선·와이어', r'경강선|강선|와이어로프'),
    ('metals', '금속 가공', 'metal_forging', '금속 단조품', r'단조품|단조제품'),
    (
      'building-materials',
      '유리·창호',
      'building_glass',
      '건축용 유리',
      r'건축용\s*유리|판유리',
    ),
    ('building-materials', '유리·창호', 'window_frame', '창호', r'창호'),
    (
      'building-materials',
      '건축 마감재',
      'building_board',
      '건축용 보드·목재',
      r'석고보드|합판|MDF|파티클보드',
    ),
    ('household', '가구', 'furniture', '가구', r'사무용\s*가구|주방가구|가구'),
    ('household', '생활용품', 'hygiene_products', '위생용품', r'생리대|기저귀|화장지'),
    (
      'household',
      '종이·포장',
      'plastic_packaging',
      '플라스틱 포장',
      r'플라스틱\s*포장|연포장|PET\s*용기',
    ),
    ('fashion', '섬유·원단', 'textile', '섬유·원단', r'합성섬유|직물|원단|면사'),
    ('fashion', '신발·잡화', 'footwear', '신발', r'신발'),
  ];
}
