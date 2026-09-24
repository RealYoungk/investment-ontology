import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../market_load_notice.dart';
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
  bool _failed = false;

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
    setState(() => _failed = false);
    try {
      final p = await client.market.capHistory(
        market: widget.market,
        days: _days < 380 ? 380 : _days,
      );
      if (mounted && seq == _seq) setState(() => _points = p);
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
      return MarketLoadNotice(subject: '시가총액 추이', retry: _load);
    }
    final c = context.colors;
    final t = context.typo;
    final points = _points.isEmpty
        ? _points
        : _points
              .where(
                (p) => !p.date.isBefore(
                  _points.last.date.subtract(Duration(days: _days)),
                ),
              )
              .toList();
    if (points.length < 2) return const SizedBox.shrink();
    final first = points.first, last = points.last;
    final from = first.marketCap.toDouble();
    final change = from <= 0
        ? null
        : (last.marketCap.toDouble() / from - 1) * 100;

    DateTime monthBack(int months) {
      final first = DateTime.utc(last.date.year, last.date.month - months);
      final end = DateTime.utc(first.year, first.month + 1, 0).day;
      return DateTime.utc(first.year, first.month, last.date.day.clamp(1, end));
    }

    final comparisons = [
      for (final period in [
        (label: '전일', date: last.date.subtract(const Duration(days: 1))),
        (label: '1주', date: last.date.subtract(const Duration(days: 7))),
        (label: '1개월', date: monthBack(1)),
        (label: '1년', date: monthBack(12)),
      ])
        () {
          final base = _points
              .where(
                (p) =>
                    !p.date.isAfter(period.date) &&
                    !p.date.isBefore(
                      period.date.subtract(const Duration(days: 10)),
                    ),
              )
              .lastOrNull;
          final rate = base == null || base.marketCap <= BigInt.zero
              ? null
              : (last.marketCap.toDouble() / base.marketCap.toDouble() - 1) *
                    100;
          return (label: period.label, base: base, rate: rate);
        }(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '시가총액 추이',
          tooltip: '그날 시세가 있는 종목의 시가총액 합입니다. 상장·폐지로 종목 수가 달라지므로 지수와는 다릅니다.',
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
        Text(
          formatKrw(last.marketCap),
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
                      item.rate == null
                          ? '자료 부족'
                          : '${item.rate! > 0 ? '+' : ''}${item.rate!.toStringAsFixed(2)}%',
                      style: t.numeric(
                        13,
                        color: c.marketChange(item.rate),
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
            label: '시가총액',
            color: c.marketChange(change),
            values: [for (final p in points) p.marketCap.toDouble()],
          ),
          formatValue: formatKrwShort,
          height: 180,
          includeZeroBaseline: false,
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: c.surface),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            dense: true,
            title: Text('기준·출처', style: t.body(11.5, color: c.textSecondary)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '기준 ${formatDate(last.date)} · ${formatCount(last.securityCount)}개 종목 · 금융위원회 주식시세정보',
                  style: t.body(12, color: c.textSecondary),
                ),
              ),
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
                              ? '비교 자료 부족'
                              : '${formatDate(item.base!.date)} · ${formatKrw(item.base!.marketCap)}',
                          style: t.body(12, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '휴장일은 이전 종가를 사용하며 10일 넘게 떨어진 자료는 제외합니다. 상장·폐지로 구성 종목 수가 달라져 지수 수익률과는 다릅니다.',
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
