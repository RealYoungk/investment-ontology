import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../formatters.dart';

/// 제목 + 시장별 상장사 수. 숫자를 누르면 시장 필터가 된다.
class MarketSummary extends StatelessWidget {
  const MarketSummary({
    super.key,
    required this.overview,
    required this.selected,
    required this.onSelect,
  });

  static const _markets = [Market.kospi, Market.kosdaq, Market.konex];

  final Overview? overview;
  final Market? selected;
  final ValueChanged<Market> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final o = overview;
    final counts = {for (final f in o?.byMarket ?? <FacetCount>[]) f.code: f};
    return Wrap(
      spacing: 56,
      runSpacing: AppSpace.xl,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionLabel('INVESTMENT ONTOLOGY · 01', accent: true),
            const SizedBox(height: 10),
            Text('상장사 원장', style: t.display(52, color: c.textPrimary)),
            const SizedBox(height: AppSpace.sm),
            Text(
              o == null
                  ? '불러오는 중…'
                  : '국내 상장 ${formatCount(o.totalListed)}개사 · 출처 DART 기업개황',
              style: t.body(14, color: c.textSecondary),
            ),
          ],
        ),
        for (final market in _markets)
          _MarketFigure(
            label: marketLabel(market),
            count: counts[market.name]?.count,
            color: marketColor(context, market),
            active: selected == market,
            dimmed: selected != null && selected != market,
            onTap: () => onSelect(market),
          ),
      ],
    );
  }
}

class _MarketFigure extends StatelessWidget {
  const _MarketFigure({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final int? count;
  final Color color;
  final bool active;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    return HoverBuilder(
      onTap: onTap,
      builder: (context, hovered) => AnimatedOpacity(
        duration: AppMotion.normal,
        opacity: dimmed ? 0.35 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: color),
                const SizedBox(width: AppSpace.sm),
                Text(label, style: t.label(color: context.colors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count == null ? '—' : formatCount(count!),
              style: t.numeric(40, color: color, weight: FontWeight.w600),
            ),
            AnimatedContainer(
              duration: AppMotion.normal,
              height: 3,
              width: active || hovered ? 64 : 0,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
