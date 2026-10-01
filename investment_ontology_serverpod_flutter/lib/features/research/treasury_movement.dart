import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/components/charts/app_charts.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';

bool treasuryBalances(TreasuryStockEntry r) =>
    r.sharesBegin != null &&
    r.acquired != null &&
    r.disposed != null &&
    r.retired != null &&
    r.sharesEnd != null &&
    r.sharesBegin! + r.acquired! - r.disposed! - r.retired! == r.sharesEnd!;

bool treasuryHasValues(TreasuryStockEntry r) => [
  r.sharesBegin,
  r.acquired,
  r.disposed,
  r.retired,
  r.sharesEnd,
].any((v) => v != null);

int treasuryDefaultIndex(List<TreasuryStockEntry> rows) {
  final total = rows.indexWhere(
    (r) =>
        treasuryHasValues(r) &&
        [r.method1, r.method2, r.method3].contains('총계'),
  );
  if (total >= 0) return total;
  final subtotal = rows.indexWhere((r) => r.isTotal && treasuryHasValues(r));
  return subtotal >= 0 ? subtotal : rows.indexWhere(treasuryHasValues);
}

/// Each source row is separate: never add subtotal and detail rows together.
class TreasuryMovement extends StatefulWidget {
  const TreasuryMovement({super.key, required this.rows});
  final List<TreasuryStockEntry> rows;
  @override
  State<TreasuryMovement> createState() => _TreasuryMovementState();
}

class _TreasuryMovementState extends State<TreasuryMovement> {
  int? _selected;
  @override
  void didUpdateWidget(covariant TreasuryMovement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.rows.any(treasuryHasValues)) return const SizedBox.shrink();
    final index = _selected ?? treasuryDefaultIndex(widget.rows);
    final safe = index < 0 || index >= widget.rows.length ? 0 : index;
    final r = widget.rows[safe];
    final balanced = treasuryBalances(r);
    final values = [
      r.sharesBegin,
      r.acquired,
      r.disposed == null ? null : -r.disposed!,
      r.retired == null ? null : -r.retired!,
      r.sharesEnd,
    ];
    String label(TreasuryStockEntry v) => [
      v.method1,
      v.method2,
      v.method3,
      v.stockKind,
    ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<int>(
          isExpanded: true,
          value: safe,
          items: [
            for (var i = 0; i < widget.rows.length; i++)
              if (treasuryHasValues(widget.rows[i]))
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    label(widget.rows[i]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ],
          onChanged: (v) => setState(() => _selected = v),
        ),
        Text(
          'FY${r.bsnsYear} 공시된 실제 수량 · 주',
          style: context.typo.body(13, weight: FontWeight.w600),
        ),
        AppColumnChart(
          categories: const ['기초 보유', '취득 +', '처분 −', '소각 −', '기말 보유'],
          series: [
            ChartSeries(
              label: '자기주식',
              color: context.colors.chartSeries1,
              values: [for (final v in values) v?.toDouble()],
            ),
          ],
          formatValue: (v) => '${formatCount(v.round())}주',
          showMissingMarkers: true,
        ),
        Text(
          balanced
              ? '기초 + 취득 − 처분 − 소각 = 기말 확인'
              : '일부 수량이 없거나 잔액식이 일치하지 않습니다. 원문을 확인하세요.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
        Text(
          '기간 전체의 변동입니다. 개별 취득 계획의 이행률로 환산하지 않습니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
      ],
    );
  }
}
