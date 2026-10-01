import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hover_builder.dart';

/// Compact destination card with a separate supporting count.
class AppNavigationTile extends StatelessWidget {
  const AppNavigationTile({
    super.key,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HoverBuilder(
    onTap: onTap,
    builder: (context, hovered) => Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: hovered ? context.colors.surfaceHover : context.colors.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.typo.body(14, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            detail,
            style: context.typo.body(12, color: context.colors.textSecondary),
          ),
          const SizedBox(width: AppSpace.xs),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.colors.textMuted,
          ),
        ],
      ),
    ),
  );
}
