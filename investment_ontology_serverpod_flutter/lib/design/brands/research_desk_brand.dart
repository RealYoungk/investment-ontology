import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../tokens.dart';

/// Research Desk: quiet surfaces, charcoal navigation, readable financial data.
///
/// 리브랜딩할 때는 이 파일과 같은 형태의 브랜드를 새로 만들고 `main.dart`에서 바꾼다.
final researchDeskBrand = AppBrand(
  colors: researchDeskColors,
  typography: AppTypography(
    displayBase: GoogleFonts.ibmPlexSansKr(
      fontWeight: FontWeight.w700,
      height: 1.25,
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
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ).copyWith(fontFamilyFallback: _koreanFallback),
  ),
  shape: const AppShape(radius: 10, strokeWidth: 1),
);

/// 모노 폰트가 못 그리는 글자(한글)를 맡는 폰트.
final _koreanFallback = <String>[
  ?GoogleFonts.ibmPlexSansKr().fontFamily,
];

const researchDeskColors = AppColors(
  background: Color(0xFFF5F7FA),
  surface: Color(0xFFFFFFFF),
  surfaceHover: Color(0xFFEEF2F6),
  inverse: Color(0xFF202831),
  onInverse: Color(0xFFF5F7FA),
  textPrimary: Color(0xFF202831),
  textSecondary: Color(0xFF536171),
  textMuted: Color(0xFF607080),
  border: Color(0xFFE1E6EC),
  borderStrong: Color(0xFFBAC5D0),
  accent: Color(0xFF276A9B),
  accentSubtle: Color(0xFFE8F1F8),
  onAccent: Color(0xFFF5F7FA),
  success: Color(0xFF25745B),
  marketUp: Color(0xFFB83232),
  marketDown: Color(0xFF2463AD),
  marketKospi: Color(0xFF202831),
  marketKosdaq: Color(0xFF276A9B),
  marketKonex: Color(0xFF64748B),
  // Blue / ochre distinguish revenue and earnings without borrowing gain/loss colors.
  chartSeries1: Color(0xFF2F6DA8),
  chartSeries2: Color(0xFF9C5D22),
  chartSeries3: Color(0xFF6D44A1),
  chartGrid: Color(0xFFE5EAF0),
  chartTile: Color(0xFFE8EFF6),
  chartTileHover: Color(0xFFCFDEEC),
);
