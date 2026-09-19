import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import 'disclosure_sync.dart';
import 'financial_facts_sync.dart';
import 'ingest_jobs.dart';
import 'market_snapshot_sync.dart';

/// 수집 FutureCall 예약.
///
/// 생성된 `futureCalls` 디스패처는 이 파일에서만 참조한다. FutureCall이나 Endpoint
/// 파일이 생성 코드를 직접 참조하면, 생성기가 그 파일을 분석하다 실패했을 때 FutureCall
/// 자체를 빼 버려 참조하던 생성 코드가 다시 생기지 않는 순환에 빠진다.
abstract final class IngestSchedule {
  /// 매일 자동 수집 예약 식별자.
  static const marketSnapshotDailyId = 'market_snapshot_daily';
  static const financialsDailyId = 'financial_facts_daily';
  static const disclosuresDailyId = 'disclosures_daily';

  /// 매일 18:00 KST(09:00 UTC) 시세. 전날 시세가 오후에 올라오므로 저녁에 받는다.
  static const marketSnapshotDailyCron = '0 9 * * *';

  /// 매일 18:30 KST(09:30 UTC) 재무. 백필 중이면 하루 예산만큼 이어서, 끝나면 새 공시만 받는다.
  static const financialsDailyCron = '30 9 * * *';

  /// 매일 19:00 KST(10:00 UTC) 정기보고서 주요정보. 재무가 새 공시를 장부에 넣은 뒤에 돈다.
  static const disclosuresDailyCron = '0 10 * * *';

  /// 서버가 켜질 때 부른다.
  ///
  /// 1. 이전 서버와 함께 끊긴 수집 작업을 정리한다. Serverpod가 다시 실행할 작업은 둔다.
  /// 2. 다시 실행되지 않는 재무·시세·주요정보 수집은 바로 이어받기를 예약한다 (기업마스터는 수동).
  /// 3. 매일 자동 수집 예약이 없으면 건다.
  static Future<void> onServerStart(Session session) async {
    final r = await IngestJobs.recoverInterrupted(session);
    final soon = DateTime.now().toUtc().add(const Duration(seconds: 10));
    for (final (kind, resumeId, resume) in [
      (FinancialFactsSync.kind, financialsResumeId, financialsResume),
      (MarketSnapshotSync.kind, marketSnapshotResumeId, marketSnapshotResume),
      (DisclosureSync.kind, disclosuresResumeId, disclosuresResume),
    ]) {
      if (r.orphaned.contains(kind)) {
        await resume(session, soon);
      } else if (r.rerunning.contains(kind)) {
        // Serverpod가 끊긴 작업을 다시 실행하므로 남아 있는 이어받기 예약은 겹친다.
        await sp.FutureCallEntry.db.deleteWhere(
          session,
          where: (t) => t.identifier.equals(resumeId),
        );
      }
    }
    await ensureDaily(session);
  }

  /// 매일 자동 수집 예약이 없으면 건다. 서버가 켜질 때마다 부른다.
  ///
  /// 이미 있으면 그대로 둔다. 서버가 꺼져 있는 동안 지난 예약은 다시 켜질 때 한 번
  /// 실행되고 다음 날로 넘어가므로, 지우고 다시 걸면 그 한 번을 놓친다.
  /// 실행은 `resume`이라 같은 종류의 수집이 돌고 있으면 건너뛴다.
  static Future<void> ensureDaily(Session session) async {
    if (!await _scheduled(session, marketSnapshotDailyId)) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: marketSnapshotDailyId)
          .cron(marketSnapshotDailyCron)
          .marketSnapshot
          .resume();
    }
    if (!await _scheduled(session, financialsDailyId)) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: financialsDailyId)
          .cron(financialsDailyCron)
          .financialFacts
          .resume();
    }
    if (!await _scheduled(session, disclosuresDailyId)) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: disclosuresDailyId)
          .cron(disclosuresDailyCron)
          .disclosure
          .resume();
    }
  }

  static Future<bool> _scheduled(Session session, String identifier) async =>
      await sp.FutureCallEntry.db.count(
        session,
        where: (t) => t.identifier.equals(identifier),
      ) >
      0;

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

  static const disclosuresResumeId = 'disclosures_resume';

  static Future<void> disclosuresNow(Session session, int jobId) => session
      .serverpod
      .futureCalls
      .callWithDelay(Duration.zero)
      .disclosure
      .run(jobId);

  static Future<void> disclosuresForCompanyNow(
    Session session,
    int jobId,
    String corpCode,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .disclosure
      .runCompany(jobId, corpCode);

  static Future<void> disclosuresResume(Session session, DateTime at) async {
    await session.serverpod.futureCalls.cancel(disclosuresResumeId);
    await session.serverpod.futureCalls
        .callAtTime(at, identifier: disclosuresResumeId)
        .disclosure
        .resume();
  }
}
