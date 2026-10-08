import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart' show formatUnitAmount;

/// Compact axis labels; preserve the printed period in source details.
String businessHistoryAxisLabel(int year, String period) {
  final yy = (year % 100).toString().padLeft(2, '0');
  if (period.contains('상반기') || period.contains('반기')) return '$yy.1H';
  final quarter = RegExp(r'([1-4])분기').firstMatch(period)?.group(1);
  if (quarter != null) {
    return '$yy.${quarter}Q${period.contains('누적') ? ' 누적' : ''}';
  }
  return '$yy년';
}

/// Multi-row headers append a metric after the period (e.g. bank balance/rate).
String businessTablePeriodKey(String period) => period.split(' · ').first;

bool conflictingPriceUnit(
  BusinessTableMeasure value,
  Iterable<BusinessTableMeasure> others,
) => others.any(
  (other) =>
      businessTablePeriodKey(other.period) ==
          businessTablePeriodKey(value.period) &&
      other.label.split(' · ').first == value.label.split(' · ').first &&
      other.metric == value.metric &&
      other.value == value.value &&
      other.unit != value.unit &&
      other.unit.replaceFirst(RegExp(r'^(백만|천)'), '') ==
          value.unit.replaceFirst(RegExp(r'^(백만|천)'), ''),
);

/// Stored reports only. Latest disclosure remains in the main panel above.
class BusinessTableHistory extends StatefulWidget {
  const BusinessTableHistory({
    super.key,
    required this.corpCode,
    required this.latest,
    this.topic,
    this.title,
    this.share = false,
  });
  final String corpCode;
  final BusinessContent latest;
  final String? topic, title;
  final bool share;
  @override
  State<BusinessTableHistory> createState() => _BusinessTableHistoryState();
}

class _BusinessTableHistoryState extends State<BusinessTableHistory> {
  List<BusinessContent> _reports = [];
  bool _loading = true;

  final List<int> _failed = [];
  int _seq = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessTableHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.latest.rceptNo != widget.latest.rceptNo) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _reports = [];
      _failed.clear();
    });
    final isAnnual = widget.latest.source?.title.contains('사업보고서') ?? false;
    final end = widget.latest.bsnsYear - (isAnnual ? 0 : 1);
    final years = [for (var y = end - 4; y <= end; y++) y];
    final results = await Future.wait(
      years.map((year) async {
        try {
          final report = await client.disclosure.businessContent(
            widget.corpCode,
            bsnsYear: year,
          );
          return (year, report);
        } catch (_) {
          return (year, null);
        }
      }),
    );
    if (!mounted || seq != _seq) return;
    setState(() {
      for (final (year, report) in results) {
        if (report == null) {
          _failed.add(year);
        } else {
          _reports.add(report);
        }
      }
      if (!_reports.any((r) => r.rceptNo == widget.latest.rceptNo)) {
        _reports.add(widget.latest);
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups =
        <
          (String, String, String),
          List<
            (BusinessContent, BusinessTableInsight, List<BusinessTableMeasure>)
          >
        >{};
    final prices = [
      for (final report in _reports)
        for (final table in report.tableInsights ?? <BusinessTableInsight>[])
          if (table.topic == 'materialPrice' || table.topic == 'productPrice')
            ...table.measures,
    ];
    final conflicts = <(BusinessContent, BusinessTableMeasure)>[];
    for (final report in _reports) {
      for (final table in report.tableInsights ?? <BusinessTableInsight>[]) {
        if (widget.topic != null && table.topic != widget.topic) continue;
        if (widget.title != null && table.title != widget.title) continue;
        final periods = table.measures.map((m) => m.period).toSet();
        if (periods.isEmpty) continue;
        // First printed period is kept verbatim, never relabelled as cumulative.
        final measures = table.measures.where((m) {
          if (businessTablePeriodKey(m.period) !=
              businessTablePeriodKey(periods.first)) {
            return false;
          }
          if ((table.topic == 'materialPrice' ||
                  table.topic == 'productPrice') &&
              conflictingPriceUnit(m, prices)) {
            conflicts.add((report, m));
            return false;
          }
          return true;
        }).toList();
        for (final key in measures.map((m) => (m.metric, m.unit)).toSet()) {
          groups.putIfAbsent((table.title, key.$1, key.$2), () => []).add((
            report,
            table,
            measures.where((m) => (m.metric, m.unit) == key).toList(),
          ));
        }
      }
    }
    for (final key in groups.keys.toList()) {
      final merged =
          <
            (String, String),
            (BusinessContent, BusinessTableInsight, List<BusinessTableMeasure>)
          >{};
      for (final row in groups[key]!) {
        final periodKey = (row.$1.rceptNo, '');
        final previous = merged[periodKey];
        if (previous == null) {
          merged[periodKey] = row;
        } else {
          merged[periodKey] = (
            row.$1,
            previous.$2.copyWith(
              evidence: '${previous.$2.evidence}\n\n${row.$2.evidence}',
            ),
            [...previous.$3, ...row.$3],
          );
        }
      }
      groups[key] = merged.values.toList();
    }
    final hasAmounts = groups.keys.any((k) => k.$3 != '%');
    final hasShares = groups.keys.any((k) => k.$3 == '%');
    final selectable =
        widget.topic == 'materialPurchase' && hasAmounts && hasShares;
    final visibleGroups = groups.entries.where(
      (g) => !selectable || (g.key.$3 == '%') == widget.share,
    );
    final labelsAcrossViews = groups.values
        .expand((rows) => rows)
        .expand((row) => row.$3)
        .map((m) => m.label)
        .toSet()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (conflicts.isNotEmpty)
          ShadAccordion<int>(
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: const Text('원문 단위 충돌 · 추이에서 제외'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (report, measure) in conflicts)
                      Text(
                        '${report.bsnsYear}년 보고서 · ${measure.period} · ${measure.label}: ${measure.value} ${measure.unit}',
                        style: context.typo.body(12),
                      ),
                    const Text('동일 기간·항목·수치의 단위가 다른 보고서와 다릅니다. 임의 환산하지 않습니다.'),
                  ],
                ),
              ),
            ],
          ),
        if (!_loading && _failed.isNotEmpty)
          Text(
            '${_failed.join(', ')}년 자료는 저장 여부 또는 조회 상태를 확인하지 못했습니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
        for (final group in visibleGroups) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            '${group.key.$2} (${group.key.$3})',
            style: context.typo.body(16, weight: FontWeight.w700),
          ),
          Builder(
            builder: (context) {
              final labels = group.value
                  .expand((r) => r.$3)
                  .map((m) => m.label)
                  .toSet()
                  .toList();
              final palette = categoricalChartColors(context);
              final series = [
                for (final label in labels)
                  ChartSeries(
                    label: label,
                    color:
                        palette[labelsAcrossViews.indexOf(label) %
                            palette.length],
                    values: [
                      for (final row in group.value)
                        (() {
                          final values = row.$3
                              .where((m) => m.label == label)
                              .map((m) => m.value)
                              .toSet();
                          return values.length == 1 ? values.single : null;
                        })(),
                    ],
                  ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChartLegend(series: series),
                  AppColumnChart(
                    categories: [
                      for (final row in group.value)
                        businessHistoryAxisLabel(
                          row.$1.bsnsYear,
                          row.$3.first.period,
                        ),
                    ],
                    series: series,
                    formatValue: (v) => formatUnitAmount(v, group.key.$3),
                    height: 240,
                    showMissingMarkers: true,
                  ),
                  ShadAccordion<int>(
                    children: [
                      ShadAccordionItem<int>(
                        value: 0,
                        title: const Text('연도별 수치와 원문 근거'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final row in group.value) ...[
                              Text(
                                '${row.$1.bsnsYear}년 보고서 · ${row.$3.first.period}',
                                style: context.typo.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              for (final m in row.$3)
                                Text(
                                  '${m.label}: ${formatUnitAmount(m.value, m.unit)}',
                                  style: context.typo.body(13),
                                ),
                              SelectableText(
                                row.$2.evidence,
                                style: context.typo.body(12),
                              ),
                              const SizedBox(height: AppSpace.md),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
        if (!_loading && groups.isEmpty)
          const Text('최근 5개년에서 시각화 가능한 표를 찾지 못했습니다.'),
      ],
    );
  }
}
