import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hover_builder.dart';

/// 화면 안의 탭 (밑줄로 지금 탭을 표시).
class AppTabBar<T> extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderStrong)),
      ),
      // 좁은 화면에서는 탭을 가로로 밀어 본다.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final MapEntry(key: tab, value: label) in tabs.entries)
              HoverBuilder(
                onTap: tab == value ? null : () => onChanged(tab),
                builder: (context, hovered) {
                  final active = tab == value;
                  return AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.xs,
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.sm,
                    ),
                    margin: const EdgeInsets.only(right: AppSpace.xl),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active
                              ? c.accent
                              : hovered
                              ? c.border
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      label,
                      style: t.body(
                        15,
                        color: active ? c.textPrimary : c.textSecondary,
                        weight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
