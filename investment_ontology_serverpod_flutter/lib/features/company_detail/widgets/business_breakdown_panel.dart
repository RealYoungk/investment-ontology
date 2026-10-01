import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart' show formatUnitAmount;
import 'business_operating_section.dart';

/// Only an explicitly partitioned single table can supply export exposure.
double? exportRevenueShare(List<DocumentFact> rows) {
  if (rows.isEmpty ||
      rows.any(
        (r) =>
            r.kind != DocumentFactKind.geographicRevenue ||
            r.status != RelationStatus.verified ||
            r.value < 0 ||
            r.documentId != rows.first.documentId ||
            r.unit != rows.first.unit ||
            r.evidence != rows.first.evidence ||
            businessFactDate(r) != businessFactDate(rows.first) ||
            !(r.label.startsWith('내수 · ') || r.label.startsWith('수출 · ')),
      )) {
    return null;
  }
  final total = rows.fold(0.0, (s, r) => s + r.value);
  return total <= 0
      ? null
      : rows
                .where((r) => r.label.startsWith('수출 · '))
                .fold(0.0, (s, r) => s + r.value) /
            total *
            100;
}

/// Match the numerator and denominator by source table as well as period/unit.
/// Ordinary product revenue is deliberately not a fallback for segment sales.
double? segmentMargin(DocumentFact profit, List<DocumentFact> facts) {
  if (profit.kind != DocumentFactKind.segmentOperatingProfit ||
      profit.status != RelationStatus.verified) {
    return null;
  }
  final matches = facts
      .where(
        (f) =>
            f.kind == DocumentFactKind.segmentOperatingRevenue &&
            f.status == RelationStatus.verified &&
            f.documentId == profit.documentId &&
            f.label == profit.label &&
            f.unit == profit.unit &&
            businessFactDate(f) == businessFactDate(profit) &&
            f.evidence == profit.evidence,
      )
      .toList();
  if (matches.length != 1 || matches.single.value <= 0) return null;
  return profit.value / matches.single.value * 100;
}

class BusinessBreakdownPanel extends StatefulWidget {
  const BusinessBreakdownPanel({
    super.key,
    required this.facts,
    this.periods = const [],
    this.latestReport,
  });
  final List<DocumentFact> facts;
  final List<BusinessFactPeriod> periods;
  final FinancialPeriod? latestReport;
  @override
  State<BusinessBreakdownPanel> createState() => _BusinessBreakdownPanelState();
}

class _BusinessBreakdownPanelState extends State<BusinessBreakdownPanel> {
  int? _document;
  @override
  Widget build(BuildContext context) {
    final facts =
        widget.facts
            .where(
              (f) =>
                  f.status == RelationStatus.verified &&
                  {
                    DocumentFactKind.segmentOperatingRevenue,
                    DocumentFactKind.segmentOperatingProfit,
                    DocumentFactKind.geographicRevenue,
                  }.contains(f.kind),
            )
            .toList()
          ..sort((a, b) => businessFactDate(b).compareTo(businessFactDate(a)));
    if (facts.isEmpty) return const SizedBox.shrink();
    final documents = <int, DocumentFact>{};
    for (final f in facts) {
      documents.putIfAbsent(f.documentId, () => f);
    }
    final selected = documents.containsKey(_document)
        ? _document!
        : documents.keys.first;
    final rows = facts.where((f) => f.documentId == selected).toList();
    final profits = rows
        .where((f) => f.kind == DocumentFactKind.segmentOperatingProfit)
        .toList();
    final geography = rows
        .where((f) => f.kind == DocumentFactKind.geographicRevenue)
        .toList();
    final expected = operatingLatestPeriod(widget.periods, widget.latestReport);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('어디서 팔고, 어떤 사업이 이익을 내나요?', accent: true),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<int>(
            value: selected,
            items: [
              for (final d in documents.entries)
                DropdownMenuItem(
                  value: d.key,
                  child: Text(businessPeriodLabel(d.value)),
                ),
            ],
            onChanged: (value) => setState(() => _document = value),
          ),
        ),
        if (expected != null &&
            businessFactDate(facts.first).isBefore(expected.periodEnd))
          Text(
            '${factPeriodLabel(expected)} 사업부문·지역 지표 미확보',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
        if (profits.isNotEmpty)
          _card(context, '사업부문별 수익성', [
            Text(
              '영업이익률 = 같은 표의 영업이익 ÷ 매출액. 부문 합계는 내부거래 조정 때문에 전체 실적과 다를 수 있습니다.',
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
            for (final p in profits) _profit(context, p, rows),
          ]),
        if (geography.isNotEmpty)
          _card(context, '지역별 매출 · 내수와 수출', [
            Text(
              '표에 공시된 구분과 회계 기준을 유지합니다. 별도 매출을 연결 매출과 합산하지 않습니다.',
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
            for (final group in _tables(geography)) ...[
              if (exportRevenueShare(group) case final share?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Text(
                    '수출 비중 ${share.toStringAsFixed(1)}% · 내수 ${(100 - share).toStringAsFixed(1)}%',
                    style: context.typo.numeric(16, weight: FontWeight.w700),
                  ),
                ),
              for (final f in group)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Wrap(
                    spacing: AppSpace.md,
                    runSpacing: AppSpace.xs,
                    children: [
                      Text(f.label, style: context.typo.body(13)),
                      Text(
                        formatUnitAmount(f.value, f.unit),
                        style: context.typo.numeric(
                          14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(f.value / group.fold(0.0, (s, r) => s + r.value) * 100).toStringAsFixed(1)}%',
                        style: context.typo.numeric(
                          13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '비중은 이 표의 지역 매출 합계 기준',
                style: context.typo.body(11, color: context.colors.textMuted),
              ),
            ],
          ]),
        ExpansionTile(
          title: const Text('연간 추이와 공시 근거'),
          children: [
            for (final current in [...profits, ...geography])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: OperatingMetricCard(
                  facts:
                      facts
                          .where(
                            (f) =>
                                f.kind == current.kind &&
                                f.label == current.label &&
                                f.unit == current.unit,
                          )
                          .toList()
                        ..sort(
                          (a, b) =>
                              businessFactDate(a)
                                  .compareTo(businessFactDate(b)),
                        ),
                  periods: widget.periods,
                  latestReport: widget.latestReport,
                ),
              ),
            for (final evidence in rows.map((f) => f.evidence).toSet())
              Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: SelectableText(evidence, style: context.typo.body(12)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }

  List<List<DocumentFact>> _tables(List<DocumentFact> facts) {
    final groups = <(String, String), List<DocumentFact>>{};
    for (final f in facts) {
      (groups[(f.evidence, f.unit)] ??= []).add(f);
    }
    return groups.values.toList();
  }

  Widget _card(BuildContext context, String title, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(top: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: context.colors.border),
          borderRadius: context.shape.borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.typo.body(16, weight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            ...children,
          ],
        ),
      );

  Widget _profit(
    BuildContext context,
    DocumentFact profit,
    List<DocumentFact> rows,
  ) {
    final margin = segmentMargin(profit, rows);
    final revenue = rows
        .where(
          (f) =>
              f.kind == DocumentFactKind.segmentOperatingRevenue &&
              f.label == profit.label &&
              f.unit == profit.unit &&
              f.evidence == profit.evidence,
        )
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            profit.label,
            style: context.typo.body(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              Text(
                '매출 ${revenue == null ? '미확보' : formatUnitAmount(revenue.value, revenue.unit)}',
                style: context.typo.body(13),
              ),
              Text(
                '영업${profit.value < 0 ? '손실' : '이익'} ${formatUnitAmount(profit.value, profit.unit)}',
                style: context.typo.body(13),
              ),
              Text(
                '이익률 ${margin == null ? '계산 불가' : '${margin.toStringAsFixed(1)}%'}',
                style: context.typo.numeric(14, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
