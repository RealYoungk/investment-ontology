/// Searchable destinations, using existing route/filter contracts.
typedef SearchDestination = ({String title, String detail, String location});
List<SearchDestination> searchDestinations(String query) {
  String normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final q = normalize(query);
  if (q.isEmpty) return [];
  const entries = <SearchDestination>[
    (title: '시장', detail: '코스피 코스닥 지수 시가총액 업종', location: '/market'),
    (title: '시장 지표', detail: '매크로 경제 지표', location: '/market/indicators'),
    (
      title: '원/달러 환율',
      detail: '환율 달러 원달러 USD KRW',
      location: '/market/indicators?series=EXIM_USDKRW',
    ),
    (
      title: '미국 국채 2년',
      detail: '미국 금리 국채 채권 단기금리 DGS2',
      location: '/market/indicators?series=DGS2',
    ),
    (
      title: '미국 국채 10년',
      detail: '미국 금리 국채 채권 장기금리 DGS10',
      location: '/market/indicators?series=DGS10',
    ),
    (
      title: '브렌트 원유',
      detail: '원유 유가 오일 브렌트 Brent',
      location: '/market/indicators?series=DCOILBRENTEU',
    ),
    (
      title: 'WTI 원유',
      detail: '원유 유가 오일 WTI',
      location: '/market/indicators?series=DCOILWTICO',
    ),
    (title: '기업', detail: '상장기업 종목 목록', location: '/companies'),
    (
      title: '종목 발굴',
      detail: '기업 찾기 스크리너 재무 조건 PER PBR ROE FCF',
      location: '/screen',
    ),
    (title: '매출이 늘어난 기업', detail: '매출 성장 성장률', location: '/screen?rgrow=10'),
    (title: '이익을 남기는 기업', detail: '수익성 영업이익률', location: '/screen?margin=10'),
    (title: '배당을 주는 기업', detail: '배당 배당수익률', location: '/screen?div=3'),
    (title: '하는 일로 기업 찾기', detail: '산업 업종 반도체 제품 공정', location: '/industries'),
    (
      title: '자동차 기업',
      detail: '자동차 자동차부품',
      location: '/companies?section=C&division=30',
    ),
    (title: '기업 비교', detail: '재무 수익성 밸류에이션 비교', location: '/compare'),
    (title: '관계망', detail: '주주 임원 고객 공급 출자 연결', location: '/graph'),
    (title: '관심종목', detail: '관심기업 즐겨찾기 워치리스트', location: '/watchlist'),
    (title: '알림함', detail: '알림 새소식 공시', location: '/notifications'),
    (title: '서비스 소개', detail: '사용법 도움말 출처', location: '/about'),
  ];
  final found = entries
      .where((e) => normalize('${e.title} ${e.detail}').contains(q))
      .toList();
  int rank(SearchDestination e) => normalize(e.title) == q
      ? 0
      : normalize(e.title).startsWith(q)
      ? 1
      : 2;
  found.sort((a, b) => rank(a).compareTo(rank(b)));
  return found.take(8).toList();
}
