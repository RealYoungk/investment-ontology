import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// 개요 탭 맨 위의 주가 추이.
///
/// 값은 공공데이터포털 일별 시세 그대로의 종가다. 기간 등락률은 화면에서
/// (마지막 종가 ÷ 첫 종가 − 1)로 계산하며, 배당은 반영하지 않는다.
class PriceChart extends StatefulWidget {
  const PriceChart({super.key, required this.corpCode});

  final String corpCode;

  /// 고를 수 있는 기간 (달력일).
  static const ranges = <({String label, int days})>[
    (label: '1년', days: 365),
    (label: '3년', days: 1095),
    (label: '5년', days: 1825),
  ];

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int _days = PriceChart.ranges.first.days;
  PriceHistory? _history;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      setState(() {
        _history = null;
        _loading = true;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final days = _days;
    final corpCode = widget.corpCode;
    try {
      final h = await client.market.priceHistory(corpCode, days: days);
      if (!mounted || days != _days || corpCode != widget.corpCode) return;
      setState(() {
        _history = h;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(int days) {
    if (days == _days) return;
    setState(() {
      _days = days;
      _loading = true;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final h = _history;
    if (h == null) {
      return _loading ? const SizedBox(height: 220) : const SizedBox.shrink();
    }
    final points = h.points;
    final last = points.last;
    final first = points.first;
    final change = first.close == 0
        ? null
        : (last.close / first.close - 1) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '주가 추이',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${h.securityName} ${h.shortCode}',
                style: t.body(12, color: c.textMuted),
              ),
              const SizedBox(width: AppSpace.md),
              for (final r in PriceChart.ranges)
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${formatCount(last.close)}원', style: t.numeric(22)),
            const SizedBox(width: AppSpace.sm),
            if (change != null)
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: t.numeric(
                  14,
                  color: change >= 0 ? c.accent : c.textSecondary,
                ),
              ),
            const SizedBox(width: AppSpace.sm),
            Text(
              '${formatDate(first.date)} → ${formatDate(last.date)}',
              style: t.body(12, color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppLineChart(
          categories: [for (final p in points) formatDate(p.date)],
          series: ChartSeries(
            label: '종가',
            color: c.chartSeries1,
            values: [for (final p in points) p.close.toDouble()],
          ),
          formatValue: (v) => formatCount(v.round()),
          height: 200,
          includeZeroBaseline: false,
        ),
      ],
    );
  }
}
