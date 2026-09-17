import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 종이 원장(ledger) 느낌의 팔레트. 잉크색 본문 + 주홍 인주 하나를 강조색으로 쓴다.
abstract final class Pal {
  static const paper = Color(0xFFF2EDE2);
  static const paperDeep = Color(0xFFE8E0D0);
  static const card = Color(0xFFFAF7F0);
  static const ink = Color(0xFF17140F);
  static const inkSoft = Color(0xFF5C554A);
  static const inkFaint = Color(0xFF9A9183);
  static const rule = Color(0xFFCFC5B3);
  static const seal = Color(0xFFC8401A);
  static const sealSoft = Color(0xFFF3D9CC);
  static const moss = Color(0xFF3F6B4E);

  /// 시장 구분 색 (유가/코스닥/코넥스).
  static const kospi = Color(0xFF17140F);
  static const kosdaq = Color(0xFFC8401A);
  static const konex = Color(0xFF8A7B5E);
}

abstract final class Typo {
  static TextStyle display(double size, {Color color = Pal.ink}) =>
      GoogleFonts.nanumMyeongjo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle body(
    double size, {
    Color color = Pal.ink,
    FontWeight weight = FontWeight.w400,
  }) => GoogleFonts.ibmPlexSansKr(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.35,
  );

  static TextStyle mono(
    double size, {
    Color color = Pal.ink,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 작은 대문자 라벨.
  static TextStyle label({Color color = Pal.inkSoft}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.4,
      );
}

ThemeData buildLedgerTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Pal.seal,
      primary: Pal.ink,
      secondary: Pal.seal,
      surface: Pal.paper,
      onSurface: Pal.ink,
    ),
    scaffoldBackgroundColor: Pal.paper,
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansKrTextTheme(
      base.textTheme,
    ).apply(bodyColor: Pal.ink, displayColor: Pal.ink),
    dividerColor: Pal.rule,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Pal.ink,
        borderRadius: BorderRadius.circular(2),
      ),
      textStyle: Typo.body(12, color: Pal.paper),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Pal.card,
      hintStyle: Typo.body(14, color: Pal.inkFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Pal.ink, width: 1.2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Pal.ink, width: 1.2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Pal.seal, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Pal.seal,
      linearTrackColor: Pal.paperDeep,
    ),
  );
}
