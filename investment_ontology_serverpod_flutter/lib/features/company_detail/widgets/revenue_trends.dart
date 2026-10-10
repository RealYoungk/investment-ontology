import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';
import 'business_operating_section.dart'
    show businessFactDate, operatingLatestPeriod;
import 'revenue_composition.dart' show revenuePresentation;

/// Keep statement periods, units and the original classification distinct.
Map<String, List<DocumentFact>> revenueTrendPeriods(List<DocumentFact> facts) {
  final out = <String, List<DocumentFact>>{};
  for (final f in facts) {
    if (f.kind != DocumentFactKind.segmentRevenue ||
        f.status != RelationStatus.verified ||
        !f.value.isFinite) {
      continue;
    }
    final d = businessFactDate(f);
    final key =
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    out.putIfAbsent(key, () => []).add(f);
  }
  return out;
}

/// Conflicting disclosures are missing observations, never summed or guessed.
double? revenueTrendValue(
  List<DocumentFact> facts,
  String label,
  int year, {
  required bool share,
}) {
  final matches = facts
      .where((f) => f.label.trim() == label && businessFactDate(f).year == year)
      .toList();
  if (matches.isEmpty) return null;
  final values = matches
      .map((f) => share ? revenuePresentation(f).share : f.value)
      .toSet();
  return values.length == 1 ? values.single : null;
}

List<DateTime> revenueTrendDates(
  List<DocumentFact> facts,
  List<BusinessFactPeriod> periods, {
  FinancialPeriod? latestReport,
}) {
  final actual = facts.map(businessFactDate).toSet();
  final latest = operatingLatestPeriod(periods, latestReport);
  final lastDate = actual.toList()..sort();
  if (latest == null && lastDate.isEmpty) return [];
  final last = latest?.periodEnd ?? lastDate.last;
  final end = latest != null
      ? latest.bsnsYear -
            ((latest.reportCode == FinancialReportCode.annual) ? 0 : 1)
      : last.year - (last.month == 12 ? 0 : 1);
  final dates = <DateTime>{
    for (var y = end - 4; y <= end; y++)
      periods
              .where(
                (p) =>
                    (p.reportCode == FinancialReportCode.annual) &&
                    p.bsnsYear == y,
              )
              .firstOrNull
              ?.periodEnd ??
          DateTime.utc(y, 12, 31),
    ...actual.where(
      (d) =>
          d == last &&
          (latest == null || latest.reportCode != FinancialReportCode.annual),
    ),
    if (latest != null && !(latest.reportCode == FinancialReportCode.annual))
      latest.periodEnd,
  }.toList()..sort();
  return dates;
}

class RevenueTrends extends StatefulWidget {
  const RevenueTrends({
    super.key,
    required this.facts,
    this.periods = const [],
    this.latestReport,
  });
  final List<DocumentFact> facts;
  final List<BusinessFactPeriod> periods;
  final FinancialPeriod? latestReport;
  @override
  State<RevenueTrends> createState() => _RevenueTrendsState();
}

class _RevenueTrendsState extends State<RevenueTrends> {
  bool _share = false;
  String periodName(String key) => switch (key) {
    '12.31' => '연간 (1~12월)',
    '06.30' => '상반기 (1~6월)',
    '03.31' => '1분기 (1~3월)',
    '09.30' => '1~9월 합계',
    _ => '$key 기준',
  };
  @override
  Widget build(BuildContext context) {
    final groups = revenueTrendPeriods(widget.facts);
    if (groups.isEmpty) return const SizedBox.shrink();
    final facts = groups.values.expand((items) => items).toList();
    final dates = revenueTrendDates(
      facts,
      widget.periods,
      latestReport: widget.latestReport,
    );
    String dateLabel(DateTime date) =>
        '${date.year}년 ${periodName('${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}')}';
    final units = facts.map((f) => f.unit).toSet().toList();
    final c = context.colors, t = context.typo;
    final palette = categoricalChartColors(context);
    List<ChartSeries> seriesFor(String unit) => [
      for (final (index, label)
          in facts
              .where((f) => f.unit == unit)
              .map((f) => f.label.trim())
              .toSet()
              .indexed)
        ChartSeries(
          label: label,
          color: palette[index % palette.length],
          values: [
            for (final date in dates)
              revenueTrendValue(
                facts
                    .where((f) => f.unit == unit && businessFactDate(f) == date)
                    .toList(),
                label,
                date.year,
                share: _share,
              ),
          ],
        ),
    ];
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompanySectionHeading(
            '사업부문·제품별 매출 추이',
            trailing: IntrinsicWidth(
              child: ShadTabs<bool>(
                value: _share,
                onChanged: (value) => setState(() => _share = value),
                expandTabs: false,
                tabs: const [
                  ShadTab<bool>(value: false, child: Text('매출액')),
                  ShadTab<bool>(value: true, child: Text('매출 비중 (%)')),
                ],
              ),
            ),
            help: '공시에 실제로 구분된 항목만 표시합니다. 사업부문을 제품별로 임의 분해하지 않습니다. 동일 기준일·단위끼리 비교하며 미확인 값은 0으로 채우지 않습니다.',
          ),
          const SizedBox(height: AppSpace.sm),
          const SizedBox(height: AppSpace.md),
          Text(
            _share
                ? '각 기간 전체 매출에서 해당 부문이 차지하는 비율입니다. 보고서에 기재된 비율을 표시합니다.'
                : '연간은 1~12월, 상반기는 1~6월 매출 합계입니다. 상반기는 한 해 전체 매출이 아닙니다.',
            style: t.body(13, color: c.textMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          if (dates.length < 2)
            Text(
              '저장된 매출 자료가 한 기간만 있습니다.',
              style: t.body(13, color: c.textMuted),
            )
          else
            for (final unit in units) ...[
              if (!_share)
                Text(
                  '금액은 원 단위로 환산해 표시합니다. 원문 단위: $unit',
                  style: t.body(12, color: c.textMuted),
                ),
              ChartLegend(series: seriesFor(unit)),
              const SizedBox(height: AppSpace.sm),
              AppColumnChart(
                categories: dates.map(dateLabel).toList(),
                series: seriesFor(unit),
                formatValue: (v) => _share
                    ? '${v.toStringAsFixed(1)}%'
                    : formatUnitAmountCompact(v, unit),
                showMissingMarkers: true,
                categoryNotes: [
                  for (final _ in dates) '공시 분류별 확인된 값입니다. 누락·상충 값은 미확인으로 표시하며 비중을 100%로 재조정하지 않습니다.',
                ],
                height: 260,
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          Text(
            '항목 이름이나 사업 구분이 달라진 경우 자동으로 같은 항목이라고 합치지 않습니다.',
            style: t.body(12, color: c.textMuted),
          ),
          ShadAccordion<int>(
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: const Text('기간별 원문 근거'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in facts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: Text(
                          '${dateLabel(businessFactDate(f))} · ${f.label}\n${f.evidence}',
                          style: t.body(12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
