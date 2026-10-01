import 'package:flutter/material.dart';

import '../monetization/service_links.dart';

import 'package:go_router/go_router.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_auth_idp_flutter/widgets.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'auth_localization_ko.dart';
import 'widgets/login_form_ko.dart';
import 'widgets/password_setup_ko.dart';
import 'widgets/verification_form_ko.dart';

/// 로그인 화면.
///
/// 이메일 로그인·가입·비밀번호 재설정을 한 카드 안에서 오가며, Serverpod의
/// [EmailAuthController] 위에 화면만 새로 그린다 — 인증 호출은 그대로 컨트롤러가 한다.
/// 로그인 화면이 맨 먼저 보인다([EmailAuthController]의 기본 시작 화면). 패키지가 이미
/// 지역화된 가입·재설정 시작 폼은 재사용한다. 나머지는 한국어 문구와 작은 화면의
/// 높이에 맞춰 구성하고 내장 컨트롤러의 인증·비밀번호 검증 로직을 사용한다.
///
/// 가입하면 일반 회원이다. 관리자 권한은 서버에서만 부여한다.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.resetPassword = false});
  final bool resetPassword;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final _controller = EmailAuthController(
    client: client,
    startScreen: widget.resetPassword
        ? EmailFlowScreen.requestPasswordReset
        : EmailFlowScreen.login,
    emailValidation: koreanEmailValidation,
    onError: _showError,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(koreanAuthErrorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return SignInLocalizationProvider(
      email: koreanEmailSignInTexts,
      passwordRequirementTexts: koreanPasswordRequirementTexts,
      child: Scaffold(
        appBar: widget.resetPassword
            ? AppBar(title: const Text('비밀번호 재설정'))
            : null,
        backgroundColor: c.background,
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 480
                  ? AppSpace.md
                  : AppSpace.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'alfinder',
                    style: t.display(22).copyWith(color: c.accent),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 480 ? 24 : 32,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: context.shape.borderRadius,
                      border: Border.all(
                        color: c.border,
                        width: context.shape.strokeWidth,
                      ),
                    ),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RegistrationProgress(
                            screen: _controller.currentScreen,
                          ),
                          _AuthFlowScreen(controller: _controller),
                        ],
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) =>
                        _Notices(screen: _controller.currentScreen),
                  ),
                  const ServiceLinks(),
                  if (!widget.resetPassword) ...[
                    const SizedBox(height: AppSpace.md),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          '둘러보기',
                          style: t.body(13, color: c.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 지금 단계에 맞는 화면 하나.
class _AuthFlowScreen extends StatelessWidget {
  const _AuthFlowScreen({required this.controller});

  final EmailAuthController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.currentScreen) {
      EmailFlowScreen.login => LoginFormKo(controller: controller),
      EmailFlowScreen.startRegistration => LoginFormKo(
        controller: controller,
        registration: true,
      ),
      EmailFlowScreen.verifyRegistration => VerificationFormKo(
        controller: controller,
        title: koreanEmailSignInTexts.verifyAccountTitle,
        onCompleted: controller.verifyRegistrationCode,
      ),
      EmailFlowScreen.completeRegistration => PasswordSetupKo(
        controller: controller,
      ),
      EmailFlowScreen.requestPasswordReset => RequestPasswordResetForm(
        controller: controller,
      ),
      EmailFlowScreen.verifyPasswordReset => VerificationFormKo(
        controller: controller,
        title: koreanEmailSignInTexts.verifyResetCodeTitle,
        onCompleted: controller.verifyPasswordResetCode,
      ),
      EmailFlowScreen.completePasswordReset => PasswordSetupKo(
        reset: true,
        controller: controller,
      ),
    };
  }
}

/// 지금 단계에서만 뜻이 있는 안내들. 로그인 화면에는 아무것도 보이지 않는다.
class _Notices extends StatelessWidget {
  const _Notices({required this.screen});

  final EmailFlowScreen screen;

  static const _verificationSteps = {
    EmailFlowScreen.verifyRegistration,
    EmailFlowScreen.verifyPasswordReset,
  };

  @override
  Widget build(BuildContext context) {
    final notices = [
      if (_verificationSteps.contains(screen))
        '메일이 보이지 않으면 스팸함을 확인해 주세요. 인증번호는 다른 사람에게 알려주지 마세요.',
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in notices) ...[
          const SizedBox(height: AppSpace.md),
          AppNotice(message: notice),
        ],
      ],
    );
  }
}

class _RegistrationProgress extends StatelessWidget {
  const _RegistrationProgress({required this.screen});
  final EmailFlowScreen screen;

  @override
  Widget build(BuildContext context) {
    final step = switch (screen) {
      EmailFlowScreen.startRegistration => 0,
      EmailFlowScreen.verifyRegistration => 1,
      EmailFlowScreen.completeRegistration => 2,
      _ => -1,
    };
    if (step < 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Text(
                '${i + 1} ${['이메일', '인증', '비밀번호'][i]}',
                style: context.typo.body(
                  12,
                  color: i == step
                      ? context.colors.accent
                      : context.colors.textSecondary,
                  weight: i == step ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
