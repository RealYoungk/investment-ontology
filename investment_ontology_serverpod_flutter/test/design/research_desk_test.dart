import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/app_button.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';

void main() {
  test('Research Desk text and market colors have readable contrast', () {
    final c = researchDeskColors;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final foreground in [
      c.textPrimary,
      c.textSecondary,
      c.textMuted,
      c.marketUp,
      c.marketDown,
      c.accent,
      c.chartSeries1,
      c.chartSeries2,
    ]) {
      expect(contrast(foreground, c.background), greaterThanOrEqualTo(4.5));
      expect(contrast(foreground, c.surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(c.onInverse, c.inverse), greaterThanOrEqualTo(4.5));
    expect(c.marketChange(0), c.textSecondary);
    expect(c.marketChange(null), c.textSecondary);
  });
  testWidgets('Shared action supports keyboard and disabled state', (
    tester,
  ) async {
    var count = 0;
    final brand = AppBrand(
      colors: researchDeskColors,
      shape: const AppShape(radius: 10, strokeWidth: 1),
      typography: const AppTypography(
        displayBase: TextStyle(),
        bodyBase: TextStyle(),
        numericBase: TextStyle(),
        labelBase: TextStyle(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brand),
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: '선택', onPressed: () => count++),
              const AppButton(label: '비활성', onPressed: null),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 1);
    await tester.tap(find.text('비활성'));
    expect(count, 1);
  });
}
