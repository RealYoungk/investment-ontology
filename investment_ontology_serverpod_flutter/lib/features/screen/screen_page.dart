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

/// 스크리너: 재무·시세로 기업을 거른다.
///
/// 지표는 저장하지 않고 서버가 조회할 때 계산한다. 계산에 쓴 원천 값(매출·영업이익·
/// 순이익·자본)을 같이 보여 줘서 숫자의 근거를 볼 수 있게 한다.
class ScreenerPage extends StatefulWidget {
  const ScreenerPage({super.key, required this.filter});

  /// 조건은 주소에 남는다 (`/screen?per=10&roe=15`). 북마크·뒤로가기가 된다.
  final ScreenFilter filter;

  @override
  State<ScreenerPage> createState() => _ScreenerPageState();
}

class _ScreenerPageState extends State<ScreenerPage> {
  ScreenPage? _page;
  Object? _error;
  bool _loading = false;
  Timer? _debounce;
  int _seq = 0;

  ScreenFilter get _f => widget.filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ScreenerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// 조건을 주소에 반영한다. 조건을 바꿀 때마다 방문 기록이 쌓이지 않게 한다.
  void _apply(ScreenFilter next) {
    if (next == _f) return;
    Router.neglect(context, () => context.go(next.location));
  }

  void _applySoon(ScreenFilter next) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _apply(next));
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final p = await client.screen.list(
        market: _f.market,
        perMax: _f.perMax,
        pbrMax: _f.pbrMax,
        roeMin: _f.roeMin,
        operatingMarginMin: _f.marginMin,
        debtRatioMax: _f.debtMax,
        dividendYieldMin: _f.dividendMin,
        fcfYieldMin: _f.fcfMin,
        revenueGrowthMin: _f.revenueGrowthMin,
        operatingIncomeGrowthMin: _f.opGrowthMin,
        // 화면에서는 억원으로 받는다 (원 단위 숫자는 세기 어렵다).
        avgTradingValueMin: _f.liquidityMin == null
            ? null
            : BigInt.from((_f.liquidityMin! * 100000000).round()),
        sort: _f.sort,
        ascending: _f.ascending,
        limit: 100,
      );
      if (!mounted || seq != _seq) return;
      setState(() => (_page = p, _error = null));
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final page = _page;
    return PageFrame(
      children: [
        PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 스크리너',
          title: '스크리너',
          subtitle:
              '최근 12개월(TTM) 연결 실적과 최근 시세로 계산합니다 — 기업 화면과 같은 기준입니다. '
              '값이 없는 기업(적자·자본잠식·'
              '표준계정 미사용)은 그 조건을 걸면 빠집니다'
              '${page?.baseDate == null ? '' : ' · 시세 ${formatDate(page!.baseDate)}'}'
              '${page == null ? '' : ' · 계산 가능 ${formatCount(page.universe)}개사'}',
        ),
        const SizedBox(height: AppSpace.xl),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.md,
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
            _NumberField(
              label: 'PER 이하',
              value: _f.perMax,
              onChanged: (v) => _applySoon(_f.copyWith(perMax: () => v)),
            ),
            _NumberField(
              label: 'PBR 이하',
              value: _f.pbrMax,
              onChanged: (v) => _applySoon(_f.copyWith(pbrMax: () => v)),
            ),
            _NumberField(
              label: 'ROE % 이상',
              value: _f.roeMin,
              onChanged: (v) => _applySoon(_f.copyWith(roeMin: () => v)),
            ),
            _NumberField(
              label: '영업이익률 % 이상',
              value: _f.marginMin,
              onChanged: (v) => _applySoon(_f.copyWith(marginMin: () => v)),
            ),
            _NumberField(
              label: '부채비율 % 이하',
              value: _f.debtMax,
              onChanged: (v) => _applySoon(_f.copyWith(debtMax: () => v)),
            ),
            _NumberField(
              label: '배당수익률 % 이상',
              value: _f.dividendMin,
              onChanged: (v) => _applySoon(_f.copyWith(dividendMin: () => v)),
            ),
            _NumberField(
              label: 'FCF 수익률 % 이상',
              value: _f.fcfMin,
              onChanged: (v) => _applySoon(_f.copyWith(fcfMin: () => v)),
            ),
            _NumberField(
              label: '매출 성장률 % 이상',
              value: _f.revenueGrowthMin,
              onChanged: (v) =>
                  _applySoon(_f.copyWith(revenueGrowthMin: () => v)),
            ),
            _NumberField(
              label: '영업이익 성장률 % 이상',
              value: _f.opGrowthMin,
              onChanged: (v) => _applySoon(_f.copyWith(opGrowthMin: () => v)),
            ),
            _NumberField(
              label: '거래대금 억원 이상',
              value: _f.liquidityMin,
              onChanged: (v) => _applySoon(_f.copyWith(liquidityMin: () => v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppToggleGroup<ScreenSort>(
              label: '정렬',
              value: _f.sort,
              options: const {
                ScreenSort.marketCap: '시가총액',
                ScreenSort.per: 'PER',
                ScreenSort.pbr: 'PBR',
                ScreenSort.roe: 'ROE',
                ScreenSort.operatingMargin: '영업이익률',
                ScreenSort.debtRatio: '부채비율',
                ScreenSort.dividendYield: '배당수익률',
                ScreenSort.fcfYield: 'FCF 수익률',
                ScreenSort.revenueGrowth: '매출 성장률',
                ScreenSort.operatingIncomeGrowth: '영업이익 성장률',
                ScreenSort.return3m: '3개월 주가',
                ScreenSort.return12m: '12개월 주가',
                ScreenSort.bandPosition: '52주 최저에 가까운',
                ScreenSort.avgTradingValue: '거래대금',
              },
              // 싼 것·높은 수익성을 먼저 보는 쪽이 자연스럽다.
              onChanged: (s) => _apply(
                _f.copyWith(
                  sort: s,
                  ascending: s == ScreenSort.per || s == ScreenSort.pbr,
                ),
              ),
            ),
            AppToggleGroup<bool>(
              value: _f.ascending,
              options: const {true: '작은 순', false: '큰 순'},
              onChanged: (v) => _apply(_f.copyWith(ascending: v)),
            ),
            if (_f.hasCondition)
              AppButton(
                label: '조건 초기화',
                icon: Icons.close,
                variant: AppButtonVariant.link,
                tone: c.accent,
                onPressed: () => _apply(
                  ScreenFilter(sort: _f.sort, ascending: _f.ascending),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (_error != null)
          AppNotice(message: '스크리닝에 실패했습니다 — $_error')
        else ...[
          SizedBox(
            height: 2,
            child: _loading
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
          const SizedBox(height: AppSpace.sm),
          if (page != null)
            Text(
              '${formatCount(page.total)}개사'
              '${page.total > page.items.length ? ' 중 ${formatCount(page.items.length)}개사' : ''}',
              style: t.numeric(12.5, color: c.textSecondary),
            ),
          const SizedBox(height: AppSpace.sm),
          if (page != null) _ResultTable(page: page, sort: _f.sort),
          const SizedBox(height: AppSpace.md),
          Text(
            'PER = 시가총액 ÷ 지배주주 당기순이익 · PBR = 시가총액 ÷ 지배주주 자본 · '
            'ROE = 지배주주 순이익 ÷ 지배주주 자본 · 영업이익률 = 영업이익 ÷ 매출액 · '
            '부채비율 = 부채총계 ÷ 자본총계 · FCF 수익률 = (영업활동 현금흐름 − 유형자산 취득) ÷ 시가총액 · '
            '배당수익률 = 최근 사업연도 현금배당금총액 ÷ 시가총액 · '
            '3·12개월 = 대표 종목(시가총액이 가장 큰 종목) 종가 등락률 · '
            '52주 위치 = 최근 1년 종가의 최저(0)~최고(100) 사이 지금 자리 · '
            '거래대금 = 최근 한 달 하루 평균 (사고팔 수 있는 크기) · '
            '성장률 = 올해 누적 대비 전년 같은 기간 누적 (전년이 적자면 계산하지 않음). '
            '손익 항목은 최근 12개월 합계(사업보고서면 그 해, 아니면 전년 연간 + 올해 누적 − 전년 같은 기간 '
            '누적)이고 자본은 최근 보고서 시점 값입니다. 모두 연결 기준이며, 지배주주 값이 없으면 전체 값을 씁니다. '
            '표준계정(XBRL)으로만 찾으므로 '
            '금융업 등 일부 기업은 매출·영업이익이 비어 보일 수 있고, 영업활동 현금흐름의 성격이 달라 '
            'FCF 수익률이 지나치게 크게 나올 수 있습니다. 배당수익률은 공시된 배당수익률이 아니라 '
            '최근 시세로 다시 계산한 값입니다.',
            style: t.body(11.5, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.page, required this.sort});

  final ScreenPage page;
  final ScreenSort sort;

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
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (page.items.isEmpty) {
      return Text('조건에 맞는 기업이 없습니다.', style: t.body(13, color: c.textMuted));
    }
    String? fixed(double? v, int digits) => v?.toStringAsFixed(digits);
    final columns = <(String, String? Function(ScreenRow))>[
      ('기업', (r) => r.company.name),
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
      ('최근 보고서', (r) => '${r.bsnsYear}'),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        // 들어갈 만큼만 보이고, 좁으면 중요한 열부터 남긴다 (가로로도 밀 수 있다).
        final fits = ((box.maxWidth - _nameWidth) / _columnWidth).floor();
        final keep = {
          '기업',
          ?_sortColumn(sort),
          ..._priority.take(fits.clamp(2, _priority.length)),
        };
        final shown = [
          for (final col in columns)
            if (keep.contains(col.$1)) col,
        ];
        return AppDataTable(
          columns: [
            for (final col in shown) AppColumn(col.$1, numeric: col.$1 != '기업'),
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
                        r.company.name,
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
                    AppDataTable.text(context, col.$2(r), numeric: true),
              ]),
          ],
        );
      },
    );
  }
}

/// 숫자 하나를 받는 작은 입력칸. 비우면 그 조건을 끈다.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    // 치는 중에는 건드리지 않는다. "1"을 "1.0"으로 고쳐 쓰면 이어 친 "5"가
    // "1.05"가 되어 사용자가 넣지 않은 조건이 걸린다.
    if (_focus.hasFocus && double.tryParse(_controller.text) == widget.value) {
      return;
    }
    final text = widget.value?.toString() ?? '';
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
      width: 148,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        style: t.numeric(14),
        decoration: InputDecoration(
          isDense: true,
          labelText: widget.label,
          labelStyle: t.body(12, color: c.textSecondary),
          hintText: '제한 없음',
        ),
        onChanged: (v) => widget.onChanged(double.tryParse(v.trim())),
      ),
    );
  }
}
