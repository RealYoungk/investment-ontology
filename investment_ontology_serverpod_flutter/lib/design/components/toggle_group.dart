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
    this.disabled = const {},
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? label;

  /// 고를 수 없는 항목 (자료가 아직 없는 해 등). 지우지 않고 흐리게 보여 준다.
  final Set<T> disabled;

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
        Flexible(
          child: Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final MapEntry(key: option, value: text) in options.entries)
                HoverBuilder(
                  onTap: disabled.contains(option)
                      ? null
                      : () => onChanged(option),
                  builder: (context, hovered) {
                    final active = option == value;
                    final off = disabled.contains(option);
                    return AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? c.inverse
                            : hovered && !off
                            ? c.surfaceHover
                            : Colors.transparent,
                        borderRadius: context.shape.borderRadius,
                        border: Border.all(
                          color: off ? c.border : c.borderStrong,
                          width: context.shape.strokeWidth,
                        ),
                      ),
                      child: Text(
                        text,
                        style: context.typo.body(
                          13,
                          color: active
                              ? c.onInverse
                              : off
                              ? c.textMuted
                              : c.textPrimary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
