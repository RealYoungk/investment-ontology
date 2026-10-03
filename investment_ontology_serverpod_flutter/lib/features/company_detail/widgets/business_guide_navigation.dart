import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// Stable navigation slots across steps, including the first and last pages.
class BusinessGuideNavigation extends StatelessWidget {
  const BusinessGuideNavigation({
    super.key,
    required this.step,
    this.count = 3,
    required this.onChanged,
  });
  final int step;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '${step + 1} / $count',
        style: context.typo.body(12, color: context.colors.textMuted),
      ),
      const Spacer(),
      ShadButton.ghost(
        onPressed: step > 0 ? () => onChanged(step - 1) : null,
        enabled: (step > 0 ? () => onChanged(step - 1) : null) != null,
        child: Flexible(child: const Text('이전')),
      ),
      const SizedBox(width: AppSpace.sm),
      ShadButton(
        onPressed: step < count - 1 ? () => onChanged(step + 1) : null,
        enabled: (step < count - 1 ? () => onChanged(step + 1) : null) != null,
        child: Flexible(child: const Text('다음 →')),
      ),
    ],
  );
}
