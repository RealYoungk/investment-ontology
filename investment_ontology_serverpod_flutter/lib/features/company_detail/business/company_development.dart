/// Curated, dated research snapshots. Never infer issuer events from products.
class CompanyDevelopment {
  const CompanyDevelopment({
    this.contextTitle = '데이터센터·광통신 배경 이해하기',
    this.roleTitle = 'CPO란?',
    required this.headline,
    required this.change,
    required this.role,
    required this.contextSteps,
    required this.sourceLabel,
    required this.sourceUrl,
  });
  final String headline, change, role, sourceLabel, sourceUrl;
  final String contextTitle, roleTitle;
  final List<({String title, String body})> contextSteps;

  static CompanyDevelopment? forCompany(String corpCode) =>
      _snapshots[corpCode];
  static const _snapshots = <String, CompanyDevelopment>{
    '00765569': CompanyDevelopment(
      headline: 'AI 반도체 기판이 정교해질수록 커지는 검사·수리 수요',
      change: 'AI 칩에 쓰이는 기판은 회로가 더 촘촘하고 여러 층으로 복잡해집니다. 기가비스는 미세한 불량을 찾고 고치는 장비를 팝니다. 기판 업체의 증설과 고성능 장비 전환이 수주 기회로 이어집니다.',
      contextTitle: 'AI 반도체와 기가비스의 연결고리',
      roleTitle: '장비 매출로 이어지는 지점',
      role: '기판 제조사가 생산라인을 늘리거나 더 미세한 회로를 만들기 위해 설비를 바꿀 때 장비를 발주합니다. 고성능 신제품과 검사·수리를 연결한 자동화 설비도 공급합니다.',
      contextSteps: [
        (
          title: 'AI 칩 아래의 기판도 고도화',
          body: '고성능 칩과 외부 회로를 연결하는 기판은 더 넓어지고, 층수와 회로 밀도가 높아집니다.',
        ),
        (
          title: '작은 불량을 찾고, 버릴 기판을 줄이기',
          body: 'AOI는 회로 결함을 검사하고, AOR은 불필요하게 붙은 구리 등을 레이저로 제거합니다. 불량 기판 일부를 다시 쓸 수 있게 해 정상 제품 비율인 수율을 높입니다.',
        ),
      ],
      sourceLabel: '2026년 1분기보고서 사업의 내용 · 2026-09-30 확인',
      sourceUrl: 'https://kind.krx.co.kr/external/2026/05/15/001382/20260515003007/11013.htm',
    ),
    '00317210': CompanyDevelopment(
      headline: 'AI 데이터센터의 광통신 투자와 연결된 장비 사업',
      contextSteps: [
        (
          title: 'AI는 여러 칩이 함께 계산합니다',
          body: '데이터센터 안의 많은 연산 칩이 작업을 나눠 맡습니다. 계산 결과를 주고받는 통신이 느리면 다음 계산도 기다려야 합니다.',
        ),
        (
          title: '많은 데이터를 빛으로 보냅니다',
          body: '서버 사이에 데이터를 빠르게 보내기 위해 전기 신호를 빛으로 바꾸고 광섬유로 전달합니다. 속도와 거리가 늘수록 통신에 쓰는 전력도 중요한 문제가 됩니다.',
        ),
        (
          title: '그 광통신 부품을 만드는 장비입니다',
          body: '빛이 정확히 전달되려면 작은 렌즈와 광섬유의 위치를 정밀하게 맞춰야 합니다. ADS테크는 이 정렬·접합·검사 공정에 쓰이는 장비를 팝니다.',
        ),
      ],
      change: 'AI 데이터센터가 늘면 서버 사이에서 빛으로 데이터를 주고받는 광통신 부품의 수요도 커질 수 있습니다. 성호전자는 ADS테크 인수로, 이 부품을 정밀하게 조립·검사하는 장비 사업에 진출했습니다.',
      role: 'CPO는 빛으로 신호를 바꾸는 부품을 통신용 반도체와 같은 패키지에 넣어 전기 신호가 이동하는 거리를 줄이는 방식입니다. 전기 신호의 이동 거리를 줄여 통신에 쓰는 전력을 낮추려는 기술입니다.',
      sourceLabel: '2026 반기보고서 기준 · 9월 29일 확인',
      sourceUrl: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260814003108',
    ),
  };
}
