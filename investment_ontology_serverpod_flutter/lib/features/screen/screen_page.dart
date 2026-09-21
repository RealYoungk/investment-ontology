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
          if (page != null) _ResultTable(page: page),
          const SizedBox(height: AppSpace.md),
          Text(
            'PER = 시가총액 ÷ 지배주주 당기순이익 · PBR = 시가총액 ÷ 지배주주 자본 · '
            'ROE = 지배주주 순이익 ÷ 지배주주 자본 · 영업이익률 = 영업이익 ÷ 매출액. '
            '손익 항목은 최근 12개월 합계(사업보고서면 그 해, 아니면 전년 연간 + 올해 누적 − 전년 같은 기간 '
            '누적)이고 자본은 최근 보고서 시점 값입니다. 모두 연결 기준이며, 지배주주 값이 없으면 전체 값을 씁니다. '
            '표준계정(XBRL)으로만 찾으므로 '
            '금융업 등 일부 기업은 매출·영업이익이 비어 보일 수 있습니다.',
            style: t.body(11.5, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.page});

  final ScreenPage page;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (page.items.isEmpty) {
      return Text('조건에 맞는 기업이 없습니다.', style: t.body(13, color: c.textMuted));
    }
    return AppDataTable(
      columns: const [
        AppColumn('기업'),
        AppColumn('시가총액', numeric: true),
        AppColumn('PER(배)', numeric: true),
        AppColumn('PBR(배)', numeric: true),
        AppColumn('ROE(%)', numeric: true),
        AppColumn('영업이익률(%)', numeric: true),
        AppColumn('매출액(TTM)', numeric: true),
        AppColumn('영업이익(TTM)', numeric: true),
        AppColumn('최근 보고서'),
      ],
      rows: [
        for (final r in page.items)
          AppRow([
            HoverBuilder(
              onTap: () => context.push(AppRoutes.company(r.company.corpCode)),
              builder: (context, hovered) => Text(
                r.company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t
                    .body(13.5, color: c.accent, weight: FontWeight.w600)
                    .copyWith(
                      decoration: hovered ? TextDecoration.underline : null,
                      decorationColor: c.accent,
                    ),
              ),
            ),
            AppDataTable.text(context, formatKrw(r.marketCap), numeric: true),
            AppDataTable.text(
              context,
              r.per?.toStringAsFixed(2),
              numeric: true,
            ),
            AppDataTable.text(
              context,
              r.pbr?.toStringAsFixed(2),
              numeric: true,
            ),
            AppDataTable.text(
              context,
              r.roe?.toStringAsFixed(1),
              numeric: true,
            ),
            AppDataTable.text(
              context,
              r.operatingMargin?.toStringAsFixed(1),
              numeric: true,
            ),
            AppDataTable.text(context, formatKrw(r.revenue), numeric: true),
            AppDataTable.text(
              context,
              formatKrw(r.operatingIncome),
              numeric: true,
            ),
            AppDataTable.text(context, '${r.bsnsYear}'),
          ]),
      ],
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

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value?.toString() ?? '';
    if (widget.value != oldWidget.value && _controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
