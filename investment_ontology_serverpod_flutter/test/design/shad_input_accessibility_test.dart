import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

SemanticsNode inputNode(WidgetTester tester) {
  SemanticsNode? result;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isTextField) result = node;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(ShadInput)));
  return result!;
}

void main() {
  testWidgets('placeholder changes preserve the textbox semantics ancestry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: Scaffold(
            body: ShadInput(
              controller: controller,
              placeholder: const Text('기업 검색'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    List<int> ancestry() {
      final ids = <int>[];
      SemanticsNode? node = inputNode(tester);
      while (node != null) {
        ids.add(node.id);
        node.visitChildren((child) {
          ids.add(child.id);
          return true;
        });
        node = node.parent;
      }
      return ids;
    }

    final before = ancestry();
    tester.testTextInput.enterText('삼');
    await tester.pump();
    expect(
      ancestry(),
      before,
      reason: 'Removing the placeholder must not reparent the browser input',
    );
    tester.testTextInput.enterText('');
    await tester.pump();
    expect(ancestry(), before);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('visible field label takes priority over shared placeholder', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      shadTestHost(
        const MaterialApp(
          home: Scaffold(
            body: ShadInput(top: Text('PER 이하'), placeholder: Text('제한 없음')),
          ),
        ),
      ),
    );
    expect(inputNode(tester).getSemanticsData().label, 'PER 이하');
    semantics.dispose();
  });
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    testWidgets('editing shortcuts and composing on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final controller = TextEditingController();
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            home: Scaffold(body: ShadInput(controller: controller)),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump();
      expect(controller.value.composing, const TextRange(start: 0, end: 1));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '한글 입력',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();
      final modifier = platform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets(
    'enabled textbox focuses and delegates semantic editing to real editor',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      final focus = FocusNode();
      final changed = <String>[];
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            home: Scaffold(
              body: ShadInput(
                controller: controller,
                focusNode: focus,
                onChanged: changed.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final finder = find.byType(ShadInput);
      final node = inputNode(tester);
      final owner = tester.renderObject(finder).owner!.semanticsOwner!;
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        ui.Tristate.isTrue,
      );
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      owner.performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      final focusedNode = inputNode(tester);
      expect(focusedNode.id, node.id);
      owner.performAction(focusedNode.id, ui.SemanticsAction.setText, '한글 입력');
      await tester.pump();
      expect(controller.text, '한글 입력');
      expect(changed, ['한글 입력']);
      expect(
        inputNode(tester).getSemanticsData().textSelection,
        controller.selection,
      );
      owner.performAction(node.id, ui.SemanticsAction.setSelection, {
        'base': 0,
        'extent': controller.text.length,
      });
      await tester.pump();
      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, controller.text.length);
      owner.performAction(node.id, ui.SemanticsAction.setText, '');
      await tester.pump();
      expect(controller.text, '');
      expect(changed.last, '');
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
    },
  );
  testWidgets(
    'disabled input rejects editing and password value remains obscured',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        shadTestHost(
          const MaterialApp(
            home: Scaffold(
              body: ShadInput(
                enabled: false,
                obscureText: true,
                initialValue: 'secret',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final node = inputNode(tester);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        ui.Tristate.isFalse,
      );
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.setText),
        isFalse,
      );
      expect(node.getSemanticsData().value, isNot(contains('secret')));
      semantics.dispose();
    },
  );
  testWidgets('trailing control keeps its own accessible button and action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var cleared = false;
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: Scaffold(
            body: ShadInput(
              trailing: ShadIconButton.ghost(
                semanticLabel: '검색어 지우기',
                icon: const Icon(Icons.close),
                onPressed: () => cleared = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final finder = find.byType(ShadIconButton);
    final node = tester.getSemantics(finder);
    expect(node.getSemanticsData().label, contains('검색어 지우기'));
    await tester.tap(finder);
    await tester.pump();
    expect(cleared, isTrue);
    semantics.dispose();
  });
}
