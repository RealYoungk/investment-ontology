import 'package:flutter/material.dart';

import '../tokens.dart';

/// 짧은 분류 표시 (시장 구분, 코드 등).
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
    this.numeric = false,
    this.size = AppTagSize.small,
  });

  final String label;

  /// 기본은 본문색.
  final Color? color;
  final bool filled;

  /// 코드·숫자면 숫자 글꼴.
  final bool numeric;
  final AppTagSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.textPrimary;
    final fg = filled ? c.onAccent : tone;
    final fontSize = size == AppTagSize.small ? 11.5 : 12.5;
    final style = numeric
        ? context.typo.numeric(fontSize, color: fg, weight: FontWeight.w600)
        : context.typo.body(fontSize, color: fg, weight: FontWeight.w600);
    return Container(
      padding: size == AppTagSize.small
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? tone : Colors.transparent,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: tone, width: 1),
      ),
      // 좁은 칸에서도 글자가 줄바꿈되지 않게 ("받 음"처럼 쪼개지던 문제).
      child: Text(label, style: style, maxLines: 1, softWrap: false),
    );
  }
}

enum AppTagSize { small, medium }
