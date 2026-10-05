import 'package:flutter/material.dart';

/// Editorial membership treatment shared by the introduction and plan cards.
abstract final class PremiumStyle {
  static const ink = Color(0xFF101C2B);
  static const deep = Color(0xFF24364A);
  static const gold = Color(0xFFE8C98C);
  static const light = Color(0xFFF9F5ED);
  static const muted = Color(0xFFCFD6DF);
  static BoxDecoration decoration() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [deep, ink],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: gold.withValues(alpha: .55)),
    boxShadow: [
      BoxShadow(
        color: ink.withValues(alpha: .18),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
