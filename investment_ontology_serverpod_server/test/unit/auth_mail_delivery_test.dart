import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/auth/auth_mail_delivery.dart';
import 'package:test/test.dart';

class MailSession implements Session {
  MailSession(this.passwords);
  @override
  final Map<String, String> passwords;
  final List<String> capturedLogs = [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void log(
    String message, {
    LogLevel? level,
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, Object?>? metadata,
  }) {
    capturedLogs.add(message);
  }
}

void main() {
  test('registration and reset send to configured provider without logging secrets', () async {
    final session = MailSession({
      'authMailApiKey': 'test-only-key',
      'authMailFrom': 'Alfinder <noreply@example.com>',
    });
    final requests = <http.Request>[];
    final delivery = AuthMailDelivery(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{"id":"test-message"}', 200);
      }),
    );
    for (final reset in [false, true]) {
      await delivery.send(
        session,
        email: 'reader@example.com',
        code: '12345678',
        requestId: 'test-${reset.toString()}',
        reset: reset,
      );
    }
    expect(requests, hasLength(2));
    expect(requests.first.url.host, 'api.resend.com');
    final body = jsonDecode(requests.first.body) as Map;
    expect(body['to'], ['reader@example.com']);
    expect(body['subject'], contains('회원가입'));
    expect(jsonDecode(requests.last.body)['subject'], contains('비밀번호 재설정'));
    expect(session.capturedLogs.join(), isNot(contains('12345678')));
  });
  test('missing configuration fails without console-code fallback or network request', () async {
    var called = false;
    final delivery = AuthMailDelivery(
      client: MockClient((_) async {
        called = true;
        return http.Response('', 200);
      }),
    );
    await expectLater(
      delivery.send(
        MailSession({}),
        email: 'reader@example.com',
        code: 'secret-code',
        requestId: 'id',
        reset: false,
      ),
      throwsStateError,
    );
    expect(called, isFalse);
  });
  test(
    'provider rejection never exposes response body or verification code',
    () async {
      final session = MailSession({
        'authMailApiKey': 'test-only-key',
        'authMailFrom': 'noreply@example.com',
      });
      final delivery = AuthMailDelivery(
        client: MockClient(
          (_) async => http.Response('private-body secret-code', 403),
        ),
      );
      await expectLater(
        delivery.send(
          session,
          email: 'reader@example.com',
          code: 'secret-code',
          requestId: 'id',
          reset: true,
        ),
        throwsStateError,
      );
      expect(session.capturedLogs.join(), isNot(contains('secret-code')));
      expect(session.capturedLogs.join(), isNot(contains('private-body')));
    },
  );
}
