import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Only server-configured, verified email accounts can receive administrator scope.
/// Never derive the allowlist from a client request or grant the first signup.
class AdminProvisioning {
  AdminProvisioning(Iterable<String> emails)
    : emails = emails
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

  factory AdminProvisioning.fromEnvironment() {
    final configured = Platform.environment['ONTOLOGY_ADMIN_EMAILS'];
    final local = File('config/admin_emails.local');
    return AdminProvisioning(
      (configured ?? (local.existsSync() ? local.readAsStringSync() : ''))
          .split(RegExp(r'[,\s]+')),
    );
  }

  final Set<String> emails;

  /// The IDP invokes this only after verification and account creation.
  Future<void> onAccountCreated(
    Session session, {
    required String email,
    required UuidValue authUserId,
    required UuidValue emailAccountId,
    required Transaction? transaction,
  }) async {
    if (!emails.contains(email.trim().toLowerCase())) return;
    const users = AuthUsers();
    final user = await users.get(
      session,
      authUserId: authUserId,
      transaction: transaction,
    );
    await users.update(
      session,
      authUserId: authUserId,
      scopes: {...user.scopes, Scope.admin},
      transaction: transaction,
    );
  }

  EmailIdpConfig configuration() {
    final delivery = ServerpodCloudEmailIdpConfig(appDisplayName: '투자 온톨로지');
    return EmailIdpConfigFromPasswords(
      sendRegistrationVerificationCode:
          delivery.sendRegistrationVerificationCode,
      sendPasswordResetVerificationCode:
          delivery.sendPasswordResetVerificationCode,
      onAfterAccountCreated: onAccountCreated,
    );
  }
}
