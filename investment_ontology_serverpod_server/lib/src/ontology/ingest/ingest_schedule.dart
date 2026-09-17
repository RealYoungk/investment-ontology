import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';

/// 수집 FutureCall 예약.
///
/// 생성된 `futureCalls` 디스패처는 이 파일에서만 참조한다. FutureCall이나 Endpoint
/// 파일이 생성 코드를 직접 참조하면, 생성기가 그 파일을 분석하다 실패했을 때 FutureCall
/// 자체를 빼 버려 참조하던 생성 코드가 다시 생기지 않는 순환에 빠진다.
abstract final class IngestSchedule {
  /// 이어받기 예약 식별자. 같은 예약이 쌓이지 않도록 하나만 둔다.
  static const financialsResumeId = 'financial_facts_resume';
  static const marketSnapshotResumeId = 'market_snapshot_resume';

  static Future<void> companyMasterNow(
    Session session,
    int jobId,
    bool force,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .companyMaster
      .run(jobId, force);

  static Future<void> financialsNow(Session session, int jobId) => session
      .serverpod
      .futureCalls
      .callWithDelay(Duration.zero)
      .financialFacts
      .run(jobId);

  static Future<void> financialsForCompanyNow(
    Session session,
    int jobId,
    String corpCode,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .financialFacts
      .runCompany(jobId, corpCode);

  static Future<void> financialsResume(Session session, DateTime at) async {
    await session.serverpod.futureCalls.cancel(financialsResumeId);
    await session.serverpod.futureCalls
        .callAtTime(at, identifier: financialsResumeId)
        .financialFacts
        .resume();
  }

  static Future<void> marketSnapshotNow(Session session, int jobId) => session
      .serverpod
      .futureCalls
      .callWithDelay(Duration.zero)
      .marketSnapshot
      .run(jobId);

  static Future<void> marketSnapshotResume(Session session, DateTime at) async {
    await session.serverpod.futureCalls.cancel(marketSnapshotResumeId);
    await session.serverpod.futureCalls
        .callAtTime(at, identifier: marketSnapshotResumeId)
        .marketSnapshot
        .resume();
  }
}
