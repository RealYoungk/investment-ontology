import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../theme/ledger_theme.dart';
import 'format.dart';

/// 제목 + 시장별 상장사 수. 숫자를 누르면 시장 필터가 된다.
class MarketHeader extends StatelessWidget {
  const MarketHeader({
    super.key,
    required this.overview,
    required this.selected,
    required this.onSelect,
  });

  final Overview? overview;
  final Market? selected;
  final ValueChanged<Market> onSelect;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final counts = {for (final f in o?.byMarket ?? <FacetCount>[]) f.code: f};
    return Wrap(
      spacing: 56,
      runSpacing: 24,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'INVESTMENT ONTOLOGY · 01',
              style: Typo.label(color: Pal.seal),
            ),
            const SizedBox(height: 10),
            Text('상장사 원장', style: Typo.display(52)),
            const SizedBox(height: 8),
            Text(
              o == null
                  ? '불러오는 중…'
                  : '국내 상장 ${formatCount(o.totalListed)}개사 · 출처 DART 기업개황',
              style: Typo.body(14, color: Pal.inkSoft),
            ),
          ],
        ),
        for (final (market, color) in const [
          (Market.kospi, Pal.kospi),
          (Market.kosdaq, Pal.kosdaq),
          (Market.konex, Pal.konex),
        ])
          _MarketFigure(
            label: marketLabel(market),
            count: counts[market.name]?.count,
            color: color,
            active: selected == market,
            dimmed: selected != null && selected != market,
            onTap: () => onSelect(market),
          ),
      ],
    );
  }
}

class _MarketFigure extends StatefulWidget {
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
  State<_MarketFigure> createState() => _MarketFigureState();
}

class _MarketFigureState extends State<_MarketFigure> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final underline = widget.active || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.dimmed ? 0.35 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: widget.color),
                  const SizedBox(width: 8),
                  Text(widget.label, style: Typo.label(color: Pal.ink)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.count == null ? '—' : formatCount(widget.count!),
                style: Typo.mono(
                  40,
                  color: widget.color,
                  weight: FontWeight.w600,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: underline ? 64 : 0,
                color: widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
