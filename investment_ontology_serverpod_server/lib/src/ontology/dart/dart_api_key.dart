import 'package:serverpod/serverpod.dart';

import '../api_secret.dart';

/// DART OpenAPI 인증키.
///
/// 우선순위: `config/passwords.yaml`의 `dartApiKey`
/// (또는 `SERVERPOD_PASSWORD_dartApiKey`) → 환경변수 `DART_API_KEY`.
abstract final class DartApiKey {
  static const secret = ApiSecret(
    passwordName: 'dartApiKey',
    envName: 'DART_API_KEY',
  );
  static const envName = 'DART_API_KEY';

  static String? read(Session session) => secret.read(session);
}
