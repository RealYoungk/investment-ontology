import 'package:investment_ontology_serverpod_server/src/ontology/auth/admin_provisioning.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given email verification and JWT lifecycle',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, endpoints) {
      const code = '87654321';
      const password = 'Audit-only-Password42!';
      setUp(() {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey(
                  'test-only-signing-key-not-used-outside-isolated-tests',
                ),
              ),
              refreshTokenHashPepper: 'test-only-refresh-pepper',
            ),
          ],
          identityProviderBuilders: [
            EmailIdpConfig(
              secretHashPepper: 'test-only-email-pepper',
              registrationVerificationCodeGenerator: () => code,
              passwordResetVerificationCodeGenerator: () => code,
              onAfterAccountCreated: AdminProvisioning(['owner@example.com'])
                  .onAccountCreated,
            ),
          ],
        );
      });

      Future<AuthSuccess> register(String email) async {
        final request = await endpoints.emailIdp.startRegistration(
          builder,
          email: email,
        );
        final token = await endpoints.emailIdp.verifyRegistrationCode(
          builder,
          accountRequestId: request,
          verificationCode: code,
        );
        return endpoints.emailIdp.finishRegistration(
          builder,
          registrationToken: token,
          password: password,
        );
      }

      test(
        'wrong and replayed verification codes cannot create accounts',
        () async {
          final request = await endpoints.emailIdp.startRegistration(
            builder,
            email: 'reader@example.com',
          );
          await expectLater(
            endpoints.emailIdp.verifyRegistrationCode(
              builder,
              accountRequestId: request,
              verificationCode: '00000000',
            ),
            throwsA(isA<EmailAccountRequestException>()),
          );
          final token = await endpoints.emailIdp.verifyRegistrationCode(
            builder,
            accountRequestId: request,
            verificationCode: code,
          );
          await expectLater(
            endpoints.emailIdp.verifyRegistrationCode(
              builder,
              accountRequestId: request,
              verificationCode: code,
            ),
            throwsA(isA<EmailAccountRequestException>()),
          );
          final account = await endpoints.emailIdp.finishRegistration(
            builder,
            registrationToken: token,
            password: password,
          );
          expect(account.scopeNames, isEmpty);
          await expectLater(
            endpoints.emailIdp.finishRegistration(
              builder,
              registrationToken: token,
              password: password,
            ),
            throwsA(isA<EmailAccountRequestException>()),
          );
        },
      );

      test('only verified allowlisted owner receives admin on login', () async {
        await register('owner@example.com');
        final owner = await endpoints.emailIdp.login(
          builder,
          email: 'owner@example.com',
          password: password,
        );
        expect(owner.scopeNames, contains(Scope.admin.name));
        final reader = await register('reader-scope@example.com');
        expect(reader.scopeNames, isEmpty);
      });

      test(
        'password reset invalidates old password and refresh tokens',
        () async {
          final old = await register('reader-reset@example.com');
          final request = await endpoints.emailIdp.startPasswordReset(
            builder,
            email: 'reader-reset@example.com',
          );
          final reset = await endpoints.emailIdp.verifyPasswordResetCode(
            builder,
            passwordResetRequestId: request,
            verificationCode: code,
          );
          await endpoints.emailIdp.finishPasswordReset(
            builder,
            finishPasswordResetToken: reset,
            newPassword: 'Replacement-Audit-Password43!',
          );
          await expectLater(
            endpoints.emailIdp.login(
              builder,
              email: 'reader-reset@example.com',
              password: password,
            ),
            throwsA(isA<EmailAccountLoginException>()),
          );
          await expectLater(
            endpoints.jwtRefresh.refreshAccessToken(
              builder,
              refreshToken: old.refreshToken!,
            ),
            throwsA(isA<RefreshTokenNotFoundException>()),
          );
          final current = await endpoints.emailIdp.login(
            builder,
            email: 'reader-reset@example.com',
            password: 'Replacement-Audit-Password43!',
          );
          expect(current.authUserId, old.authUserId);
        },
      );
    },
  );
}
