import 'package:flutter/material.dart';

import '../tokens.dart';

/// 구역 제목으로 쓰는 작은 대문자 라벨.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.accent = false,
    this.trailing,
  });

  final String text;
  final bool accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Text(
      text,
      style: context.typo.label(color: accent ? c.accent : c.textSecondary),
    );
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
