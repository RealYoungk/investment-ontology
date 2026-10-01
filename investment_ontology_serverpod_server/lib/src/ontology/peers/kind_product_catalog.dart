import 'dart:convert';
import 'dart:io';

import '../../generated/protocol.dart';
import 'discovery_offerings.dart';
import 'discovery_taxonomy.dart';
import 'product_activity_vocabulary.dart';
import 'registered_offerings.dart';
import 'product_offering_rules.dart';

/// A versioned KRX source snapshot, joined by stock code, never issuer name.
/// The primary-products field is evidence of offerings, not revenue or peers.
abstract final class KindProductCatalog {
  static final source = jsonDecode(
    File('assets/discovery/kind_products.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  static final rows = <String, Map<String, dynamic>>{
    for (final row in source['rows'] as List)
      row['stockCode'] as String: Map<String, dynamic>.from(row as Map),
  };

  static final _companyCache =
      <(String, String?, String, String?, Market?), List<IndustryActivity>>{};
  static final _patterns = [
    for (final row in [...ProductActivityVocabulary.rows, ..._extra])
      (row, RegExp(row.$5, caseSensitive: false)),
  ];
  static List<IndustryActivity> forCompany(Company c) =>
      _companyCache.putIfAbsent(
        (c.corpCode, c.stockCode, c.name, c.industryCode, c.market),
        () => List.unmodifiable(_forCompany(c)),
      );
  static List<IndustryActivity> _forCompany(Company c) {
    final row = rows[c.stockCode];
    if (row == null) return [];
    final products = row['products'] as String;
    if (products.trim().isEmpty || products == '-') return [];
    if (RegExp(r'^(?:기업인수(?:목적회사|합병)?|기업인수및합병|금융지원서비스(?:\(SPAC\))?)$')
            .hasMatch(products.replaceAll(RegExp(r'\s'), '')) &&
        !RegExp(r'스팩|기업인수목적').hasMatch(c.name)) {
      return [];
    }
    final sector = DiscoveryTaxonomy.category(c.industryCode);
    final registered = RegisteredOfferings.definition(
      sector.$1,
      c.industryCode ?? '',
    );
    final evidence =
        '한국거래소 KIND 상장법인목록 · ${row['name']} (${row['stockCode']})\n주요제품: $products\n조회일: ${(source['retrievedAt'] as String).substring(0, 10)}\n거래소 기재 내용이며 제품별 매출·현재 주력도까지 확인한 것은 아닙니다.';
    final offeringMatches = ProductOfferingRules.match(products, sector.$1);
    final isHolding =
        RegExp(r'지주\s*회사|지주사업|지주업').hasMatch(products) &&
        !products.trimLeft().startsWith('자회사 제품');
    final isSpac =
        RegExp(r'스팩|기업인수목적').hasMatch(c.name) &&
        RegExp(r'기업\s*인수|합병|금융\s*지원').hasMatch(products);
    final found = isHolding
        ? <(String, String, String, String)>[
            ('holdings', '지주회사', 'legal:holding', '지주회사'),
          ]
        : isSpac
        ? <(String, String, String, String)>[
            ('finance', '기업인수목적회사', 'legal:spac', '기업인수목적회사(SPAC)'),
          ]
        : sector.$1 == 'holdings'
        ? <(String, String, String, String)>[]
        : offeringMatches.isNotEmpty
        ? offeringMatches
        : classify(products);
    // Retailers sell these products, but are not their manufacturers. The
    // distribution role stays primary and product text remains visible.
    if (sector.$1 == 'retail') {
      found.removeWhere(
        (r) => !r.$3.startsWith('offering:') && !r.$3.startsWith('legal:'),
      );
    }
    found.removeWhere(
      (r) =>
          !r.$3.startsWith('offering:') &&
          !r.$3.startsWith('legal:') &&
          !_compatible(sector.$1, r.$1) &&
          !(sector.$1 == 'chemicals' && r.$3 == 'tire'),
    );
    // KIND may retain a SPAC's pre-merger descriptor. Require its current
    // legal identity as well, so an operating successor never becomes a SPAC.
    found.removeWhere(
      (r) => r.$3 == 'spac' && !RegExp(r'스팩|기업인수목적').hasMatch(c.name),
    );
    if (found.isEmpty) {
      if (registered == null) return [];
      final label = registered['label'] as String;
      return [
        IndustryActivity(
          corpCode: c.corpCode,
          companyName: c.name,
          market: c.market!.name,
          industryCode: c.industryCode,
          industryKey: sector.$1,
          industryName: sector.$2,
          groupName: label,
          role: RegisteredOfferings.role(sector.$1, label),
          productKey: 'kind-registration:${c.industryCode}',
          productName: sector.$1 == 'holdings' ? '지주회사' : products,
          process: '',
          evidence: evidence,
          classificationBasis: 'kind_registered',
          bsnsYear: 0,
          rceptNo: '',
        ),
      ];
    }
    return [
      for (final match in found)
        DiscoveryOfferings.normalize(
          IndustryActivity(
            corpCode: c.corpCode,
            companyName: c.name,
            market: c.market!.name,
            industryCode: c.industryCode,
            industryKey: match.$1,
            industryName: DiscoveryTaxonomy.categories[match.$1]!.$1,
            groupName: match.$2,
            role: RegisteredOfferings.role(match.$1, match.$2),
            productKey: match.$3,
            productName: match.$4,
            process: '',
            evidence: evidence,
            classificationBasis: 'kind_product',
            bsnsYear: 0,
            rceptNo: '',
          ),
        ),
    ];
  }

  /// Match only what the primary-products field actually says. A component,
  /// input, manufacturing tool or customer application is not a finished good.
  static List<(String, String, String, String)> classify(String products) {
    final found = <String, (String, String, String, String)>{};
    final parts = products.split(RegExp(r'[,;／/]'));
    // A shared suffix can govern an entire enumeration (A, B 및 C 부품).
    final componentField = RegExp(r'부품|부분품|용코어').hasMatch(products);
    for (final compiled in _patterns) {
      final row = compiled.$1;
      for (final part in parts) {
        if (RegExp(r'추진|예정|계획|중단|철수').hasMatch(part)) continue;
        final match = compiled.$2.firstMatch(part);
        if (match == null) continue;
        if ({
              'smartphone',
              'tv',
              'appliance',
              'tire',
              'furniture',
              'footwear',
              'agricultural_machine',
              'construction_machine',
            }.contains(row.$3) &&
            componentField) {
          continue;
        }
        final before = part.substring(0, match.start);
        final after = part.substring(match.end).trimLeft();
        if (RegExp(r'^[A-Za-z]').hasMatch(after) &&
            RegExp(r'[A-Za-z]$').hasMatch(match.group(0)!)) {
          continue;
        }
        if (row.$3 == 'dairy' && RegExp(r'윤활유제품|석유제품').hasMatch(part)) continue;
        if (row.$3 == 'steel_wire' && RegExp(r'초전도|비철').hasMatch(part)) {
          continue;
        }
        if (row.$3 == 'kind_software' && RegExp(r'게임').hasMatch(part)) continue;
        if (row.$3 == 'drug_product' &&
            RegExp(r'개발지원|개발\s*플랫폼|개발\s*서비스|위탁|연구지원').hasMatch(part)) {
          continue;
        }
        if (RegExp(
          r'^(?:방송|드라마|스탠드|코드지|사이클|병|필터|피팅|공급시스템|임대|자동설비|제조검사|초정밀\s*부품)',
        ).hasMatch(after)) {
          continue;
        }
        if (RegExp(r'등의?\s*(?:부품|단조|소재)|용코어').hasMatch(after)) continue;
        if (RegExp(
          r'^(?:용|용의|제조\s*(?:장비|설비)|생산\s*(?:장비|설비)|장비|설비|부품|소재|원료|재료|금형|금속|케이스|모듈|필름|몰드|코팅|검사|테스트|측정|가공|용기|첨가|튜브|합금)',
        ).hasMatch(after)) {
          continue;
        }
        if (RegExp(r'(?:용|원료|소재|부품)\s*$').hasMatch(before)) continue;
        if ({
              'smartphone',
              'tv',
              'appliance',
              'tire',
              'furniture',
              'footwear',
            }.contains(row.$3) &&
            (before.trim().isNotEmpty ||
                RegExp(r'카메라|부품|용|장비|소재|검사|금형|케이스|힌지').hasMatch(after))) {
          continue;
        }
        // Prevent e.g. 금형강 -> 강선, and English acronym substrings.
        if (match.start > 0 &&
            RegExp(r'[A-Za-z]').hasMatch(part[match.start - 1]) &&
            RegExp(r'^[A-Za-z]').hasMatch(match.group(0)!)) {
          continue;
        }
        found[row.$3] = (row.$1, row.$2, row.$3, row.$4);
      }
    }
    return found.values.toList();
  }

  static bool _compatible(String registered, String product) {
    if (registered == product) return true;
    const families = [
      {'pharma', 'medical', 'research'},
      {'semiconductor', 'electronics', 'instruments', 'machinery'},
      {'battery', 'electrical', 'machinery', 'chemicals'},
      {'software', 'gaming'},
      {'food', 'agriculture'},
    ];
    return families.any((f) => f.contains(registered) && f.contains(product));
  }

  static const _extra = <(String, String, String, String, String)>[
    ('electronics', '기판', 'pcb', '인쇄회로기판', r'인쇄회로기판|\bPCB\b|FPCB'),
    ('electronics', '광학 부품', 'camera_module', '카메라 모듈', r'카메라모듈|카메라\s*모듈'),
    ('energy', '정유', 'refining', '석유 정제 제품', r'석유제품|석유정제|정유제품|휘발유|경유'),
    ('energy', '윤활유', 'lubricants', '윤활유·윤활기유', r'윤활유|윤활기유'),
    (
      'pharma',
      '연구·임상 지원',
      'protein_analysis',
      '바이오 분석 서비스',
      r'바이오마커.{0,30}분석서비스|단백질.{0,30}분석서비스',
    ),
    (
      'pharma',
      '연구·임상 지원',
      'cro',
      '임상·비임상 시험',
      r'임상시험\s*수탁|비임상시험|임상시험대행|\bCRO\b',
    ),
    (
      'pharma',
      '개발·생산 수탁',
      'bio_cdmo',
      '의약품 위탁개발·생산',
      r'\bCDMO\b|\bCMO\b|의약품\s*위탁',
    ),
    ('pharma', '의약 원료', 'api_drug', '원료의약품', r'원료의약품|의약품\s*원료'),
    ('pharma', '의약품·치료제', 'drug_product', '의약품·치료제', r'의약품|치료제|신약|바이오시밀러'),
    ('medical', '치과 기기·재료', 'dental', '치과 기기·재료', r'치과용|치과\s*의료'),
    ('medical', '체외진단', 'ivd', '체외진단', r'체외\s*진단|진단키트|진단시약'),
    ('medical', '영상 진단', 'medical_imaging', '영상 진단', r'초음파진단|의료용\s*엑스레이|의료영상'),
    (
      'semiconductor',
      '설계 IP',
      'design_ip',
      '반도체 설계 IP',
      r'반도체\s*(?:설계\s*)?IP|반도체\s*설계자산',
    ),
    (
      'semiconductor',
      '설계 서비스',
      'design_house',
      '반도체 설계 서비스',
      r'디자인하우스|반도체\s*설계\s*서비스',
    ),
    (
      'semiconductor',
      '장비',
      'kind_semi_equipment',
      '반도체 제조 장비',
      r'반도체\s*(?:제조|공정|검사|후공정|전공정|증착|식각|세정)?\s*(?:장비|설비)',
    ),
    (
      'semiconductor',
      '패키징·테스트 서비스',
      'osat',
      '반도체 패키징·테스트',
      r'반도체\s*패키징|반도체\s*조립|반도체\s*테스트\s*서비스',
    ),
    (
      'software',
      '소프트웨어 제품',
      'kind_software',
      '소프트웨어',
      r'소프트웨어|보안솔루션|ERP|보안\s*솔루션',
    ),
    (
      'software',
      'IT 구축·운영',
      'si',
      'IT 구축·운영',
      r'시스템통합|시스템\s*통합|SI서비스|IT\s*서비스',
    ),
    ('software', '클라우드·인프라 서비스', 'cloud', '클라우드·호스팅', r'클라우드|호스팅'),
    ('gaming', '게임', 'game_service', '게임', r'온라인게임|모바일게임|게임소프트웨어|게임\s*개발'),
    ('chemicals', '염료·안료', 'dye', '염료·안료', r'염료|안료'),
    ('chemicals', '산업용 가스', 'hydrogen', '수소·산업용 가스', r'수소가스|고순도\s*가스'),
    ('food', '사료', 'animal_feed', '사료', r'배합사료|동물사료'),
    ('metals', '철강 판재·선재', 'steel_wire', '강선·와이어', r'강선|와이어로프|선재'),
    (
      'finance',
      '기업인수목적회사',
      'spac',
      '기업인수목적회사',
      r'기업인수목적|인수합병|기업의\s*인수\s*및\s*합병',
    ),
    ('finance', '결제·정산', 'payment_service', '결제·정산 서비스', r'전자결제|결제대행|지불결제'),
    ('content', '영상', 'video_content', '영상 콘텐츠', r'영상콘텐츠|드라마|영화\s*제작'),
    ('content', '음악', 'music_business', '음악', r'음악|음반'),
    (
      'battery',
      '배터리 소재',
      'battery_material',
      '배터리 소재',
      r'양극재|음극재|전해액|배터리용\s*분리막',
    ),
    (
      'battery',
      '배터리 제조 장비',
      'battery_equipment',
      '배터리 제조 장비',
      r'(?:이차전지|2차전지|배터리)\s*(?:제조|공정)?\s*(?:장비|설비)',
    ),
    ('battery', '배터리', 'battery_cell', '배터리', r'리튬이온전지|리튬이온\s*이차전지|축전지'),
  ];
}
