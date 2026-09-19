import 'package:serverpod/serverpod.dart';

import 'dart:convert';

import 'package:serverpod/protocol.dart' as sp;

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

  /// 작업을 실행하기 직전에 부른다. 실행하지 말아야 하면 null.
  ///
  /// Serverpod는 서버가 꺼지며 끊긴 FutureCall을 다음에 켜질 때 다시 실행한다. 그래서 같은
  /// 작업이 다시 실행될 수 있다. 사용자가 취소한 작업이면 실행하지 않고, 아니면 실행 중으로
  /// 되돌린다 (받은 것은 장부에 남아 있어 이어서 받는다).
  static Future<IngestJob?> claim(Session session, int jobId) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null || job.status == IngestStatus.cancelled) return null;
    if (job.status == IngestStatus.running) return job;
    return IngestJob.db.updateRow(
      session,
      job.copyWith(
        status: IngestStatus.running,
        finishedAt: null,
        message: null,
      ),
    );
  }

  /// 수집 종류 → FutureCall 이름 앞부분 (생성된 이름은 `<앞부분><메서드>FutureCall`).
  static const _futureCallPrefixes = {
    'financial_facts': 'FinancialFacts',
    'financial_facts_company': 'FinancialFacts',
    'market_snapshot': 'MarketSnapshot',
    'disclosures': 'Disclosure',
    'disclosures_company': 'Disclosure',
    'company_master': 'CompanyMaster',
  };

  /// FutureCall 예약이 [jobId] 작업을 실행하는 것인지. `run(jobId)`·`runCompany(jobId, …)`는
  /// 인자를 `{"jobId": …}`로 저장한다. 매일·이어받기 예약(`resume`)은 인자가 없어 해당하지 않는다.
  static bool _runsJob(sp.FutureCallEntry entry, IngestJob job) {
    final prefix = _futureCallPrefixes[job.kind];
    final data = entry.serializedObject;
    if (prefix == null || data == null || !entry.name.startsWith(prefix)) {
      return false;
    }
    try {
      final json = jsonDecode(data);
      return json is Map && json['jobId'] == job.id;
    } on FormatException {
      return false;
    }
  }

  /// 서버가 켜질 때 부른다. 수집은 서버 프로세스 안에서만 돌므로, 이때 "실행 중"으로
  /// 남은 작업은 이전 서버와 함께 끊긴 것이다.
  ///
  /// 그 작업을 실행하던 FutureCall이 남아 있으면(갑자기 꺼진 경우) Serverpod가 다시 실행하므로
  /// 그대로 둔다 ([claim]이 실행 중으로 되돌린다). 남아 있지 않으면(정상 종료로 지워진 경우)
  /// 실패로 정리하고 그 종류를 돌려준다 (호출한 쪽이 이어받기를 예약한다).
  static Future<({Set<String> orphaned, Set<String> rerunning})>
  recoverInterrupted(Session session) async {
    final jobs = await IngestJob.db.find(
      session,
      where: (t) => t.status.equals(IngestStatus.running),
    );
    final now = DateTime.now().toUtc();
    final entries = await sp.FutureCallEntry.db.find(session);
    bool willRerun(IngestJob job) => entries.any((e) => _runsJob(e, job));

    final orphaned = <String>{}, rerunning = <String>{};
    for (final job in jobs) {
      if (willRerun(job)) {
        rerunning.add(job.kind);
        continue;
      }
      orphaned.add(job.kind);
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
    return (orphaned: orphaned, rerunning: rerunning);
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
