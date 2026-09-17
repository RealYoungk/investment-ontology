import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 수집 작업(IngestJob) 공통 처리.
abstract final class IngestJobs {
  /// 서버 재시작 등으로 멈춘 작업을 실행 중으로 보지 않는 기준.
  static const staleAfter = Duration(hours: 3);

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
