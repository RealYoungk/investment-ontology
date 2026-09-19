import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_api_key.dart';
import '../data_go_kr/data_go_kr_service_key.dart';
import '../ingest/company_master_sync.dart';
import '../ingest/disclosure_sync.dart';
import '../ingest/financial_facts_sync.dart';
import '../ingest/ingest_jobs.dart';
import '../ingest/ingest_schedule.dart';
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
    await IngestSchedule.companyMasterNow(session, job.id!, full);
    return job;
  }

  /// 재무제표 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 공시 목록에서 새 정기보고서를 찾고, 받지 않은 보고서를 최신순으로 받는다.
  /// DART 일일 호출 예산을 다 쓰면 멈추고 다음 날 이어서 받는다.
  /// [corpCode]를 주면 그 기업의 정기보고서만 찾아 바로 받는다. 전체 수집이 돌고 있어도 된다.
  Future<IngestJob> startFinancials(Session session, {String? corpCode}) async {
    _requireDartKey(session);
    // 기업 하나 수집은 따로 세어, 전체 백필이 도는 중에도 바로 받을 수 있게 한다.
    final kind = corpCode == null
        ? FinancialFactsSync.kind
        : FinancialFactsSync.companyKind;
    final running = await IngestJobs.running(session, kind);
    if (running != null) return running;
    final job = (await IngestJobs.start(session, kind))!;
    if (corpCode == null) {
      await IngestSchedule.financialsNow(session, job.id!);
    } else {
      await IngestSchedule.financialsForCompanyNow(session, job.id!, corpCode);
    }
    return job;
  }

  /// 정기보고서 주요정보(주주·임원·출자·배당 등 28종) 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 재무 수집이 장부에 넣은 사업보고서의 항목을 최신 사업연도·핵심 항목부터 받는다.
  /// 재무 백필이 남아 있으면 최신 사업연도의 핵심 항목만 받는다.
  /// [corpCode]를 주면 그 기업의 사업보고서 항목만 바로 받는다.
  Future<IngestJob> startDisclosures(
    Session session, {
    String? corpCode,
  }) async {
    _requireDartKey(session);
    final kind = corpCode == null
        ? DisclosureSync.kind
        : DisclosureSync.companyKind;
    final running = await IngestJobs.running(session, kind);
    if (running != null) return running;
    final job = (await IngestJobs.start(session, kind))!;
    if (corpCode == null) {
      await IngestSchedule.disclosuresNow(session, job.id!);
    } else {
      await IngestSchedule.disclosuresForCompanyNow(session, job.id!, corpCode);
    }
    return job;
  }

  /// 시세 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 받지 않은 평일 기준일을 최신순으로 받고(처음에는 5년), 가장 최근 기준일의
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
    await IngestSchedule.marketSnapshotNow(session, job.id!);
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

  /// [kind]의 최근 작업 (`company_master`, `financial_facts`, `market_snapshot`, `disclosures` …).
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
