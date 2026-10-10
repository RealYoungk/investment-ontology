import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../app/ingest_monitor.dart';
import 'business_history_cache.dart';
import 'disclosure_term_label.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart' show formatUnitAmount;

final _historyCache = BusinessHistoryCache(
  (code, year) => client.disclosure.businessContent(code, bsnsYear: year),
);

/// The five annual slots survive missing source reports; interim stays separate.
List<int> businessAnnualYears(
  BusinessContent latest, {
  FinancialPeriod? latestReport,
}) {
  final annual = latestReport != null
      ? latestReport.reportCode == FinancialReportCode.annual
      : latest.source?.title.contains('사업보고서') ?? false;
  final end = (latestReport?.bsnsYear ?? latest.bsnsYear) - (annual ? 0 : 1);
  return [for (var y = end - 4; y <= end; y++) y];
}

List<({int year, BusinessContent? report, String period})> businessHistorySlots(
  BusinessContent latest,
  List<BusinessContent> reports, {
  FinancialPeriod? latestReport,
}) {
  final years = businessAnnualYears(latest, latestReport: latestReport);
  final interimYear = latestReport?.bsnsYear ?? latest.bsnsYear;
  final interim = latestReport != null
      ? latestReport.reportCode != FinancialReportCode.annual
      : !years.contains(latest.bsnsYear);
  final interimPeriod = latestReport == null
      ? latest.source?.title ?? '$interimYear 중간보고서'
      : switch (latestReport.reportCode) {
          FinancialReportCode.halfYear => '$interimYear 상반기',
          FinancialReportCode.q1 => '$interimYear 1분기',
          FinancialReportCode.q3 => '$interimYear 3분기 누적',
          FinancialReportCode.annual => '$interimYear년',
        };
  final expectedDate = latestReport == null
      ? null
      : RegExp(r'\((20\d{2}\.\d{2})\)')
            .firstMatch(latestReport.reportName)
            ?.group(1);
  final sourceDate = RegExp(r'\((20\d{2}\.\d{2})\)')
      .firstMatch(latest.source?.title ?? '')
      ?.group(1);
  final matchesInterim =
      latestReport == null ||
      latest.rceptNo == latestReport.rceptNo ||
      (expectedDate != null && sourceDate == expectedDate);
  return [
    for (final year in years)
      (
        year: year,
        report: reports
            .where(
              (r) =>
                  r.bsnsYear == year &&
                  (r.source == null || r.source!.title.contains('사업보고서')),
            )
            .firstOrNull,
        period: '$year년',
      ),
    if (interim)
      (
        year: interimYear,
        report:
            matchesInterim &&
                latest.bsnsYear == interimYear &&
                !(latest.source?.title.contains('사업보고서') ?? false)
            ? latest
            : null,
        period: interimPeriod,
      ),
  ];
}

/// Compact axis labels; preserve the printed period in source details.
String businessHistoryAxisLabel(int year, String period) {
  final printedYear = int.tryParse(
    RegExp(r'(?:19|20)\d{2}').firstMatch(period)?.group(0) ?? '',
  );
  final yy = ((printedYear ?? year) % 100).toString().padLeft(2, '0');
  if (period.contains('상반기') || period.contains('반기')) return '$yy.1H';
  final quarter = RegExp(r'([1-4])분기').firstMatch(period)?.group(1);
  if (quarter != null) {
    return '$yy.${quarter}Q${period.contains('누적') ? ' 누적' : ''}';
  }
  return '$yy년';
}

/// Multi-row headers append a metric after the period (e.g. bank balance/rate).
String businessTablePeriodKey(String period) => period.split(' · ').first;

String newestBusinessTablePeriod(Iterable<String> periods) {
  final values = periods.map(businessTablePeriodKey).toSet().toList();
  int? rank(String value) => int.tryParse(
    RegExp(r'(?:19|20)\d{2}|제\s*(\d+)\s*기')
            .firstMatch(value)
            ?.group(0)
            ?.replaceAll(RegExp(r'제|기|\s'), '') ??
        '',
  );
  if (values.isEmpty) return '';
  if (values.any((v) => rank(v) == null)) return values.first;
  return values.reduce((a, b) => rank(b)! > rank(a)! ? b : a);
}

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
    this.latestReport,
  });
  final String corpCode;
  final BusinessContent latest;
  final String? topic, title;
  final bool share;
  final FinancialPeriod? latestReport;
  @override
  State<BusinessTableHistory> createState() => _BusinessTableHistoryState();
}

/// Each year's own filing wins over comparative project/patent listings.
Map<int, List<BusinessTableRecord>> businessRecordHistory(
  List<BusinessContent> reports,
  String topic,
) {
  final result = <int, List<BusinessTableRecord>>{};
  for (final report in reports) {
    final rows = [
      for (final table in report.tableInsights ?? <BusinessTableInsight>[])
        if (table.topic == topic)
          ...table.rows.where(
            (r) =>
                topic != 'researchProjects' ||
                (r.cells.isNotEmpty &&
                    int.tryParse(
                          RegExp(r'20\d{2}')
                                  .firstMatch(r.cells.first)
                                  ?.group(0) ??
                              '',
                        ) ==
                        report.bsnsYear),
          ),
    ];
    if (rows.isNotEmpty) result[report.bsnsYear] = rows;
  }
  return result;
}

/// A missing chart is different from a filing explicitly reporting no contracts.
String businessTopicCoverage(BusinessContent report, String topic) {
  if ((report.tableInsights ?? []).any(
    (t) => t.topic == topic && (t.rows.isNotEmpty || t.measures.isNotEmpty),
  )) {
    return '공시 항목 확인';
  }
  if (topic == 'customerConcentration') {
    return (report.tableInsights ?? []).any(
          (t) => t.topic == 'customerShareTotal',
        )
        ? '상위 매출처 합계만 확인'
        : '개별 비중 미확인';
  }
  if (topic == 'derivatives') {
    final text = report.sections.map((s) => s.text).join('\n');
    final fx = RegExp(r'미결제\s*통화선도계약의\s*내역은\s*없습니다').hasMatch(text);
    final swap = RegExp(r'미결제\s*금리스왑\s*계약의\s*내역은\s*없습니다').hasMatch(text);
    if (fx && swap) return '미결제 계약 없음';
  }
  return '자동 추출 항목 없음';
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
        oldWidget.latest.rceptNo != widget.latest.rceptNo ||
        oldWidget.latestReport?.rceptNo != widget.latestReport?.rceptNo) {
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
    final years = businessAnnualYears(
      widget.latest,
      latestReport: widget.latestReport,
    );
    final results = await Future.wait(
      years.map((year) async {
        try {
          final report = await _historyCache.read(
            widget.corpCode,
            year,
            (
              widget.corpCode,
              widget.latest.rceptNo,
              IngestMonitor.instance.dataVersion.value,
            ),
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

  Widget _researchList(BuildContext context, List<BusinessTableRecord> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ${row.cells.length > 1 ? row.cells[1] : row.label}',
                  style: context.typo.body(14),
                ),
                if (row.cells.length > 2 &&
                    row.cells[2].trim().isNotEmpty &&
                    row.cells[2].trim() != '-')
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpace.md),
                    child: Text(
                      row.cells[2],
                      style: context.typo.body(
                        12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
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
        if (widget.topic != 'derivatives' &&
            widget.title != null &&
            table.title != widget.title) {
          continue;
        }

        final periods = table.measures.map((m) => m.period).toSet();
        if (periods.isEmpty) continue;
        final newestPeriod = newestBusinessTablePeriod(periods);
        // The newest printed period is retained verbatim, including interim scope.
        final measures = table.measures.where((m) {
          if (businessTablePeriodKey(m.period) != newestPeriod) {
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
          groups
              .putIfAbsent((
                widget.topic ?? table.title,
                key.$1,
                key.$2,
              ), () => [])
              .add((
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
    final recordGroups = businessRecordHistory(_reports, widget.topic ?? '');
    final recordTopic = {
      'researchProjects',
      'intellectualProperty',
      'materialContext',
      'majorContracts',
    }.contains(widget.topic);
    final slots = businessHistorySlots(
      widget.latest,
      _reports,
      latestReport: widget.latestReport,
    );
    final recordYears = slots.map((s) => s.year).toList();
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
        if (!_loading && widget.topic != null) ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            children: [
              for (final slot in slots)
                Text(
                  '${slot.period} · ${slot.report == null ? '— 자료 미확보' : businessTopicCoverage(slot.report!, widget.topic!)}',
                  style: context.typo.body(
                    12,
                    color: context.colors.textSecondary,
                  ),
                ),
            ],
          ),
          if (widget.topic == 'customerConcentration')
            Text(
              '개별 매출처 비중이 공시된 기간만 표시합니다. 상위 매출처 합계는 별도의 집중도 차트에서 확인하세요. A사 등 익명 표기는 연도 간 같은 고객이라는 의미가 아닙니다.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
        ],
        if (widget.topic == 'researchProjects' && !_loading) ...[
          const SizedBox(height: AppSpace.md),
          Text('보고서 연도별 연구과제', style: context.typo.body(13)),
          Text(
            '각 연도 보고서에 기재된 해당 연도 과제입니다. 이전 연도 비교 항목은 중복하지 않습니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          for (final year in recordYears.reversed) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              '$year년 · ${recordGroups[year]?.length ?? 0}개 확인',
              style: context.typo.body(14),
            ),
            if (!recordGroups.containsKey(year))
              const Text('— 해당 연도 과제 미확인')
            else if (recordGroups[year]!.length <= 15)
              _researchList(context, recordGroups[year]!)
            else
              ShadAccordion<int>(
                children: [
                  ShadAccordionItem<int>(
                    value: year,
                    title: Text('과제 ${recordGroups[year]!.length}개 보기'),
                    child: _researchList(context, recordGroups[year]!),
                  ),
                ],
              ),
            if (_reports.any((r) => r.bsnsYear == year))
              ShadButton.ghost(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${_reports.lastWhere((r) => r.bsnsYear == year).rceptNo}',
                  ),
                ),
                child: Text('$year년 DART 원문'),
              ),
          ],
        ],
        if (recordTopic &&
            widget.topic != 'researchProjects' &&
            recordGroups.isNotEmpty)
          BusinessRecordTimeline(reports: _reports, topic: widget.topic!),
        for (final group in visibleGroups) ...[
          const SizedBox(height: AppSpace.lg),
          DisclosureTermLabel(
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
                      for (final slot in slots)
                        (() {
                          final values = group.value
                              .where(
                                (row) => row.$1.rceptNo == slot.report?.rceptNo,
                              )
                              .expand((row) => row.$3)
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
                  ChartLegend(
                    series: series,
                    labelBuilder: widget.topic == 'derivatives'
                        ? (context, label) => DisclosureTermLabel(label)
                        : null,
                  ),
                  AppColumnChart(
                    categories: [
                      for (final slot in slots)
                        businessHistoryAxisLabel(
                          slot.year,
                          slot.period,
                        ),
                    ],
                    series: series,
                    formatValue: (v) => formatUnitAmount(v, group.key.$3),
                    height: 240,
                    showMissingMarkers: true,
                    categoryNotes: [
                      for (final slot in slots)
                        slot.report == null
                            ? '자료 미확보 · 빈값은 0이 아닙니다.'
                            : '${businessTopicCoverage(slot.report!, widget.topic ?? '')} · —는 추출값 미확인입니다.',
                    ],
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
        if (!_loading &&
            groups.isEmpty &&
            (!recordTopic || recordGroups.isEmpty))
          const Text('최근 5개년에서 시각화 가능한 표를 찾지 못했습니다.'),
      ],
    );
  }
}

/// Exact records recur in successive filings. Show each once with all source years.
class BusinessRecordTimeline extends StatelessWidget {
  const BusinessRecordTimeline({
    super.key,
    required this.reports,
    required this.topic,
  });
  final List<BusinessContent> reports;
  final String topic;
  @override
  Widget build(BuildContext context) {
    final groups =
        <String, (List<String>, Map<String, (List<String>, Set<int>)>)>{};
    for (final report in reports) {
      for (final table in report.tableInsights ?? <BusinessTableInsight>[]) {
        if (table.topic != topic) continue;
        final key = table.columns.join('\u001f');
        final group = groups.putIfAbsent(key, () => (table.columns, {}));
        for (final row in table.rows) {
          final record = group.$2.putIfAbsent(
            row.cells.join('\u001f'),
            () => (row.cells, <int>{}),
          );
          record.$2.add(report.bsnsYear);
        }
      }
    }
    final orderedReports = [...reports]
      ..sort((a, b) => b.bsnsYear.compareTo(a.bsnsYear));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.md),
        Text(
          '동일 항목은 한 번 표시하고 공시에서 확인한 연도를 함께 적었습니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
        for (final group in groups.values) ...[
          const SizedBox(height: AppSpace.sm),
          if (topic == 'intellectualProperty')
            _PatentRecordList(
              columns: group.$1,
              records: group.$2.values.toList(),
            )
          else
            AppDataTable(
              columns: [
                for (final column in group.$1) AppColumn(column),
                const AppColumn('확인 연도'),
              ],
              rows: [
                for (final record in group.$2.values)
                  AppRow([
                    for (final cell in record.$1)
                      AppDataTable.text(context, cell),
                    AppDataTable.text(
                      context,
                      (record.$2.toList()..sort()).join(' · '),
                    ),
                  ]),
              ],
            ),
        ],
        ShadAccordion<int>(
          children: [
            for (final report in orderedReports)
              if ((report.tableInsights ?? []).any((t) => t.topic == topic))
                ShadAccordionItem<int>(
                  value: report.bsnsYear,
                  title: Text('${report.bsnsYear}년 원문 근거'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        report.tableInsights!
                            .where((t) => t.topic == topic)
                            .map((t) => t.evidence)
                            .join('\n\n'),
                        style: context.typo.body(12),
                      ),
                      ShadButton.ghost(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${report.rceptNo}',
                          ),
                        ),
                        child: Text('${report.bsnsYear}년 DART 원문'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _PatentRecordList extends StatelessWidget {
  const _PatentRecordList({required this.columns, required this.records});
  final List<String> columns;
  final List<(List<String>, Set<int>)> records;
  @override
  Widget build(BuildContext context) {
    final sorted = [...records]
      ..sort(
        (a, b) => b.$2
            .reduce((x, y) => x > y ? x : y)
            .compareTo(a.$2.reduce((x, y) => x > y ? x : y)),
      );
    String cell(List<String> cells, String name) {
      final i = columns.indexWhere((c) => c.replaceAll(' ', '').contains(name));
      return i >= 0 && i < cells.length ? cells[i] : '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${sorted.length}개 공시 항목',
          style: context.typo.body(13, weight: FontWeight.w600),
        ),
        for (final (index, record) in sorted.indexed) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            record.$1.first,
            style: context.typo.body(14, weight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              Text(
                '취득 ${cell(record.$1, '취득일')}',
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                '공시 확인 ${(record.$2.toList()..sort()).join(' · ')}',
                style: context.typo.body(12, color: context.colors.textMuted),
              ),
            ],
          ),
          ShadAccordion<int>(
            children: [
              ShadAccordionItem<int>(
                value: index,
                title: const Text('내용·활용 계획과 출원 국가'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var i = 0;
                      i < columns.length && i < record.$1.length;
                      i++
                    ) ...[
                      Text(
                        columns[i],
                        style: context.typo.body(
                          12,
                          color: context.colors.textMuted,
                        ),
                      ),
                      SelectableText(
                        record.$1[i],
                        style: context.typo.body(13),
                      ),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
