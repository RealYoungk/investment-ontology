import 'package:serverpod/serverpod.dart';

/// 온톨로지 엔드포인트의 권한 규칙.
///
/// - 공용 기업 데이터는 비로그인도 조회한다. 계정 정보는 본인만 조회한다.
/// - 수집·AI 운영은 엔드포인트 전체를 관리자 스코프로 보호한다.
/// - 공개 검수 결과는 승인된 관계와 익명화한 정확도만 제공한다.
/// - 데이터를 바꾸는 메서드는 [Scope.admin]이 있어야 한다. 읽기와 쓰기가 섞인
///   엔드포인트는 엔드포인트 전체가 아니라 쓰기 메서드 첫 줄에서 [requireAdmin]을 부른다.
///
/// 관리자 권한은 가입만으로 생기지 않는다. 서버 쪽 허용 목록에서 준다.
abstract final class OntologyAccess {
  /// 관리자 권한이 없으면 Serverpod의 [NotAuthorizedException]을 던진다.
  ///
  /// 엔드포인트 디스패치가 던지는 것과 같은 예외라 HTTP로는 401/403이 되고,
  /// 생성된 테스트 도구에서는 `ServerpodUnauthenticatedException` /
  /// `ServerpodInsufficientAccessException`으로 보인다.
  static void requireAdmin(Session session) {
    final auth = session.authenticated;
    if (auth == null) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
    if (!isAdmin(auth)) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.insufficientAccess,
        message: '관리자 권한이 필요합니다.',
      );
    }
  }

  /// 인증 정보에 관리자 스코프가 있는가.
  static bool isAdmin(AuthenticationInfo? auth) =>
      auth?.scopes.contains(Scope.admin) ?? false;
}
