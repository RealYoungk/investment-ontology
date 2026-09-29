import 'package:flutter/material.dart';

import '../tokens.dart';

/// 목록에서 하나를 고르는 버튼. 고른 값이 없으면 [placeholder]를 보여준다.
///
/// [onChanged]에 null이 오면 선택을 해제한 것이다 (목록 맨 위 "전체").
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.label,
    this.allLabel = '전체',
    this.allowClear = true,
  });

  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final String? label;
  final String allLabel;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final selected = value == null ? null : options[value];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: t.label(color: c.textSecondary)),
          const SizedBox(width: AppSpace.md),
        ],
        PopupMenuButton<_Choice<T>>(
          tooltip: '',
          enabled: options.isNotEmpty,
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(maxHeight: 420, minWidth: 220),
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: context.shape.borderRadius,
            side: BorderSide(color: c.borderStrong),
          ),
          onSelected: (choice) => onChanged(choice.value),
          itemBuilder: (context) => [
            if (allowClear)
              PopupMenuItem(
                value: _Choice<T>(null),
                height: 36,
                child: Text(
                  allLabel,
                  style: t.body(13, color: c.textSecondary),
                ),
              ),
            for (final MapEntry(key: option, value: text) in options.entries)
              PopupMenuItem(
                value: _Choice(option),
                height: 36,
                child: Text(
                  text,
                  style: t.body(
                    13,
                    color: c.textPrimary,
                    weight: option == value ? FontWeight.w700 : null,
                  ),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: selected == null ? Colors.transparent : c.inverse,
              borderRadius: context.shape.borderRadius,
              border: Border.all(
                color: c.borderStrong,
                width: context.shape.strokeWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    selected ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.body(
                      13,
                      color: selected == null ? c.textPrimary : c.onInverse,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.expand_more,
                  size: 16,
                  color: selected == null ? c.textPrimary : c.onInverse,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// PopupMenuButton은 null 값을 "선택 안 함"으로 취급하므로 한 번 감싼다.
class _Choice<T> {
  const _Choice(this.value);
  final T? value;
}
