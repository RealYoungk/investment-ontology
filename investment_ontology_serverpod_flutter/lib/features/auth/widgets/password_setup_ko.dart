import 'package:flutter/material.dart';
import 'package:shad/shad.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_auth_idp_flutter/widgets.dart';

/// 고정 높이 없이 한국어 비밀번호 조건을 표시한다. 인증은 내장 컨트롤러가 처리한다.
class PasswordSetupKo extends StatefulWidget {
  const PasswordSetupKo({
    super.key,
    required this.controller,
    this.reset = false,
  });

  final EmailAuthController controller;
  final bool reset;

  @override
  State<PasswordSetupKo> createState() => _PasswordSetupKoState();
}

class _PasswordSetupKoState extends State<PasswordSetupKo> {
  bool _visible = false;
  EmailAuthController get controller => widget.controller;
  bool get reset => widget.reset;

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
              style: ShadTheme.of(context).textTheme.h3,
            ),
            smallGap,
            ShadInputFormField(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              label: Text(reset ? texts.newPasswordLabel : texts.passwordLabel),
              obscureText: !_visible,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (requirements.isValid(password) && !controller.isLoading) {
                  reset
                      ? controller.finishPasswordReset()
                      : controller.finishRegistration();
                }
              },
              trailing: Semantics(
                container: true,
                button: true,
                enabled: !controller.isLoading,
                label: _visible ? '비밀번호 숨기기' : '비밀번호 표시',
                onTap: controller.isLoading
                    ? null
                    : () => setState(() => _visible = !_visible),
                child: ExcludeSemantics(
                  child: ShadIconButton.ghost(
                    width: 20,
                    height: 20,
                    padding: EdgeInsets.zero,
                    enabled: !controller.isLoading,
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                    ),
                  ),
                ),
              ),
              controller: controller.passwordController,
              enabled: !controller.isLoading,
            ),
            if (requirements.isNotEmpty) ...[
              tinyGap,
              PasswordRequirements(
                password: password,
                requirements: requirements,
              ),
            ],
            smallGap,
            ShadButton(
              height: 48,
              enabled: requirements.isValid(password) && !controller.isLoading,
              onPressed: requirements.isValid(password) && !controller.isLoading
                  ? (reset
                        ? controller.finishPasswordReset
                        : controller.finishRegistration)
                  : null,
              child: controller.isLoading
                  ? const ShadSpinner()
                  : Text(reset ? texts.resetPassword : texts.signUp),
            ),
            if (reset)
              ShadButton.ghost(
                enabled: !controller.isLoading,
                onPressed: () => controller.navigateTo(EmailFlowScreen.login),
                child: const Text('로그인으로 돌아가기'),
              )
            else
              ShadButton.ghost(
                enabled: !controller.isLoading,
                onPressed: () =>
                    controller.navigateTo(EmailFlowScreen.startRegistration),
                child: Text(texts.backToSignUp),
              ),
          ],
        );
      },
    );
  }
}
