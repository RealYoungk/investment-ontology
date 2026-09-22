import 'screen_filter.dart';

/// A convenience for filling the existing inputs. Market and sort are unchanged.
class ScreenPreset {
  const ScreenPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
    required this.filter,
  });
  final String id;
  final String title;
  final String description;
  final String group;
  final ScreenFilter filter;

  ScreenFilter applyTo(ScreenFilter current) => filter.copyWith(
    market: () => current.market,
    sort: current.sort,
    ascending: current.ascending,
  );

  bool matches(ScreenFilter current) => applyTo(current) == current;

  static ScreenPreset? matching(ScreenFilter filter) =>
      screenPresets.where((p) => p.matches(filter)).firstOrNull;
}

// These are editable starting values, not backtested strategies or sector ranks.
const screenPresets = [
  ScreenPreset(
    id: 'value',
    group: '가격과 성장',
    title: '이익 대비 저렴한 주식',
    description:
        '기업 전체 가격이 최근 12개월 순이익의 12배 이하이고, 자기자본 대비 순이익이 10% 이상인 기업을 찾습니다.',
    filter: ScreenFilter(perMax: 12, roeMin: 10),
  ),
  ScreenPreset(
    id: 'profit',
    group: '수익성과 재무',
    title: '돈 잘 버는 회사',
    description: '매출 100원당 영업이익을 10원 이상 남기고, 자기자본 대비 순이익도 10% 이상인 기업을 찾습니다.',
    filter: ScreenFilter(roeMin: 10, marginMin: 10),
  ),
  ScreenPreset(
    id: 'growth',
    group: '가격과 성장',
    title: '더 팔고 더 버는 회사',
    description: '전년 같은 기간보다 매출과 영업이익이 모두 10% 이상 늘어난 기업을 찾습니다. 전년 적자에서 흑자로 바뀐 기업은 이 조건에 포함되지 않습니다.',
    filter: ScreenFilter(revenueGrowthMin: 10, opGrowthMin: 10),
  ),
  ScreenPreset(
    id: 'dividend',
    group: '배당과 현금',
    title: '부채 부담 낮은 배당주',
    description: '최근 연간 현금배당금총액이 기업 전체 가격의 3% 이상이고, 부채가 자기자본보다 많지 않은 기업을 찾습니다. 앞으로 받을 배당을 보장하는 조건은 아닙니다.',
    filter: ScreenFilter(dividendMin: 3, debtMax: 100),
  ),
  ScreenPreset(
    id: 'cash',
    group: '배당과 현금',
    title: '투자하고도 현금이 남는 회사',
    description: '영업에서 들어온 현금에서 유형자산 취득액을 뺀 금액이 기업 전체 가격의 5% 이상이고, 부채가 자기자본보다 많지 않은 기업을 찾습니다.',
    filter: ScreenFilter(fcfMin: 5, debtMax: 100),
  ),
  ScreenPreset(
    id: 'low-debt',
    group: '수익성과 재무',
    title: '부채 적은 흑자 기업',
    description:
        '부채가 자기자본의 절반 이하이고, 자기자본 대비 순이익이 5% 이상인 기업을 찾습니다. 부채를 더 엄격하게 보는 조건입니다.',
    filter: ScreenFilter(debtMax: 50, roeMin: 5),
  ),
  ScreenPreset(
    id: 'asset-value',
    group: '가격과 성장',
    title: '자산 대비 저렴한 주식',
    description: '기업 전체 가격이 장부상 자기자본 이하(PBR 1배 이하)이고, PER 15배 이하·ROE 5% 이상인 기업을 찾습니다. 자산의 실제 매각가를 뜻하지는 않습니다.',
    filter: ScreenFilter(pbrMax: 1, perMax: 15, roeMin: 5),
  ),
  ScreenPreset(
    id: 'value-growth',
    group: '가격과 성장',
    title: '가격 부담 낮은 성장주',
    description: '매출과 영업이익이 전년 같은 기간보다 각각 10% 이상 늘면서, PER은 20배 이하인 기업을 찾습니다. 향후 성장을 예측하는 조건은 아닙니다.',
    filter: ScreenFilter(perMax: 20, revenueGrowthMin: 10, opGrowthMin: 10),
  ),
  ScreenPreset(
    id: 'dividend-history',
    group: '배당과 현금',
    title: '3년 배당을 이어온 회사',
    description: '최근 수집한 연간 공시에서 3년 모두 현금배당이 확인되고, 배당수익률 3% 이상·배당성향 70% 이하인 기업을 찾습니다. 결과의 배당 기준연도를 함께 확인하세요.',
    filter: ScreenFilter(dividendMin: 3, payoutMax: 70, dividendYearsMin: 3),
  ),
  ScreenPreset(
    id: 'growing-dividend',
    group: '배당과 현금',
    title: '배당도 주고 실적도 성장',
    description: '3년 배당 이력과 배당수익률 2% 이상·배당성향 60% 이하를 확인하고, 매출과 영업이익이 전년 대비 각각 5% 이상 늘어난 기업을 찾습니다. 배당금 자체의 증가를 뜻하지는 않습니다.',
    filter: ScreenFilter(
      dividendMin: 2,
      payoutMax: 60,
      dividendYearsMin: 3,
      revenueGrowthMin: 5,
      opGrowthMin: 5,
    ),
  ),
  ScreenPreset(
    id: 'volume-surge',
    group: '주가와 거래',
    title: '평소보다 거래가 활발한 주식',
    description: '마지막 수집 거래일의 거래량이 직전 20거래일 평균의 2배 이상·10만 주 이상이고, 최근 한 달 하루 평균 거래대금이 10억원 이상인 종목을 찾습니다. 실시간 거래량이 아닙니다.',
    filter: ScreenFilter(volumeRatioMin: 2, volumeMin: 10, liquidityMin: 10),
  ),
  ScreenPreset(
    id: 'price-momentum',
    group: '주가와 거래',
    title: '최근 흐름이 강한 주식',
    description: '대표 종목 주가가 3개월·12개월 전보다 각각 10% 이상 올랐고, 최근 한 달 하루 평균 거래대금이 10억원 이상인 기업을 찾습니다. 매일 연속 상승했다는 뜻은 아닙니다.',
    filter: ScreenFilter(return3mMin: 10, return12mMin: 10, liquidityMin: 10),
  ),
  ScreenPreset(
    id: 'near-high',
    group: '주가와 거래',
    title: '연중 높은 가격대의 주식',
    description: '최근 1년 종가 범위의 상위 10% 구간(52주 가격 위치 90 이상)에 있고, 3개월 등락률 10% 이상·평균 거래대금 10억원 이상인 기업을 찾습니다. 신고가 돌파를 뜻하지는 않습니다.',
    filter: ScreenFilter(
      bandPositionMin: 90,
      return3mMin: 10,
      liquidityMin: 10,
    ),
  ),
];

const screenPresetGroups = ['가격과 성장', '수익성과 재무', '배당과 현금', '주가와 거래'];
