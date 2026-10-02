import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../design/tokens.dart';

/// 로그인과 가입 시작의 공통 입력 레이아웃. 인증은 Serverpod가 처리한다.
class LoginFormKo extends StatefulWidget {
  const LoginFormKo({
    super.key,
    required this.controller,
    this.registration = false,
  });
  final EmailAuthController controller;
  final bool registration;
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
    final t = context.typo;
    final c = context.colors;
    final ready =
        controller.emailController.text.trim().isNotEmpty &&
        (registration || controller.passwordController.text.isNotEmpty) &&
        !controller.isLoading;
    void submit() {
      // Autofill can update controllers between the last build and submission.
      if (controller.isLoading ||
          controller.emailController.text.trim().isEmpty ||
          (!registration && controller.passwordController.text.isEmpty)) {
        return;
      }
      if (registration) {
        controller.startRegistration();
      } else {
        controller.login();
      }
    }

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(registration ? '회원가입' : '로그인', style: t.display(26)),
          const SizedBox(height: 8),
          Text(
            registration ? '이메일 인증으로 계정을 만들어 주세요.' : '이메일로 알파인더에 로그인하세요.',
            style: t.body(14, color: c.textSecondary),
          ),
          const SizedBox(height: 28),
          Text('이메일', style: t.body(13, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('login-email'),
            controller: controller.emailController,
            focusNode: _emailFocus,
            enabled: !controller.isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textCapitalization: TextCapitalization.none,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: registration
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: registration
                ? (_) => submit()
                : (_) => _passwordFocus.requestFocus(),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              errorText: controller.error is InvalidEmailException
                  ? controller.errorMessage
                  : null,
            ),
          ),
          if (!registration) ...[
            const SizedBox(height: 20),
            Text('비밀번호', style: t.body(13, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
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
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해 주세요',
                suffixIcon: IconButton(
                  tooltip: _visible ? '비밀번호 숨기기' : '비밀번호 표시',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () => controller.navigateTo(
                        EmailFlowScreen.requestPasswordReset,
                      ),
                child: const Text('비밀번호 찾기'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              '가입 이메일·인증 정보는 계정 생성과 보안에 사용하며 회원 탈퇴까지 보관합니다. 인증 메일은 Resend를 통해 미국에서 처리됩니다. 아래 개인정보처리방침에서 처리 경로와 권리 행사 방법을 확인하세요. 회원가입 없이도 기업 데이터를 조회할 수 있습니다.',
              style: t.body(13, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            height: 48,
            child: FilledButton(
              key: const ValueKey('login-submit'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: context.shape.borderRadius,
                ),
              ),
              onPressed: ready ? submit : null,
              child: controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(registration ? '인증번호 받기' : '로그인'),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                registration ? '이미 계정이 있나요?' : '아직 계정이 없나요?',
                style: t.body(13, color: c.textSecondary),
              ),
              TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () => controller.navigateTo(
                        registration
                            ? EmailFlowScreen.login
                            : EmailFlowScreen.startRegistration,
                      ),
                child: Text(registration ? '로그인' : '회원가입'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
