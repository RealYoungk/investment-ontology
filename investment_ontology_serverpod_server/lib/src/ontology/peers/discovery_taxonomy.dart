/// Alfinder navigation categories. These are not official GICS assignments.
/// Prefixes describe registered KSIC activities; no product is inferred from a
/// customer, subsidiary or a company's name. More-specific prefixes win.
abstract final class DiscoveryTaxonomy {
  static const categories = <String, (String, List<String>)>{
    'semiconductor': ('반도체', ['261', '29271']),
    'software': ('소프트웨어·IT 서비스', ['582', '62', '63']),
    'electronics': ('전자부품·IT 기기', ['26', '285']),
    'gaming': ('게임', ['5821']),
    'battery': ('배터리', ['282']),
    'cosmetics': ('화장품', ['20423']),
    'instruments': ('측정·광학 기기', ['27']),
    'telecom': ('통신', ['61']),
    'pharma': ('제약·바이오 의약품', ['21', '70113']),
    'medical': ('의료기기·의료 서비스', ['271', '86', '21301']),
    'auto': ('자동차·부품', ['30']),
    'shipbuilding': ('조선', ['311']),
    'aerospace': ('항공·우주', ['313']),
    'rail': ('철도·기타 운송장비', ['312', '319', '31']),
    'machinery': ('기계·생산 장비', ['29', '34']),
    'electrical': ('전기장비', ['28']),
    'chemicals': ('화학·소재', ['20', '22']),
    'metals': ('철강·금속', ['24', '25']),
    'building-materials': ('유리·시멘트·건축 소재', ['23']),
    'energy': ('에너지·자원', ['05', '06', '07', '08', '19']),
    'utilities': ('전기·가스·수도', ['35', '36']),
    'environment': ('환경·재활용', ['37', '38', '39']),
    'food': ('식품·음료', ['10', '11', '12']),
    'agriculture': ('농림·수산', ['01', '02', '03']),
    'fashion': ('의류·섬유·신발', ['13', '14', '15']),
    'household': ('생활용품·가구', ['16', '17', '18', '32', '33']),
    'retail': ('유통·무역', ['45', '46', '47']),
    'transport': ('운송·물류', ['49', '50', '51', '52']),
    'travel': ('여행·숙박·외식', ['55', '56', '752']),
    'content': ('미디어·콘텐츠', ['581', '58', '59', '60', '90']),
    'leisure': ('스포츠·여가', ['91']),
    'finance': ('금융·보험', ['64', '65', '66']),
    'holdings': ('지주회사', ['64992']),
    'real-estate': ('부동산', ['68']),
    'construction': ('건설·인프라', ['41', '42']),
    'research': ('연구·엔지니어링', ['70', '72']),
    'business-services': ('기업 서비스', ['71', '73', '74', '75', '76']),
    'education': ('교육', ['85']),
    'other-services': (
      '공공·생활 서비스',
      ['84', '87', '94', '95', '96', '97', '98', '99'],
    ),
  };

  static (String, String) category(String? code) {
    if (code == null) return ('unclassified', '업종 확인이 필요한 기업');
    String? key;
    var length = 0;
    for (final entry in categories.entries) {
      for (final prefix in entry.value.$2) {
        if (code.startsWith(prefix) && prefix.length > length) {
          key = entry.key;
          length = prefix.length;
        }
      }
    }
    return key == null
        ? ('unclassified', '업종 확인이 필요한 기업')
        : (key, categories[key]!.$1);
  }

  static const names = <String, String>{
    '211': '의약 원료·바이오 제제',
    '212': '완제 의약품',
    '213': '의료용품',
    '261': '반도체 소자',
    '262': '전자부품',
    '263': '컴퓨터·주변기기',
    '264': '통신·방송장비',
    '265': '영상·음향기기',
    '266': '저장 매체',
    '271': '의료기기',
    '272': '측정·시험·항해 기기',
    '273': '광학기기',
    '274': '시계',
    '281': '발전·전력변환·제어 장치',
    '282': '배터리',
    '283': '전선·케이블',
    '284': '조명',
    '285': '가전',
    '289': '기타 전기장비',
    '291': '범용 기계',
    '292': '산업별 생산 장비',
    '29271': '반도체 제조 장비',
    '301': '완성차',
    '302': '차체·트레일러',
    '303': '자동차 부품',
    '311': '선박·보트',
    '312': '철도차량·부품',
    '313': '항공기·우주선·부품',
    '319': '기타 운송장비',
    '581': '출판',
    '582': '소프트웨어',
    '591': '영화·영상',
    '592': '음악·오디오',
    '601': '라디오',
    '602': 'TV 방송',
    '611': '유선 통신',
    '612': '무선·위성 통신',
    '620': 'IT 개발·운영',
    '631': '데이터 처리·호스팅',
    '639': '정보 서비스',
    '641': '은행·저축기관',
    '642': '신탁·집합투자',
    '649': '기타 금융',
    '64992': '지주회사',
    '651': '보험',
    '652': '재보험',
    '653': '연금·공제',
    '661': '금융 지원 서비스',
    '662': '보험·연금 지원 서비스',
    '701': '자연과학·공학 연구',
    '702': '사회과학 연구',
    '721': '설계·엔지니어링',
    '729': '시험·검사·기술 서비스',
  };

  static String label(String code, String official) =>
      names[code] ??
      official
          .replaceAll(' 제조업', '')
          .replaceAll(' 도매업', ' 도매')
          .replaceAll(' 소매업', ' 소매')
          .replaceAll(' 및 ', '·')
          .replaceAll('그 외 기타 ', '기타 ');
}
