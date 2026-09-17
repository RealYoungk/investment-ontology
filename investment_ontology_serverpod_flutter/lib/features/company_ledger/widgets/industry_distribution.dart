import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../formatters.dart';

/// KSIC 대분류 분포를 한 줄 비례 막대로 보여주고, 선택 시 중분류 목록을 편다.
class IndustryDistribution extends StatelessWidget {
  const IndustryDistribution({
    super.key,
    required this.sections,
    required this.divisions,
    required this.selectedSection,
    required this.selectedDivision,
    required this.onSelectSection,
    required this.onSelectDivision,
  });

  /// 범례에 이름까지 보여줄 상위 대분류 수.
  static const _legendCount = 8;

  final List<FacetCount> sections;
  final List<FacetCount> divisions;
  final String? selectedSection;
  final String? selectedDivision;
  final ValueChanged<String> onSelectSection;
  final ValueChanged<String> onSelectDivision;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = sections.fold(0, (s, f) => s + f.count);
    double share(FacetCount f) => total == 0 ? 0 : f.count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '업종 분포 · KSIC 대분류',
          trailing: Text(
            '막대를 눌러 필터',
            style: context.typo.body(12, color: c.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (rank, s) in sections.indexed)
                Expanded(
                  flex: s.count,
                  child: _Segment(
                    facet: s,
                    share: share(s),
                    rank: rank,
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
            for (final s in sections.take(_legendCount))
              _Legend(
                facet: s,
                share: share(s),
                active: selectedSection == s.code,
                onTap: () => onSelectSection(s.code),
              ),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.slow,
          curve: AppMotion.curve,
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

class _Segment extends StatelessWidget {
  const _Segment({
    required this.facet,
    required this.share,
    required this.rank,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  /// 이 비율 미만이면 막대 안에 코드를 쓰지 않는다.
  static const _minLabelShare = 0.04;

  final FacetCount facet;
  final double share;
  final int rank;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 순위가 높을수록 진하게, 선택은 강조색.
    final depth = (rank / 10).clamp(0.0, 0.85);
    final base = Color.lerp(c.inverse, c.border, depth)!;
    final fill = selected ? c.accent : base;
    final onFill = selected || depth < 0.5 ? c.onInverse : c.textPrimary;

    return Tooltip(
      message:
          '${facet.code} ${facet.name}\n'
          '${formatCount(facet.count)}개사 · ${(share * 100).toStringAsFixed(1)}%',
      waitDuration: const Duration(milliseconds: 150),
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovered) => AnimatedContainer(
          duration: AppMotion.normal,
          margin: EdgeInsets.only(right: 2, top: hovered || selected ? 0 : 6),
          color: fill.withValues(alpha: dimmed ? 0.25 : 1),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(left: 5, bottom: 4),
          child: share >= _minLabelShare
              ? Text(
                  facet.code,
                  style: context.typo.numeric(
                    12,
                    color: onFill,
                    weight: FontWeight.w700,
                  ),
                )
              : null,
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
    final c = context.colors;
    final t = context.typo;
    return HoverBuilder(
      onTap: onTap,
      builder: (context, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${facet.code} ',
              style: t.numeric(
                12,
                color: active ? c.accent : c.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: facet.name,
              style: t.body(12.5, color: active ? c.accent : c.textSecondary),
            ),
            TextSpan(
              text: ' ${(share * 100).toStringAsFixed(0)}%',
              style: t.numeric(12, color: c.textMuted),
            ),
          ],
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
    final c = context.colors;
    final max = divisions.fold(0, (m, d) => d.count > m ? d.count : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(left: BorderSide(color: c.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('중분류', accent: true),
          const SizedBox(height: 10),
          Wrap(
            spacing: 28,
            runSpacing: AppSpace.sm,
            children: [
              for (final d in divisions)
                SizedBox(
                  width: 300,
                  child: _DivisionItem(
                    facet: d,
                    ratio: max == 0 ? 0 : d.count / max,
                    active: selected == d.code,
                    onTap: () => onSelect(d.code),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DivisionItem extends StatelessWidget {
  const _DivisionItem({
    required this.facet,
    required this.ratio,
    required this.active,
    required this.onTap,
  });

  final FacetCount facet;
  final double ratio;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final tone = active ? c.accent : c.textPrimary;
    return HoverBuilder(
      onTap: onTap,
      builder: (context, _) => Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              facet.code,
              style: t.numeric(12, color: active ? c.accent : c.textMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body(
                    13,
                    color: tone,
                    weight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(height: 3, color: tone),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(formatCount(facet.count), style: t.numeric(12.5)),
        ],
      ),
    );
  }
}
