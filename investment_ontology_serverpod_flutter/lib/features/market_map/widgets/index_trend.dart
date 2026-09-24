import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../market_load_notice.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// 코스피·코스닥 지수 추이 (공공데이터포털 금융위원회_지수시세정보).
///
/// 시가총액 추이와 달리 종목 구성이 바뀌어도 이어지는 값이다. 두 지수는 눈금이 달라
/// 나란히 따로 그린다. 지수 자료가 아직 없으면 아무것도 그리지 않는다.
class IndexTrend extends StatefulWidget {
  const IndexTrend({super.key});

  static const ranges = <({String label, int days})>[
    (label: '1년', days: 365),
    (label: '3년', days: 1095),
    (label: '5년', days: 1825),
  ];

  static const names = ['코스피', '코스닥'];

  @override
  State<IndexTrend> createState() => _IndexTrendState();
}

class _IndexTrendState extends State<IndexTrend> {
  int _days = IndexTrend.ranges.first.days;
  List<IndexHistory?> _histories = const [];
  int _seq = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _failed = false);
    try {
      final h = await Future.wait([
        for (final n in IndexTrend.names)
          client.market.indexHistory(n, days: _days),
      ]);
      if (mounted && seq == _seq) setState(() => _histories = h);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  void _pick(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return MarketLoadNotice(subject: '지수 추이', retry: _load);
    }
    final c = context.colors;
    final t = context.typo;
    final histories = [
      for (final h in _histories)
        if (h != null && h.points.length >= 2) h,
    ];
    if (histories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '지수 추이',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in IndexTrend.ranges)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: HoverBuilder(
                    onTap: () => _pick(r.days),
                    builder: (context, hovered) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: r.days == _days
                            ? c.accentSubtle
                            : (hovered ? c.surfaceHover : null),
                        borderRadius: context.shape.borderRadius,
                      ),
                      child: Text(
                        r.label,
                        style: t.body(
                          12,
                          color: r.days == _days ? c.accent : c.textSecondary,
                          weight: r.days == _days
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, box) {
            final cards = [
              for (final h in histories) _IndexCard(history: h),
            ];
            // 폰에서는 세로로, 넓으면 나란히.
            if (box.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, w) in cards.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpace.lg),
                    w,
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, w) in cards.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xl),
                  Expanded(child: w),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.history});
  final IndexHistory history;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final points = history.points;
    final first = points.first, last = points.last;
    double? rate(IndexPoint? base) => base == null || base.value <= 0
        ? null
        : (last.value / base.value - 1) * 100;
    final change = rate(first);
    final comparisons = [
      (label: '전일', base: history.dayBase, value: history.lastChangeRate),
      (label: '1주', base: history.weekBase, value: rate(history.weekBase)),
      (label: '1개월', base: history.monthBase, value: rate(history.monthBase)),
      (label: '1년', base: history.yearBase, value: rate(history.yearBase)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(history.name, style: t.body(13, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.xs),
        Text(
          formatDecimal(last.value),
          style: t.numeric(26, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.md),
        Text('이전 시점 대비', style: t.body(11, color: c.textSecondary)),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: [
            for (final item in comparisons)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: t.body(12, color: c.textSecondary)),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      item.value == null
                          ? '자료 부족'
                          : '${item.value! > 0 ? '+' : ''}${item.value!.toStringAsFixed(2)}%',
                      style: t.numeric(
                        13,
                        color: c.marketChange(item.value),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppLineChart(
          formatCategory: (date) =>
              date.length >= 7 ? date.substring(2, 7) : date,
          maxAxisLabels: 6,
          categories: [for (final p in points) formatDate(p.date)],
          series: ChartSeries(
            label: history.name,
            color: c.marketChange(change),
            values: [for (final p in points) p.value],
          ),
          formatValue: formatDecimal,
          height: 180,
          includeZeroBaseline: false,
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: c.surface),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AppSpace.sm),
            dense: true,
            title: Text('기준·출처', style: t.body(11.5, color: c.textSecondary)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '종가 기준 ${formatDate(last.date)} · 금융위원회 지수시세정보',
                  style: t.body(12, color: c.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final item in comparisons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(item.label, style: t.body(12)),
                      ),
                      Expanded(
                        child: Text(
                          item.base == null
                              ? '비교 종가 자료 없음'
                              : '${formatDate(item.base!.date)} · ${formatDecimal(item.base!.value)}',
                          style: t.numeric(12, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '1주·1개월·1년은 기준일에서 거슬러 계산합니다. 휴장일은 이전 종가를 사용하며 10일 넘게 떨어진 자료는 제외합니다. 월말·윤년은 해당 월말로 맞춥니다. 전일 등락률은 원천기관 제공 값입니다.',
                style: t.body(12, color: c.textSecondary),
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '차트 ${formatDate(first.date)}–${formatDate(last.date)}${change == null ? '' : ' · 기간 ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%'}',
                  style: t.body(12, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
