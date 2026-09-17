import 'package:serverpod/serverpod.dart';

import '../api_secret.dart';

/// 공공데이터포털 서비스키 (금융위원회_주식시세정보, 금융위원회_KRX상장종목정보).
///
/// 우선순위: `config/passwords.yaml`의 `dataGoKrServiceKey`
/// (또는 `SERVERPOD_PASSWORD_dataGoKrServiceKey`) → 환경변수 `DATA_GO_KR_SERVICE_KEY`.
/// 포털의 Decoding 키를 넣는다. Encoding 키를 넣어도 풀어서 쓴다.
abstract final class DataGoKrServiceKey {
  static const secret = ApiSecret(
    passwordName: 'dataGoKrServiceKey',
    envName: 'DATA_GO_KR_SERVICE_KEY',
  );

  static String? read(Session session) {
    final key = secret.read(session);
    if (key == null || !key.contains('%')) return key;
    try {
      return Uri.decodeComponent(key);
    } on ArgumentError {
      return key;
    }
  }
}
