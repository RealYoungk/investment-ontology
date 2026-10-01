import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../billing/membership_ledger.dart';
import '../auth/auth_mail_delivery.dart';

class AccountEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  UuidValue _id(Session session) =>
      UuidValue.fromString(session.authenticated!.userIdentifier);

  Future<AccountView> _view(Session session, AuthUserModel user) async {
    final email = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(user.id),
    );
    return AccountView(
      userId: user.id.toString(),
      email: email?.email ?? '',
      createdAt: user.createdAt,
      isAdmin: user.scopes.contains(Scope.admin),
      blocked: user.blocked,
    );
  }

  Future<bool> mailConfigured(Session session) async {
    OntologyAccess.requireAdmin(session);
    return AuthMailDelivery.configured(session);
  }

  Future<AccountView> me(Session session) async => _view(
    session,
    await const AuthUsers().get(session, authUserId: _id(session)),
  );

  Future<List<AccountView>> list(Session session, {int offset = 0}) async {
    OntologyAccess.requireAdmin(session);
    if (offset < 0) throw ArgumentError('Invalid offset');
    final rows = await AuthUser.db.find(
      session,
      orderBy: (t) => t.createdAt,
      limit: 50,
      offset: offset,
    );
    return [
      for (final row in rows)
        await _view(
          session,
          await const AuthUsers().get(session, authUserId: row.id!),
        ),
    ];
  }

  Future<void> updateAccess(
    Session session,
    String userId, {
    required bool isAdmin,
    required bool blocked,
  }) async {
    OntologyAccess.requireAdmin(session);
    final id = UuidValue.fromString(userId);
    if (id == _id(session)) throw StateError('자신의 권한이나 이용 상태는 변경할 수 없습니다.');
    await session.db.transaction((tx) async {
      // Serialize role edits, including concurrent demotions by two administrators.
      await session.db.unsafeQuery(
        'LOCK TABLE serverpod_auth_core_user IN EXCLUSIVE MODE',
        transaction: tx,
      );
      final actor = await const AuthUsers().get(
        session,
        authUserId: _id(session),
        transaction: tx,
      );
      if (actor.blocked || !actor.scopes.contains(Scope.admin)) {
        throw StateError('관리자 권한이 필요합니다.');
      }
      final target = await const AuthUsers().get(
        session,
        authUserId: id,
        transaction: tx,
      );
      final scopes = {...target.scopes}..remove(Scope.admin);
      if (isAdmin) scopes.add(Scope.admin);
      await const AuthUsers().update(
        session,
        authUserId: id,
        scopes: scopes,
        blocked: blocked,
        transaction: tx,
      );
      await AuthServices.instance.tokenManager.revokeAllTokens(
        session,
        authUserId: id,
        transaction: tx,
      );
    });
    session.log(
      'Account access changed: actor=${_id(session)} target=$id admin=$isAdmin blocked=$blocked',
    );
  }

  Future<void> revokeSessions(Session session, {String? userId}) async {
    final id = userId == null ? _id(session) : UuidValue.fromString(userId);
    if (id != _id(session)) OntologyAccess.requireAdmin(session);
    await AuthServices.instance.tokenManager.revokeAllTokens(
      session,
      authUserId: id,
    );
    session.log('Account sessions revoked: actor=${_id(session)} target=$id');
  }

  Future<void> deleteMe(Session session, String password) async {
    final user = await me(session);
    // Administrator deletion requires first transferring responsibilities.
    if (user.isAdmin) throw StateError('관리자 계정은 권한을 이전한 뒤 탈퇴할 수 있습니다.');
    final provider = AuthServices.getIdentityProvider<EmailIdp>();
    final verifiedId = await provider.utils.authentication.authenticate(
      session,
      email: user.email,
      password: password,
      transaction: null,
    );
    if (verifiedId != _id(session)) throw StateError('계정을 확인할 수 없습니다.');
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE serverpod_auth_core_user IN EXCLUSIVE MODE',
        transaction: tx,
      );
      final current = await const AuthUsers().get(
        session,
        authUserId: verifiedId,
        transaction: tx,
      );
      if (current.blocked || current.scopes.contains(Scope.admin)) {
        throw StateError('현재 계정 상태에서는 탈퇴할 수 없습니다.');
      }
      await MembershipLedger.beforeDelete(session, verifiedId, tx);
      await const AuthUsers().delete(
        session,
        authUserId: verifiedId,
        transaction: tx,
      );
    });
    session.log('Account deleted by owner: $verifiedId');
  }
}
