import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/components/components.dart';
import 'business_table_history.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart' show formatUnitAmount;

/// Each chart keeps one named metric, unit and printed period together.
Map<(String, String, String), List<BusinessTableMeasure>> tableMeasureGroups(
  BusinessTableInsight insight,
) {
  final groups = <(String, String, String), List<BusinessTableMeasure>>{};
  for (final measure in insight.measures) {
    if (!measure.value.isFinite || measure.unit.isEmpty) continue;
    groups
        .putIfAbsent((measure.metric, measure.unit, measure.period), () => [])
        .add(measure);
  }
  return groups;
}

class BusinessTableInsightsPanel extends StatefulWidget {
  const BusinessTableInsightsPanel({
    super.key,
    required this.insights,
    required this.rceptNo,
    this.corpCode,
    this.latest,
  });
  final List<BusinessTableInsight> insights;
  final String rceptNo;
  final String? corpCode;
  final BusinessContent? latest;

  @override
  State<BusinessTableInsightsPanel> createState() =>
      _BusinessTableInsightsPanelState();
}

class _BusinessTableInsightsPanelState
    extends State<BusinessTableInsightsPanel> {
  final Map<int, bool> _shares = {};
  List<BusinessTableInsight> get insights {
    if (corpCode == null || latest == null) return widget.insights;
    // History loads every table matching this topic/title. Rendering one history
    // per source table repeats the same merged chart and its source evidence.
    final seen = <(String, String)>{};
    return widget.insights
        .where((table) => seen.add((table.topic, table.title)))
        .toList();
  }

  String get rceptNo => widget.rceptNo;
  String? get corpCode => widget.corpCode;
  BusinessContent? get latest => widget.latest;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, insight) in insights.indexed) ...[
        const SizedBox(height: AppSpace.lg),
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanySectionHeading(
                insight.title,
                trailing:
                    insight.topic == 'materialPurchase' &&
                        corpCode != null &&
                        latest != null
                    ? IntrinsicWidth(
                        child: ShadTabs<bool>(
                          value: _shares[index] ?? false,
                          onChanged: (value) =>
                              setState(() => _shares[index] = value),
                          expandTabs: false,
                          tabs: const [
                            ShadTab<bool>(value: false, child: Text('매입액')),
                            ShadTab<bool>(value: true, child: Text('비중 (%)')),
                          ],
                        ),
                      )
                    : null,
                help:
                    '${insight.validation}\n${insight.scope ?? ''}\n기간·단위는 원문 표기를 따릅니다. 분류 변경은 구분하고 누락 값은 0으로 채우지 않습니다. 분기 표기만으로 누적 여부를 추정하지 않습니다.',
              ),
              const SizedBox(height: AppSpace.sm),
              if (insight.measures.any(
                (m) =>
                    m.period.contains('분기') &&
                    !RegExp(r'누적|상반기|1~|3개월|6개월').hasMatch(m.period),
              ))
                Text(
                  '분기·누적 구분 미확인',
                  style: context.typo.body(12, color: context.colors.textMuted),
                ),
              if (corpCode == null || latest == null) ...[
                if (insight.topic == 'investmentPlan')
                  Text(
                    '계획·진행 중인 투자입니다. 기투자액과 향후투자액을 구분해 보세요.',
                    style: context.typo.body(13),
                  ),
                if (insight.topic == 'materialPurchase') ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    '원문 금액 단위: ${insight.measures.where((m) => m.unit != '%').map((m) => m.unit).toSet().join(', ')}. 금액·비율은 각 열에 적힌 기간의 값입니다.',
                    style: context.typo.body(13),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _MaterialPurchaseVisual(insight: insight),
                  const SizedBox(height: AppSpace.md),
                ],
                for (final group
                    in (insight.topic == 'materialPurchase'
                        ? <
                            MapEntry<
                              (String, String, String),
                              List<BusinessTableMeasure>
                            >
                          >[]
                        : tableMeasureGroups(insight).entries)) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    '${group.key.$1} · ${group.key.$3} · ${group.key.$2}',
                    style: context.typo.body(13, weight: FontWeight.w600),
                  ),
                  _TableMeasureChart(
                    measures: group.value,
                    metric: group.key.$1,
                    unit: group.key.$2,
                  ),
                ],
                if (insight.measures.isEmpty)
                  Text(
                    '${insight.rows.length}개 공시 항목 · 금액·단위가 명확한 열이 없어 차트를 만들지 않았습니다.',
                    style: context.typo.body(13),
                  ),
                if (insight.topic == 'researchProjects' ||
                    insight.topic == 'majorContracts')
                  for (final row in insight.rows.take(3)) ...[
                    const SizedBox(height: AppSpace.md),
                    Text(
                      row.cells.first,
                      style: context.typo.body(14, weight: FontWeight.w600),
                    ),
                    for (var i = 1; i < insight.columns.length; i++)
                      if (row.cells[i].isNotEmpty && row.cells[i] != '-')
                        Text(
                          '${insight.columns[i]} · ${row.cells[i]}',
                          style: context.typo.body(12),
                        ),
                  ],
                ShadAccordion<int>(
                  key: ValueKey('table-$rceptNo-$index'),
                  children: [
                    ShadAccordionItem<int>(
                      value: 0,
                      title: Text('항목별 정보 ${insight.rows.length}개'),
                      child: AppDataTable(
                        columns: [
                          for (final column in insight.columns)
                            AppColumn(column),
                        ],
                        rows: [
                          for (final row in insight.rows)
                            AppRow([
                              for (final cell in row.cells)
                                AppDataTable.text(context, cell),
                            ]),
                        ],
                      ),
                    ),
                    ShadAccordionItem<int>(
                      value: 1,
                      title: const Text('추출 근거'),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          insight.evidence,
                          style: context.typo.body(12),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.ghost(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$rceptNo',
                      ),
                    ),
                    child: const Text('DART 공시 원문'),
                  ),
                ),
              ] else
                BusinessTableHistory(
                  key: ValueKey('$corpCode-${insight.topic}-${insight.title}'),
                  corpCode: corpCode!,
                  latest: latest!,
                  topic: insight.topic,
                  title: insight.title,
                  share: _shares[index] ?? false,
                ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _TableMeasureChart extends StatefulWidget {
  const _TableMeasureChart({
    required this.measures,
    required this.metric,
    required this.unit,
  });
  final List<BusinessTableMeasure> measures;
  final String metric, unit;
  @override
  State<_TableMeasureChart> createState() => _TableMeasureChartState();
}

class _TableMeasureChartState extends State<_TableMeasureChart> {
  int _page = 0;
  static const _size = 16;
  @override
  void didUpdateWidget(covariant _TableMeasureChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measures != widget.measures) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * _size;
    final visible = widget.measures.skip(start).take(_size).toList();
    return Column(
      children: [
        AppColumnChart(
          categoryNoun: '항목',
          categories: visible.map((m) => m.label).toList(),
          series: [
            ChartSeries(
              label: widget.metric,
              color: context.colors.chartSeries1,
              values: visible.map((m) => m.value).toList(),
            ),
          ],
          formatValue: (v) => formatUnitAmount(v, widget.unit),
          formatCategory: (s) => s.length > 12 ? '${s.substring(0, 11)}…' : s,
          height: 210,
        ),
        if (widget.measures.length > _size)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShadButton.ghost(
                enabled: _page > 0,
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
                child: const Text('이전 항목'),
              ),
              Text(
                '${start + 1}–${start + visible.length} / ${widget.measures.length}개',
                style: context.typo.body(12),
              ),
              ShadButton.ghost(
                enabled: start + _size < widget.measures.length,
                onPressed: start + _size < widget.measures.length
                    ? () => setState(() => _page++)
                    : null,
                child: const Text('다음 항목'),
              ),
            ],
          ),
      ],
    );
  }
}

/// Printed shares determine bar length; amounts retain their own unit and period.
class _MaterialPurchaseVisual extends StatelessWidget {
  const _MaterialPurchaseVisual({required this.insight});
  final BusinessTableInsight insight;

  @override
  Widget build(BuildContext context) {
    final shares = insight.measures
        .where((m) => m.unit == '%' && m.value >= 0 && m.value <= 100)
        .toList();
    final labels = insight.measures.map((m) => m.label).toSet().toList();
    final palette = categoricalChartColors(context);
    final groups = <String, List<BusinessTableMeasure>>{};
    for (final share in shares) {
      groups.putIfAbsent(share.period, () => []).add(share);
    }
    if (groups.isEmpty) {
      return Column(
        children: [
          for (final group in tableMeasureGroups(insight).entries)
            if (group.key.$2 != '%') ...[
              Text('${group.key.$3} · ${group.key.$1} (${group.key.$2})'),
              _TableMeasureChart(
                measures: group.value,
                metric: group.key.$1,
                unit: group.key.$2,
              ),
            ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            group.key,
            style: context.typo.body(15, weight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final share in group.value) ...[
            Builder(
              builder: (context) {
                final amount = insight.measures
                    .where(
                      (m) =>
                          m.period == share.period &&
                          m.label == share.label &&
                          m.unit != '%',
                    )
                    .toList();
                final valueText =
                    '${share.value.toStringAsFixed(2)}%${amount.length == 1 ? ' · ${formatUnitAmount(amount.single.value, amount.single.unit)}' : ''}';
                return Semantics(
                  label: '${group.key} · ${share.label} · $valueText',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(share.label, style: context.typo.body(13)),
                      Text(
                        valueText,
                        style: context.typo.body(13, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Container(
                        height: 14,
                        color: context.colors.chartGrid,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: share.value / 100,
                          heightFactor: 1,
                          child: ColoredBox(
                            color:
                                palette[labels.indexOf(share.label) %
                                    palette.length],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
        Text(
          '막대 길이는 원문 매입 비중(0~100%)입니다. 기간별 금액의 증감률은 계산하지 않습니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
      ],
    );
  }
}
