import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../theme/ledger_theme.dart';
import 'format.dart';

/// KSIC 대분류 분포를 한 줄 비례 막대로 보여주고, 선택 시 중분류 목록을 편다.
class SectionStrip extends StatelessWidget {
  const SectionStrip({
    super.key,
    required this.sections,
    required this.divisions,
    required this.selectedSection,
    required this.selectedDivision,
    required this.onSelectSection,
    required this.onSelectDivision,
  });

  final List<FacetCount> sections;
  final List<FacetCount> divisions;
  final String? selectedSection;
  final String? selectedDivision;
  final ValueChanged<String> onSelectSection;
  final ValueChanged<String> onSelectDivision;

  @override
  Widget build(BuildContext context) {
    final total = sections.fold(0, (s, f) => s + f.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('업종 분포 · KSIC 대분류', style: Typo.label()),
            const Spacer(),
            Text('막대를 눌러 필터', style: Typo.body(12, color: Pal.inkFaint)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, s) in sections.indexed)
                Expanded(
                  flex: s.count,
                  child: _Segment(
                    facet: s,
                    share: total == 0 ? 0 : s.count / total,
                    shade: i,
                    selected: selectedSection == s.code,
                    dimmed:
                        selectedSection != null && selectedSection != s.code,
                    onTap: () => onSelectSection(s.code),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            for (final s in sections.take(8))
              _Legend(
                facet: s,
                share: total == 0 ? 0 : s.count / total,
                active: selectedSection == s.code,
                onTap: () => onSelectSection(s.code),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: selectedSection == null || divisions.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _DivisionList(
                    divisions: divisions,
                    selected: selectedDivision,
                    onSelect: onSelectDivision,
                  ),
                ),
        ),
      ],
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.facet,
    required this.share,
    required this.shade,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final FacetCount facet;
  final double share;
  final int shade;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // 큰 업종일수록 진한 잉크, 선택은 인주색.
    final base = Color.lerp(
      Pal.ink,
      Pal.rule,
      (widget.shade / 10).clamp(0.0, 0.85),
    )!;
    final color = widget.selected ? Pal.seal : base;
    return Tooltip(
      message:
          '${widget.facet.code} ${widget.facet.name}\n'
          '${formatCount(widget.facet.count)}개사 · ${(widget.share * 100).toStringAsFixed(1)}%',
      waitDuration: const Duration(milliseconds: 150),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(
              right: 2,
              top: _hover || widget.selected ? 0 : 6,
            ),
            color: color.withValues(alpha: widget.dimmed ? 0.25 : 1),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 5, bottom: 4),
            child: widget.share > 0.04
                ? Text(
                    widget.facet.code,
                    style: Typo.mono(
                      12,
                      color: widget.shade < 5 || widget.selected
                          ? Pal.paper
                          : Pal.ink,
                      weight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.facet,
    required this.share,
    required this.active,
    required this.onTap,
  });

  final FacetCount facet;
  final double share;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${facet.code} ',
                style: Typo.mono(
                  12,
                  color: active ? Pal.seal : Pal.ink,
                  weight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: facet.name,
                style: Typo.body(12.5, color: active ? Pal.seal : Pal.inkSoft),
              ),
              TextSpan(
                text: ' ${(share * 100).toStringAsFixed(0)}%',
                style: Typo.mono(12, color: Pal.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivisionList extends StatelessWidget {
  const _DivisionList({
    required this.divisions,
    required this.selected,
    required this.onSelect,
  });

  final List<FacetCount> divisions;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final max = divisions.fold(0, (m, d) => d.count > m ? d.count : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: Pal.card,
        border: Border(left: BorderSide(color: Pal.seal, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('중분류', style: Typo.label(color: Pal.seal)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 28,
            runSpacing: 8,
            children: [
              for (final d in divisions)
                SizedBox(
                  width: 300,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onSelect(d.code),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              d.code,
                              style: Typo.mono(
                                12,
                                color: selected == d.code
                                    ? Pal.seal
                                    : Pal.inkFaint,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.body(
                                    13,
                                    color: selected == d.code
                                        ? Pal.seal
                                        : Pal.ink,
                                    weight: selected == d.code
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FractionallySizedBox(
                                  widthFactor: max == 0 ? 0 : d.count / max,
                                  child: Container(
                                    height: 3,
                                    color: selected == d.code
                                        ? Pal.seal
                                        : Pal.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatCount(d.count),
                            style: Typo.mono(12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
