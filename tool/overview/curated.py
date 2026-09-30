"""Small reviewed issuer exceptions. Evidence phrases must match the exported filing.
These are not the two original hand-drawn lessons (which retain UI precedence).
"""
NOTES = {
 '00877059': dict(models=['cdmo'], summary='제약사가 개발한 바이오의약품을 대신 생산하고, 세포주와 생산 공정을 개발하는 CDMO입니다.', evidence=['바이오의약품 위탁생산 및 세포주ㆍ공정 개발 서비스를 제공']),
 '00989619': dict(models=['biotech'], summary='정맥주사를 피하주사로 바꾸는 기술 등을 개발합니다. 제약사에 기술을 이전하고 계약금·개발 단계별 대가·판매 로열티를 받는 구조입니다.', evidence=['피하주사(Subcutaneous injection, SC) 제형으로 전환', '선급금(upfront), 마일스톤(milestone), 상업화 후 로열티(royalty)']),
 '00413046': dict(models=['pharma'], summary='자가면역질환·암 등에 쓰이는 바이오의약품을 개발하고 판매합니다. 램시마 등 바이오시밀러의 판매와 후속 제품 확대가 사업의 중심입니다.', evidence=['자가면역질환, 종양 등 질병의 치료에 사용되는 의약품을 개발 및 상업화', '램시마(CT-P13)']),
 '00145109': dict(models=['pharma'], summary='렉라자·안티푸라민·삐콤씨 등 의약품을 판매하고 신약을 개발합니다. 기존 의약품 판매와 신약 사업을 함께 갖고 있습니다.', evidence=['렉라자, 안티푸라민, 삐콤씨', 'R&D 부문']),
 '00842619': dict(models=['biotech','medical'], summary='암세포에 약물을 전달하는 ADC 등 신약 기술을 개발하고 기술이전으로 사업화합니다. 의료기기·소모품 판매사업도 함께 운영합니다.', evidence=['의료기기, 의료용 소모품 판매사업', '기술이전을 비롯한 사업화']),
 '00688996': dict(models=['financial_holding'], summary='KB국민은행을 비롯한 은행·증권·보험·카드 계열사를 보유한 금융지주입니다. 계열사가 벌어들이는 금융사업 이익이 연결 실적을 만듭니다.', evidence=['은행업, 금융투자업, 보험업, 여신전문업', 'KB국민은행']),
 '00126256': dict(models=['insurance'], summary='생명보험·연금보험·퇴직연금 등을 제공합니다. 보험 보장 서비스를 제공하며, 보험료 등으로 마련한 자산을 운용합니다.', evidence=['생명보험과 연금보험', '자산을 운용']),
 '00258801': dict(models=['platform','content'], summary='카카오톡을 중심으로 광고·커머스 서비스를 운영하고, 게임·음악·스토리 등 콘텐츠를 제공합니다.', evidence=['카카오톡', '광고, 커머스', '게임, 뮤직, 스토리']),
 '00164742': dict(models=['auto','credit'], summary='자동차와 부품을 만들어 판매합니다. 연결 자회사를 통해 차량 할부금융·리스 등 금융사업도 운영합니다.', evidence=['자동차와 자동차부품의 제조 및 판매', '차량할부금융']),
 '00159193': dict(models=['utilities'], summary='발전사에서 전기를 구매해 고객에게 판매합니다. 연결 자회사에는 원자력·화력발전과 전력 관련 서비스 사업이 포함됩니다.', evidence=['생산한 전력을 전력거래소에서 구입하여 일반 고객에게 판매', '원자력발전사업부문', '화력발전사업부문']),
}
NOTES['00126380'] = dict(models=['electronics','semiconductor'],
 summary='스마트폰·TV·가전 같은 완제품과, 메모리·모바일 칩·디스플레이 같은 부품을 함께 만듭니다. 소비자용 제품과 다른 제조사에 공급하는 부품은 수요와 수익 구조가 다릅니다.',
 evidence=['TV를 비롯하여 모니터, 냉장고, 세탁기, 에어컨, 스마트폰', 'DRAM, NAND Flash, 모바일AP', 'OLED 패널'],
 labels=['스마트폰','TV','가전','DRAM','NAND Flash','모바일AP','OLED 패널'])
