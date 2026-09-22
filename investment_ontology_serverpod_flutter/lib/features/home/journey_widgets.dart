import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// Native Material interaction keeps the new entry flow keyboard accessible.
class JourneyButton extends StatelessWidget {
  const JourneyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon = Icons.arrow_forward,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = TextButton.styleFrom(
      foregroundColor: primary ? c.onInverse : c.textPrimary,
      backgroundColor: primary ? c.inverse : c.surface,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      textStyle: context.typo.body(14, weight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: context.shape.borderRadius,
        side: BorderSide(color: primary ? c.inverse : c.border),
      ),
    );
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: AppSpace.md),
          Icon(icon, size: 18),
        ],
      ),
    );
  }
}

class JourneyHeading extends StatelessWidget {
  const JourneyHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.large = false,
  });
  final String eyebrow;
  final String title;
  final String description;
  final bool large;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = context.typo;
      final c = context.colors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: t.label(color: c.accent)),
          const SizedBox(height: AppSpace.lg),
          Text(
            title,
            style: t
                .display(
                  box.maxWidth < 480 ? 28 : (large ? 36 : 32),
                  color: c.textPrimary,
                )
                .copyWith(height: 1.3),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            description,
            style: t.body(16, color: c.textSecondary).copyWith(height: 1.65),
          ),
        ],
      );
    },
  );
}

/// A qualitative illustration: no fabricated prices, returns, or company data.
class ResearchPath extends StatelessWidget {
  const ResearchPath({super.key, this.activeStep = 0, this.onStep});
  final int activeStep;
  final ValueChanged<int>? onStep;
  static const steps = [
    ('01', '사업을 이해하고', '무엇을 팔고, 어디에서 매출이 나는지', Icons.storefront_outlined),
    ('02', '변화를 확인하고', '매출과 이익이 어떻게 달라졌는지', Icons.stacked_line_chart),
    ('03', '비교하며 판단해요', '다른 기업과 무엇이 같고 다른지', Icons.compare_arrows),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('기업을 읽는 세 가지 질문', style: t.label(color: c.textSecondary)),
          const SizedBox(height: AppSpace.xl),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 1, height: 24, color: c.border),
                ),
              ),
            Semantics(
              selected: i == activeStep,
              child: Material(
                color: i == activeStep ? c.accentSubtle : c.surface,
                child: InkWell(
                  onTap: onStep == null ? null : () => onStep!(i),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Row(
                      children: [
                        Icon(
                          steps[i].$4,
                          color: i == activeStep ? c.accent : c.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[i].$2,
                                style: t.body(17, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                steps[i].$3,
                                style: t.body(13, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Text('궁금한 곳부터 시작해도 괜찮아요.', style: t.body(13, color: c.textSecondary)),
        ],
      ),
    );
  }
}
