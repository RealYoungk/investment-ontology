import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';

/// 구역 제목으로 쓰는 작은 대문자 라벨.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.accent = false,
    this.trailing,
    this.tooltip,
    this.style,
  });

  final String text;
  final bool accent;
  final Widget? trailing;
  final String? tooltip;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget label = Text(
      text,
      style:
          style ??
          context.typo.label(color: accent ? c.accent : c.textSecondary),
    );
    if (tooltip != null) {
      final tipKey = GlobalKey<TooltipState>();
      label = ShadTooltip(
        key: tipKey,
        waitDuration: const Duration(milliseconds: 300),
        showDuration: const Duration(seconds: 6),
        builder: (_) => Text(tooltip!),
        child: Semantics(
          tooltip: tooltip!,
          child: ShadButton.ghost(
            height: 0,
            width: 0,
            padding: EdgeInsets.zero,
            onPressed: () => tipKey.currentState?.ensureTooltipVisible(),
            child: Flexible(child: label),
          ),
        ),
      );
    }
    if (trailing == null) return label;
    // 좁은 화면에서는 오른쪽 글이 줄어들거나 줄바꿈된다.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: trailing),
        ),
      ],
    );
  }
}
