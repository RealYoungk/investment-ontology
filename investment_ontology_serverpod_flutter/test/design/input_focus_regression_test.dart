import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

void main() {
  testWidgets('Tab switches directly between editable inputs', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShadInput(focusNode: first, placeholder: const Text('첫 입력')),
                ShadInput(focusNode: second, placeholder: const Text('다음 입력')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ShadInput).first);
    await tester.pump();
    expect(first.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
    tester.testTextInput.enterText('한글');
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      '한글',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
