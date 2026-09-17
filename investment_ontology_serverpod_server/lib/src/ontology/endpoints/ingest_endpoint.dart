import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../../generated/protocol.dart';
import '../dart/dart_api_key.dart';
import '../data_go_kr/data_go_kr_service_key.dart';
import '../ingest/company_master_sync.dart';
import '../ingest/financial_facts_sync.dart';
import '../ingest/ingest_jobs.dart';
import '../ingest/market_snapshot_sync.dart';

/// 외부 원천 수집 제어.
///
/// 1인 로컬 사용 전제라 인증이 없다. 외부에 배포하기 전에 인증을 붙여야 한다.
class IngestEndpoint extends Endpoint {
  /// 상장사 마스터 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 평소에는 DART 변경일이 바뀐 기업만 다시 받는다. [force]이거나 마지막 전체
  /// 갱신 후 [CompanyMasterSync.fullRefreshInterval]이 지났으면 전체를 다시 받는다.
  Future<IngestJob> startCompanyMaster(
    Session session, {
    bool? force,
  }) async {
    _requireDartKey(session);

    final running = await IngestJobs.running(session, CompanyMasterSync.kind);
    if (running != null) return running;

    final full =
        (force ?? false) || await CompanyMasterSync.isFullRefreshDue(session);
    final job = (await IngestJobs.start(
      session,
      CompanyMasterSync.kind,
      fullRefresh: full,
    ))!;
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero)
        .companyMaster
        .run(job.id!, full);
    return job;
  }

  /// 재무제표 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 공시 목록에서 새 정기보고서를 찾고, 받지 않은 보고서를 최신순으로 받는다.
  /// DART 일일 호출 예산을 다 쓰면 멈추고 다음 날 이어서 받는다.
  Future<IngestJob> startFinancials(Session session) async {
    _requireDartKey(session);
    final running = await IngestJobs.running(session, FinancialFactsSync.kind);
    if (running != null) return running;
    final job = (await IngestJobs.start(session, FinancialFactsSync.kind))!;
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero)
        .financialFacts
        .run(job.id!);
    return job;
  }

  /// 시세 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 받지 않은 평일 기준일을 최신순으로 받고(처음에는 3년), 가장 최근 기준일의
  /// 상장종목 정보로 종목을 기업에 잇는다.
  Future<IngestJob> startMarketSnapshot(Session session) async {
    if (DataGoKrServiceKey.read(session) == null) {
      throw IngestException(
        message: DataGoKrServiceKey.secret.missingMessage('공공데이터포털 서비스'),
      );
    }
    final running = await IngestJobs.running(session, MarketSnapshotSync.kind);
    if (running != null) return running;
    final job = (await IngestJobs.start(session, MarketSnapshotSync.kind))!;
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero)
        .marketSnapshot
        .run(job.id!);
    return job;
  }

  Future<IngestJob?> cancel(Session session, int jobId) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null || job.status != IngestStatus.running) return job;
    return IngestJob.db.updateRow(
      session,
      job.copyWith(
        status: IngestStatus.cancelled,
        finishedAt: DateTime.now().toUtc(),
        message: '사용자 취소',
      ),
    );
  }

  Future<IngestJob?> latest(Session session) =>
      IngestJobs.latest(session, CompanyMasterSync.kind);

  /// [kind]의 최근 작업 (`company_master`, `financial_facts`, `market_snapshot`).
  Future<IngestJob?> latestOf(Session session, String kind) =>
      IngestJobs.latest(session, kind);

  static void _requireDartKey(Session session) {
    if (DartApiKey.read(session) == null) {
      throw IngestException(
        message: DartApiKey.secret.missingMessage('DART API'),
      );
    }
  }
}
