import 'package:serverpod/serverpod.dart';

/// Scheduling indirection keeps generated dispatch out of endpoints/FutureCalls.
abstract final class CharterHooks {
  static Future<void> Function(Session session, int jobId, DateTime at)?
  continueAt;
  static Future<void> schedule(Session session, int jobId, DateTime at) =>
      (continueAt ?? (throw StateError('정관 수집 예약이 아직 등록되지 않았습니다.')))(
        session,
        jobId,
        at,
      );
}
