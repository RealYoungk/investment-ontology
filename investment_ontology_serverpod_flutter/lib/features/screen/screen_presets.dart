import 'screen_filter.dart';

/// A convenience for filling the existing inputs. Market and sort are unchanged.
class ScreenPreset {
  const ScreenPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.filter,
  });
  final String id;
  final String title;
  final String description;
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
    title: '이익 대비 저렴한 주식',
    description: '기업 전체 가격이 연간 순이익의 12배 이하이고, 자기자본 대비 순이익이 10% 이상인 기업을 찾습니다.',
    filter: ScreenFilter(perMax: 12, roeMin: 10),
  ),
  ScreenPreset(
    id: 'profit',
    title: '돈 잘 버는 회사',
    description: '매출 100원당 영업이익을 10원 이상 남기고, 자기자본 대비 순이익도 10% 이상인 기업을 찾습니다.',
    filter: ScreenFilter(roeMin: 10, marginMin: 10),
  ),
  ScreenPreset(
    id: 'growth',
    title: '더 팔고 더 버는 회사',
    description: '전년 같은 기간보다 매출과 영업이익이 모두 10% 이상 늘어난 기업을 찾습니다. 전년 적자에서 흑자로 바뀐 기업은 이 조건에 포함되지 않습니다.',
    filter: ScreenFilter(revenueGrowthMin: 10, opGrowthMin: 10),
  ),
  ScreenPreset(
    id: 'dividend',
    title: '부채 부담 낮은 배당주',
    description: '주가 대비 공시된 배당금이 3% 이상이고, 부채가 자기자본보다 많지 않은 기업을 찾습니다. 앞으로 받을 배당을 보장하는 조건은 아닙니다.',
    filter: ScreenFilter(dividendMin: 3, debtMax: 100),
  ),
  ScreenPreset(
    id: 'cash',
    title: '투자하고도 현금이 남는 회사',
    description: '영업에서 들어온 현금에서 유형자산 취득액을 뺀 금액이 기업 전체 가격의 5% 이상이고, 부채가 자기자본보다 많지 않은 기업을 찾습니다.',
    filter: ScreenFilter(fcfMin: 5, debtMax: 100),
  ),
  ScreenPreset(
    id: 'low-debt',
    title: '부채 적은 흑자 기업',
    description:
        '부채가 자기자본의 절반 이하이고, 자기자본 대비 순이익이 5% 이상인 기업을 찾습니다. 부채를 더 엄격하게 보는 조건입니다.',
    filter: ScreenFilter(debtMax: 50, roeMin: 5),
  ),
];
