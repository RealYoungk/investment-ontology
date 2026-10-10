import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import 'business_breakdown_panel.dart';
import '../business/overview_catalog.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../business/business_tab.dart' show documentFactKindLabel;
import '../../financials/financial_metrics.dart'
    show formatUnitAmount, formatUnitAmountCompact, formatSourceAmount;

const _operatingKinds = [
  DocumentFactKind.orderBacklog,
  DocumentFactKind.orderTotal,
  DocumentFactKind.orderDelivered,
  DocumentFactKind.utilization,
  DocumentFactKind.marketShare,
  DocumentFactKind.capacity,
  DocumentFactKind.production,
  DocumentFactKind.investmentActual,
  DocumentFactKind.investmentPlan,
  DocumentFactKind.rndExpense,
  DocumentFactKind.rndRatio,
];

/// Do not combine currencies, physical units, plans and realized investments.
/// Each year uses the API's deduplicated, verified source value.
DateTime businessFactDate(DocumentFact f) =>
    f.asOf ?? DateTime.utc(f.bsnsYear, 12, 31);

String businessPeriodLabel(DocumentFact f) {
  final date = businessFactDate(f);
  if (date.month == 12 && date.day == 31) return '${date.year}년';
  if (date.month == 6 && date.day == 30) return '${date.year} 상반기';
  if (date.month == 3 && date.day == 31) return '${date.year} 1분기';
  if (date.month == 9 && date.day == 30) return '${date.year} 1~3분기';
  return '${date.year}.${date.month.toString().padLeft(2, '0')}까지';
}

/// Short axis labels; the card and touch/hover detail retain the full period.
String businessAxisLabel(DocumentFact f, {bool narrow = false}) {
  final date = businessFactDate(f);
  final year = (date.year % 100).toString().padLeft(2, '0');
  if (date.month == 12 && date.day == 31) return year;
  if (date.month == 6 && date.day == 30) {
    return narrow ? '${year}H1' : '$year.1H';
  }
  if (date.month == 3 && date.day == 31) {
    return narrow ? '${year}Q1' : '$year.1Q';
  }
  if (date.month == 9 && date.day == 30) return '$year.9M';
  return '$year.${date.month.toString().padLeft(2, '0')}';
}

class OperatingPoint {
  const OperatingPoint({
    required this.date,
    required this.label,
    required this.axisLabel,
    this.fact,
  });
  final DateTime date;
  final String label;
  final String axisLabel;
  final DocumentFact? fact;
}

String factPeriodLabel(BusinessFactPeriod p) => switch (p.reportCode) {
  FinancialReportCode.annual => '${p.bsnsYear}년',
  FinancialReportCode.q1 => '${p.bsnsYear} 1분기',
  FinancialReportCode.halfYear => '${p.bsnsYear} 상반기',
  FinancialReportCode.q3 => '${p.bsnsYear} 1~3분기',
};

BusinessFactPeriod? operatingLatestPeriod(
  List<BusinessFactPeriod> periods,
  FinancialPeriod? latestReport,
) {
  final candidates = [...periods];
  if (latestReport != null) {
    final match = RegExp(r'\((20\d{2})[.](\d{2})\)')
        .firstMatch(latestReport.reportName);
    final month = switch (latestReport.reportCode) {
      FinancialReportCode.annual => 12,
      FinancialReportCode.q1 => 3,
      FinancialReportCode.halfYear => 6,
      FinancialReportCode.q3 => 9,
    };
    final date = match == null
        ? DateTime.utc(latestReport.bsnsYear, month + 1, 0)
        : DateTime.utc(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!) + 1,
            0,
          );
    candidates.add(
      BusinessFactPeriod(
        documentId: -1,
        bsnsYear: latestReport.bsnsYear,
        reportCode: latestReport.reportCode,
        periodEnd: date,
      ),
    );
  }
  candidates.sort((a, b) => a.periodEnd.compareTo(b.periodEnd));
  return candidates.lastOrNull;
}

/// Missing years are null observations, never zeros or silently connected bars.
List<OperatingPoint> operatingTimeline(
  List<DocumentFact> facts, {
  List<BusinessFactPeriod> periods = const [],
  FinancialPeriod? latestReport,
}) {
  final byDocument = {for (final p in periods) p.documentId: p};
  bool annual(DocumentFact f) {
    final p = byDocument[f.documentId];
    if (p != null && p.reportCode != FinancialReportCode.annual) return false;
    final date = businessFactDate(f);
    return p == null
        ? date.month == 12 && date.day == 31
        : date.month == p.periodEnd.month && date.day == p.periodEnd.day;
  }

  int year(DocumentFact f) {
    final p = byDocument[f.documentId];
    return p != null && businessFactDate(f) == p.periodEnd
        ? p.bsnsYear
        : businessFactDate(f).year;
  }

  final yearly = {for (final f in facts.where(annual)) year(f): f};
  final latest = operatingLatestPeriod(periods, latestReport);
  final lastYear = latest == null
      ? businessFactDate(facts.last).year -
            (businessFactDate(facts.last).month == 12 ? 0 : 1)
      : latest.bsnsYear -
            (latest.reportCode == FinancialReportCode.annual ? 0 : 1);
  final end = yearly.keys.fold(lastYear, (a, b) => a > b ? a : b);
  final start = end - 4;
  final points = <OperatingPoint>[
    for (var y = start; y <= end; y++)
      OperatingPoint(
        date:
            periods
                .where(
                  (p) =>
                      p.reportCode == FinancialReportCode.annual &&
                      p.bsnsYear == y,
                )
                .firstOrNull
                ?.periodEnd ??
            DateTime.utc(y, 12, 31),
        label: '$y년',
        axisLabel: (y % 100).toString().padLeft(2, '0'),
        fact: yearly[y],
      ),
  ];
  // Ratios and backlog snapshots can share a timeline with interim observations.
  // Cumulative production/investment amounts retain a separate annual chart.
  if (facts.last.kind == DocumentFactKind.rndExpense ||
      facts.last.kind == DocumentFactKind.rndRatio ||
      facts.last.kind == DocumentFactKind.utilization ||
      facts.last.kind == DocumentFactKind.marketShare ||
      facts.last.kind == DocumentFactKind.orderBacklog) {
    for (final f in facts.where((f) => !annual(f))) {
      final p = byDocument[f.documentId];
      points.add(
        OperatingPoint(
          date: businessFactDate(f),
          label: p != null && p.periodEnd == businessFactDate(f)
              ? factPeriodLabel(p)
              : businessPeriodLabel(f),
          axisLabel: businessAxisLabel(f),
          fact: f,
        ),
      );
    }
    if (latest != null &&
        latest.reportCode != FinancialReportCode.annual &&
        !points.any((p) => p.date == latest.periodEnd)) {
      final year = (latest.bsnsYear % 100).toString().padLeft(2, '0');
      final suffix = switch (latest.reportCode) {
        FinancialReportCode.halfYear => '1H',
        FinancialReportCode.q1 => '1Q',
        _ => '9M',
      };
      points.add(
        OperatingPoint(
          date: latest.periodEnd,
          label: factPeriodLabel(latest),
          axisLabel: '$year.$suffix',
        ),
      );
    }
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

bool matchesOperatingFocus(List<DocumentFact> series, List<String> focus) =>
    focus.any(
      (term) => series.first.label.toLowerCase().contains(term.toLowerCase()),
    );

List<List<DocumentFact>> operatingSeries(
  List<DocumentFact> facts, {
  List<String> focus = const [],
}) {
  final groups = <(DocumentFactKind, String, String), List<DocumentFact>>{};
  for (final f in facts) {
    if (!_operatingKinds.contains(f.kind) ||
        f.status != RelationStatus.verified ||
        !f.value.isFinite) {
      continue;
    }
    groups.putIfAbsent((f.kind, f.label, f.unit), () => []).add(f);
  }
  final result = groups.values.toList();
  for (final group in result) {
    group.sort(
      (a, b) => businessFactDate(a).compareTo(businessFactDate(b)),
    );
  }
  // The same table may be extracted under a short label and its annotated
  // equivalent. Collapse only identical annual values, retaining the annotation.
  String base(String label) => label.replaceAll(RegExp(r'\s+'), '').trim();
  final redundant = <List<DocumentFact>>{};
  for (var i = 0; i < result.length; i++) {
    for (var j = i + 1; j < result.length; j++) {
      final a = result[i], b = result[j];
      if (a.first.kind != b.first.kind ||
          a.first.unit != b.first.unit ||
          base(a.first.label) != base(b.first.label)) {
        continue;
      }
      DateTime date(DocumentFact f) => businessFactDate(f);
      final shorter = a.length <= b.length ? a : b;
      final longer = a.length <= b.length ? b : a;
      final byYear = {for (final f in longer) date(f): f.value};
      if (shorter.every((f) => byYear[date(f)] == f.value)) {
        final label = a.first.label.length >= b.first.label.length
            ? a.first.label
            : b.first.label;
        for (var k = 0; k < longer.length; k++) {
          longer[k] = longer[k].copyWith(label: label);
        }
        redundant.add(shorter);
      }
    }
  }
  result.removeWhere(redundant.contains);
  result.sort((a, b) {
    final af = matchesOperatingFocus(a, focus),
        bf = matchesOperatingFocus(b, focus);
    if (af != bf) return af ? -1 : 1;
    if (af && bf) {
      final ap = a.first.kind == DocumentFactKind.marketShare,
          bp = b.first.kind == DocumentFactKind.marketShare;
      if (ap != bp) return ap ? -1 : 1;
    }
    final order = _operatingKinds
        .indexOf(a.first.kind)
        .compareTo(_operatingKinds.indexOf(b.first.kind));
    return order == 0 ? a.first.label.compareTo(b.first.label) : order;
  });
  return result;
}

class BusinessOperatingSection extends StatefulWidget {
  const BusinessOperatingSection({
    super.key,
    required this.corpCode,
    this.dataVersion = 0,
    this.latestReport,
  });
  final FinancialPeriod? latestReport;
  final String corpCode;
  final int dataVersion;
  @override
  State<BusinessOperatingSection> createState() =>
      _BusinessOperatingSectionState();
}

class _BusinessOperatingSectionState extends State<BusinessOperatingSection> {
  List<List<DocumentFact>> _series = const [];
  List<DocumentFact> _breakdowns = const [];
  List<String> _focus = const [];
  List<BusinessFactPeriod> _periods = const [];
  bool _failed = false;
  bool _loaded = false;
  int _seq = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessOperatingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.dataVersion != widget.dataVersion) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _series = const [];
      _breakdowns = const [];
      _failed = false;
      _loaded = false;
    });
    try {
      final (facts, catalog, periods) = await (
        client.disclosure.factTrends(widget.corpCode),
        OverviewCatalog.load(),
        client.disclosure.factPeriods(widget.corpCode),
      ).wait;
      final focus =
          catalog.forCompany(widget.corpCode)?.research?.operatingFocus ??
          <String>[];
      if (mounted && seq == _seq) {
        setState(() {
          _loaded = true;
          _periods = periods;
          _breakdowns = facts;
          _focus = focus;
          _series = operatingSeries(facts, focus: focus);
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '사업 지표를 불러오지 못했습니다.',
                style: context.typo.body(
                  13,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            ShadButton.raw(
              onPressed: _load,

              variant: ShadButtonVariant.link,
              child: Flexible(child: Text('다시 시도')),
            ),
          ],
        ),
      );
    }
    if (!_loaded) return const SizedBox.shrink();
    final expected = operatingLatestPeriod(_periods, widget.latestReport);
    final missingKinds = _operatingKinds
        // Investment table history below owns these slots; do not label its
        // confirmed table values missing just because they are not facts.
        .where(
          (kind) =>
              kind != DocumentFactKind.investmentActual &&
              kind != DocumentFactKind.investmentPlan,
        )
        .where((kind) => !_breakdowns.any((f) => f.kind == kind))
        .toList();
    final annualEnd = expected == null
        ? null
        : expected.bsnsYear -
              (expected.reportCode == FinancialReportCode.annual ? 0 : 1);
    final years = annualEnd == null
        ? <int>[]
        : [for (var y = annualEnd - 4; y <= annualEnd; y++) y];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BusinessBreakdownPanel(
            key: ValueKey(('breakdowns', widget.corpCode, widget.dataVersion)),
            facts: _breakdowns,
            periods: _periods,
            latestReport: widget.latestReport,
          ),
          if (_series.isNotEmpty)
            OperatingMetricsList(
              key: ValueKey((widget.corpCode, widget.dataVersion)),
              series: _series,
              focus: _focus,
              periods: _periods,
              latestReport: widget.latestReport,
            ),
          if (missingKinds.isNotEmpty && years.isNotEmpty)
            DataPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('공시 수치 미확인 항목', style: context.typo.sectionTitle),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '—는 확인된 추출값이 없는 기간입니다. 0이나 공시하지 않았다는 의미가 아닙니다.',
                    style: context.typo.body(
                      12,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppDataTable(
                    columns: [
                      const AppColumn('항목'),
                      for (final year in years) AppColumn('$year년'),
                      if (expected != null &&
                          expected.reportCode != FinancialReportCode.annual)
                        AppColumn(factPeriodLabel(expected)),
                    ],
                    rows: [
                      for (final kind in missingKinds)
                        AppRow([
                          AppDataTable.text(
                            context,
                            documentFactKindLabel(kind),
                          ),
                          for (final _ in years)
                            AppDataTable.text(context, '—'),
                          if (expected != null &&
                              expected.reportCode != FinancialReportCode.annual)
                            AppDataTable.text(context, '—'),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Keep a company's reported backlog visible even when its editorial focus
/// prioritizes other products. Prefer a total over component backlog series.
List<List<DocumentFact>> primaryOperatingSeries(
  List<List<DocumentFact>> series, {
  List<String> focus = const [],
}) {
  final focused = focus.isEmpty
      ? <List<DocumentFact>>[]
      : series.where((s) => matchesOperatingFocus(s, focus)).toList();
  final preferred = focused.isEmpty ? series : focused;
  final backlog = series
      .where((s) => s.first.kind == DocumentFactKind.orderBacklog)
      .toList();
  final total = backlog
      .where(
        (s) =>
            RegExp(r'^합계(?:[\s(]|$)|^(?:연결|전체|총).*(?:수주|계약)')
                .hasMatch(s.first.label),
      )
      .firstOrNull;
  final pinned = total ?? backlog.firstOrNull;
  return <List<DocumentFact>>[
    ?pinned,
    ...preferred.where((s) => !identical(s, pinned)),
  ].take(4).toList();
}

/// Expanding adds secondary metrics without resizing or moving the primary ones.
class OperatingMetricsList extends StatefulWidget {
  const OperatingMetricsList({
    super.key,
    required this.series,
    this.focus = const [],
    this.periods = const [],
    this.latestReport,
  });
  final List<List<DocumentFact>> series;
  final List<String> focus;
  final List<BusinessFactPeriod> periods;
  final FinancialPeriod? latestReport;

  @override
  State<OperatingMetricsList> createState() => _OperatingMetricsListState();
}

class _OperatingMetricsListState extends State<OperatingMetricsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final utilization = widget.series
        .where((s) => s.first.kind == DocumentFactKind.utilization)
        .toList();
    final otherSeries = widget.series
        .where(
          (s) => !{
            DocumentFactKind.utilization,
            DocumentFactKind.capacity,
            DocumentFactKind.production,
          }.contains(s.first.kind),
        )
        .toList();
    final productionGroups =
        <(DocumentFactKind, String), List<List<DocumentFact>>>{};
    for (final facts in widget.series.where(
      (s) => {
        DocumentFactKind.capacity,
        DocumentFactKind.production,
      }.contains(s.first.kind),
    )) {
      (productionGroups[(facts.first.kind, facts.first.unit)] ??= []).add(
        facts,
      );
    }
    final primary = primaryOperatingSeries(otherSeries, focus: widget.focus);
    final secondary = otherSeries.where((s) => !primary.contains(s)).toList();
    final groups = <DocumentFactKind, List<List<DocumentFact>>>{};
    for (final series in secondary) {
      (groups[series.last.kind] ??= []).add(series);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CompanySectionHeading(
          '사업 지표',
          help: '생산능력은 설비의 생산 규모, 가동률은 설비를 사용한 비율입니다. 시장점유율은 해당 제품 시장에서 차지하는 비중입니다.\n\n지표마다 공시 시점과 단위가 다를 수 있으므로 표시된 기준 기간을 함께 확인하세요. 값이 없는 기간은 0으로 처리하지 않습니다.',
        ),
        if (utilization.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          _UtilizationOverview(
            series: utilization,
            periods: widget.periods,
            latestReport: widget.latestReport,
          ),
        ],
        for (final group in productionGroups.entries) ...[
          const SizedBox(height: AppSpace.md),
          _UtilizationOverview(
            series: group.value,
            periods: widget.periods,
            latestReport: widget.latestReport,
            title: documentFactKindLabel(group.key.$1),
            unit: group.key.$2,
          ),
        ],
        for (final series in primary) ...[
          const SizedBox(height: AppSpace.md),
          OperatingMetricCard(
            facts: series,
            periods: widget.periods,
            latestReport: widget.latestReport,
          ),
        ],
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.raw(
              onPressed: () => setState(() => _expanded = !_expanded),
              variant: ShadButtonVariant.link,
              child: Flexible(
                child: Text(
                  _expanded
                      ? '그 밖의 사업 지표 접기'
                      : '그 밖의 사업 지표 ${secondary.length}개 보기',
                ),
              ),
            ),
          ),
          if (_expanded)
            for (final group in groups.entries) ...[
              const SizedBox(height: AppSpace.lg),
              Text(
                group.key == DocumentFactKind.marketShare
                    ? '그 밖의 시장점유율'
                    : documentFactKindLabel(group.key),
                style: context.typo.body(14, weight: FontWeight.w700),
              ),
              for (final series in group.value) ...[
                const SizedBox(height: AppSpace.md),
                OperatingMetricCard(
                  facts: series,
                  periods: widget.periods,
                  latestReport: widget.latestReport,
                ),
              ],
            ],
        ],
      ],
    );
  }
}

class OperatingMetricCard extends StatelessWidget {
  const OperatingMetricCard({
    super.key,
    required this.facts,
    this.periods = const [],
    this.latestReport,
  });
  final List<BusinessFactPeriod> periods;
  final FinancialPeriod? latestReport;
  final List<DocumentFact> facts;
  @override
  Widget build(BuildContext context) {
    final latest = facts.last;
    final c = context.colors, t = context.typo;
    final points = operatingTimeline(
      facts,
      periods: periods,
      latestReport: latestReport,
    );
    final expected = operatingLatestPeriod(periods, latestReport);
    final missingLatest =
        latest.kind != DocumentFactKind.investmentPlan &&
            expected != null &&
            businessFactDate(latest).isBefore(expected.periodEnd)
        ? '${factPeriodLabel(expected)} 값 미확보'
        : null;
    final snapshot =
        latest.kind == DocumentFactKind.marketShare ||
        latest.kind == DocumentFactKind.orderBacklog;
    final sourcePeriod = periods
        .where(
          (p) =>
              p.documentId == latest.documentId &&
              p.periodEnd == businessFactDate(latest),
        )
        .firstOrNull;
    final hint = switch (latest.kind) {
      DocumentFactKind.orderBacklog => '받은 주문 중 아직 매출로 이어지지 않은 금액',
      DocumentFactKind.orderTotal => '공시 표에 기재된 계약 총액 · 신규 수주액과 구분',
      DocumentFactKind.orderDelivered => '계약 중 이미 납품한 금액',
      DocumentFactKind.rndExpense => '공시 표의 연구개발비 · 원문 단위 기준',
      DocumentFactKind.rndRatio => '공시된 연구개발비 ÷ 매출액 비율',
      DocumentFactKind.utilization => '생산설비를 사용한 비율',
      DocumentFactKind.marketShare =>
        latest.reviewNote?.isNotEmpty == true
            ? latest.reviewNote!
            : '해당 제품 시장에서 차지하는 비중',
      DocumentFactKind.capacity => '설비가 생산할 수 있는 규모',
      DocumentFactKind.production => '실제로 생산한 규모',
      DocumentFactKind.investmentActual => '설비 등에 집행한 투자',
      DocumentFactKind.investmentPlan => '회사가 밝힌 향후 투자 계획',
      _ => '',
    };
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          documentFactKindLabel(latest.kind),
          style: t.body(14, weight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          latest.label.contains('디지털 콕핏')
              ? '${latest.label} · 차량 운전석 시스템'
              : latest.label,
          style: t.body(13, color: c.textSecondary),
        ),
      ],
    );
    final reading = Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ShadTooltip(
          builder: (_) => Text(formatSourceAmount(latest.value, latest.unit)),
          child: Semantics(
            tooltip: formatSourceAmount(latest.value, latest.unit),
            child: Text(
              formatUnitAmountCompact(latest.value, latest.unit),
              style: t.numeric(20, weight: FontWeight.w700),
            ),
          ),
        ),
        Text(
          sourcePeriod == null
              ? businessPeriodLabel(latest)
              : factPeriodLabel(sourcePeriod),
          style: t.numeric(12, color: c.textMuted),
        ),
      ],
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: AppSpace.sm),
        reading,
        const SizedBox(height: AppSpace.xs),
        Text(hint, style: t.body(12, color: c.textSecondary)),
        if (missingLatest != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(missingLatest, style: t.body(12, color: c.textMuted)),
        ],
      ],
    );
    final chart = points.any((p) => p.fact != null)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xs),
                child: Text(
                  [
                    if (!snapshot)
                      points.any((p) => p.date.month != 12)
                          ? '기간별 추이'
                          : '연간 추이',
                    if (points.any((p) => p.fact == null)) '— 값 미확보',
                  ].join(' · '),
                  style: t.body(12, color: c.textMuted),
                ),
              ),
              LayoutBuilder(
                builder: (context, box) => AppColumnChart(
                  categories: [for (final p in points) p.label],
                  formatCategory: (label) {
                    final axis = points
                        .firstWhere((p) => p.label == label)
                        .axisLabel;
                    return box.maxWidth < 300
                        ? axis.replaceAll('.1H', 'H1').replaceAll('.1Q', 'Q1')
                        : axis;
                  },
                  series: [
                    ChartSeries(
                      label: documentFactKindLabel(latest.kind),
                      color: c.chartSeries1,
                      values: [for (final p in points) p.fact?.value],
                    ),
                  ],
                  categoryNotes: [
                    for (final p in points)
                      p.fact == null ? '해당 기간 값 미확보' : p.fact!.reviewNote,
                  ],
                  showMissingMarkers: true,
                  formatValue: (v) => formatUnitAmount(v, latest.unit),
                  height: 150,
                ),
              ),
            ],
          )
        : Text('연간 값 미확보', style: t.body(12, color: c.textMuted));
    return DataPanel(
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 620) {
            return Row(
              children: [
                SizedBox(width: 220, child: details),
                const SizedBox(width: AppSpace.xl),
                Expanded(child: chart),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: AppSpace.md),
              chart,
            ],
          );
        },
      ),
    );
  }
}

/// One metric card; distinct source scopes remain separate colored series.
class _UtilizationOverview extends StatelessWidget {
  const _UtilizationOverview({
    required this.series,
    required this.periods,
    this.latestReport,
    this.title = '가동률',
    this.unit = '%',
  });
  final List<List<DocumentFact>> series;
  final List<BusinessFactPeriod> periods;
  final FinancialPeriod? latestReport;
  final String title, unit;
  @override
  Widget build(BuildContext context) {
    final timelines = [
      for (final facts in series)
        operatingTimeline(facts, periods: periods, latestReport: latestReport),
    ];
    final points = <DateTime, OperatingPoint>{};
    for (final timeline in timelines) {
      for (final point in timeline) {
        points[point.date] = point;
      }
    }
    final dates = points.keys.toList()..sort();
    final palette = categoricalChartColors(context);
    final chartSeries = [
      for (final (index, facts) in series.indexed)
        ChartSeries(
          label: facts.first.label,
          color: palette[index % palette.length],
          values: [
            for (final date in dates)
              timelines[index]
                  .where((p) => p.date == date)
                  .firstOrNull
                  ?.fact
                  ?.value,
          ],
        ),
    ];
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompanySectionHeading(
            title,
            help: '서로 다른 원문 명칭·측정 범위는 별도 색상으로 표시합니다. 명칭이 바뀐 기간을 같은 계열로 임의 연결하지 않습니다. 합계는 개별 항목과 구분합니다.',
          ),
          Text(
            '단위: $unit',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          ChartLegend(series: chartSeries),
          Text(
            '품목 분류가 바뀐 기간은 별도 색상으로 표시합니다. 빈 구간은 해당 품목의 공시 수치가 없는 기간입니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          AppColumnChart(
            categories: [for (final date in dates) points[date]!.axisLabel],
            series: chartSeries,
            formatValue: (value) => unit == '%'
                ? '${value.toStringAsFixed(1)}%'
                : formatUnitAmount(value, ''),
            showMissingMarkers: true,
            height: 240,
            categoryNotes: [for (final date in dates) points[date]!.label],
          ),
          if (series.first.first.kind == DocumentFactKind.capacity ||
              series.first.first.kind == DocumentFactKind.production) ...[
            Text(
              '차트는 연간 기준입니다. 중간보고서의 생산 규모는 연간 값과 합산하지 않습니다.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
            if (series.any(
              (facts) => businessFactDate(facts.last).month != 12,
            )) ...[
              const SizedBox(height: AppSpace.md),
              Text(
                '최근 중간보고서',
                style: context.typo.body(13, weight: FontWeight.w600),
              ),
              AppDataTable(
                columns: const [
                  AppColumn('품목'),
                  AppColumn('기간'),
                  AppColumn('공시 수치', numeric: true),
                ],
                rows: [
                  for (final facts in series)
                    if (businessFactDate(facts.last).month != 12)
                      AppRow([
                        AppDataTable.text(context, facts.last.label),
                        AppDataTable.text(
                          context,
                          businessPeriodLabel(facts.last),
                        ),
                        AppDataTable.text(
                          context,
                          formatUnitAmount(facts.last.value, unit),
                        ),
                      ]),
                ],
              ),
            ],
          ],
          ShadAccordion<int>(
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: const Text('기간별 수치와 원문 근거'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final facts in series) ...[
                      Text(
                        facts.first.label,
                        style: context.typo.body(14, weight: FontWeight.w600),
                      ),
                      for (final fact in facts)
                        Text(
                          '${businessPeriodLabel(fact)} · ${formatUnitAmount(fact.value, fact.unit)}\n${fact.evidence}',
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
      ),
    );
  }
}
