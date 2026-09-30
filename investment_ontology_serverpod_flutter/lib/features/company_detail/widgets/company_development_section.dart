import 'package:flutter/material.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../business/company_development.dart';

class CompanyDevelopmentSection extends StatelessWidget {
  const CompanyDevelopmentSection({super.key, required this.development});
  final CompanyDevelopment development;

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final d = development;
    Widget paragraph(String label, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.body(13, color: c.textSecondary, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(text, style: t.body(14).copyWith(height: 1.65)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('어떤 투자포인트가 있나요?', accent: true),
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
                d.headline,
                style: t
                    .body(20, weight: FontWeight.w700)
                    .copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpace.md),
              Text(d.change, style: t.body(14).copyWith(height: 1.6)),
              const SizedBox(height: AppSpace.sm),
              Material(
                color: c.surface,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  childrenPadding: const EdgeInsets.only(bottom: AppSpace.md),
                  title: Text(
                    d.contextTitle,
                    style: t.body(13, color: c.textSecondary),
                  ),
                  children: [
                    for (final step in d.contextSteps) ...[
                      paragraph(step.title, step.body),
                      const SizedBox(height: AppSpace.md),
                    ],
                    paragraph(d.roleTitle, d.role),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
