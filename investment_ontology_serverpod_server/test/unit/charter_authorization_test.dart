import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/charter_endpoint.dart';

/// Database/API access fails: denial must happen before either side effect.
class _DeniedSession implements Session {
  _DeniedSession(this.authenticated);
  @override
  final AuthenticationInfo? authenticated;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected access before authorization');
}

void main() {
  for (final role in ['anonymous', 'reader']) {
    final session = _DeniedSession(
      role == 'anonymous'
          ? null
          : AuthenticationInfo('reader', {}, authId: 'test-reader'),
    );
    test('$role cannot start all-company charter collection', () async {
      await expectLater(
        CharterEndpoint().startCollection(session),
        throwsA(isA<NotAuthorizedException>()),
      );
    });
    test('$role cannot advance charter collection', () async {
      await expectLater(
        CharterEndpoint().advanceCollection(session),
        throwsA(isA<NotAuthorizedException>()),
      );
    });
  }
}
