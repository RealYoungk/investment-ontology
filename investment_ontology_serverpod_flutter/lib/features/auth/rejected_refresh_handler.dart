import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// The SDK latches rejected refresh credentials, but retains the old auth info.
/// Clear that local state so listeners stop polling with the expired access token.
/// Ordinary 401s, permissions, and network failures must not log a user out.
Future<void> handleRejectedRefresh(
  MethodCallContext context,
  Object error, {
  required Future<void> Function() clearLocalSession,
}) async {
  if (context.endpointName != 'jwtRefresh' ||
      context.methodName != 'refreshAccessToken') {
    return;
  }
  if (error is RefreshTokenMalformedException ||
      error is RefreshTokenNotFoundException ||
      error is RefreshTokenExpiredException ||
      error is RefreshTokenInvalidSecretException) {
    await clearLocalSession();
  }
}
