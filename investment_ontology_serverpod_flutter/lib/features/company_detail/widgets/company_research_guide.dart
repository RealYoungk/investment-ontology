import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../business/company_research_profile.dart';

class CompanyResearchGuide extends StatefulWidget {
  const CompanyResearchGuide({super.key, required this.profile});
  final CompanyResearchProfile profile;
  @override
  State<CompanyResearchGuide> createState() => _CompanyResearchGuideState();
}

class _CompanyResearchGuideState extends State<CompanyResearchGuide> {
  int _selected = 0;
  @override
  void didUpdateWidget(covariant CompanyResearchGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final c = context.colors, t = context.typo;
    final product = profile.products[_selected];
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (i, p) in profile.products.indexed)
                  IntrinsicWidth(
                    child: ShadToggle.outline(
                      value: i == _selected,
                      onChanged: (_) => setState(() => _selected = i),
                      child: Text(p.name.split(' · ').first),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (profile.diagram == 'hbm' && _selected == 0) ...[
              const _HbmDiagram(),
              const SizedBox(height: AppSpace.md),
              Text(product.use, style: t.body(12, color: c.textSecondary)),
            ] else ...[
              Text(product.name, style: t.body(16, weight: FontWeight.w700)),
              const SizedBox(height: AppSpace.sm),
              Text(product.body, style: t.body(14).copyWith(height: 1.6)),
              const SizedBox(height: AppSpace.sm),
              Text(product.use, style: t.body(12, color: c.textSecondary)),
            ],
            if (profile.segments.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              ShadAccordion<int>(
                maintainState: false,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Text(
                      '그 밖의 사업',
                      style: t.body(13, color: c.textSecondary),
                    ),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in profile.segments)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    s.name,
                                    style: t.body(13, weight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    s.body,
                                    style: t.body(13).copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Original conceptual drawing: HBM sits beside the compute die, joined by an
/// interposer. Layer count is illustrative, never a product specification.
class _HbmDiagram extends StatelessWidget {
  const _HbmDiagram();
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GPU가 계산하고, HBM이 데이터를 공급합니다',
          style: t.body(16, weight: FontWeight.w700).copyWith(height: 1.4),
        ),
        const SizedBox(height: AppSpace.lg),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        height: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.inverse,
                          borderRadius: context.shape.borderRadius,
                        ),
                        child: Text(
                          'GPU\nAI 계산',
                          textAlign: TextAlign.center,
                          style: t.body(
                            14,
                            color: c.onInverse,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '데이터',
                            style: t.body(11, color: c.textSecondary),
                          ),
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 32,
                            color: c.accent,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'HBM',
                            textAlign: TextAlign.center,
                            style: t.body(14, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          for (var i = 0; i < 4; i++)
                            Container(
                              height: 16,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: c.chartSeries1,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: c.surfaceHover,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '인터포저 · 두 칩을 촘촘한 회로로 연결하는 판',
                    textAlign: TextAlign.center,
                    style: t.body(11, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          '빠른 계산에는 많은 데이터를 한꺼번에 전달하는 메모리가 필요합니다. '
          'HBM은 DRAM을 쌓아 GPU 가까이에 연결한 고대역폭 메모리입니다.',
          style: t.body(13, color: c.textSecondary).copyWith(height: 1.6),
        ),
      ],
    );
  }
}
