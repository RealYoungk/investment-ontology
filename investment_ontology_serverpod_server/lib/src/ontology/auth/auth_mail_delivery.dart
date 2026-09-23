import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Transactional authentication mail. Never prints codes, keys, recipient or body.
class AuthMailDelivery {
  // Public injection point keeps transport tests independent of real email.
  // ignore: prefer_initializing_formals
  AuthMailDelivery({http.Client? client}) : _client = client;
  final http.Client? _client;

  static String? setting(Session session, String key, String env) =>
      Platform.environment[env] ?? session.passwords[key];

  static bool configured(Session session) =>
      (setting(
            session,
            'authMailApiKey',
            'ALFINDER_MAIL_API_KEY',
          )?.isNotEmpty ??
          false) &&
      (setting(session, 'authMailFrom', 'ALFINDER_MAIL_FROM')?.isNotEmpty ??
          false);

  Future<void> send(
    Session session, {
    required String email,
    required String code,
    required String requestId,
    required bool reset,
  }) async {
    final key = setting(session, 'authMailApiKey', 'ALFINDER_MAIL_API_KEY');
    final from = setting(session, 'authMailFrom', 'ALFINDER_MAIL_FROM');
    if (!configured(session)) {
      throw StateError('인증 메일 발송 설정이 필요합니다. 운영자에게 문의해 주세요.');
    }
    final purpose = reset ? '비밀번호 재설정' : '회원가입';
    final safeCode = const HtmlEscape().convert(code);
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.https('api.resend.com', '/emails'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              // Retrying a callback must not duplicate the same verification email.
              'Idempotency-Key':
                  'alfinder-${reset ? 'reset' : 'signup'}-$requestId',
            },
            body: jsonEncode({
              'from': from,
              'to': [email],
              'subject': '[알파인더] $purpose 인증번호',
              'text':
                  '알파인더 $purpose 인증번호: $code\n15분 안에 입력해 주세요.\n요청하지 않았다면 이 메일을 무시하셔도 됩니다. 인증번호는 다른 사람에게 알려주지 마세요.',
              'html':
                  '<div style="font-family:system-ui,sans-serif;color:#202831;max-width:480px;margin:40px auto;padding:24px"><h2>알파인더</h2><p>$purpose 인증번호입니다.</p><p style="font-size:32px;letter-spacing:6px;font-weight:700">$safeCode</p><p>15분 안에 입력해 주세요.</p><p style="color:#607080;font-size:13px">요청하지 않았다면 이 메일을 무시하셔도 됩니다.<br>인증번호는 다른 사람에게 알려주지 마세요.</p></div>',
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        session.log(
          'Authentication email provider rejected request (${response.statusCode})',
          level: LogLevel.warning,
        );
        throw StateError('인증 메일을 보내지 못했습니다. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (_client == null) client.close();
    }
  }
}
