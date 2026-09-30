import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';
import '../business/power_product_lesson.dart';

/// Preserve filing labels before the amount, including merged category cells.
/// A percentage is shown only when the first printed amount matches the fact.
({String label, double? share}) revenuePresentation(DocumentFact fact) {
  final cells = fact.evidence.split('|').map((s) => s.trim()).toList();
  final index = cells.indexWhere(
    (s) => RegExp(r'^-?[\d,]+(?:\.\d+)?$').hasMatch(s),
  );
  if (index <= 0 ||
      double.tryParse(cells[index].replaceAll(',', '')) != fact.value) {
    return (label: fact.label, share: null);
  }
  final labels = cells.take(index).where((s) => s.isNotEmpty).toList();
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
  int year(DocumentFact f) => f.asOf?.year ?? f.bsnsYear;
  rows.sort((a, b) {
    final byYear = year(b).compareTo(year(a));
    return byYear != 0 ? byYear : b.documentId.compareTo(a.documentId);
  });
  final first = rows.first;
  return rows
      .where((f) => year(f) == year(first) && f.documentId == first.documentId)
      .toList();
}

class RevenueComposition extends StatefulWidget {
  const RevenueComposition({
    super.key,
    required this.corpCode,
    this.products = const [],
    this.printedMix,
  });
  final String corpCode;
  final List<BusinessProduct> products;
  final PowerProductLesson? printedMix;
  @override
  State<RevenueComposition> createState() => _RevenueCompositionState();
}

class _RevenueCompositionState extends State<RevenueComposition> {
  List<DocumentFact>? _rows;
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
      _failed = false;
    });
    try {
      final facts = await client.disclosure.factTrends(widget.corpCode);
      if (mounted && seq == _seq) {
        setState(() => _rows = latestRevenueFacts(facts));
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
        const SectionLabel('무엇으로 매출을 내나요?', accent: true),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: context.shape.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '사업별 매출 구성',
                style: t
                    .body(18, weight: FontWeight.w700)
                    .copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpace.sm),
              if (_failed) ...[
                Text('매출 구성을 불러오지 못했습니다.', style: t.body(13)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _load,
                    child: const Text('다시 불러오기'),
                  ),
                ),
              ] else if (rows == null)
                const LinearProgressIndicator(minHeight: 2)
              else if (rows.isEmpty && widget.printedMix != null)
                PrintedProductMix(mix: widget.printedMix!)
              else if (rows.isEmpty)
                Text(
                  '자동 검증된 부문별 매출이 아직 없습니다.',
                  style: t.body(13, color: c.textMuted),
                )
              else ...[
                Text(
                  'FY${rows.first.asOf?.year ?? rows.first.bsnsYear} · 사업보고서 기준',
                  style: t.body(13, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final fact in rows)
                  _RevenueRow(fact: fact, products: widget.products),
                Text(
                  '사업보고서에 공시된 항목과 매출 비중입니다. 위 재무 기준 선택과 별개이며, 표시된 항목의 합계가 총매출과 다를 수 있습니다.',
                  style: t.body(11, color: c.textMuted).copyWith(height: 1.5),
                ),
              ],
            ],
          ),
        ),
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
                child: LinearProgressIndicator(
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
          product?.name ?? row.label,
          style: t.body(13, weight: FontWeight.w600),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: description == null
                    ? label
                    : Tooltip(message: description, child: label),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: wide ? 132 : 112,
                child: Text(
                  formatUnitAmount(fact.value, fact.unit),
                  textAlign: TextAlign.right,
                  style: t.numeric(13),
                ),
              ),
              if (wide) ...[
                const SizedBox(width: AppSpace.lg),
                SizedBox(
                  width: 100,
                  child: row.share == null
                      ? const SizedBox.shrink()
                      : LinearProgressIndicator(
                          value: row.share! / 100,
                          minHeight: 5,
                          color: c.chartSeries1,
                          backgroundColor: c.chartGrid,
                        ),
                ),
              ],
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 46,
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
