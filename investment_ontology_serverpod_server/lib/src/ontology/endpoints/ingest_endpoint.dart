import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../../generated/protocol.dart';
import '../ingest/company_master_sync.dart';

/// 외부 원천 수집 제어.
///
/// 1인 로컬 사용 전제라 인증이 없다. 외부에 배포하기 전에 인증을 붙여야 한다.
class IngestEndpoint extends Endpoint {
  /// 서버 재시작 등으로 멈춘 작업을 실행 중으로 보지 않는 기준.
  static const _staleAfter = Duration(hours: 3);

  /// 상장사 마스터 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// [force]가 false면 DART 변경일이 바뀐 기업만 다시 받는다.
  Future<IngestJob> startCompanyMaster(
    Session session, {
    bool? force,
  }) async {
    final key = session.passwords['dartApiKey'];
    if (key == null || key.isEmpty) {
      throw IngestException(
        message:
            'DART API 키가 없습니다. config/passwords.yaml의 shared: 아래에 '
            'dartApiKey를 추가하고 서버를 재시작하세요.',
      );
    }

    final running = await _running(session);
    if (running != null) return running;

    final job = await IngestJob.db.insertRow(
      session,
      IngestJob(
        kind: CompanyMasterSync.kind,
        status: IngestStatus.running,
        startedAt: DateTime.now().toUtc(),
      ),
    );
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero)
        .companyMaster
        .run(job.id!, force ?? false);
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

  Future<IngestJob?> latest(Session session) => IngestJob.db.findFirstRow(
    session,
    where: (t) => t.kind.equals(CompanyMasterSync.kind),
    orderBy: (t) => t.startedAt.desc(),
  );

  Future<IngestJob?> _running(Session session) async {
    final job = await IngestJob.db.findFirstRow(
      session,
      where: (t) =>
          t.kind.equals(CompanyMasterSync.kind) &
          t.status.equals(IngestStatus.running),
      orderBy: (t) => t.startedAt.desc(),
    );
    if (job == null) return null;
    if (DateTime.now().toUtc().difference(job.startedAt) < _staleAfter) {
      return job;
    }
    await IngestJob.db.updateRow(
      session,
      job.copyWith(
        status: IngestStatus.failed,
        finishedAt: DateTime.now().toUtc(),
        message: '응답 없는 작업으로 정리됨',
      ),
    );
    return null;
  }
}
