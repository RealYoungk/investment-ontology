/// Product-cell vocabulary. No issuer names, tickers or manually chosen peers.
/// Keep narrow products distinct from equipment, raw materials and end uses.
abstract final class ProductTaxonomy {
  static final entries = <String, (String, RegExp)>{
    for (final row in const <(String, String, String)>[
      ('dram', 'DRAM 메모리', r'\bDRAM\b|디램'),
      ('nand', 'NAND 메모리', r'\bNAND\b|낸드'),
      ('foundry', '반도체 위탁생산', r'파운드리|foundry'),
      ('mlcc', '적층세라믹콘덴서', r'\bMLCC\b|적층세라믹'),
      ('substrate', '반도체 패키지기판', r'반도체\s*패키지\s*기판|패키지\s*기판|FC[ -]?BGA'),
      ('pcb', '인쇄회로기판', r'\bPCB\b|\bFPCB\b|인쇄회로기판'),
      ('camera', '카메라 모듈', r'카메라\s*모듈|camera\s*module'),
      ('oled', 'OLED 패널', r'OLED\s*패널|OLED\s*panel'),
      ('cathode', '양극재', r'양극재|양극활물질'),
      ('anode', '음극재', r'음극재|음극활물질'),
      ('separator', '배터리 분리막', r'분리막'),
      ('electrolyte', '전해액', r'전해액'),
      (
        'battery_cell',
        '이차전지',
        r'리튬이온\s*(전지|배터리)|EV용\s*배터리|ESS용\s*배터리|이차전지|2차전지',
      ),
      ('tire', '타이어', r'타이어|tire'),
      ('cosmetics', '화장품', r'화장품|기초화장|색조화장|스킨케어|기초제품류|색조제품류'),
      ('ramen', '라면', r'라면|라멘|유탕면'),
      ('snack', '스낵·과자', r'스낵|비스킷|과자'),
      ('beer', '맥주', r'맥주'),
      ('soju', '소주', r'소주'),
      ('dairy', '유제품', r'우유|발효유|분유'),
      ('cement', '시멘트', r'시멘트'),
      ('ready_mix', '레미콘', r'레미콘'),
      ('rebar', '철근', r'철근'),
      ('steel_pipe', '강관', r'강관'),
      ('steel_sheet', '냉연·도금강판', r'냉연강판|도금강판|칼라강판|컬러강판'),
      ('transformer', '변압기', r'변압기|transformer'),
      ('switchgear', '차단기·배전반', r'차단기|배전반'),
      ('cable', '전력 케이블', r'전력\s*케이블|전력선|초고압\s*케이블'),
      ('solar', '태양광 셀·모듈', r'태양광\s*(셀|모듈)|태양전지'),
      ('wind_tower', '풍력 타워', r'풍력\s*타워|풍력발전\s*타워'),
      ('lng_ship', 'LNG 운반선', r'LNG\s*(운반선|선)|액화천연가스\s*운반선'),
      ('container_ship', '컨테이너선', r'컨테이너선'),
      ('tanker', '탱커·유조선', r'유조선|탱커'),
      ('ethylene', '에틸렌', r'에틸렌'),
      ('propylene', '프로필렌', r'프로필렌'),
      ('abs', 'ABS 수지', r'\bABS\b'),
      ('pvc', 'PVC 수지', r'\bPVC\b'),
      ('synthetic_rubber', '합성고무', r'합성고무'),
      ('fertilizer', '비료', r'비료'),
      ('feed', '배합사료', r'배합사료'),
    ])
      row.$1: (row.$2, RegExp(row.$3, caseSensitive: false)),
  };

  static Iterable<(String, String)> match(String product) sync* {
    product = product.replaceAll(RegExp(r'(?<=[가-힣])\s+(?=[가-힣])'), '');
    // Do not equate a machine, part or material with the product it makes.
    if (RegExp(r'장비|설비|검사|장치|제조용|부품|소재|원료|가공용|프로브카드|세라믹STF')
        .hasMatch(product)) {
      return;
    }
    var recognized = false;
    for (final e in entries.entries) {
      if (e.value.$2.hasMatch(product)) {
        recognized = true;
        yield ('product/${e.key}', e.value.$1);
      }
    }
    if (recognized) return;
    // Unknown names can match literally, within the same industry division.
    // Do not turn generic business labels, equipment or narrative into products.
    for (final part in product.split(RegExp(r'[,·/\n]'))) {
      final label = part
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll(RegExp(r'\s*(등|외|外)$'), '')
          .trim();
      if (label.length < 3 ||
          label.length > 24 ||
          RegExp(
            r'제품|상품|용역|사업|기타|합계|소계|기초|기말|배당|유지보수|의약품|의료기기|건강기능식품|반도체|부동산|출연료|대행|부문|제조|판매|서비스|소프트웨어|원재료|소재|장비|설비|공사|솔루션|위탁|임대|수수료|매출|[0-9%|]',
          ).hasMatch(label)) {
        continue;
      }
      if (!RegExp(r'^[가-힣a-zA-Z -]+$').hasMatch(label)) continue;
      final normalized = label.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
      yield ('product/exact/$normalized', label);
    }
  }
}
