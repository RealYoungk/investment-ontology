import 'tokens.dart';

/// Service reading/layout rules. Use allocated width, not device type.
abstract final class AppLayout {
  static const compact = 720.0;
  static const readingWidth = 760.0;
  static const contentWidth = 1280.0;
  static const tableCellVerticalPadding = 10.0;
  static double gutter(double width) =>
      width < compact ? AppSpace.lg : AppSpace.xxl;
  static double panelPadding(double width) =>
      width < compact ? AppSpace.lg : AppSpace.xl;
}
