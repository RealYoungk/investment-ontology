import 'package:investment_ontology_serverpod_server/src/ontology/auth/account_security.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Account management boundaries',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, endpoints) {
      setUp(() {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('isolated-test-account-signing-key-not-production'),
              ),
              refreshTokenHashPepper: 'isolated-test-pepper',
            ),
          ],
          identityProviderBuilders: [
            EmailIdpConfig(
              secretHashPepper: 'isolated-email-pepper',
              registrationVerificationCodeGenerator: () => '87654321',
            ),
          ],
        );
      });
      TestSessionBuilder signed(UuidValue id, Set<Scope> scopes) =>
          builder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              id.toString(),
              scopes,
            ),
          );

      test(
        'reader deletion requires password and invalidates access token',
        () async {
          const password = 'Isolated-test-Password42!';
          final request = await endpoints.emailIdp.startRegistration(
            builder,
            email: 'delete-reader@example.com',
          );
          final registration = await endpoints.emailIdp.verifyRegistrationCode(
            builder,
            accountRequestId: request,
            verificationCode: '87654321',
          );
          final result = await endpoints.emailIdp.finishRegistration(
            builder,
            registrationToken: registration,
            password: password,
          );
          final id = result.authUserId;
          final auth = signed(id, {});
          await expectLater(
            endpoints.account.deleteMe(auth, 'incorrect-password'),
            throwsA(isA<EmailAuthenticationInvalidCredentialsException>()),
          );
          expect((await endpoints.account.me(auth)).userId, id.toString());
          await endpoints.account.deleteMe(auth, password);
          expect(
            await AccountSecurity.authenticate(builder.build(), result.token),
            isNull,
          );
        },
      );

      test(
        'reader can see own account but cannot list or modify members',
        () async {
          final session = builder.build();
          final reader = await const AuthUsers().create(session);
          final auth = signed(reader.id, {});
          expect(
            (await endpoints.account.me(auth)).userId,
            reader.id.toString(),
          );
          await expectLater(
            endpoints.account.list(auth, offset: 0),
            throwsA(isA<ServerpodInsufficientAccessException>()),
          );
          await expectLater(
            endpoints.account.updateAccess(
              auth,
              reader.id.toString(),
              isAdmin: true,
              blocked: false,
            ),
            throwsA(isA<ServerpodInsufficientAccessException>()),
          );
          await expectLater(
            endpoints.account.mailConfigured(auth),
            throwsA(isA<ServerpodInsufficientAccessException>()),
          );
        },
      );

      test('admin can block readers but cannot change own access', () async {
        final session = builder.build();
        final admin = await const AuthUsers().create(
          session,
          scopes: {Scope.admin},
        );
        final reader = await const AuthUsers().create(session);
        final auth = signed(admin.id, {Scope.admin});
        await expectLater(
          endpoints.account.updateAccess(
            auth,
            admin.id.toString(),
            isAdmin: false,
            blocked: true,
          ),
          throwsStateError,
        );
        await endpoints.account.updateAccess(
          auth,
          reader.id.toString(),
          isAdmin: false,
          blocked: true,
        );
        expect(
          (await const AuthUsers().get(session, authUserId: reader.id)).blocked,
          isTrue,
        );
        await endpoints.account.updateAccess(
          auth,
          reader.id.toString(),
          isAdmin: false,
          blocked: false,
        );
        expect(
          (await const AuthUsers().get(session, authUserId: reader.id)).blocked,
          isFalse,
        );
      });

      test(
        'live handler rejects blocked users and drops stale admin scopes',
        () async {
          final session = builder.build();
          final user = await const AuthUsers().create(
            session,
            scopes: {Scope.admin},
          );
          final token = await AuthServices.instance.tokenManager.createToken(
            session,
            authUserId: user.id,
            method: 'email',
          );
          await const AuthUsers().update(
            session,
            authUserId: user.id,
            scopes: {},
          );
          final current = await AccountSecurity.authenticate(
            session,
            token.token,
          );
          expect(current?.scopes.contains(Scope.admin), isFalse);
          await const AuthUsers().update(
            session,
            authUserId: user.id,
            blocked: true,
          );
          expect(
            await AccountSecurity.authenticate(session, token.token),
            isNull,
          );
        },
      );

      test('reader cannot revoke another member sessions and admin cannot self-delete', () async {
        final session = builder.build();
        final reader = await const AuthUsers().create(session);
        final admin = await const AuthUsers().create(
          session,
          scopes: {Scope.admin},
        );
        await expectLater(
          endpoints.account.revokeSessions(
            signed(reader.id, {}),
            userId: admin.id.toString(),
          ),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.account.deleteMe(
            signed(admin.id, {Scope.admin}),
            'not-used',
          ),
          throwsStateError,
        );
      });
    },
  );
}
