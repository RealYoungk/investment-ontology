import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// Covers the native video until a decoded frame is available.
class IntroFilmPlaceholder extends StatelessWidget {
  const IntroFilmPlaceholder({super.key, required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: context.colors.accentSubtle),
      Image.network(
        'intro/poster.jpg',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
      Align(
        alignment: const Alignment(0, -.25),
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: .95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!failed) ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                Text(
                  failed ? '영상 대신 미리보기를 표시하고 있어요' : '소개 영상을 준비하고 있어요',
                  style: context.typo.body(
                    12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
