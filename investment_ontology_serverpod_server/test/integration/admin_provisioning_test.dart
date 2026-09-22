import 'package:investment_ontology_serverpod_server/src/ontology/auth/admin_provisioning.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given explicit administrator allowlist', (builder, _) {
    test(
      'verified matching account gets admin while other accounts do not',
      () async {
        final session = builder.build();
        const users = AuthUsers();
        final admin = await users.create(
          session,
          scopes: {const Scope('existing')},
        );
        final reader = await users.create(session);
        final policy = AdminProvisioning([' Owner@example.com ']);
        await policy.onAccountCreated(
          session,
          email: 'owner@example.com',
          authUserId: admin.id,
          emailAccountId: admin.id,
          transaction: null,
        );
        await policy.onAccountCreated(
          session,
          email: 'outsider@example.com',
          authUserId: reader.id,
          emailAccountId: reader.id,
          transaction: null,
        );
        expect(
          (await users.get(session, authUserId: admin.id)).scopes,
          containsAll([Scope.admin, const Scope('existing')]),
        );
        expect(
          (await users.get(session, authUserId: reader.id)).scopes,
          isEmpty,
        );
      },
    );
    test('empty allowlist never promotes even the first account', () async {
      final session = builder.build();
      const users = AuthUsers();
      final user = await users.create(session);
      await AdminProvisioning([]).onAccountCreated(
        session,
        email: 'owner@example.com',
        authUserId: user.id,
        emailAccountId: user.id,
        transaction: null,
      );
      expect((await users.get(session, authUserId: user.id)).scopes, isEmpty);
    });
  });
}
