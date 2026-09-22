import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import '../../financials/financial_metrics.dart';

/// 시장 전체 시가총액 추이.
///
/// 그 기준일에 시세가 있는 종목의 시가총액 합이다. 상장·폐지로 종목 수가 달라지므로
/// 지수가 아니라 "그날 시장에 얼마가 있었는가"로 읽는다.
class MarketCapTrend extends StatefulWidget {
  const MarketCapTrend({super.key, this.market});

  final Market? market;

  static const ranges = <({String label, int days})>[
    (label: '1년', days: 365),
    (label: '3년', days: 1095),
    (label: '5년', days: 1825),
  ];

  @override
  State<MarketCapTrend> createState() => _MarketCapTrendState();
}

class _MarketCapTrendState extends State<MarketCapTrend> {
  int _days = MarketCapTrend.ranges.first.days;
  List<MarketCapPoint> _points = const [];
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MarketCapTrend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.market != widget.market) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    try {
      final p = await client.market.capHistory(
        market: widget.market,
        days: _days,
      );
      if (mounted && seq == _seq) setState(() => _points = p);
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
    final points = _points;
    if (points.length < 2) return const SizedBox.shrink();
    final first = points.first, last = points.last;
    final from = first.marketCap.toDouble();
    final change = from <= 0
        ? null
        : (last.marketCap.toDouble() / from - 1) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '시가총액 추이',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in MarketCapTrend.ranges)
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
        // 좁은 화면에서는 기간이 다음 줄로 내려간다 (Row면 오른쪽이 잘린다).
        Wrap(
          spacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(formatKrw(last.marketCap), style: t.numeric(22)),
            if (change != null)
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: t.numeric(
                  14,
                  color: change >= 0 ? c.accent : c.textSecondary,
                ),
              ),
            Text(
              '${formatDate(first.date)} → ${formatDate(last.date)} · '
              '종목 ${formatCount(last.securityCount)}개',
              style: t.body(12, color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppLineChart(
          categories: [for (final p in points) formatDate(p.date)],
          series: ChartSeries(
            label: '시가총액',
            color: c.chartSeries1,
            values: [for (final p in points) p.marketCap.toDouble()],
          ),
          formatValue: formatKrwShort,
          height: 200,
          includeZeroBaseline: false,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '그날 시세가 있는 종목의 시가총액 합입니다. 상장·폐지로 종목 수가 달라지므로 지수와는 다릅니다.',
          style: t.body(11.5, color: c.textMuted),
        ),
      ],
    );
  }
}
