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
    return Row(children: [label, const Spacer(), trailing!]);
  }
}
