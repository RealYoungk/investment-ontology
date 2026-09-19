import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// 외부 API 인증키 읽기.
///
/// 우선순위: `config/passwords.yaml`의 `shared:` 아래 [passwordName]
/// (또는 `SERVERPOD_PASSWORD_<passwordName>`) → 환경변수 [envName].
class ApiSecret {
  const ApiSecret({required this.passwordName, required this.envName});

  final String passwordName;
  final String envName;

  String? read(Session session) {
    for (final value in [
      session.passwords[passwordName],
      Platform.environment[envName],
    ]) {
      final key = value?.trim();
      if (key != null && key.isNotEmpty) return key;
    }
    return null;
  }

  /// 키가 없을 때 사용자에게 보여줄 안내.
  String missingMessage(String label) =>
      '$label 키가 없습니다. 환경변수 $envName를 설정하거나 '
      'config/passwords.yaml의 shared: 아래에 $passwordName를 추가하고 '
      '서버를 재시작하세요.';
}
