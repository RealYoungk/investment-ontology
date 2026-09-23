import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// 이메일 로그인 흐름의 한국어 문구.
///
/// [EmailSignInTexts]/[PasswordRequirementTexts]는 패키지가 실제로 `context`에서
/// 읽는 화면(가입·재설정 등, 그대로 재사용하는 패키지 폼들과 비밀번호 조건 목록)에
/// [SignInLocalizationProvider]로 꽂아 넣는다. 로그인 화면과 인증 코드 화면은 같은
/// 값을 직접 읽어 새로 그린다(각각 [LoginFormKo]/[VerificationFormKo] 참고) — 패키지의
/// `LoginForm`은 비밀번호 칸 라벨을, `VerificationForm`은 재전송 버튼 문구를 지역화하지
/// 않기 때문이다.
const koreanEmailSignInTexts = EmailSignInTexts(
  title: '이메일로 로그인',
  forgotPassword: '비밀번호를 잊으셨나요?',
  signIn: '로그인',
  dontHaveAnAccount: '계정이 없으신가요?',
  signUp: '가입하기',
  signUpTitle: '이메일로 가입',
  continueAction: '계속',
  alreadyHaveAnAccount: '이미 계정이 있으신가요?',
  verifyAccountTitle: '계정 인증',
  verifyResetCodeTitle: '재설정 코드 인증',
  verificationMessage:
      '인증 코드를 확인한 뒤 아래에 입력하세요. 로컬 개발 서버를 사용 중이면 서버 실행 콘솔에서 확인할 수 있습니다.',
  verify: '인증',
  setAccountPasswordTitle: '계정 비밀번호 설정',
  passwordLabel: '비밀번호',
  backToSignUp: '가입 화면으로 돌아가기',
  setNewPasswordTitle: '새 비밀번호 설정',
  newPasswordLabel: '새 비밀번호',
  resetPasswordTitle: '비밀번호 재설정',
  resetPasswordDescription: '비밀번호를 재설정할 이메일 주소를 입력하세요.',
  requestPasswordReset: '재설정 메일 보내기',
  resetPassword: '비밀번호 재설정',
  backToSignIn: '로그인 화면으로 돌아가기',
  emailLabel: '이메일',
  // 이 앱은 약관/개인정보처리방침 콜백을 연결하지 않으므로(StartRegistrationForm의
  // hasTermsAndConditions가 항상 false) 아래 네 값은 실제로 쓰이지 않는다.
  termsIntro: '아래 ',
  termsAndConditions: '이용약관',
  andText: '과 ',
  privacyPolicy: '개인정보처리방침',
);

const koreanPasswordRequirementTexts = PasswordRequirementTexts(
  minLengthTemplate: '최소 {length}자 이상',
  maxLengthTemplate: '최대 {length}자 이하',
  containsLowercase: '소문자를 하나 이상 포함',
  containsUppercase: '대문자를 하나 이상 포함',
  containsNumber: '숫자를 하나 이상 포함',
  containsSpecialCharacter: '특수문자를 하나 이상 포함',
);

/// 새 계정은 읽기 전용이라는 안내. 가입 단계(시작·인증·비밀번호 설정)에서만 보여준다.
const readOnlyAccountNotice = '새 계정은 읽기 전용입니다. 관리자 권한이 필요하면 운영자에게 요청하세요.';

const _genericAuthError = '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도하세요.';

/// [EmailAuthController.validateEmail]의 규칙은 그대로 신뢰하고, 사람에게 보여줄
/// 문구만 한국어로 바꾼다 — 검증 로직 자체를 다시 구현하지 않는다.
void koreanEmailValidation(String email) {
  try {
    EmailAuthController.validateEmail(email);
  } on InvalidEmailException catch (e) {
    throw InvalidEmailException(
      e.reason == 'Email aliases are not allowed'
          ? '별칭이 포함된 이메일 주소는 사용할 수 없습니다.'
          : '올바른 이메일 주소를 입력하세요.',
    );
  }
}

/// [EmailAuthController]는 서버 예외를 자신의 `UserFacingException`(패키지 src/ 전용이라
/// 이 앱에서는 타입으로 가져올 수 없다)으로 감싼 뒤 `onError`로 넘긴다. 감싸고 있는 원래
/// 예외는 `originalException`이라는 공개 게터로만 꺼낼 수 있어 동적으로 접근한다 — 이후는
/// 공개 타입(EmailAccountLoginException 등)으로 정확히 구분해 한국어로 옮긴다. 게터가
/// 없거나(우리가 직접 던진 예외 등) 알 수 없는 타입이면 일반 안내 문구로 대신한다. 영어
/// 원문이나 예외 객체를 그대로 보여주는 일은 없다.
Object _unwrap(Object error) {
  try {
    final dynamic wrapped = error;
    final Object? original = wrapped.originalException;
    if (original != null) return original;
  } catch (_) {
    // originalException 게터가 없는 예외 — 그대로 쓴다.
  }
  return error;
}

String koreanAuthErrorMessage(Object error) {
  return switch (_unwrap(error)) {
    InvalidEmailException(:final reason) => reason,
    EmailAccountLoginException(:final reason) => switch (reason) {
      EmailAccountLoginExceptionReason.invalidCredentials =>
        '이메일 또는 비밀번호가 올바르지 않습니다.',
      EmailAccountLoginExceptionReason.tooManyAttempts =>
        '로그인 시도가 너무 많습니다. 잠시 후 다시 시도하세요.',
      EmailAccountLoginExceptionReason.unknown => '로그인 중 오류가 발생했습니다. 다시 시도하세요.',
    },
    EmailAccountRequestException(:final reason) => switch (reason) {
      EmailAccountRequestExceptionReason.tooManyAttempts =>
        '가입 시도가 너무 많습니다. 잠시 후 다시 시도하세요.',
      EmailAccountRequestExceptionReason.expired =>
        '인증 코드가 만료되었습니다. 새 코드를 요청하세요.',
      EmailAccountRequestExceptionReason.invalid =>
        '인증 코드가 올바르지 않습니다. 다시 확인하세요.',
      EmailAccountRequestExceptionReason.policyViolation =>
        '비밀번호가 요구 조건을 만족하지 않습니다. 다른 비밀번호를 선택하세요.',
      EmailAccountRequestExceptionReason.unknown =>
        '가입 처리 중 오류가 발생했습니다. 잠시 후 다시 시도하세요. 문제가 계속되면 운영자에게 문의하세요.',
    },
    EmailAccountPasswordResetException(:final reason) => switch (reason) {
      EmailAccountPasswordResetExceptionReason.tooManyAttempts =>
        '재설정 시도가 너무 많습니다. 잠시 후 다시 시도하세요.',
      EmailAccountPasswordResetExceptionReason.expired =>
        '재설정 코드가 만료되었습니다. 새 코드를 요청하세요.',
      EmailAccountPasswordResetExceptionReason.invalid =>
        '재설정 코드가 올바르지 않습니다. 다시 확인하세요.',
      EmailAccountPasswordResetExceptionReason.policyViolation =>
        '비밀번호가 요구 조건을 만족하지 않습니다. 다른 비밀번호를 선택하세요.',
      EmailAccountPasswordResetExceptionReason.unknown =>
        '비밀번호 재설정 중 오류가 발생했습니다. 잠시 후 다시 시도하세요. 문제가 계속되면 운영자에게 문의하세요.',
    },
    ServerpodClientNetworkException() =>
      '서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도하세요.',
    ServerpodClientException() =>
      '요청을 처리하지 못했습니다. 잠시 후 다시 시도하세요. 문제가 계속되면 운영자에게 문의하세요.',
    _ => _genericAuthError,
  };
}
