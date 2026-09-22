import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
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
/// 가입하면 읽기 전용이다. 관리자 권한은 서버의 허용 목록으로만 생긴다.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final _controller = EmailAuthController(
    client: client,
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
                  Text('ALFINDER', style: t.label(color: c.accent)),
                  const SizedBox(height: AppSpace.sm),
                  Text('알파인더', style: t.display(28)),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '로그인한 계정만 볼 수 있습니다. 데이터를 바꾸는 일은 관리자만 합니다.',
                    style: t.body(13.5, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: context.shape.borderRadius,
                      border: Border.all(
                        color: c.borderStrong,
                        width: context.shape.strokeWidth,
                      ),
                    ),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) =>
                          _AuthFlowScreen(controller: _controller),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) =>
                        _Notices(screen: _controller.currentScreen),
                  ),
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
      EmailFlowScreen.startRegistration => StartRegistrationForm(
        controller: controller,
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

  static const _registrationSteps = {
    EmailFlowScreen.startRegistration,
    EmailFlowScreen.verifyRegistration,
    EmailFlowScreen.completeRegistration,
  };

  static const _verificationSteps = {
    EmailFlowScreen.verifyRegistration,
    EmailFlowScreen.verifyPasswordReset,
  };

  @override
  Widget build(BuildContext context) {
    final notices = [
      if (_registrationSteps.contains(screen)) readOnlyAccountNotice,
      // 로컬 개발 서버에서만 뜻이 있는 안내라, 개발 실행일 때만 보여준다.
      if (kDebugMode && _verificationSteps.contains(screen))
        devVerificationNotice,
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
