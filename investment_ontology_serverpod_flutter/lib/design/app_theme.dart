import 'package:flutter/material.dart';

import 'tokens.dart';

/// 브랜드 = 색 + 글꼴 + 형태. 화면 코드는 브랜드를 직접 참조하지 않는다.
class AppBrand {
  const AppBrand({
    required this.colors,
    required this.typography,
    required this.shape,
  });

  final AppColors colors;
  final AppTypography typography;
  final AppShape shape;
}

ThemeData buildAppTheme(AppBrand brand) {
  final c = brand.colors;
  final t = brand.typography;
  final radius = brand.shape.borderRadius;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      primary: c.textPrimary,
      secondary: c.accent,
      surface: c.background,
      onSurface: c.textPrimary,
    ),
    scaffoldBackgroundColor: c.background,
  );

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: color, width: width),
  );

  return base.copyWith(
    extensions: [c, t, brand.shape],
    textTheme: base.textTheme.apply(
      fontFamily: t.bodyBase.fontFamily,
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    ),
    dividerColor: c.border,
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: t.body(20, color: c.textPrimary, weight: FontWeight.w600),
      contentTextStyle: t.body(14, color: c.textSecondary),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: c.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      textStyle: t.body(14, color: c.textPrimary),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.textSecondary,
        minimumSize: const Size(44, 44),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(44, 44),
        textStyle: t.body(14, weight: FontWeight.w600),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.inverse, borderRadius: radius),
      textStyle: t.body(12, color: c.onInverse),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: c.surface,
      hintStyle: t.body(14, color: c.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(c.borderStrong, brand.shape.strokeWidth),
      enabledBorder: border(c.borderStrong, brand.shape.strokeWidth),
      focusedBorder: border(c.accent, 2),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceHover,
    ),
  );
}
