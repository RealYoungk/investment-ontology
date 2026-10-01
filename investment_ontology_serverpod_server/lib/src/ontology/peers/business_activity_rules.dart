import 'operating_activity_vocabulary.dart';
import 'product_activity_vocabulary.dart';

/// Conservative business-model/product rules over a company's own statements.
/// Each match retains one verbatim sentence; unrelated products are not joined.
class BusinessActivityRule {
  BusinessActivityRule(
    this.industry,
    this.group,
    this.key,
    this.label,
    String pattern,
  ) : pattern = RegExp(pattern, caseSensitive: false);
  final String industry, group, key, label;
  final RegExp pattern;
}

abstract final class BusinessActivityRules {
  static final rules = <BusinessActivityRule>[
    BusinessActivityRule(
      'finance',
      '기업인수목적회사',
      'spac',
      '기업인수목적회사(SPAC)',
      r'기업인수목적회사로서.{0,450}(유일한\s*사업목적|합병)',
    ),
    BusinessActivityRule(
      'finance',
      '결제·정산',
      'payment_service',
      '전자결제·정산 서비스',
      r'(전자결제|전자금융|결제\s*플랫폼|결제\s*대행|지불대행).{0,70}(제공|영위|운영)',
    ),
    BusinessActivityRule(
      'finance',
      '환급 대행',
      'tax_refund',
      '세금 환급 대행',
      r'(세금환급|내국세\s*환급대행|텍스리펀드).{0,60}(서비스|사업|주업|영위)',
    ),

    for (final r in OperatingActivityVocabulary.rows)
      BusinessActivityRule(r.$1, r.$2, r.$3, r.$4, r.$5),
    for (final r in ProductActivityVocabulary.rows)
      if (!{'smartphone', 'tv'}.contains(r.$3))
        BusinessActivityRule(
          r.$1,
          r.$2,
          r.$3,
          r.$4,
          ProductActivityVocabulary.pattern(r.$5),
        ),
    BusinessActivityRule(
      'pharma',
      '연구·임상 서비스',
      'protein_analysis',
      '단백질 상호작용 분석',
      r'단백질.{0,15}상호작용.{0,90}(분석|빅데이터).{0,15}(기업|서비스|솔루션)',
    ),
    BusinessActivityRule(
      'pharma',
      '연구·임상 서비스',
      'drug_research_platform',
      '신약개발 지원 서비스',
      r'(신약|항체).{0,20}(개발|설계).{0,25}(지원|솔루션|서비스).{0,35}(제공|공급|영위)',
    ),

    BusinessActivityRule(
      'pharma',
      '위탁개발·생산',
      'bio_cdmo',
      '바이오의약품 위탁개발·생산',
      r'(바이오의약품.{0,30}위탁생산|\bCDMO\b).{0,100}(제공|영위|수행)',
    ),
    BusinessActivityRule(
      'pharma',
      '위탁개발·생산',
      'drug_cmo',
      '의약품 위탁생산',
      r'의약품.{0,25}(위탁생산|\bCMO\b).{0,70}(제공|영위|수행)',
    ),
    BusinessActivityRule(
      'pharma',
      '신약 개발·기술이전',
      'drug_license',
      '신약·바이오 기술이전',
      r'(제약사|바이오|신약|의약품).{0,160}(라이선스아웃|기술이전|License.out).{0,60}(계약을 체결|수익|사업|수취)',
    ),
    BusinessActivityRule(
      'pharma',
      '신약 개발·기술이전',
      'drug_discovery',
      '신약 연구개발',
      r'(신약.{0,15}(연구개발|개발).{0,30}(전문|주력|영위)|신약개발 전문)',
    ),
    BusinessActivityRule(
      'pharma',
      '의약품 개발·판매',
      'biosimilar',
      '바이오시밀러',
      r'바이오시밀러.{0,100}(개발.{0,40}(판매|상업화)|생산.{0,30}판매|판매하고|판매하는)',
    ),
    BusinessActivityRule(
      'pharma',
      '의약품 개발·판매',
      'generic_drug',
      '제네릭 의약품',
      r'제네릭.{0,60}(생산|판매|제조)',
    ),
    BusinessActivityRule(
      'pharma',
      '의약 원료',
      'api_drug',
      '원료의약품',
      r'원료의약품.{0,60}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'pharma',
      '연구·임상 서비스',
      'cro',
      '비임상·임상 연구 서비스',
      r'(임상시험수탁|임상시험 수탁|\bCRO\b).{0,80}(제공|영위|전문|수행)',
    ),
    BusinessActivityRule(
      'software',
      '업무용 소프트웨어',
      'erp',
      'ERP·기업 업무 솔루션',
      r'(\bERP\b|전사적 자원관리).{0,80}(개발.{0,25}(공급|판매)|제공|공급하고|판매하고)',
    ),
    BusinessActivityRule(
      'software',
      '보안',
      'security',
      '정보보안 솔루션·서비스',
      r'(통합보안 기업|정보보안 전문|보안 솔루션.{0,40}(개발|공급|제공)|보안관제.{0,35}(제공|영위))',
    ),
    BusinessActivityRule(
      'software',
      '클라우드·인프라',
      'cloud',
      '클라우드 서비스',
      r'(제공하는 IT서비스.{0,60}클라우드|클라우드.{0,25}서비스.{0,45}(제공|영위)|클라우드 서비스 전문)',
    ),
    BusinessActivityRule(
      'software',
      '클라우드·인프라',
      'hosting',
      '호스팅·서버 운영',
      r'(웹.?서버호스팅|웹호스팅|서버호스팅|호스팅 서비스).{0,35}제공',
    ),
    BusinessActivityRule(
      'software',
      '전자상거래 솔루션',
      'commerce_platform',
      '쇼핑몰 구축·운영 솔루션',
      r'(이커머스|전자상거래|쇼핑몰).{0,45}(솔루션|통합서비스).{0,30}(제공|공급)',
    ),
    BusinessActivityRule(
      'software',
      'IT 구축·운영',
      'si',
      '시스템 구축·운영',
      r'(시스템 통합|시스템통합|\bSI\b).{0,30}(서비스|사업).{0,35}(제공|영위|수행)',
    ),
    BusinessActivityRule(
      'software',
      '데이터·AI',
      'ai_software',
      'AI 소프트웨어',
      r'(인공지능|\bAI\b).{0,20}(솔루션|소프트웨어).{0,35}(개발.{0,15}(공급|판매)|제공|판매)',
    ),
    BusinessActivityRule(
      'battery',
      '소재',
      'cathode',
      '양극재',
      r'(양극재|양극소재|양극활물질).{0,60}(개발 및 생산|제조|생산하고|생산하는|전문 생산)',
    ),
    BusinessActivityRule(
      'battery',
      '소재',
      'anode',
      '음극재',
      r'음극재.{0,40}(생산|제조|판매)',
    ),
    BusinessActivityRule(
      'battery',
      '소재',
      'electrolyte',
      '전해액',
      r'(이차전지|리튬|배터리).{0,30}전해액.{0,40}(생산|제조|판매)',
    ),
    BusinessActivityRule(
      'battery',
      '소재',
      'separator',
      '분리막',
      r'(이차전지|리튬|배터리).{0,30}분리막.{0,40}(생산|제조|판매)',
    ),
    BusinessActivityRule(
      'battery',
      '소재',
      'copper_foil',
      '전지용 동박',
      r'(전지용|이차전지용|배터리용).{0,10}동박.{0,40}(생산|제조|판매)',
    ),
    BusinessActivityRule(
      'battery',
      '셀·팩',
      'battery_cell',
      '이차전지 셀·팩',
      r'(이차전지|리튬이온전지|배터리 셀|배터리 팩).{0,30}(제조 및 판매|생산 및 판매|생산하고|제조하는)',
    ),
    BusinessActivityRule(
      'battery',
      '생산 장비',
      'battery_equipment',
      '배터리 제조 장비',
      r'(이차전지|배터리).{0,25}(제조장비|생산장비|제조 장비|생산 장비).{0,30}(제조|생산|공급|개발)',
    ),
    BusinessActivityRule(
      'battery',
      '재활용',
      'battery_recycling',
      '폐배터리 재활용',
      r'(폐배터리|폐이차전지).{0,20}(재활용|리사이클링).{0,35}(영위|수행|전문)',
    ),
    BusinessActivityRule(
      'cosmetics',
      '위탁개발·생산',
      'cosmetics_odm',
      '화장품 ODM·OEM',
      r'화장품\s*(?:의\s*)?(\bODM\b|\bOEM\b|제조자개발생산|위탁생산).{0,65}(전문|영위|제조|생산)',
    ),
    BusinessActivityRule(
      'cosmetics',
      '브랜드·판매',
      'cosmetics_brand',
      '화장품 브랜드',
      r'(자체|자사).{0,15}화장품 브랜드.{0,40}(판매|운영|보유)|화장품.{0,15}브랜드.{0,30}(운영하고|운영하는)',
    ),
    BusinessActivityRule(
      'cosmetics',
      '원료·용기',
      'cosmetics_ingredients',
      '화장품 원료',
      r'화장품.{0,8}원료.{0,45}(개발.{0,15}(판매|공급)|제조|생산)',
    ),
    BusinessActivityRule(
      'cosmetics',
      '원료·용기',
      'cosmetics_packaging',
      '화장품 용기',
      r'화장품.{0,8}용기.{0,35}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'medical',
      '진단',
      'ivd',
      '체외진단',
      r'체외진단.{0,40}(제품|기기|시약|키트).{0,45}(개발|제조|판매)',
    ),
    BusinessActivityRule(
      'medical',
      '치과',
      'dental',
      '치과 임플란트',
      r'(치과용 임플란트|치과 임플란트).{0,45}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'medical',
      '영상·치료 기기',
      'medical_imaging',
      '의료 영상 장비',
      r'(의료용|진단용).{0,15}(엑스레이|X.ray|초음파|영상).{0,30}(기기|장비).{0,30}(개발|제조|판매)',
    ),
    BusinessActivityRule(
      'auto',
      '구동·섀시',
      'auto_brake',
      '자동차 제동장치',
      r'(자동차|차량).{0,25}(제동장치|브레이크).{0,35}(제조|생산|공급)',
    ),
    BusinessActivityRule(
      'auto',
      '구동·섀시',
      'auto_drive',
      '자동차 구동·변속 부품',
      r'(자동차|차량).{0,25}(구동축|변속기|드라이브샤프트).{0,35}(제조|생산|공급)',
    ),
    BusinessActivityRule(
      'auto',
      '차체·내장',
      'auto_seat',
      '자동차 시트',
      r'(자동차|차량).{0,10}시트.{0,35}(제조|생산|공급)',
    ),
    BusinessActivityRule(
      'auto',
      '전장·열관리',
      'auto_thermal',
      '자동차 공조·열관리',
      r'(자동차|차량).{0,25}(공조|열관리).{0,35}(제조|생산|공급)',
    ),
    BusinessActivityRule(
      'electronics',
      '기판',
      'pcb',
      '인쇄회로기판',
      r'(인쇄회로기판|\bPCB\b).{0,35}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'electronics',
      '디스플레이',
      'display',
      '디스플레이 패널',
      r'(디스플레이 패널|OLED 패널|LCD 패널|디스플레이 기술을 활용한 관련 제품).{0,35}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'food',
      '건강기능식품',
      'healthfood_odm',
      '건강기능식품 ODM·OEM',
      r'건강기능식품.{0,40}(\bODM\b|\bOEM\b|위탁생산).{0,45}(전문|제조|생산|영위)',
    ),
    BusinessActivityRule(
      'electrical',
      '전력기기',
      'transformer',
      '변압기',
      r'변압기.{0,30}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'electrical',
      '전력기기',
      'switchgear',
      '차단기·배전반',
      r'(차단기|배전반).{0,30}(제조|생산|판매)',
    ),
    BusinessActivityRule(
      'energy',
      '정유',
      'petroleum_refining',
      '원유 정제·석유제품',
      r'원유\s*정제능력을 보유한 정유사|원유를 정제하여.{0,45}(생산|제조)|정유\s*사업을 영위',
    ),
    BusinessActivityRule(
      'energy',
      '윤활유·윤활기유',
      'lubricants',
      '윤활유·윤활기유',
      r'윤활유.{0,20}(제조 및 판매사업|생산)|주요제품은.{0,40}윤활유.{0,60}생산에 주력',
    ),
    BusinessActivityRule(
      'energy',
      '태양광',
      'solar_module',
      '태양광 모듈',
      r'태양광 모듈.{0,30}(제조|생산|판매)',
    ),
  ];

  static bool _eligible(String key, String sentence) {
    final exclusions = <String, String>{
      'petroleum_refining': r'장비|설비를|촉매|지원|고객',
      'lubricants': r'장비|첨가제|원료를|고객',
      'display': r'장비|부품|제조사|칩|구동|검사|반도체|유리|고객사|T-Con|TCON',
      'pcb': r'장비|약품|검사|세정|Assy|화학|기계',
      'battery_cell': r'소재|장비|테이프|Tape|부품|제조사',
      'cathode': r'재활용|정제|분리|제조원료|전구체|주요 원료|황산코발트',
      'anode': r'SWCNT|CNT|도전재|첨가',
      'drug_discovery': r'평가|지원|서비스|경영진|반려동물',
      'drug_license': r'인수|프린팅|로부터',
      'battery_equipment': r'부품|차세대|개발을 통해',
      'transformer': r'소재|생산에 필요한',
      'advertising': r'광고대행사에',
      'banking': r'투자은행',
      'securities': r'법률|신용평가',
      'game_service': r'서비스 개선|설립 및 출자|연구개발비',
      'city_gas': r'목적으로.{0,20}설립',
      'textile': r'골판지|피혁|섬유로프',
      'industrial_valve': r'자동차|정수기',
      'electrolyte': r'첨가제|전해질',
      'telecom_service': r'무선통신 사업|장비|안테나|부품|통신단말기|THURAYA',
      'cloud': r'클라우드 보안|접근제어|암호화 솔루션',
      'si': r'서보|로봇',
      'security': r'CCTV|불법촬영|무선도청',
      'ai_software': r'의료|진단|로봇|CCTV|계량|미터링',
    };
    if (key == 'cro' && !RegExp(r'비임상|임상시험|임상연구').hasMatch(sentence)) {
      return false;
    }
    if (key == 'bio_cdmo' &&
        !RegExp(r'바이오의약품|첨단바이오의약품|세포치료|바이오신약|항체').hasMatch(sentence)) {
      return false;
    }
    if (ProductActivityVocabulary.rows.any((r) => r.$3 == key) &&
        RegExp(
          r'백화점|도소매업|판매업자|유통플랫폼|플랫폼을 통해 판매|유통하고|법률|영위할 목적으로|공급가격|생산하는 데|생산하기 위한',
        ).hasMatch(sentence)) {
      return false;
    }
    final excluded = exclusions[key];
    return excluded == null ||
        !RegExp(excluded, caseSensitive: false).hasMatch(sentence);
  }

  static List<(BusinessActivityRule, String)> parse(
    String text, {
    required String companyName,
  }) {
    final result = <(BusinessActivityRule, String)>[];
    final seen = <String>{};
    final name = companyName.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
    var active = false;
    var subsidiary = false;
    var productsOnly = false;
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        productsOnly =
            subsidiary &&
            RegExp(r'주요\s*제품').hasMatch(line) &&
            !RegExp(r'종속|자회사|계열회사').hasMatch(line);
        active = RegExp(r'사업의\s*개요|주요\s*제품|주요\s*서비스').hasMatch(line);
        continue;
      }
      if (RegExp(r'주요종속회사|종속회사의 개요|종속기업의 개요|\[.*(?:㈜|주식회사|\(주\))')
          .hasMatch(line)) {
        final heading = line.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
        final ownHeading =
            name.isNotEmpty &&
            line.length < 100 &&
            RegExp(
              r'(?<![가-힣A-Za-z0-9])' +
                  RegExp.escape(name) +
                  r'(?![가-힣A-Za-z0-9])',
            ).hasMatch(heading);
        subsidiary = !ownHeading;
        if (ownHeading) productsOnly = false;
      }
      if (!active || (subsidiary && !productsOnly) || line.contains('|')) {
        continue;
      }
      for (final raw in line.split(RegExp(r'(?<=다[.!?])\s*'))) {
        var sentence = raw.trim().replaceFirst(RegExp(r'^지배회사인\s*'), '');
        // Filings often concatenate a numbered heading and the first sentence.
        final ownStart = sentence.indexOf('당사');
        if (ownStart > 0 &&
            ownStart < 70 &&
            RegExp(r'^(?:[가-힣0-9]+[.)]|[（(]?[0-9]+[)）])').hasMatch(sentence) &&
            !RegExp(r'종속|자회사|계열|고객|경쟁')
                .hasMatch(sentence.substring(0, ownStart))) {
          sentence = sentence.substring(ownStart);
        }
        final normalized = sentence.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
        final own =
            RegExp(
              r'^당사(는|가\s*제공하는|의\s*(주요\s*(?:생산\s*)?제품|주력\s*제품|사업|주요\s*사업))',
            ).hasMatch(sentence) ||
            (name.isNotEmpty &&
                (normalized.startsWith('$name는') ||
                    normalized.startsWith('$name은')));
        // SPACs explicitly negate every OTHER business in their legal purpose.
        // That negation must not erase the positive sole-merger-purpose clause.
        if (own &&
            sentence.length <= 650 &&
            RegExp(r'^당사는.{0,300}합병하는.{0,260}유일한\s*사업목적으로\s*(?:하고|하는)')
                .hasMatch(sentence) &&
            !RegExp(r'합병하지|합병하는\s*것이\s*아닌').hasMatch(sentence) &&
            seen.add('spac')) {
          result.add((rules.firstWhere((r) => r.key == 'spac'), sentence));
        }
        if (!own ||
            sentence.length > 650 ||
            RegExp(
              r'종속회사|종속기업|지배회사|연결회사|연결대상회사|자회사|계열회사|고객사인|경쟁사|계획|예정|추진|목표|검토|준비|중단|철수|사업종료|영업정지|않으|않습|아닙|사업을 매각|사업 양도|하지\s*않|아닌|아니며|구매|도입|사용하고|사용하는|해외 주요 생산법인|과거|경영권을 인수|개발지원|전문가들',
            ).hasMatch(sentence)) {
          continue;
        }
        for (final product in ProductActivityVocabulary.enumerated(sentence)) {
          if (_eligible(product.$3, sentence) && seen.add(product.$3)) {
            result.add((
              BusinessActivityRule(
                product.$1,
                product.$2,
                product.$3,
                product.$4,
                product.$5,
              ),
              sentence,
            ));
          }
        }
        if (subsidiary) continue;
        for (final rule in rules) {
          if (_eligible(rule.key, sentence) &&
              rule.pattern.hasMatch(sentence) &&
              seen.add(rule.key)) {
            result.add((rule, sentence));
          }
        }
      }
    }
    // CDMO is more informative than the overlapping CMO label.
    if (seen.contains('bio_cdmo')) {
      result.removeWhere((a) => a.$1.key == 'drug_cmo');
    }
    return result;
  }
}
