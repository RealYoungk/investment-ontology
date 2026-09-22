import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_auth_idp_flutter/widgets.dart';

/// 로그인 화면.
///
/// 패키지 기본 `LoginForm`은 [PasswordField]에 라벨을 넘기지 않아 항상 영어 "Password"로
/// 뜬다(가입·재설정 화면의 비밀번호 칸은 `texts.passwordLabel`/`texts.newPasswordLabel`을
/// 넘겨 제대로 지역화된다). 같은 부품(EmailTextField·PasswordField·ActionButton·
/// HyperlinkTextButton·FormStandardLayout)으로 라벨만 채워 다시 그린다 — 인증 호출은
/// 그대로 [EmailAuthController.login]을 쓴다.
class LoginFormKo extends StatelessWidget {
  const LoginFormKo({super.key, required this.controller});

  final EmailAuthController controller;

  @override
  Widget build(BuildContext context) {
    final texts = context.emailSignInTexts;

    return FormStandardLayout(
      title: texts.title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmailTextField(controller: controller),
          smallGap,
          PasswordField(
            labelText: texts.passwordLabel,
            controller: controller.passwordController,
            isLoading: controller.isLoading,
          ),
          tinyGap,
          Align(
            alignment: Alignment.centerRight,
            child: HyperlinkTextButton(
              onPressed: () =>
                  controller.navigateTo(EmailFlowScreen.requestPasswordReset),
              label: texts.forgotPassword,
            ),
          ),
        ],
      ),
      actionButton: ActionButton(
        onPressed:
            controller.emailController.text.isNotEmpty &&
                controller.passwordController.text.isNotEmpty &&
                controller.state == EmailAuthState.idle
            ? controller.login
            : null,
        label: texts.signIn,
        isLoading: controller.isLoading,
      ),
      // 계정이 없는 사람을 위한 가입 링크. 로그인 화면에서 바로 보인다.
      bottomText: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(texts.dontHaveAnAccount),
          HyperlinkTextButton(
            onPressed: () =>
                controller.navigateTo(EmailFlowScreen.startRegistration),
            label: texts.signUp,
          ),
        ],
      ),
    );
  }
}
