import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/widgets/login_form_ko.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final mode in ['login', 'registration', 'reset']) {
    testWidgets('$mode: 320px input and return navigation', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = EmailAuthController(
        client: Client('http://localhost:1/'),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(serviceBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => LoginFormKo(
                      controller: controller,
                      registration: mode == 'registration',
                      reset: mode == 'reset',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      ShadButton submit() =>
          tester.widget(find.byKey(const ValueKey('login-submit')));
      expect(submit().enabled, isFalse);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('login-email')),
          matching: find.byType(EditableText),
        ),
        'sample@example.com',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(submit().enabled, mode != 'login');
      if (mode == 'login') {
        final emailInput = find.descendant(
          of: find.byKey(const ValueKey('login-email')),
          matching: find.byType(ShadInput),
        );
        final passwordInput = find.descendant(
          of: find.byKey(const ValueKey('login-password')),
          matching: find.byType(ShadInput),
        );
        expect(
          tester.getSize(emailInput).height,
          tester.getSize(passwordInput).height,
        );
        await tester.tap(find.text('비밀번호 찾기'));
        expect(controller.currentScreen, EmailFlowScreen.requestPasswordReset);
      } else {
        await tester.tap(find.text('로그인'));
        expect(controller.currentScreen, EmailFlowScreen.login);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
