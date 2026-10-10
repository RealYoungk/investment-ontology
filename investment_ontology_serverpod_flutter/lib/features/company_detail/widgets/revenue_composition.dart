import 'revenue_trends.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';
import '../business/power_product_lesson.dart';
import 'business_operating_section.dart'
    show businessFactDate, businessPeriodLabel;

/// Preserve filing labels before the amount, including merged category cells.
/// Dated facts use an unambiguous amount/ratio pair from the printed row.
({String label, double? share}) revenuePresentation(DocumentFact fact) {
  final cells = fact.evidence
      .split('\n')
      .first
      .split('|')
      .map((s) => s.trim())
      .toList();
  final combined = RegExp(r'^([\d,]+(?:\.\d+)?)\s*\(\s*([\d.]+)\s*%\s*\)$');
  final combinedCells = cells.map(combined.firstMatch).nonNulls.toList();
  if (combinedCells.isNotEmpty) {
    final matching = combinedCells
        .where(
          (m) => double.tryParse(m.group(1)!.replaceAll(',', '')) == fact.value,
        )
        .toList();
    final match = fact.asOf == null
        ? combinedCells.first
        : matching.length == 1
        ? matching.single
        : null;
    if (match == null ||
        double.tryParse(match.group(1)!.replaceAll(',', '')) != fact.value) {
      return (label: fact.label, share: null);
    }
    final share = double.tryParse(match.group(2)!);
    return (
      label: fact.label,
      share: share != null && share <= 100 ? share : null,
    );
  }
  final firstAmount = cells.indexWhere(
    (s) => RegExp(r'^-?[\d,]+(?:\.\d+)?$').hasMatch(s),
  );
  final matches = [
    for (var i = 0; i + 1 < cells.length; i++)
      if (double.tryParse(cells[i].replaceAll(',', '')) == fact.value &&
          RegExp(r'^\d+(?:\.\d+)?%$').hasMatch(cells[i + 1]))
        i,
  ];
  if (fact.asOf != null && matches.length > 1) {
    return (label: fact.label, share: null);
  }
  // Period-dated rule facts can come from ascending year headers. The stored
  // amount must identify exactly one amount/ratio pair; never guess on ties.
  final index = fact.asOf != null && matches.length == 1
      ? matches.single
      : firstAmount;
  if (index <= 0 ||
      double.tryParse(cells[index].replaceAll(',', '')) != fact.value) {
    return (label: fact.label, share: null);
  }
  final labels = cells.take(firstAmount).where((s) => s.isNotEmpty).toList();
  final share =
      index + 1 < cells.length &&
          RegExp(r'^\d+(?:\.\d+)?%$').hasMatch(cells[index + 1])
      ? double.tryParse(cells[index + 1].replaceAll('%', ''))
      : null;
  return (
    label: labels.join(' · '),
    share: share != null && share <= 100 ? share : null,
  );
}

String revenueBasisNote(DocumentFact fact) {
  final basis = RegExp(r'\(\s*(별도|연결)\s*\)')
      .allMatches(fact.evidence)
      .map((m) => m.group(1)!)
      .toSet();
  return basis.length == 1
      ? '${basis.single} 기준 · 재무 탭과 보고 기준을 확인해 비교하세요.'
      : '연결·별도 기준은 공시 원문에서 확인하세요.';
}

/// A validated row does not prove that the whole company's mix was extracted.
String revenueCoverageNote(List<DocumentFact> rows) {
  final shares = rows.map((f) => revenuePresentation(f).share).toList();
  if (shares.any((s) => s == null)) {
    return '확인된 공시 항목만 표시합니다. 전체 매출 구성은 확인되지 않았습니다.';
  }
  final total = shares.fold<double>(0, (sum, s) => sum + s!);
  if (total > 101) return '공시 비중 합계가 100%를 넘습니다. 내부거래·중복 부문이 포함될 수 있습니다.';
  if (total < 99) {
    return '표시된 공시 비중 합계 ${total.toStringAsFixed(1)}% · 전체 매출 구성이 아닙니다.';
  }
  if (rows.length == 1) return '공시에서는 하나의 부문으로 묶어 표시합니다. 제품별 매출 구분은 아닙니다.';
  return '공시의 부문 구분과 비중입니다.';
}

/// One document/year only: never combine overlapping segment tables or years.
List<DocumentFact> latestRevenueFacts(List<DocumentFact> facts) {
  final rows = facts
      .where(
        (f) =>
            f.kind == DocumentFactKind.segmentRevenue &&
            f.status == RelationStatus.verified,
      )
      .toList();
  if (rows.isEmpty) return [];
  rows.sort((a, b) {
    final byYear = businessFactDate(b).compareTo(businessFactDate(a));
    return byYear != 0 ? byYear : b.documentId.compareTo(a.documentId);
  });
  final first = rows.first;
  return rows
      .where(
        (f) =>
            businessFactDate(f) == businessFactDate(first) &&
            f.documentId == first.documentId,
      )
      .toList();
}

class RevenueComposition extends StatefulWidget {
  const RevenueComposition({
    super.key,
    required this.corpCode,
    this.products = const [],
    this.printedMix,
    this.showTrends = true,
    this.compact = false,
    this.latestReport,
  });
  final bool compact;
  final FinancialPeriod? latestReport;
  final bool showTrends;
  final String corpCode;
  final List<BusinessProduct> products;
  final PowerProductLesson? printedMix;
  @override
  State<RevenueComposition> createState() => _RevenueCompositionState();
}

class _RevenueCompositionState extends State<RevenueComposition> {
  List<DocumentFact>? _rows;
  List<DocumentFact> _history = [];
  List<BusinessFactPeriod> _historyPeriods = [];
  bool _failed = false;
  int _seq = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RevenueComposition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.corpCode != oldWidget.corpCode) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _rows = null;
      _history = [];
      _failed = false;
    });
    try {
      final (facts, periods) = await (
        client.disclosure.factTrends(widget.corpCode),
        client.disclosure.factPeriods(widget.corpCode),
      ).wait;
      if (mounted && seq == _seq) {
        setState(() {
          _rows = latestRevenueFacts(facts);
          _history = facts;
          _historyPeriods = periods;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final rows = _rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanySectionHeading(
                '매출 구성',
                help:
                    '사업별 매출 규모와 공시에 적힌 비중을 비교합니다.\n\n'
                    '${rows != null && rows.isNotEmpty ? revenueCoverageNote(rows) : '수집한 공시에서 자동 검증된 항목을 표시합니다.'}\n\n'
                    '분기·반기는 해당 기간의 누적 매출이며, 연간 매출과 기간이 다릅니다. 비중을 임의로 100%에 맞추지 않습니다.',
              ),
              const SizedBox(height: AppSpace.sm),
              if (_failed) ...[
                Text('매출 구성을 불러오지 못했습니다.', style: t.body(13)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.ghost(
                    onPressed: _load,
                    child: Flexible(child: const Text('다시 불러오기')),
                  ),
                ),
              ] else if (rows == null)
                const ShadProgress(minHeight: 2)
              else if (rows.isEmpty && widget.printedMix != null)
                PrintedProductMix(mix: widget.printedMix!)
              else if (rows.isEmpty)
                Text(
                  '자동 검증된 부문별 매출이 아직 없습니다.',
                  style: t.body(13, color: c.textMuted),
                )
              else ...[
                Text(
                  businessPeriodLabel(rows.first),
                  style: t.body(13, color: c.textSecondary),
                ),
                Text(
                  revenueBasisNote(rows.first),
                  style: t.body(12, color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final fact in rows)
                  if (widget.compact)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              revenuePresentation(fact).label
                                  .split(' · ')
                                  .first,
                              style: t.body(14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: LinearProgressIndicator(
                              value:
                                  ((revenuePresentation(fact).share ?? 0) / 100)
                                      .clamp(0, 1),
                              minHeight: 8,
                              color: c.chartSeries1,
                              backgroundColor: c.chartGrid,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          SizedBox(
                            width: 55,
                            child: Text(
                              revenuePresentation(fact).share == null
                                  ? '—'
                                  : '${revenuePresentation(fact).share!.toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: t.numeric(14),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _RevenueRow(fact: fact, products: widget.products),
                if (rows.any((r) => revenuePresentation(r).share == null) ||
                    rows.fold<double>(
                          0,
                          (s, r) => s + (revenuePresentation(r).share ?? 0),
                        ) <
                        99)
                  Text('일부 항목만 확인됨', style: t.body(11, color: c.textMuted)),
                if (rows.fold<double>(
                      0,
                      (s, r) => s + (revenuePresentation(r).share ?? 0),
                    ) >
                    101)
                  Text(
                    revenueCoverageNote(rows),
                    style: t.body(12, color: c.textSecondary),
                  ),
              ],
            ],
          ),
        ),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          if (widget.showTrends)
            RevenueTrends(
              facts: _history,
              periods: _historyPeriods,
              latestReport: widget.latestReport,
            ),
        ],
      ],
    );
  }
}

/// Percentage-only filing table. Never invent monetary values from other totals.
class PrintedProductMix extends StatelessWidget {
  const PrintedProductMix({super.key, required this.mix});
  final PowerProductLesson mix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${mix.year} · 공시의 주요 제품 매출 비중',
        style: context.typo.body(13, color: context.colors.textSecondary),
      ),
      const SizedBox(height: AppSpace.sm),
      for (final row in mix.shares)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: context.typo.body(13, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              SizedBox(
                width: 64,
                child: ShadProgress(
                  value: row.share / 100,
                  minHeight: 5,
                  color: context.colors.chartSeries1,
                  backgroundColor: context.colors.chartGrid,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 48,
                child: Text(
                  '${row.share.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: context.typo.numeric(13),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.fact, required this.products});
  final DocumentFact fact;
  final List<BusinessProduct> products;
  @override
  Widget build(BuildContext context) {
    final row = revenuePresentation(fact);
    final c = context.colors, t = context.typo;
    final parts = row.label.split(' · ');
    BusinessProduct? product;
    for (final candidate in products) {
      final shortName = candidate.name.split(' · ').first;
      if (parts.any((part) => part.toLowerCase() == shortName.toLowerCase())) {
        product = candidate;
        break;
      }
    }
    final description =
        product != null && product.explanationKind != 'source_only'
        ? product.role
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 500;
        final label = Text(
          parts.first,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.body(13, weight: FontWeight.w600),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: description == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          if (parts.length > 1)
                            ShadAccordion<int>(
                              children: [
                                ShadAccordionItem<int>(
                                  value: 0,
                                  title: Text('제품·용도 보기', style: t.body(12)),
                                  child: Text(
                                    parts.skip(1).join(' · '),
                                    style: t.body(12),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    : ShadTooltip(
                        builder: (_) => Text(description),
                        child: Semantics(tooltip: description, child: label),
                      ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: wide ? 132 : 112,
                child: ShadTooltip(
                  builder: (_) =>
                      Text(formatSourceAmount(fact.value, fact.unit)),
                  child: Semantics(
                    tooltip: formatSourceAmount(fact.value, fact.unit),
                    child: Text(
                      formatUnitAmountCompact(fact.value, fact.unit),
                      textAlign: TextAlign.right,
                      style: t.numeric(13),
                    ),
                  ),
                ),
              ),
              if (wide) ...[
                const SizedBox(width: AppSpace.lg),
                SizedBox(
                  width: 100,
                  child: row.share == null
                      ? const SizedBox.shrink()
                      : ShadProgress(
                          value: row.share! / 100,
                          minHeight: 5,
                          color: c.chartSeries1,
                          backgroundColor: c.chartGrid,
                        ),
                ),
              ],
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 60,
                child: Text(
                  row.share == null ? '—' : '${row.share!.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: t.numeric(13, color: c.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
