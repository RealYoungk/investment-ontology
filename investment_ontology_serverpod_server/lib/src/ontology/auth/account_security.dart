import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Read live status/scopes on every request: old JWTs cannot retain admin access.
abstract final class AccountSecurity {
  static Future<AuthenticationInfo?> authenticate(
    Session session,
    String token,
  ) async {
    final info = await AuthServices.instance.authenticationHandler(
      session,
      token,
    );
    if (info == null) return null;
    try {
      final user = await const AuthUsers().get(
        session,
        authUserId: UuidValue.fromString(info.userIdentifier),
      );
      if (user.blocked) return null;
      return AuthenticationInfo(
        info.userIdentifier,
        user.scopes,
        authId: info.authId,
      );
    } on AuthUserNotFoundException {
      return null;
    }
  }
}
