import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/app_tab_bar.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 1045.0]) {
    testWidgets('company tabs fit labels and remain selectable at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var selected = 'overview';
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Align(
                  alignment: Alignment.topLeft,
                  child: AppTabBar<String>(
                    fitContent: true,
                    value: selected,
                    tabs: const {
                      'overview': '개요',
                      'financials': '재무',
                      'governance': '지배구조',
                      'returns': '주주환원',
                      'disclosures': '공시',
                    },
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(ShadTabs<String>)).width,
        lessThan(500),
      );
      expect(
        tester.getSize(find.byType(ShadTabs<String>)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('재무'));
      await tester.pumpAndSettle();
      expect(selected, 'financials');
      expect(tester.takeException(), isNull);
    });
  }
}
