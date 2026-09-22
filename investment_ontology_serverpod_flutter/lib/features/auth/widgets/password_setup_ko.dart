import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_auth_idp_flutter/widgets.dart';

/// 고정 높이 없이 한국어 비밀번호 조건을 표시한다. 인증은 내장 컨트롤러가 처리한다.
class PasswordSetupKo extends StatelessWidget {
  const PasswordSetupKo({
    super.key,
    required this.controller,
    this.reset = false,
  });

  final EmailAuthController controller;
  final bool reset;

  @override
  Widget build(BuildContext context) {
    final texts = context.emailSignInTexts;
    return ListenableBuilder(
      listenable: controller.passwordController,
      builder: (context, _) {
        final requirements = controller.passwordRequirements;
        final password = controller.passwordController.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reset ? texts.setNewPasswordTitle : texts.setAccountPasswordTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            smallGap,
            PasswordField(
              labelText: reset ? texts.newPasswordLabel : texts.passwordLabel,
              controller: controller.passwordController,
              isLoading: controller.isLoading,
            ),
            if (requirements.isNotEmpty) ...[
              tinyGap,
              PasswordRequirements(
                password: password,
                requirements: requirements,
              ),
            ],
            smallGap,
            ActionButton(
              onPressed: requirements.isValid(password) && !controller.isLoading
                  ? (reset
                        ? controller.finishPasswordReset
                        : controller.finishRegistration)
                  : null,
              label: reset ? texts.resetPassword : texts.signUp,
              isLoading: controller.isLoading,
            ),
            if (reset)
              BackToSignInButton(controller: controller)
            else
              HyperlinkTextButton(
                onPressed: () =>
                    controller.navigateTo(EmailFlowScreen.startRegistration),
                label: texts.backToSignUp,
              ),
          ],
        );
      },
    );
  }
}
