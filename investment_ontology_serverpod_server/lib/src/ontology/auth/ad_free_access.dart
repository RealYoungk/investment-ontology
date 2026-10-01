import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import 'ontology_access.dart';

/// Ad-removal entitlement, deliberately independent of administrator access.
/// Not a billing ledger: recurring renewal/refund/expiry must be implemented
/// with the chosen payment provider before selling subscriptions.
abstract final class AdFreeAccess {
  static const scope = Scope('alfinder.adFree');

  /// Internal administrative service, not a public RPC or client purchase flag.
  /// Real billing may call this only after trusted payment reconciliation.
  static Future<void> setEnabled(
    Session session,
    UuidValue userId, {
    required bool enabled,
  }) async {
    OntologyAccess.requireAdmin(session);
    final actorId = UuidValue.fromString(session.authenticated!.userIdentifier);
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE serverpod_auth_core_user IN EXCLUSIVE MODE',
        transaction: tx,
      );
      final actor = await const AuthUsers().get(
        session,
        authUserId: actorId,
        transaction: tx,
      );
      if (actor.blocked || !actor.scopes.contains(Scope.admin)) {
        throw NotAuthorizedException(
          reason: AuthenticationFailureReason.insufficientAccess,
        );
      }
      final target = await const AuthUsers().get(
        session,
        authUserId: userId,
        transaction: tx,
      );
      final scopes = {...target.scopes}..remove(scope);
      if (enabled) scopes.add(scope);
      await const AuthUsers().update(
        session,
        authUserId: userId,
        scopes: scopes,
        transaction: tx,
      );
      // Refresh tokens retain their original scope set. Require re-login so
      // a removed entitlement cannot live on indefinitely in token refreshes.
      await AuthServices.instance.tokenManager.revokeAllTokens(
        session,
        authUserId: userId,
        transaction: tx,
      );
    });
    session.log(
      'Ad-free access changed: actor=$actorId target=$userId enabled=$enabled',
    );
  }
}
