import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// 시장 화면 제목 + 시장별 상장사 수. 숫자를 누르면 시장 필터가 된다.
class MarketSummary extends StatelessWidget {
  const MarketSummary({
    super.key,
    required this.overview,
    required this.selected,
    required this.onSelect,
    this.failed = false,
  });

  static const _markets = [Market.kospi, Market.kosdaq, Market.konex];

  final Overview? overview;
  final bool failed;
  final Market? selected;
  final ValueChanged<Market> onSelect;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final counts = {for (final f in o?.byMarket ?? <FacetCount>[]) f.code: f};
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 600;
        final heading = PageHeading(
          title: '시장',
          subtitle: o == null
              ? failed
                    ? '시장 요약을 불러오지 못했어요'
                    : '불러오는 중…'
              : '국내 상장 ${formatCount(o.totalListed)}개사',
        );
        final figures = [
          for (final market in _markets)
            _MarketFigure(
              label: marketLabel(market),
              count: counts[market.name]?.count,
              color: marketColor(context, market),
              active: selected == market,
              dimmed: selected != null && selected != market,
              compact: narrow,
              onTap: () => onSelect(market),
            ),
        ];
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 24),
              Row(
                children: [
                  for (final figure in figures) Expanded(child: figure),
                ],
              ),
            ],
          );
        }
        return Wrap(
          spacing: 56,
          runSpacing: AppSpace.xl,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [heading, ...figures],
        );
      },
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
    this.compact = false,
  });

  final bool compact;
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
              style: t.numeric(
                compact ? 26 : 40,
                color: color,
                weight: FontWeight.w600,
              ),
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
