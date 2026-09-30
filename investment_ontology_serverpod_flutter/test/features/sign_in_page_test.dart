import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/widgets/login_form_ko.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart'
    as app_client;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/auth_localization_ko.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/sign_in_page.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// 화면 전환·한국어 문구만 확인한다. 실제 로그인/가입 버튼은 서버로 요청을 보내므로
/// 누르지 않는다 — 컨트롤러의 [EmailAuthController.navigateTo] 같은 순수 화면 전환만 누른다.
void main() {
  setUpAll(() {
    // 어떤 요청도 실제로 나가지 않는다(화면 전환·검증만 확인하므로). late final
    // client는 한 번만 대입할 수 있어 전체 파일에서 한 번만 만든다.
    app_client.client = Client('http://localhost:8080/')
      ..authSessionManager = FlutterAuthSessionManager();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(ledgerBrand), home: const SignInPage()),
    );
    await tester.pumpAndSettle();
  }

  Finder emailField() => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == 'name@example.com',
  );

  testWidgets('가입 단계와 인증 대상 이메일을 보여주고 주소를 수정할 수 있다', (tester) async {
    await pump(tester);
    final controller = tester
        .widget<LoginFormKo>(find.byType(LoginFormKo))
        .controller;
    controller.emailController.text = 'reader@example.com';
    controller.navigateTo(EmailFlowScreen.verifyRegistration);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('2 인증'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(find.textContaining('서버 실행 콘솔'), findsNothing);
    final verify = find.widgetWithText(ElevatedButton, '인증');
    if (verify.evaluate().isNotEmpty) {
      expect(tester.widget<ElevatedButton>(verify).onPressed, isNull);
    }
    await tester.tap(find.text('이메일 주소 수정'));
    await tester.pump();
    expect(find.text('인증번호 받기'), findsOneWidget);
    expect(controller.emailController.text, 'reader@example.com');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('로그인 화면이 맨 먼저 보이고, 가입 링크가 있다', (tester) async {
    await pump(tester);

    expect(find.text('이메일로 알파인더에 로그인하세요.'), findsOneWidget);
    expect(find.text('로그인'), findsNWidgets(2));
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('아직 계정이 없나요?'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);

    // 패키지 기본 로그인 폼의 영어 잔재(비밀번호 칸 라벨 등)가 없다.
    expect(find.text('Password'), findsNothing);
    expect(find.text('Sign in'), findsNothing);

    // 가입 단계에서만 뜻이 있는 안내는 로그인 화면에 없다.
    expect(find.text(readOnlyAccountNotice), findsNothing);
    expect(find.textContaining('서버 실행 콘솔'), findsNothing);
  });

  testWidgets('가입하기를 누르면 가입 화면으로, 로그인으로 돌아가면 다시 로그인 화면', (tester) async {
    await pump(tester);

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('이메일로 알파인더에 로그인하세요.'), findsNothing);
    expect(find.text('인증번호 받기'), findsOneWidget);
    // 새 계정은 읽기 전용이라는 안내는 가입 단계에서만 보인다.
    expect(find.text(readOnlyAccountNotice), findsNothing);

    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.text('이메일로 알파인더에 로그인하세요.'), findsOneWidget);
    expect(find.text(readOnlyAccountNotice), findsNothing);
  });

  testWidgets('비밀번호를 잊으셨나요를 누르면 재설정 화면으로, 돌아가면 다시 로그인 화면', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('비밀번호 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호 재설정'), findsOneWidget);
    expect(find.text('재설정 메일 보내기'), findsOneWidget);

    await tester.tap(find.text('로그인 화면으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('이메일로 알파인더에 로그인하세요.'), findsOneWidget);
  });

  testWidgets('잘못된 이메일을 적으면 한국어 안내가 뜬다', (tester) async {
    await pump(tester);

    await tester.enterText(emailField(), 'not-an-email');
    // emailController 변경은 500ms 뒤에야 검증한다(EmailAuthController의 디바운스).
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('올바른 이메일 주소를 입력하세요.'), findsOneWidget);
    expect(find.text('Invalid email address'), findsNothing);
  });

  testWidgets('별칭이 포함된 이메일은 다른 한국어 안내가 뜬다', (tester) async {
    await pump(tester);

    await tester.enterText(emailField(), 'user+alias@example.com');
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('별칭이 포함된 이메일 주소는 사용할 수 없습니다.'), findsOneWidget);
  });
  testWidgets('좁은 화면에서도 로그인과 가입 화면이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('인증 코드와 비밀번호 설정도 한글이며 좁은 화면에 맞는다', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester);
    final controller = tester
        .widget<LoginFormKo>(find.byType(LoginFormKo))
        .controller;
    for (final screen in [
      EmailFlowScreen.verifyRegistration,
      EmailFlowScreen.verifyPasswordReset,
      EmailFlowScreen.completeRegistration,
      EmailFlowScreen.completePasswordReset,
    ]) {
      controller.navigateTo(screen);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: screen.name);
      expect(find.text('Password'), findsNothing);
      expect(find.textContaining('Resend'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
