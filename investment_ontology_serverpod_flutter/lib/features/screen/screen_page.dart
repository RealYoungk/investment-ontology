import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';
import 'screen_filter.dart';
import 'company_discovery_navigation.dart';
import 'screen_presets.dart';

typedef ScreenFetch = Future<ScreenPage> Function(
  ScreenFilter filter, {
  int offset,
  int limit,
});

Future<ScreenPage> fetchScreen(
  ScreenFilter f, {
  int offset = 0,
  int limit = 10,
}) => client.screen.list(
  market: f.market,
  perMax: f.perMax,
  pbrMax: f.pbrMax,
  roeMin: f.roeMin,
  operatingMarginMin: f.marginMin,
  debtRatioMax: f.debtMax,
  dividendYieldMin: f.dividendMin,
  fcfYieldMin: f.fcfMin,
  revenueGrowthMin: f.revenueGrowthMin,
  operatingIncomeGrowthMin: f.opGrowthMin,
  avgTradingValueMin: f.liquidityMin == null
      ? null
      : BigInt.from((f.liquidityMin! * 100000000).round()),
  dividendPayoutMax: f.payoutMax,
  dividendYearsMin: f.dividendYearsMin?.toInt(),
  volumeMin: f.volumeMin == null
      ? null
      : BigInt.from((f.volumeMin! * 10000).round()),
  volumeRatioMin: f.volumeRatioMin,
  marketCapMin: f.marketCapMin == null
      ? null
      : BigInt.from((f.marketCapMin! * 100000000).round()),
  return3mMin: f.return3mMin,
  return12mMin: f.return12mMin,
  bandPositionMin: f.bandPositionMin,
  sort: f.sort,
  ascending: f.ascending,
  offset: offset,
  limit: limit,
);

/// 스크리너: 재무·시세로 기업을 거른다.
///
/// 지표는 저장하지 않고 서버가 조회할 때 계산한다. 계산에 쓴 원천 값(매출·영업이익·
/// 순이익·자본)을 같이 보여 줘서 숫자의 근거를 볼 수 있게 한다.
class ScreenerPage extends StatefulWidget {
  const ScreenerPage({
    super.key,
    required this.filter,
    this.fetch = fetchScreen,
  });

  final ScreenFetch fetch;

  /// 조건은 주소에 남는다 (`/screen?per=10&roe=15`). 북마크·뒤로가기가 된다.
  final ScreenFilter filter;

  @override
  State<ScreenerPage> createState() => _ScreenerPageState();
}

class _ScreenerPageState extends State<ScreenerPage> {
  ScreenPage? _page;
  Object? _error;
  bool _loading = false;
  bool _editingConditions = false;
  Timer? _debounce;
  ScreenFilter? _pending;
  int _inputRevision = 0;
  int _seq = 0;
  int _offset = 0;
  static const _pageSize = 10;

  ScreenFilter get _f => _pending ?? widget.filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ScreenerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _debounce?.cancel();
      _pending = null;
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// 조건을 주소에 반영한다. 조건을 바꿀 때마다 방문 기록이 쌓이지 않게 한다.
  void _apply(ScreenFilter next) {
    _debounce?.cancel();
    _pending = null;
    if (next == widget.filter) return;
    Router.neglect(context, () => context.go(next.location));
  }

  void _applySoon(ScreenFilter next) {
    _debounce?.cancel();
    _pending = next;
    _debounce = Timer(const Duration(milliseconds: 300), () => _apply(next));
  }

  Future<void> _load({int offset = 0}) async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final p = await widget.fetch(
        widget.filter,
        offset: offset,
        limit: _pageSize,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _page = p;
        _offset = offset;
        _error = null;
      });
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  static const _conditionLabels = <String, (String, String)>{
    'per': ('PER', '배 이하'),
    'pbr': ('PBR', '배 이하'),
    'roe': ('ROE', '% 이상'),
    'margin': ('영업이익률', '% 이상'),
    'rgrow': ('매출 성장률', '% 이상'),
    'ogrow': ('영업이익 성장률', '% 이상'),
    'debt': ('부채비율', '% 이하'),
    'div': ('배당수익률', '% 이상'),
    'fcf': ('FCF 수익률', '% 이상'),
    'liq': ('거래대금', '억원 이상'),
    'payout': ('배당성향', '% 이하'),
    'divyears': ('연속 배당', '년 이상'),
    'vol': ('거래량', '만주 이상'),
    'volratio': ('평소 대비 거래량', '배 이상'),
    'cap': ('시가총액', '억원 이상'),
    'r3m': ('3개월 등락률', '% 이상'),
    'r12m': ('12개월 등락률', '% 이상'),
    'band': ('52주 가격 위치', '% 이상'),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final page = _page;
    return PageFrame(
      children: [
        const CompanyDiscoveryNavigation(discovery: false),
        const SizedBox(height: AppSpace.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('어떤 회사를 찾고 있나요?', style: t.sectionTitle),
            const SizedBox(height: AppSpace.md),
            for (final group in screenPresetGroups)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final choices = Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final preset in screenPresets.where(
                          (p) => p.group == group,
                        ))
                          Semantics(
                            selected: preset.matches(_f),
                            child: AppButton(
                              key: ValueKey('preset-${preset.id}'),
                              label: preset.title,
                              variant: preset.matches(_f)
                                  ? AppButtonVariant.primary
                                  : AppButtonVariant.secondary,
                              onPressed: () {
                                setState(() => _inputRevision++);
                                _apply(preset.applyTo(_f));
                              },
                            ),
                          ),
                      ],
                    );
                    final label = Text(
                      group,
                      style: t.body(12, color: c.textSecondary),
                    );
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          const SizedBox(height: AppSpace.xs),
                          choices,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: label,
                          ),
                        ),
                        Expanded(child: choices),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: _editingConditions ? '조건 접기' : '조건 바꾸기',
                  icon: _editingConditions ? Icons.expand_less : Icons.tune,
                  variant: AppButtonVariant.link,
                  onPressed: () => setState(
                    () => _editingConditions = !_editingConditions,
                  ),
                ),
                Text(
                  _f.hasCondition
                      ? '조건 ${_f.conditionCount}개 적용'
                      : '조건 없이 전체 보기',
                  style: t.body(12, color: c.textSecondary),
                ),
                if (ScreenPreset.matching(_f) case final preset?)
                  Tooltip(
                    message: preset.description,
                    triggerMode: TooltipTriggerMode.tap,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.info_outline, size: 20),
                    ),
                  ),
                const Tooltip(
                  message: '찾기 예시는 미리 정해 둔 조건이에요. 선택하면 기존 숫자 조건을 바꿔요. 원하는 값으로 수정할 수 있어요. 최신 자료의 연결재무제표를 먼저 사용하고, 자료가 부족하면 가능한 경우 별도재무제표로 보완해요. 조건에 필요한 숫자가 없는 기업은 결과에서 빠져요. 지배주주 값이 없으면 전체 값을 써요. 금융업은 회계 구조가 달라 다른 업종과 단순 비교하기 어려워요.',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.help_outline, size: 20),
                  ),
                ),
              ],
            ),
            if (_f.hasCondition) ...[
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final entry in Uri.parse(
                    _f.location,
                  ).queryParameters.entries)
                    if (_conditionLabels[entry.key] case final label?)
                      InputChip(
                        label: Text('${label.$1} ${entry.value}${label.$2}'),
                        onDeleted: () {
                          final query = Map<String, String>.from(
                            Uri.parse(_f.location).queryParameters,
                          )..remove(entry.key);
                          setState(() => _inputRevision++);
                          _apply(ScreenFilter.fromQuery(query));
                        },
                      ),
                ],
              ),
            ],
            if (_editingConditions) ...[
              SectionLabel(
                _f.conditionCount == 0
                    ? '조건 · 비우면 제한 없음'
                    : '조건 ${_f.conditionCount}개 적용',
                trailing: _f.hasCondition
                    ? AppButton(
                        label: '조건 지우기',
                        icon: Icons.close,
                        variant: AppButtonVariant.link,
                        tone: c.accent,
                        onPressed: () {
                          setState(() => _inputRevision++);
                          _apply(
                            ScreenFilter(
                              market: _f.market,
                              sort: _f.sort,
                              ascending: _f.ascending,
                            ),
                          );
                        },
                      )
                    : null,
              ),
              const SizedBox(height: AppSpace.sm),
              _FilterGroup(
                label: '가격과 이익',
                children: [
                  _NumberField(
                    key: ValueKey('per-$_inputRevision'),
                    min: 0,
                    label: 'PER 이하',
                    help: '시가총액 ÷ 최근 12개월 순이익입니다. 연결은 지배주주 몫을 우선하며, 없으면 전체 값을 사용합니다. 순이익이 0 이하면 계산하지 않습니다.',
                    value: _f.perMax,
                    onChanged: (v) => _applySoon(_f.copyWith(perMax: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('pbr-$_inputRevision'),
                    min: 0,
                    label: 'PBR 이하',
                    help: '시가총액 ÷ 최근 보고서의 자본입니다. 연결은 지배주주 몫을 우선하며, 없으면 자본총계를 사용합니다.',
                    value: _f.pbrMax,
                    onChanged: (v) => _applySoon(_f.copyWith(pbrMax: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('div-$_inputRevision'),
                    min: 0,
                    label: '배당수익률 % 이상',
                    help: '최근 연간 공시의 현금배당금총액 ÷ 현재 시가총액 × 100입니다. 공시 당시 배당수익률과 다를 수 있습니다.',
                    value: _f.dividendMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(dividendMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('fcf-$_inputRevision'),
                    label: 'FCF 수익률 % 이상',
                    help: '최근 12개월 (영업활동 현금흐름 − 유형자산 취득) ÷ 시가총액 × 100입니다. 금융업은 현금흐름의 성격이 다릅니다.',
                    value: _f.fcfMin,
                    onChanged: (v) => _applySoon(_f.copyWith(fcfMin: () => v)),
                  ),
                ],
              ),
              _FilterGroup(
                label: '수익성 · 성장',
                children: [
                  _NumberField(
                    key: ValueKey('roe-$_inputRevision'),
                    label: 'ROE % 이상',
                    help:
                        '최근 12개월 순이익 ÷ 최근 보고서의 자본 × 100입니다. 연결은 지배주주 몫을 우선합니다.',
                    value: _f.roeMin,
                    onChanged: (v) => _applySoon(_f.copyWith(roeMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('margin-$_inputRevision'),
                    label: '영업이익률 % 이상',
                    help: '최근 12개월 영업이익 ÷ 매출액 × 100입니다.',
                    value: _f.marginMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(marginMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('rgrow-$_inputRevision'),
                    label: '매출 성장률 % 이상',
                    help: '올해 누적 매출과 전년 같은 기간을 비교합니다.',
                    value: _f.revenueGrowthMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(revenueGrowthMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('ogrow-$_inputRevision'),
                    label: '영업이익 성장률 % 이상',
                    help:
                        '올해 누적 영업이익과 전년 같은 기간을 비교합니다. 전년 이익이 0 이하이면 계산하지 않습니다.',
                    value: _f.opGrowthMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(opGrowthMin: () => v)),
                  ),
                ],
              ),
              _FilterGroup(
                label: '안정성 · 유동성',
                children: [
                  _NumberField(
                    key: ValueKey('debt-$_inputRevision'),
                    min: 0,
                    label: '부채비율 % 이하',
                    help: '최근 보고서의 부채총계 ÷ 자본총계 × 100입니다.',
                    value: _f.debtMax,
                    onChanged: (v) => _applySoon(_f.copyWith(debtMax: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('liq-$_inputRevision'),
                    min: 0,
                    label: '거래대금 억원 이상',
                    help: '최근 한 달의 하루 평균 거래대금입니다.',
                    value: _f.liquidityMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(liquidityMin: () => v)),
                  ),
                ],
              ),
              _FilterGroup(
                label: '배당 더 보기',
                last: false,
                children: [
                  _NumberField(
                    key: ValueKey('payout-$_inputRevision'),
                    label: '배당성향 % 이하',
                    help: '최근 연간 공시값입니다. 이익 중 배당으로 지급한 비율이며, 적자·미수집은 제외됩니다.',
                    min: 0,

                    integer: false,
                    value: _f.payoutMax,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(payoutMax: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('divyears-$_inputRevision'),
                    label: '확인된 연속 배당 년 이상',
                    help: '최근 연간 공시의 당기·전기·전전기 현금배당금총액을 확인합니다. 최대 3년, 빈 값은 연속으로 세지 않습니다.',
                    min: 0,
                    max: 3,
                    integer: true,
                    value: _f.dividendYearsMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(dividendYearsMin: () => v)),
                  ),
                ],
              ),
              _FilterGroup(
                label: '규모 · 거래',
                last: false,
                children: [
                  _NumberField(
                    key: ValueKey('cap-$_inputRevision'),
                    label: '시가총액 억원 이상',
                    help: '기업에 연결된 종목의 최근 시가총액 합계입니다.',
                    min: 0,

                    integer: false,
                    value: _f.marketCapMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(marketCapMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('vol-$_inputRevision'),
                    label: '기준일 거래량 만주 이상',
                    help: '대표 종목의 마지막 수집 거래일 거래량입니다. 거래대금과 단위가 다릅니다.',
                    min: 0,

                    integer: false,
                    value: _f.volumeMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(volumeMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('volratio-$_inputRevision'),
                    label: '평소 대비 거래량 배 이상',
                    help: '기준일 거래량 ÷ 직전 20거래일 평균. 2배는 평소의 두 배입니다. 이력 부족·주식수 큰 변동은 제외됩니다.',
                    min: 0,

                    integer: false,
                    value: _f.volumeRatioMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(volumeRatioMin: () => v)),
                  ),
                ],
              ),
              _FilterGroup(
                label: '주가 흐름',
                last: true,
                children: [
                  _NumberField(
                    key: ValueKey('r3m-$_inputRevision'),
                    label: '3개월 등락률 % 이상',
                    help: '대표 종목의 3개월 가격 변화입니다. 음수도 입력할 수 있습니다.',
                    min: -100,

                    integer: false,
                    value: _f.return3mMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(return3mMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('r12m-$_inputRevision'),
                    label: '12개월 등락률 % 이상',
                    help: '대표 종목의 12개월 가격 변화입니다. 일별 연속 상승을 뜻하지 않습니다.',
                    min: -100,

                    integer: false,
                    value: _f.return12mMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(return12mMin: () => v)),
                  ),
                  _NumberField(
                    key: ValueKey('band-$_inputRevision'),
                    label: '52주 가격 위치 % 이상',
                    help: '최근 1년 종가 범위에서 최저 0, 최고 100입니다. 90은 범위의 상위 10% 구간이며 신고가까지 거리와 다릅니다.',
                    min: 0,
                    max: 100,
                    integer: false,
                    value: _f.bandPositionMin,
                    onChanged: (v) =>
                        _applySoon(_f.copyWith(bandPositionMin: () => v)),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: context.shape.borderRadius,
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    page == null ? '기업 목록' : '${formatCount(page.total)}개 기업',
                    style: t.sectionTitle,
                  ),
                  if (page != null)
                    Text(
                      '${page.items.isEmpty ? '' : '${_offset + 1}–${_offset + page.items.length}번째'}'
                      '${page.baseDate == null ? '' : ' · 시세 ${formatDate(page.baseDate)}'}',
                      style: t.numeric(12, color: c.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.sm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppToggleGroup<Market?>(
                    label: '시장',
                    value: _f.market,
                    options: const {
                      null: '전체',
                      Market.kospi: 'KOSPI',
                      Market.kosdaq: 'KOSDAQ',
                    },
                    onChanged: (m) => _apply(_f.copyWith(market: () => m)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSelect<ScreenSort>(
                        label: '정렬',
                        placeholder: '시가총액',
                        allLabel: '시가총액',
                        value: _f.sort == ScreenSort.marketCap ? null : _f.sort,
                        options: const {
                          ScreenSort.per: 'PER',
                          ScreenSort.pbr: 'PBR',
                          ScreenSort.roe: 'ROE',
                          ScreenSort.operatingMargin: '영업이익률',
                          ScreenSort.revenueGrowth: '매출 성장률',
                          ScreenSort.operatingIncomeGrowth: '영업이익 성장률',
                          ScreenSort.debtRatio: '부채비율',
                          ScreenSort.dividendYield: '배당수익률',
                          ScreenSort.fcfYield: 'FCF 수익률',
                          ScreenSort.return3m: '3개월 주가',
                          ScreenSort.return12m: '12개월 주가',
                          ScreenSort.bandPosition: '52주 최저에 가까운',
                          ScreenSort.avgTradingValue: '거래대금',
                          ScreenSort.dividendPayout: '배당성향',
                          ScreenSort.dividendYears: '확인된 연속 배당',
                          ScreenSort.volume: '거래량',
                          ScreenSort.volumeRatio: '평소 대비 거래량',
                        },
                        // 싼 것·높은 수익성을 먼저 보는 쪽이 자연스럽다.
                        onChanged: (s) {
                          final sort = s ?? ScreenSort.marketCap;
                          _apply(
                            _f.copyWith(
                              sort: sort,
                              ascending:
                                  sort == ScreenSort.per ||
                                  sort == ScreenSort.pbr ||
                                  sort == ScreenSort.dividendPayout,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpace.sm),
                      AppToggleGroup<bool>(
                        value: _f.ascending,
                        options: const {false: '큰 순', true: '작은 순'},
                        onChanged: (v) => _apply(_f.copyWith(ascending: v)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              if (_error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppNotice(
                      message: '기업 목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                    ),
                    AppButton(label: '다시 불러오기', onPressed: _load),
                  ],
                )
              else ...[
                SizedBox(
                  height: 2,
                  child: _loading
                      ? const LinearProgressIndicator(minHeight: 2)
                      : null,
                ),
                const SizedBox(height: AppSpace.sm),
                if (page != null) _ResultTable(page: page, filter: _f),
                if (page != null && page.total > _pageSize) ...[
                  const SizedBox(height: AppSpace.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton(
                        label: '이전 10개',
                        onPressed: _loading || _offset == 0
                            ? null
                            : () => _load(offset: _offset - _pageSize),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text(
                        '${_offset ~/ _pageSize + 1} / ${(page.total / _pageSize).ceil()}',
                        style: t.body(13),
                      ),
                      const SizedBox(width: AppSpace.md),
                      AppButton(
                        label: '다음 10개',
                        onPressed:
                            _loading ||
                                _offset + page.items.length >= page.total
                            ? null
                            : () => _load(offset: _offset + _pageSize),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.page, required this.filter});

  final ScreenPage page;
  final ScreenFilter filter;
  ScreenSort get sort => filter.sort;

  /// 열 하나가 차지하는 대략의 폭. 화면에 맞춰 몇 개를 보일지 정하는 데 쓴다.
  static const _columnWidth = 92.0;
  static const _nameWidth = 160.0;

  /// 폭이 모자랄 때 남길 순서. 지금 정렬 기준인 열은 언제나 남긴다.
  static const _priority = [
    '시가총액',
    'PER(배)',
    'ROE(%)',
    'PBR(배)',
    '영업이익률(%)',
    '매출 성장률(%)',
    '영업이익 성장률(%)',
    '부채비율(%)',
    '배당수익률(%)',
    'FCF 수익률(%)',
    '거래대금',
    '3개월(%)',
    '12개월(%)',
    '52주 위치(%)',
    '매출액(TTM)',
    '영업이익(TTM)',
    '최근 보고서',
  ];

  static String? _sortColumn(ScreenSort sort) => switch (sort) {
    ScreenSort.marketCap => null,
    ScreenSort.per => 'PER(배)',
    ScreenSort.pbr => 'PBR(배)',
    ScreenSort.roe => 'ROE(%)',
    ScreenSort.operatingMargin => '영업이익률(%)',
    ScreenSort.revenueGrowth => '매출 성장률(%)',
    ScreenSort.operatingIncomeGrowth => '영업이익 성장률(%)',
    ScreenSort.debtRatio => '부채비율(%)',
    ScreenSort.dividendYield => '배당수익률(%)',
    ScreenSort.fcfYield => 'FCF 수익률(%)',
    ScreenSort.return3m => '3개월(%)',
    ScreenSort.return12m => '12개월(%)',
    ScreenSort.bandPosition => '52주 위치(%)',
    ScreenSort.avgTradingValue => '거래대금',
    ScreenSort.dividendPayout => '배당성향(%)',
    ScreenSort.dividendYears => '연속 배당(년)',
    ScreenSort.volume => '거래량(만주)',
    ScreenSort.volumeRatio => '거래량(배)',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (page.items.isEmpty) {
      return Text(
        '이 조건에 맞는 기업이 아직 없어요. 조건을 줄이거나 숫자 범위를 넓혀보세요.',
        style: t.body(13, color: c.textMuted),
      );
    }
    String? fixed(double? v, int digits) => v?.toStringAsFixed(digits);
    final columns = <(String, String? Function(ScreenRow))>[
      (
        '기업',
        (r) => '${r.company.name}${r.fsDiv == FsDiv.separate ? ' · 별도' : ''}',
      ),
      // 표에서는 짧게 (1,357조 · 6.1조). 긴 표기는 칸을 넘겨 두 줄이 된다.
      ('시가총액', (r) => formatKrwShort(r.marketCap.toDouble())),
      ('PER(배)', (r) => fixed(r.per, 2)),
      ('PBR(배)', (r) => fixed(r.pbr, 2)),
      ('ROE(%)', (r) => fixed(r.roe, 1)),
      ('영업이익률(%)', (r) => fixed(r.operatingMargin, 1)),
      ('매출 성장률(%)', (r) => fixed(r.revenueGrowth, 1)),
      ('영업이익 성장률(%)', (r) => fixed(r.operatingIncomeGrowth, 1)),
      ('부채비율(%)', (r) => fixed(r.debtRatio, 1)),
      ('배당수익률(%)', (r) => fixed(r.dividendYield, 2)),
      ('FCF 수익률(%)', (r) => fixed(r.fcfYield, 2)),
      ('배당성향(%)', (r) => fixed(r.dividendPayout, 1)),
      ('연속 배당(년)', (r) => r.dividendYears?.toString()),
      ('배당 기준연도', (r) => r.dividendYear?.toString()),
      (
        '거래량(만주)',
        (r) => r.volume == null
            ? null
            : (r.volume!.toDouble() / 10000).toStringAsFixed(1),
      ),
      ('거래량(배)', (r) => fixed(r.volumeRatio, 2)),
      (
        '거래대금',
        (r) => r.avgTradingValue == null
            ? null
            : formatKrwShort(r.avgTradingValue!.toDouble()),
      ),
      ('3개월(%)', (r) => fixed(r.return3m, 1)),
      ('12개월(%)', (r) => fixed(r.return12m, 1)),
      ('52주 위치(%)', (r) => fixed(r.bandPosition, 0)),
      ('매출액(TTM)', (r) => formatKrw(r.revenue)),
      ('영업이익(TTM)', (r) => formatKrw(r.operatingIncome)),
      (
        '최근 보고서',
        (r) =>
            '${r.bsnsYear} ${r.reportCode == null ? '' : reportCodeLabel(r.reportCode!)}',
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        // 들어갈 만큼만 보이고, 좁으면 중요한 열부터 남긴다 (가로로도 밀 수 있다).
        // 좁은 화면에서는 기업명 열 폭을 고정해 (긴 이름은 …으로) 숫자 두 열이 들어가게 한다.
        final narrow = box.maxWidth < 600;
        final nameWidth = narrow
            ? (box.maxWidth - 2 * _columnWidth - AppSpace.lg).clamp(
                120.0,
                _nameWidth,
              )
            : _nameWidth;
        final fits = ((box.maxWidth - nameWidth - AppSpace.md) / _columnWidth)
            .floor();
        final keep = {
          '기업',
          ?_sortColumn(sort),
          if (filter.perMax != null) 'PER(배)',
          if (filter.pbrMax != null) 'PBR(배)',
          if (filter.roeMin != null) 'ROE(%)',
          if (filter.marginMin != null) '영업이익률(%)',
          if (filter.revenueGrowthMin != null) '매출 성장률(%)',
          if (filter.opGrowthMin != null) '영업이익 성장률(%)',
          if (filter.debtMax != null) '부채비율(%)',
          if (filter.dividendMin != null) '배당수익률(%)',
          if (filter.fcfMin != null) 'FCF 수익률(%)',
          if (filter.liquidityMin != null) '거래대금',
          if (filter.marketCapMin != null) '시가총액',
          if (filter.payoutMax != null) '배당성향(%)',
          if (filter.dividendYearsMin != null) '연속 배당(년)',
          if (filter.dividendMin != null ||
              filter.payoutMax != null ||
              filter.dividendYearsMin != null)
            '배당 기준연도',
          if (filter.volumeMin != null) '거래량(만주)',
          if (filter.volumeRatioMin != null) '거래량(배)',
          if (filter.return3mMin != null) '3개월(%)',
          if (filter.return12mMin != null) '12개월(%)',
          if (filter.bandPositionMin != null) '52주 위치(%)',
          ..._priority.take(fits.clamp(2, _priority.length)),
        };
        final shown = [
          for (final col in columns)
            if (keep.contains(col.$1)) col,
        ];
        return AppDataTable(
          columns: [
            for (final col in shown)
              col.$1 == '기업'
                  ? AppColumn(
                      col.$1,
                      width: narrow ? nameWidth : null,
                      flex: true,
                    )
                  : AppColumn(col.$1, numeric: true),
          ],
          rows: [
            for (final r in page.items)
              AppRow([
                for (final col in shown)
                  if (col.$1 == '기업')
                    HoverBuilder(
                      onTap: () =>
                          context.push(AppRoutes.company(r.company.corpCode)),
                      builder: (context, hovered) => Text(
                        '${r.company.name}${r.fsDiv == FsDiv.separate ? ' · 별도' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t
                            .body(
                              13.5,
                              color: c.accent,
                              weight: FontWeight.w600,
                            )
                            .copyWith(
                              decoration: hovered
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: c.accent,
                            ),
                      ),
                    )
                  else
                    Tooltip(
                      message: screenMetricNote(r, col.$1) ?? '',
                      child: AppDataTable.text(
                        context,
                        col.$2(r),
                        numeric: true,
                      ),
                    ),
              ]),
          ],
        );
      },
    );
  }
}

/// 조건 묶음 한 줄: 왼쪽에 묶음 이름, 오른쪽에 입력칸들.
class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.children,
    this.last = false,
  });

  final String label;
  final List<Widget> children;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final name = Text(label, style: t.label(color: c.textSecondary));
    final fields = Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.sm,
      children: children,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpace.md),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 560
            // 좁으면 이름을 위에 (옆에 두면 입력칸이 한 줄에 하나씩 세로로 늘어진다).
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.md,
                    runSpacing: AppSpace.md,
                    children: [
                      for (final field in children)
                        SizedBox(
                          width: box.maxWidth < 320
                              ? box.maxWidth
                              : (box.maxWidth - AppSpace.md) / 2,
                          child: field,
                        ),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: name,
                    ),
                  ),
                  Expanded(child: fields),
                ],
              ),
      ),
    );
  }
}

/// 숫자 하나를 받는 작은 입력칸. 비우면 그 조건을 끈다.
class _NumberField extends StatefulWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.help,
    this.min,
    this.max,
    this.integer = false,
  });

  final String? help;
  final double? min;
  final double? max;
  final bool integer;
  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  static String _number(double? v) => v == null
      ? ''
      : v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();
  late final _controller = TextEditingController(
    text: _number(widget.value),
  );

  final _focus = FocusNode();
  String? _inputError;

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    _inputError = null;
    // 치는 중에는 건드리지 않는다. "1"을 "1.0"으로 고쳐 쓰면 이어 친 "5"가
    // "1.05"가 되어 사용자가 넣지 않은 조건이 걸린다.
    if (_focus.hasFocus && double.tryParse(_controller.text) == widget.value) {
      return;
    }
    final text = _number(widget.value);
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return SizedBox(
      width: 184,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
        ],
        style: t.numeric(14),
        decoration: InputDecoration(
          isDense: true,
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: t.body(12, color: c.textSecondary),
          hintText: '제한 없음',
          errorText: _inputError,
          suffixIcon: widget.help == null
              ? null
              : Tooltip(
                  message: widget.help!,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(Icons.info_outline, size: 15, color: c.textMuted),
                ),
        ),
        onChanged: (v) {
          final text = v.trim();
          final number = double.tryParse(text);
          final valid =
              text.isEmpty ||
              (number != null &&
                  number.isFinite &&
                  (widget.min == null || number >= widget.min!) &&
                  (widget.max == null || number <= widget.max!) &&
                  (!widget.integer || number == number.roundToDouble()));
          setState(() => _inputError = valid ? null : '입력 범위를 확인해 주세요');
          if (valid) widget.onChanged(number);
        },
      ),
    );
  }
}
