import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    try {
      final h = await Future.wait([
        for (final n in IndexTrend.names)
          client.market.indexHistory(n, days: _days),
      ]);
      if (mounted && seq == _seq) setState(() => _histories = h);
    } catch (_) {
      // 시장 화면의 나머지는 그대로 보여준다.
    }
  }

  void _pick(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
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
              for (final (i, h) in histories.indexed)
                _IndexCard(
                  history: h,
                  color: i == 0 ? c.chartSeries1 : c.chartSeries2,
                ),
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
        const SizedBox(height: AppSpace.xs),
        Text(
          '공공데이터포털 금융위원회_지수시세정보의 종가입니다. 종목 구성이 바뀌어도 이어지는 값이라 시가총액 합과는 다릅니다.',
          style: t.body(11.5, color: c.textMuted),
        ),
      ],
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.history, required this.color});

  final IndexHistory history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final points = history.points;
    final first = points.first, last = points.last;
    final change = first.value <= 0
        ? null
        : (last.value / first.value - 1) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(history.name, style: t.body(13, weight: FontWeight.w600)),
            const SizedBox(width: AppSpace.sm),
            Text(formatDecimal(last.value), style: t.numeric(22)),
            const SizedBox(width: AppSpace.sm),
            if (change != null)
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: t.numeric(
                  14,
                  color: change >= 0 ? c.accent : c.textSecondary,
                ),
              ),
          ],
        ),
        Text(
          '${formatDate(first.date)} → ${formatDate(last.date)}'
          '${history.lastChangeRate == null ? '' : ' · 전일 대비 ${history.lastChangeRate! >= 0 ? '+' : ''}${history.lastChangeRate!.toStringAsFixed(2)}%'}',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        AppLineChart(
          categories: [for (final p in points) formatDate(p.date)],
          series: ChartSeries(
            label: history.name,
            color: color,
            values: [for (final p in points) p.value],
          ),
          formatValue: formatDecimal,
          height: 180,
          includeZeroBaseline: false,
        ),
      ],
    );
  }
}
