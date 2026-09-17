import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hover_builder.dart';

/// 하나만 고르는 버튼 묶음.
class AppToggleGroup<T> extends StatelessWidget {
  const AppToggleGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: context.typo.label(color: c.textSecondary)),
          const SizedBox(width: AppSpace.md),
        ],
        for (final MapEntry(key: option, value: text) in options.entries)
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.xs),
            child: HoverBuilder(
              onTap: () => onChanged(option),
              builder: (context, hovered) {
                final active = option == value;
                return AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? c.inverse
                        : hovered
                        ? c.surfaceHover
                        : Colors.transparent,
                    borderRadius: context.shape.borderRadius,
                    border: Border.all(
                      color: c.borderStrong,
                      width: context.shape.strokeWidth,
                    ),
                  ),
                  child: Text(
                    text,
                    style: context.typo.body(
                      13,
                      color: active ? c.onInverse : c.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
