import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/navigation_menu.dart';

void main() {
  testWidgets(
    'site navigation activates routes and moves focus without navigation',
    (tester) async {
      var destination = '';
      await tester.pumpWidget(
        shadTestHost(
          ShadApp(
            home: Scaffold(
              body: AppNavigationMenu(
                entries: [
                  NavigationEntry(
                    label: '홈',
                    selected: true,
                    onPressed: () => destination = 'home',
                  ),
                  NavigationEntry(
                    label: '시장',
                    onPressed: () => destination = 'market',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('홈'));
      expect(destination, 'home');
      final buttons = tester
          .widgetList<ShadButton>(find.byType(ShadButton))
          .toList();
      buttons.first.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(destination, 'home');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(destination, 'market');
    },
  );
}
