import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 수집 작업(IngestJob) 공통 처리.
abstract final class IngestJobs {
  /// 이보다 오래된 "실행 중" 작업은 멈춘 것으로 본다. 서버 재시작으로 끊긴 작업은
  /// [recoverInterrupted]가 정리하므로 이것은 마지막 안전장치다. 하루 호출 예산을
  /// 다 쓰는 재무 수집이 2시간 넘게 걸릴 수 있어 넉넉히 둔다.
  static const staleAfter = Duration(hours: 12);

  /// [kind]의 실행 중인 작업. 오래 응답이 없으면 실패로 정리하고 null.
  static Future<IngestJob?> running(Session session, String kind) async {
    final job = await IngestJob.db.findFirstRow(
      session,
      where: (t) => t.kind.equals(kind) & t.status.equals(IngestStatus.running),
      orderBy: (t) => t.startedAt.desc(),
    );
    if (job == null) return null;
    if (DateTime.now().toUtc().difference(job.startedAt) < staleAfter) {
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

  /// 서버가 켜질 때 부른다. 수집은 서버 프로세스 안에서만 돌므로, 이때 "실행 중"으로
  /// 남은 작업은 이전 서버와 함께 끊긴 것이다. 실패로 정리하고 그 종류들을 돌려준다.
  static Future<Set<String>> recoverInterrupted(Session session) async {
    final jobs = await IngestJob.db.find(
      session,
      where: (t) => t.status.equals(IngestStatus.running),
    );
    final now = DateTime.now().toUtc();
    for (final job in jobs) {
      await IngestJob.db.updateRow(
        session,
        job.copyWith(
          status: IngestStatus.failed,
          finishedAt: now,
          message:
              '서버가 꺼지며 중단됨 (${job.processed}/${job.total} 처리, '
              '호출 ${job.apiCalls}회). 받은 것은 저장되어 있고 이어서 받습니다.',
        ),
      );
    }
    return {for (final j in jobs) j.kind};
  }

  /// 새 작업을 만든다. 이미 실행 중이면 null.
  static Future<IngestJob?> start(
    Session session,
    String kind, {
    bool fullRefresh = false,
  }) async {
    if (await running(session, kind) != null) return null;
    return IngestJob.db.insertRow(
      session,
      IngestJob(
        kind: kind,
        status: IngestStatus.running,
        startedAt: DateTime.now().toUtc(),
        fullRefresh: fullRefresh,
      ),
    );
  }

  static Future<IngestJob?> latest(Session session, String kind) =>
      IngestJob.db.findFirstRow(
        session,
        where: (t) => t.kind.equals(kind),
        orderBy: (t) => t.startedAt.desc(),
      );

  static Future<bool> isCancelled(Session session, int jobId) async {
    final j = await IngestJob.db.findById(session, jobId);
    return j?.status == IngestStatus.cancelled;
  }

  /// 진행 상황 저장. 그 사이 들어온 취소 요청은 덮어쓰지 않는다.
  static Future<IngestJob> save(Session session, IngestJob job) async {
    if (job.status == IngestStatus.running &&
        await isCancelled(session, job.id!)) {
      job = job.copyWith(status: IngestStatus.cancelled);
    }
    return IngestJob.db.updateRow(session, job);
  }

  /// 작업을 실패로 끝낸다.
  static Future<void> fail(
    Session session,
    int jobId,
    String message, {
    int? apiCalls,
  }) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null) return;
    await IngestJob.db.updateRow(
      session,
      job.copyWith(
        status: IngestStatus.failed,
        apiCalls: apiCalls ?? job.apiCalls,
        finishedAt: DateTime.now().toUtc(),
        message: message,
      ),
    );
  }
}
