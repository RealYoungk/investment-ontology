import 'package:shad/shad.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../design/tokens.dart';

/// 로그인과 가입 시작의 공통 입력 레이아웃. 인증은 Serverpod가 처리한다.
class LoginFormKo extends StatefulWidget {
  const LoginFormKo({
    super.key,
    required this.controller,
    this.registration = false,
    this.reset = false,
  });
  final EmailAuthController controller;
  final bool registration;
  final bool reset;
  @override
  State<LoginFormKo> createState() => _LoginFormKoState();
}

class _LoginFormKoState extends State<LoginFormKo> {
  bool _visible = false;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final registration = widget.registration;
    final reset = widget.reset;
    final emailOnly = registration || reset;
    final t = context.typo;
    final c = context.colors;
    final ready =
        controller.emailController.text.trim().isNotEmpty &&
        (emailOnly || controller.passwordController.text.isNotEmpty) &&
        !controller.isLoading;
    void submit() {
      // Autofill can update controllers between the last build and submission.
      if (controller.isLoading ||
          controller.emailController.text.trim().isEmpty ||
          (!emailOnly && controller.passwordController.text.isEmpty)) {
        return;
      }
      if (reset) {
        controller.startPasswordReset();
      } else if (registration) {
        controller.startRegistration();
      } else {
        controller.login();
      }
    }

    return AutofillGroup(
      child: ShadForm(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reset
                  ? '비밀번호 찾기'
                  : registration
                  ? '회원가입'
                  : '로그인',
              style: t.display(26),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              reset
                  ? '가입한 이메일로 인증번호를 보내드립니다.'
                  : registration
                  ? '관심기업을 저장하고 공시를 모아보세요.'
                  : '관심기업과 공시를 이어서 확인하세요.',
              style: t.body(14, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.lg),
            ShadInputFormField(
              constraints: const BoxConstraints(minHeight: 48),
              label: const Text('이메일'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              placeholder: const Text('이메일 주소'),
              forceErrorText: controller.error is InvalidEmailException
                  ? controller.errorMessage
                  : null,
              key: const ValueKey('login-email'),
              controller: controller.emailController,
              focusNode: _emailFocus,
              enabled: !controller.isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              textCapitalization: TextCapitalization.none,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: emailOnly
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: emailOnly
                  ? (_) => submit()
                  : (_) => _passwordFocus.requestFocus(),
            ),
            if (!emailOnly) ...[
              const SizedBox(height: AppSpace.lg),
              ShadInputFormField(
                constraints: const BoxConstraints(minHeight: 48),
                label: const Text('비밀번호'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                placeholder: Text('비밀번호를 입력해 주세요'),
                trailing: Semantics(
                  container: true,
                  label: _visible ? '비밀번호 숨기기' : '비밀번호 표시',
                  button: true,
                  enabled: !controller.isLoading,
                  onTap: controller.isLoading
                      ? null
                      : () => setState(() => _visible = !_visible),
                  child: ExcludeSemantics(
                    child: ShadIconButton.ghost(
                      width: 20,
                      height: 20,
                      padding: EdgeInsets.zero,
                      enabled: !controller.isLoading,
                      onPressed: controller.isLoading
                          ? null
                          : () => setState(() => _visible = !_visible),
                      icon: Icon(
                        _visible ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 20,
                      ),
                      semanticLabel: _visible ? '비밀번호 숨기기' : '비밀번호 표시',
                    ),
                  ),
                ),
                key: const ValueKey('login-password'),
                controller: controller.passwordController,
                focusNode: _passwordFocus,
                enabled: !controller.isLoading,
                obscureText: !_visible,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton.ghost(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.navigateTo(
                          EmailFlowScreen.requestPasswordReset,
                        ),
                  enabled:
                      (controller.isLoading
                          ? null
                          : () => controller.navigateTo(
                              EmailFlowScreen.requestPasswordReset,
                            )) !=
                      null,
                  child: Flexible(child: const Text('비밀번호 찾기')),
                ),
              ),
            ] else if (registration) ...[
              const SizedBox(height: 16),
              Text(
                '가입 이메일·인증 정보는 계정 생성과 보안에 사용하며 회원 탈퇴까지 보관합니다. 인증 메일은 Resend를 통해 미국에서 처리됩니다. 아래 개인정보처리방침에서 처리 경로와 권리 행사 방법을 확인하세요. 회원가입 없이도 기업 데이터를 조회할 수 있습니다.',
                style: t.body(13, color: c.textSecondary),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            if (reset) const SizedBox(height: AppSpace.lg),
            SizedBox(
              height: 48,
              child: ShadButton(
                height: 48,
                key: const ValueKey('login-submit'),
                onPressed: ready ? submit : null,
                enabled: (ready ? submit : null) != null,
                child: Flexible(
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: ShadSpinner(strokeWidth: 2),
                        )
                      : Text(emailOnly ? '인증번호 받기' : '로그인'),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  emailOnly ? '이미 계정이 있나요?' : '아직 계정이 없나요?',
                  style: t.body(13, color: c.textSecondary),
                ),
                ShadButton.ghost(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.navigateTo(
                          emailOnly
                              ? EmailFlowScreen.login
                              : EmailFlowScreen.startRegistration,
                        ),
                  enabled:
                      (controller.isLoading
                          ? null
                          : () => controller.navigateTo(
                              emailOnly
                                  ? EmailFlowScreen.login
                                  : EmailFlowScreen.startRegistration,
                            )) !=
                      null,
                  child: Flexible(child: Text(emailOnly ? '로그인' : '회원가입')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
