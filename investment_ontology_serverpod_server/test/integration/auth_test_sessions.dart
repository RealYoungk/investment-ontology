import 'package:serverpod/serverpod.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 온톨로지 엔드포인트는 로그인이 필요하다 (쓰기는 관리자). 권한 검사는 끄지 않고,
/// 테스트가 실제 로그인한 사람의 세션으로 부른다.
///
/// 같은 `withServerpod`의 빌더에서 나온 것이라 트랜잭션·롤백을 함께 쓴다.
extension OntologyTestAuth on TestSessionBuilder {
  /// 관리자 스코프가 없는 로그인 사용자 (읽기만).
  TestSessionBuilder get asReader => copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      '00000000-0000-4000-8000-000000000001',
      {},
    ),
  );

  /// [Scope.admin]이 있는 로그인 사용자.
  TestSessionBuilder get asAdmin => copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      '00000000-0000-4000-8000-000000000002',
      {Scope.admin},
    ),
  );

  /// 로그인하지 않은 호출.
  TestSessionBuilder get asAnonymous =>
      copyWith(authentication: AuthenticationOverride.unauthenticated());
}
