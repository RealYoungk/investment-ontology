import '../business/business_profiles.dart';

import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../../generated/protocol.dart' show IngestStatus;
import 'disclosure_sync.dart';
import 'company_master_sync.dart';
import 'financial_facts_sync.dart';
import 'ingest_jobs.dart';
import 'market_snapshot_sync.dart';
import 'ingest_hooks.dart';
import '../peers/peer_catalog.dart';

/// 수집 FutureCall 예약.
///
/// 엔드포인트·FutureCall 파일은 이 파일을 가져오지 않는다 ([IngestHooks] 참고).
///
/// 생성된 `futureCalls` 디스패처는 이 파일에서만 참조한다. FutureCall이나 Endpoint
/// 파일이 생성 코드를 직접 참조하면, 생성기가 그 파일을 분석하다 실패했을 때 FutureCall
/// 자체를 빼 버려 참조하던 생성 코드가 다시 생기지 않는 순환에 빠진다.
abstract final class IngestSchedule {
  /// 매일 자동 수집 예약 식별자.
  static const companyMasterDailyId = 'company_master_daily';
  static const companyMasterResumeId = 'company_master_resume';

  /// 매일 08:30 KST에 신규·변경 기업을 등록한다.
  static const companyMasterDailyCron = '30 23 * * *';

  static const marketSnapshotDailyId = 'market_snapshot_daily';
  static const financialsDailyId = 'financial_facts_daily';
  static const disclosuresDailyId = 'disclosures_daily';
  static const businessDocumentsDailyId = 'business_documents_daily';
  static const businessDocumentsResumeId = 'business_documents_resume';

  /// 매일 18:00 KST(09:00 UTC) 시세. 전날 시세가 오후에 올라오므로 저녁에 받는다.
  static const marketSnapshotDailyCron = '0 9 * * *';

  /// 매일 18:30 KST(09:30 UTC) 재무. 백필 중이면 하루 예산만큼 이어서, 끝나면 새 공시만 받는다.
  static const financialsDailyCron = '30 9 * * *';

  /// 매일 19:00 KST(10:00 UTC) 정기보고서 주요정보. 재무가 새 공시를 장부에 넣은 뒤에 돈다.
  static const disclosuresDailyCron = '0 10 * * *';

  /// 서버가 켜질 때 부른다.
  ///
  /// 1. 이전 서버와 함께 끊긴 수집 작업을 정리한다. Serverpod가 다시 실행할 작업은 둔다.
  /// 2. 다시 실행되지 않는 재무·시세·주요정보 수집은 바로 이어받기를 예약한다 (기업 마스터는 다음 일일 예약에서 갱신).
  /// 3. 매일 자동 수집 예약이 없으면 건다.
  static Future<void> onServerStart(Session session) async {
    installHooks();
    final r = await IngestJobs.recoverInterrupted(session);
    final soon = DateTime.now().toUtc().add(const Duration(seconds: 10));
    for (final (kind, resumeId, resume) in [
      (CompanyMasterSync.kind, companyMasterResumeId, companyMasterResume),
      (FinancialFactsSync.kind, financialsResumeId, financialsResume),
      (MarketSnapshotSync.kind, marketSnapshotResumeId, marketSnapshotResume),
      (
        DisclosureSync.businessKind,
        businessDocumentsResumeId,
        businessDocumentsResume,
      ),
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
      } else if (!await _scheduled(session, resumeId)) {
        final latest = await IngestJobs.latest(session, kind);
        // 이전 버전이 성공으로 기록한 부분 실패도 재시도한다.
        // 취소된 작업과 이미 예약된 예산 대기는 그대로 둔다.
        if (latest != null &&
            (latest.status == IngestStatus.failed ||
                (latest.status == IngestStatus.succeeded &&
                    latest.failed > 0))) {
          await resume(session, soon);
        }
      }
    }
    await ensureDaily(session);
    await PeerProfiles.backfill(session);
    await BusinessProfiles.backfill(session);
  }

  /// 매일 자동 수집 예약이 없으면 건다. 서버가 켜질 때마다 부른다.
  ///
  /// 이미 있으면 그대로 둔다. 서버가 꺼져 있는 동안 지난 예약은 다시 켜질 때 한 번
  /// 실행되고 다음 날로 넘어가므로, 지우고 다시 걸면 그 한 번을 놓친다.
  /// 실행은 `resume`이라 같은 종류의 수집이 돌고 있으면 건너뛴다.
  static Future<void> ensureDaily(Session session) async {
    if (!await _scheduled(session, 'watchlist_scan')) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: 'watchlist_scan')
          .cron('*/10 * * * *')
          .watchlist
          .run();
    }
    if (!await _scheduled(session, 'watchlist_delivery')) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: 'watchlist_delivery')
          .cron('* * * * *')
          .watchlist
          .deliver();
    }
    if (!await _scheduled(session, companyMasterDailyId)) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: companyMasterDailyId)
          .cron(companyMasterDailyCron)
          .companyMaster
          .resume();
    }
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
    if (!await _scheduled(session, businessDocumentsDailyId)) {
      await session.serverpod.futureCalls
          .callRecurring(identifier: businessDocumentsDailyId)
          .cron('45 9 * * *')
          .disclosure
          .resumeBusiness();
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

  static Future<void> companyMasterResume(Session session, DateTime at) async {
    await session.serverpod.futureCalls.cancel(companyMasterResumeId);
    await session.serverpod.futureCalls
        .callAtTime(at, identifier: companyMasterResumeId)
        .companyMaster
        .retry();
  }

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

  static Future<void> businessDocumentsNow(Session session, int jobId) =>
      session.serverpod.futureCalls
          .callWithDelay(Duration.zero)
          .disclosure
          .runBusiness(jobId);

  static Future<void> businessDocumentsResume(
    Session session,
    DateTime at,
  ) async {
    await session.serverpod.futureCalls.cancel(businessDocumentsResumeId);
    await session.serverpod.futureCalls
        .callAtTime(at, identifier: businessDocumentsResumeId)
        .disclosure
        .resumeBusiness();
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

  static Future<void> aiExtractionNow(Session session, int jobId, int limit) =>
      session.serverpod.futureCalls
          .callWithDelay(Duration.zero)
          .aiExtraction
          .run(jobId, limit);

  /// 엔드포인트·FutureCall이 쓰는 예약 함수를 등록한다.
  static void installHooks() {
    IngestHooks.companyMasterResume = companyMasterResume;
    IngestHooks.companyMasterNow = companyMasterNow;
    IngestHooks.financialsNow = financialsNow;
    IngestHooks.financialsForCompanyNow = financialsForCompanyNow;
    IngestHooks.financialsResume = financialsResume;
    IngestHooks.marketSnapshotNow = marketSnapshotNow;
    IngestHooks.marketSnapshotResume = marketSnapshotResume;
    IngestHooks.businessDocumentsNow = businessDocumentsNow;
    IngestHooks.businessDocumentsResume = businessDocumentsResume;
    IngestHooks.disclosuresNow = disclosuresNow;
    IngestHooks.disclosuresForCompanyNow = disclosuresForCompanyNow;
    IngestHooks.disclosures = disclosuresResume;
    IngestHooks.aiExtractionNow = aiExtractionNow;
  }
}
