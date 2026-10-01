import 'package:investment_ontology_serverpod_server/src/ontology/auth/ad_free_access.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Ad removal entitlement', (builder, endpoints) {
    setUp(() {
      AuthServices.set(
        tokenManagerBuilders: [
          JwtConfig(
            algorithm: JwtAlgorithm.hmacSha512(
              SecretKey('isolated-ad-free-test-signing-key'),
            ),
            refreshTokenHashPepper: 'isolated-ad-free-test-pepper',
          ),
        ],
        identityProviderBuilders: [],
      );
    });
    TestSessionBuilder signed(UuidValue id, Set<Scope> scopes) =>
        builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            id.toString(),
            scopes,
          ),
        );
    test('anonymous and ordinary accounts cannot grant entitlement', () async {
      final session = builder.build();
      final user = await const AuthUsers().create(session);
      await expectLater(
        AdFreeAccess.setEnabled(session, user.id, enabled: true),
        throwsA(isA<NotAuthorizedException>()),
      );
      await expectLater(
        AdFreeAccess.setEnabled(
          signed(user.id, {}).build(),
          user.id,
          enabled: true,
        ),
        throwsA(isA<NotAuthorizedException>()),
      );
    });
    test('stale admin scope is rejected against current DB role', () async {
      final session = builder.build();
      final user = await const AuthUsers().create(session);
      await expectLater(
        AdFreeAccess.setEnabled(
          signed(user.id, {Scope.admin}).build(),
          user.id,
          enabled: true,
        ),
        throwsA(isA<NotAuthorizedException>()),
      );
    });
    test(
      'grant and revoke preserve unrelated scopes and never grant admin',
      () async {
        final session = builder.build();
        final admin = await const AuthUsers().create(
          session,
          scopes: {Scope.admin},
        );
        final reader = await const AuthUsers().create(
          session,
          scopes: {const Scope('other')},
        );
        final actor = signed(admin.id, {Scope.admin}).build();
        await AdFreeAccess.setEnabled(actor, reader.id, enabled: true);
        await AdFreeAccess.setEnabled(actor, reader.id, enabled: true);
        expect(
          (await const AuthUsers().get(session, authUserId: reader.id)).scopes,
          {const Scope('other'), AdFreeAccess.scope},
        );
        await AdFreeAccess.setEnabled(actor, reader.id, enabled: false);
        expect(
          (await const AuthUsers().get(session, authUserId: reader.id)).scopes,
          {const Scope('other')},
        );
      },
    );
  });
}
