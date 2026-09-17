import 'package:flutter/material.dart';

/// 의미 기반 색 토큰. 화면·컴포넌트는 이 이름만 쓰고, 실제 색은 브랜드가 정한다.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHover,
    required this.inverse,
    required this.onInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentSubtle,
    required this.onAccent,
    required this.success,
    required this.marketKospi,
    required this.marketKosdaq,
    required this.marketKonex,
  });

  /// 페이지 바탕.
  final Color background;

  /// 카드·패널·입력창.
  final Color surface;

  /// 행·항목에 마우스를 올렸을 때.
  final Color surfaceHover;

  /// 선택된 행처럼 반전되는 면과 그 위 글자.
  final Color inverse;
  final Color onInverse;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// 표 구분선 등 약한 선 / 입력창·버튼 테두리 등 강한 선.
  final Color border;
  final Color borderStrong;

  /// 강조색 하나. 선택·링크·경고에 쓴다.
  final Color accent;
  final Color accentSubtle;
  final Color onAccent;

  final Color success;

  /// 시장 구분 색.
  final Color marketKospi;
  final Color marketKosdaq;
  final Color marketKonex;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHover: l(surfaceHover, other.surfaceHover),
      inverse: l(inverse, other.inverse),
      onInverse: l(onInverse, other.onInverse),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      accent: l(accent, other.accent),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      marketKospi: l(marketKospi, other.marketKospi),
      marketKosdaq: l(marketKosdaq, other.marketKosdaq),
      marketKonex: l(marketKonex, other.marketKonex),
    );
  }
}

/// 글꼴 역할 토큰. 크기·굵기는 호출하는 곳에서 정하고, 글꼴은 브랜드가 정한다.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayBase,
    required this.bodyBase,
    required this.numericBase,
    required this.labelBase,
  });

  /// 큰 제목.
  final TextStyle displayBase;

  /// 본문·표 텍스트.
  final TextStyle bodyBase;

  /// 숫자·코드. 자릿수가 맞는 글꼴.
  final TextStyle numericBase;

  /// 작은 대문자 라벨.
  final TextStyle labelBase;

  TextStyle display(double size, {Color? color}) =>
      displayBase.copyWith(fontSize: size, color: color);

  TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      bodyBase.copyWith(fontSize: size, color: color, fontWeight: weight);

  TextStyle numeric(double size, {Color? color, FontWeight? weight}) =>
      numericBase.copyWith(fontSize: size, color: color, fontWeight: weight);

  TextStyle label({Color? color}) => labelBase.copyWith(color: color);

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(covariant AppTypography? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// 간격 단위.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 48.0;
}

/// 움직임 시간.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;
}

/// 모서리·선 두께 등 형태.
@immutable
class AppShape extends ThemeExtension<AppShape> {
  const AppShape({required this.radius, required this.strokeWidth});

  final double radius;
  final double strokeWidth;

  BorderRadius get borderRadius => BorderRadius.circular(radius);

  @override
  AppShape copyWith() => this;

  @override
  AppShape lerp(covariant AppShape? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get typo => Theme.of(this).extension<AppTypography>()!;
  AppShape get shape => Theme.of(this).extension<AppShape>()!;
}
