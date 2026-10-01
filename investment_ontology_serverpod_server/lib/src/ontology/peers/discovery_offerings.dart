import '../../generated/protocol.dart';
import 'registered_offerings.dart';
import 'discovery_taxonomy.dart';

/// Changes navigation only; never invents products or evidence.
abstract final class DiscoveryOfferings {
  static IndustryActivity normalize(IndustryActivity source) {
    final a = _normalizeProduct(source);
    final label = _aliases[(a.industryKey, a.groupName)];
    if (label == null) return a;
    return a.copyWith(
      groupName: label,
      role: RegisteredOfferings.role(a.industryKey ?? '', label),
    );
  }

  static IndustryActivity _normalizeProduct(IndustryActivity a) {
    final canonical = _productGroups[a.productKey];
    if (canonical != null) {
      return a.copyWith(
        industryKey: canonical.$1,
        industryName: DiscoveryTaxonomy.categories[canonical.$1]!.$1,
        role: RegisteredOfferings.role(canonical.$1, canonical.$2),
        groupName: canonical.$2,
      );
    }
    final String role;
    final String name;
    if (a.industryKey == 'semiconductor') {
      (role, name) = switch (a.productKey) {
        'design_house' => ('design_service', '설계 서비스'),
        'semiconductor_ip' ||
        'interface_ip' ||
        'memory_ip' ||
        'video_ip' => ('design_ip', '설계 IP'),
        'foundry' => ('foundry', '웨이퍼 제조 서비스'),
        'osat' ||
        'packaging_service' ||
        'test_service' => ('osat', '패키징·테스트 서비스'),
        _ => (a.role, a.groupName ?? a.role),
      };
    } else if (a.industryKey == 'pharma') {
      (role, name) = switch (a.productKey) {
        'drug_discovery' || 'drug_license' => ('drug_discovery', '신약 개발·기술이전'),
        'biosimilar' || 'generic_drug' || 'drug_product' => ('drug', '의약품·치료제'),
        'bio_cdmo' || 'drug_cmo' => ('cdmo', '개발·생산 수탁'),
        'api_drug' => ('ingredient', '의약 원료'),
        'cro' ||
        'protein_analysis' ||
        'drug_research_platform' ||
        'lab_reagent' => ('research_service', '연구·임상 지원'),
        _ => (a.role, a.groupName ?? a.role),
      };
    } else if (a.industryKey == 'software') {
      (role, name) = switch (a.productKey) {
        'erp' => ('business:업무·산업 소프트웨어', '업무·산업 소프트웨어'),
        'security' => ('business:보안 소프트웨어·서비스', '보안 소프트웨어·서비스'),
        'ai_software' => ('business:AI·데이터 소프트웨어', 'AI·데이터 소프트웨어'),
        'commerce_platform' => ('business:인터넷 플랫폼', '인터넷 플랫폼'),
        'cloud' || 'hosting' => ('infrastructure', '클라우드·인프라 서비스'),
        'si' => ('it_service', 'IT 구축·운영'),
        _ => (a.role, a.groupName ?? a.role),
      };
    } else {
      return a;
    }
    return a.copyWith(role: role, groupName: name);
  }

  // Product-level evidence may choose a more precise sibling than the broad
  // registration. Shared labels share keys; evidence and product IDs are intact.
  static const _productGroups = <String, (String, String)>{
    'dram': ('semiconductor', '메모리 칩'),
    'nand': ('semiconductor', '메모리 칩'),
    'mcu': ('semiconductor', '시스템·아날로그 칩'),
    'isp': ('semiconductor', '시스템·아날로그 칩'),
    'ssd_controller': ('semiconductor', '시스템·아날로그 칩'),
    'deposition': ('semiconductor', '전공정 장비'),
    'etch': ('semiconductor', '전공정 장비'),
    'clean': ('semiconductor', '전공정 장비'),
    'bond': ('semiconductor', '후공정·검사 장비'),
    'tester': ('semiconductor', '후공정·검사 장비'),
    'wafer_optical': ('semiconductor', '후공정·검사 장비'),
    'substrate_optical': ('semiconductor', '후공정·검사 장비'),
    'substrate_repair': ('semiconductor', '후공정·검사 장비'),
    'socket': ('semiconductor', '검사 부품'),
    'probe_card': ('semiconductor', '검사 부품'),
    'auto_seat': ('auto', '차체·내외장 부품'),
    'auto_drive': ('auto', '구동·엔진 부품'),
    'auto_brake': ('auto', '조향·제동·현가 부품'),
    'auto_thermal': ('auto', '열관리·배기 부품'),
    'game_service': ('gaming', '게임'),
    'education_service': ('education', '교육'),
    'city_gas': ('utilities', '도시가스'),
    'lubricants': ('energy', '윤활유'),
    'paint': ('chemicals', '도료·잉크'),
    'adhesive': ('chemicals', '접착제'),
    'synthetic_resin': ('chemicals', '합성수지·고무'),
    'fertilizer': ('chemicals', '비료'),
    'crop_protection': ('chemicals', '농약'),
    'animal_feed': ('food', '사료'),
    'meat_processing': ('food', '육가공'),
    'dairy': ('food', '식용유·유제품'),
    'beverage': ('food', '음료'),
    'confectionery': ('food', '제과·제빵'),
    'steel_pipe': ('metals', '강관'),
    'steel_wire': ('metals', '철강 판재·선재'),
    'steel_products': ('metals', '철강'),
    'copper_products': ('metals', '비철금속 가공'),
    'advertising': ('business-services', '광고'),
    'engineering': ('construction', '설계·엔지니어링'),
    'robot': ('machinery', '로봇·자동화'),
    'agricultural_machine': ('machinery', '농기계'),
    'industrial_valve': ('machinery', '유압·펌프·밸브'),
    'life_insurance': ('finance', '생명보험'),
    'nonlife_insurance': ('finance', '손해·보증보험'),
    'music_business': ('content', '음악'),
    'electric_motor': ('electrical', '전동기·발전기·변압기'),
    'transformer': ('electrical', '전력기기'),
    'switchgear': ('electrical', '전력기기'),
    'ivd': ('medical', '체외진단'),
    'diagnostic_reagent': ('medical', '체외진단'),
    'dental': ('medical', '치과 기기·재료'),
    'medical_imaging': ('medical', '영상 진단'),
  };
  static const _aliases = <(String?, String?), String>{
    ('electronics', '생활가전'): '생활 가전',
    ('pharma', '동물 의약품'): '동물용 의약품',
    ('content', '웹툰·출판'): '출판·웹툰',
    ('content', '음악'): '음악·음원',
    ('content', '방송·채널'): '방송·스트리밍',
    ('content', '캐릭터·애니메이션'): '캐릭터·IP',
    ('energy', '바이오 연료'): '바이오연료',
    ('electrical', '조명 기기'): '조명',
    ('electrical', '태양광 장비'): '태양광 설비',
    ('electrical', '전원공급장치'): '전원·전력변환',
    ('cosmetics', '화장품 원료'): '화장품 원료·소재',
    ('education', '교육'): '교육 콘텐츠·서비스',
    ('building-materials', '창호·유리'): '유리·창호',
    ('utilities', '도시가스'): '가스 공급',
    ('household', '종이 포장'): '종이·포장',
    ('household', '위생용품'): '생활·위생용품',
    ('food', '과자·가공식품'): '제과·제빵',
    ('food', '사료'): '사료·첨가제',
    ('transport', '육상 운송·물류'): '육상 운송',
    ('medical', '의료용 소모품'): '의료 소모품·생체재료',
    ('semiconductor', '반도체 제조 장비'): '장비',

    ('medical', '치과'): '치과 기기·재료',
    ('medical', '정형외과·재활'): '정형외과·재활 기기',
    ('electronics', '전자기기'): '전자 기기',
    ('electronics', '통신장비·부품'): '통신 장비·부품',
    ('electronics', '기판'): '기판·전자조립',
    ('machinery', '디스플레이 장비'): '디스플레이 제조 장비',
    ('machinery', '디스플레이 제조장비'): '디스플레이 제조 장비',
    ('machinery', '공작기계'): '공작기계·공구',
    ('machinery', '금형'): '금형·정밀가공',
    ('machinery', '운반·물류 설비'): '물류·이송 장비',
    ('machinery', '산업용 로봇'): '로봇·자동화',
    ('semiconductor', '공정 지원장비'): '공정 지원 장비',
    ('battery', '배터리 제조장비'): '배터리 제조 장비',
    ('battery', '소재'): '배터리 소재',
    ('business-services', '광고'): '광고·마케팅',
    ('business-services', '광고 대행'): '광고·마케팅',
    ('business-services', '행사·전시'): '전시·행사',
    ('business-services', '신용조사·채권추심'): '신용평가·채권관리',
    ('construction', '인테리어·마감'): '인테리어',
    ('construction', '건축'): '주택·건축',
    ('cosmetics', '위탁개발·생산'): '화장품 위탁개발·생산',
    ('content', '영상 제작'): '영상 제작·배급',
    ('content', '영상 배급'): '영상 제작·배급',
    ('content', '영상 제작 지원'): '영상 제작·배급',
    ('content', '영화·영상'): '영상 제작·배급',
    ('content', '영상'): '영상 제작·배급',
    ('content', '공연·예술'): '공연·매니지먼트',
    ('content', '출판'): '출판·웹툰',
    ('transport', '물류·운송 지원'): '물류·하역',
    ('travel', '숙박'): '호텔·숙박',
    ('travel', '여행'): '여행·항공권',
    ('household', '가구'): '가구·침구',
    ('household', '목재·합판'): '목재·보드',
    ('household', '인쇄·복제'): '인쇄',
    ('shipbuilding', '선박 건조'): '조선',
    ('shipbuilding', '선박 부품'): '선박 엔진·기자재',
  };
}
