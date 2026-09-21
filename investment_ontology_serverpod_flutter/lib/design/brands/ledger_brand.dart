import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../tokens.dart';

/// 임시 브랜드 "원장": 미색 종이 + 잉크 검정 + 주홍 강조 하나.
///
/// 리브랜딩할 때는 이 파일과 같은 형태의 브랜드를 새로 만들고 `main.dart`에서 바꾼다.
final ledgerBrand = AppBrand(
  colors: const AppColors(
    background: Color(0xFFF2EDE2),
    surface: Color(0xFFFAF7F0),
    surfaceHover: Color(0xFFE8E0D0),
    inverse: Color(0xFF17140F),
    onInverse: Color(0xFFF2EDE2),
    textPrimary: Color(0xFF17140F),
    textSecondary: Color(0xFF5C554A),
    textMuted: Color(0xFF9A9183),
    border: Color(0xFFCFC5B3),
    borderStrong: Color(0xFF17140F),
    accent: Color(0xFFC8401A),
    accentSubtle: Color(0xFFF3D9CC),
    onAccent: Color(0xFFF2EDE2),
    success: Color(0xFF3F6B4E),
    marketKospi: Color(0xFF17140F),
    marketKosdaq: Color(0xFFC8401A),
    marketKonex: Color(0xFF8A7B5E),
    // 표면 #FAF7F0 기준 dataviz 검증 통과 (명도·채도·색각 구분·대비).
    chartSeries1: Color(0xFF2F6DA8),
    chartSeries2: Color(0xFFC8401A),
    chartGrid: Color(0xFFE3DCCD),
    chartTile: Color(0xFFDCE5EE),
    chartTileHover: Color(0xFFBFD1E3),
  ),
  typography: AppTypography(
    displayBase: GoogleFonts.nanumMyeongjo(
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    bodyBase: GoogleFonts.ibmPlexSansKr(height: 1.35),
    // 모노 폰트에는 한글이 없다. 웹에서 글자마다 대체 폰트를 받다가 빠뜨리면
    // 네모(⬜)로 보이므로, 이미 쓰는 한글 폰트를 대체로 지정해 둔다 (조·억·온톨로지 …).
    numericBase: GoogleFonts.ibmPlexMono(
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).copyWith(fontFamilyFallback: _koreanFallback),
    labelBase: GoogleFonts.ibmPlexMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
    ).copyWith(fontFamilyFallback: _koreanFallback),
  ),
  shape: const AppShape(radius: 0, strokeWidth: 1.2),
);

/// 모노 폰트가 못 그리는 글자(한글)를 맡는 폰트.
final _koreanFallback = <String>[
  ?GoogleFonts.ibmPlexSansKr().fontFamily,
];
