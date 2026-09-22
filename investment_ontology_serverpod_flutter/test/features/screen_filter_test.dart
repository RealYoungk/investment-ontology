import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_filter.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_presets.dart';

void main() {
  test('확장 필터는 URL에서 단위와 음수·0 경계를 보존한다', () {
    const f = ScreenFilter(
      payoutMax: 70,
      dividendYearsMin: 3,
      volumeMin: 10,
      volumeRatioMin: 2,
      marketCapMin: 1000,
      return3mMin: -10,
      return12mMin: 0,
      bandPositionMin: 90,
    );
    expect(ScreenFilter.fromQuery(Uri.parse(f.location).queryParameters), f);
    expect(f.conditionCount, 8);
    expect(f.copyWith(volumeRatioMin: () => null).conditionCount, 7);
    expect(
      ScreenFilter.fromQuery({
        'divyears': '4',
        'band': '101',
        'r3m': '-101',
        'vol': '-1',
      }),
      const ScreenFilter(),
    );
    expect(ScreenFilter.fromQuery({'divyears': '1.5'}), const ScreenFilter());
  });

  test('0과 음수 성장률은 보존하고 잘못된 숫자는 조건으로 쓰지 않는다', () {
    const filter = ScreenFilter(marginMin: 0, revenueGrowthMin: -5);
    expect(
      ScreenFilter.fromQuery(Uri.parse(filter.location).queryParameters),
      filter,
    );
    expect(
      ScreenFilter.fromQuery({'per': 'NaN', 'roe': 'Infinity', 'liq': '-1'}),
      const ScreenFilter(),
    );
  });

  test('프리셋은 기존 조건을 교체하고 시장과 URL 복원을 지원한다', () {
    const previous = ScreenFilter(
      market: Market.kosdaq,
      debtMax: 50,
      fcfMin: 8,
    );
    for (final preset in screenPresets) {
      final applied = preset.applyTo(previous);
      expect(applied.market, Market.kosdaq);
      expect(applied.sort, previous.sort);
      expect(applied.ascending, previous.ascending);
      expect(applied.debtMax, preset.filter.debtMax);
      expect(applied.fcfMin, preset.filter.fcfMin);
      expect(
        ScreenFilter.fromQuery(Uri.parse(applied.location).queryParameters),
        applied,
      );
      expect(preset.matches(applied), isTrue);
      expect(
        preset.matches(applied.copyWith(sort: ScreenSort.marketCap)),
        isTrue,
      );
      expect(
        preset.matches(applied.copyWith(liquidityMin: () => 999)),
        isFalse,
      );
    }
  });

  test('조건이 주소와 오간다', () {
    const filter = ScreenFilter(
      market: Market.kospi,
      perMax: 10,
      roeMin: 15.5,
      sort: ScreenSort.per,
      ascending: true,
    );
    expect(
      filter.location,
      '/screen?market=kospi&per=10&roe=15.5&sort=per&asc=1',
    );
    expect(
      ScreenFilter.fromQuery({
        'market': 'kospi',
        'per': '10',
        'roe': '15.5',
        'sort': 'per',
        'asc': '1',
      }),
      filter,
    );
  });

  test('부채비율·배당·FCF 조건도 주소에 담긴다', () {
    const filter = ScreenFilter(debtMax: 100, dividendMin: 3, fcfMin: 5);
    expect(filter.location, '/screen?debt=100&div=3&fcf=5');
    expect(
      ScreenFilter.fromQuery({'debt': '100', 'div': '3', 'fcf': '5'}),
      filter,
    );
    expect(filter.hasCondition, isTrue);
  });

  test('조건이 없으면 주소도 깨끗하다', () {
    expect(const ScreenFilter().location, '/screen');
    expect(ScreenFilter.fromQuery(const {}), const ScreenFilter());
    // 빈 값은 조건으로 치지 않는다.
    expect(
      ScreenFilter.fromQuery(const {'per': '', 'pbr': ''}).hasCondition,
      isFalse,
    );
  });
}
