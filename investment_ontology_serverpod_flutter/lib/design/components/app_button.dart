import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hover_builder.dart';

enum AppButtonVariant {
  /// 채워진 주 동작.
  primary,

  /// 테두리만 있는 보조 동작.
  secondary,

  /// 밑줄 텍스트.
  link,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.icon,
    this.tone,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// 기본 잉크색 대신 쓸 색 (예: 강조색 링크).
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final ink = enabled ? (tone ?? c.textPrimary) : c.textMuted;

    return HoverBuilder(
      onTap: onPressed,
      builder: (context, hovered) {
        final (Color bg, Color fg, Color? line) = switch (variant) {
          AppButtonVariant.primary => (
            enabled ? (hovered ? c.accent : ink) : c.border,
            c.onInverse,
            null,
          ),
          AppButtonVariant.secondary => (
            hovered ? c.surfaceHover : Colors.transparent,
            ink,
            c.border,
          ),
          AppButtonVariant.link => (Colors.transparent, ink, null),
        };
        final text = Text(
          label,
          style: context.typo
              .body(13, color: fg, weight: FontWeight.w600)
              .copyWith(
                decoration: variant == AppButtonVariant.link
                    ? TextDecoration.underline
                    : null,
                decorationColor: fg,
              ),
        );
        return AnimatedContainer(
          duration: AppMotion.fast,
          padding: variant == AppButtonVariant.link
              ? const EdgeInsets.symmetric(vertical: AppSpace.xs)
              : const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: 12,
                ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: context.shape.borderRadius,
            border: line == null
                ? null
                : Border.all(color: line, width: context.shape.strokeWidth),
          ),
          child: icon == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: AppSpace.xs + 2),
                    text,
                  ],
                ),
        );
      },
    );
  }
}

/// 아이콘만 있는 네모 버튼 (페이지 이동 등).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final button = HoverBuilder(
      onTap: onPressed,
      builder: (context, hovered) => AnimatedContainer(
        duration: AppMotion.fast,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : Colors.transparent,
          borderRadius: context.shape.borderRadius,
          border: Border.all(
            color: enabled ? c.borderStrong : c.border,
            width: context.shape.strokeWidth,
          ),
        ),
        child: Icon(icon, size: 16, color: enabled ? c.textPrimary : c.border),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
