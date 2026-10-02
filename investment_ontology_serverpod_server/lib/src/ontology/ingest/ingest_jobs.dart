import 'package:serverpod/serverpod.dart';

import 'dart:convert';

import 'package:serverpod/protocol.dart' as sp;

import '../../generated/protocol.dart';

/// 수집 작업(IngestJob) 공통 처리.
///
/// Protocol dependency of classes declared with `extends Endpoint`.
/// Serverpod 4.0's incremental watcher only refreshes analyzer contexts for
/// files matching that declaration marker. Keep it here so helper API changes
/// do not leave dependent endpoints missing from generated code.
abstract final class IngestJobs {
  /// 이보다 오래된 "실행 중" 작업은 멈춘 것으로 본다. 서버 재시작으로 끊긴 작업은
  /// [recoverInterrupted]가 정리하므로 이것은 마지막 안전장치다. 하루 호출 예산을
  /// 다 쓰는 재무 수집이 2시간 넘게 걸릴 수 있어 넉넉히 둔다.
  static const staleAfter = Duration(hours: 12);

  /// [start]가 종류별로 잡는 PostgreSQL 트랜잭션 advisory lock의 첫 번째 키.
  /// 두 번째 키는 `hashtext(kind)`. 다른 advisory lock과 겹치지 않게 이 값으로 구분한다.
  static const _startLockNamespace = 461001;

  /// [kind]의 실행 중인 작업. 오래 응답이 없으면 실패로 정리하고 null.
  static Future<IngestJob?> running(
    Session session,
    String kind, {
    Transaction? transaction,
  }) async {
    if (transaction == null) {
      return session.db.transaction(
        (tx) => running(session, kind, transaction: tx),
      );
    }
    final job = await IngestJob.db.findFirstRow(
      session,
      where: (t) => t.kind.equals(kind) & t.status.equals(IngestStatus.running),
      orderBy: (t) => t.startedAt.desc(),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
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
      transaction: transaction,
    );
    return null;
  }

  /// 작업을 실행하기 직전에 부른다. 실행하지 말아야 하면 null.
  ///
  /// Serverpod는 서버가 꺼지며 끊긴 FutureCall을 다음에 켜질 때 다시 실행한다. 그래서 같은
  /// 작업이 다시 실행될 수 있다. 사용자가 취소한 작업이면 실행하지 않고, 아니면 실행 중으로
  /// 되돌린다 (받은 것은 장부에 남아 있어 이어서 받는다). 행을 잠그고 읽어, 그 사이 들어온
  /// 취소를 실행 중으로 덮어쓰지 않는다.
  static Future<IngestJob?> claim(Session session, int jobId) =>
      session.db.transaction((tx) async {
        // A resumed price job must not begin during DB-only security linking.
        // Acquire the same start lock before taking its row lock.
        final before = await IngestJob.db.findById(
          session,
          jobId,
          transaction: tx,
        );
        if (before?.kind == 'market_snapshot') {
          await lockKind(session, 'market_snapshot', tx);
        }
        final job = await IngestJob.db.findById(
          session,
          jobId,
          transaction: tx,
          lockMode: LockMode.forUpdate,
        );
        if (job == null ||
            job.status == IngestStatus.cancelled ||
            job.status == IngestStatus.succeeded) {
          return null;
        }
        if (job.status == IngestStatus.running) return job;
        return IngestJob.db.updateRow(
          session,
          job.copyWith(
            status: IngestStatus.running,
            finishedAt: null,
            message: null,
          ),
          transaction: tx,
        );
      });

  /// 수집 종류 → FutureCall 이름 앞부분 (생성된 이름은 `<앞부분><메서드>FutureCall`).
  static const _futureCallPrefixes = {
    'financial_facts': 'FinancialFacts',
    'financial_facts_company': 'FinancialFacts',
    'market_snapshot': 'MarketSnapshot',
    'market_security_relink': 'MarketSnapshot',
    'disclosures': 'Disclosure',
    'business_documents': 'Disclosure',
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
    final r = await startOrRunning(session, kind, fullRefresh: fullRefresh);
    return r.created ? r.job : null;
  }

  /// 새 작업을 만들거나, 이미 실행 중이면 그 작업을 돌려준다 (`created`가 false).
  ///
  /// 확인과 생성을 한 트랜잭션에서 종류별 advisory lock을 잡고 하므로, 요청이 동시에 들어와도
  /// 실행 중인 작업은 하나만 생긴다. 뒤에 온 트랜잭션은 앞의 것이 커밋할 때까지 기다렸다가
  /// 그 작업을 본다 (READ COMMITTED라 lock을 얻은 뒤의 조회는 커밋된 행을 본다).
  static Future<({IngestJob job, bool created})> startOrRunning(
    Session session,
    String kind, {
    bool fullRefresh = false,
  }) => session.db.transaction((tx) async {
    // 결과(void)는 읽지 않는다. 잠금은 트랜잭션이 끝날 때 풀린다.
    await lockKind(session, kind, tx);
    final existing = await running(session, kind, transaction: tx);
    if (existing != null) return (job: existing, created: false);
    final job = await IngestJob.db.insertRow(
      session,
      IngestJob(
        kind: kind,
        status: IngestStatus.running,
        startedAt: DateTime.now().toUtc(),
        fullRefresh: fullRefresh,
      ),
      transaction: tx,
    );
    return (job: job, created: true);
  });

  /// Shared with the DB-only relink transaction; retain one lock order.
  static Future<void> lockKind(
    Session session,
    String kind,
    Transaction tx,
  ) async {
    await session.db.unsafeExecute(
      'SELECT pg_advisory_xact_lock($_startLockNamespace, hashtext(@kind))',
      parameters: QueryParameters.named({'kind': kind}),
      transaction: tx,
    );
  }

  /// 새 작업을 만들고 [schedule]로 실행을 예약한다. 이미 실행 중이면 예약하지 않고 그 작업을
  /// 돌려준다 (엔드포인트의 "이미 실행 중이면 그 작업을 돌려준다").
  ///
  /// 예약이 실패하면 방금 만든 작업을 실패로 끝내고 다시 던진다. 그대로 두면 실행되지 않는
  /// "실행 중" 작업이 [staleAfter] 동안 같은 종류의 수집을 막는다.
  static Future<IngestJob> startAndSchedule(
    Session session,
    String kind,
    Future<void> Function(IngestJob job) schedule, {
    bool fullRefresh = false,
  }) async {
    final r = await startOrRunning(session, kind, fullRefresh: fullRefresh);
    if (!r.created) return r.job;
    try {
      await schedule(r.job);
    } catch (e) {
      await fail(session, r.job.id!, '실행 예약 실패: $e');
      rethrow;
    }
    return r.job;
  }

  /// 실행 중인 작업을 취소한다. 실행 중이 아니면 그대로 돌려준다.
  ///
  /// 행을 잠그고 바꾸므로 [save]·[claim]과 순서가 정해진다.
  static Future<IngestJob?> cancel(Session session, int jobId) =>
      session.db.transaction((tx) async {
        final job = await IngestJob.db.findById(
          session,
          jobId,
          transaction: tx,
          lockMode: LockMode.forUpdate,
        );
        if (job == null || job.status != IngestStatus.running) return job;
        return IngestJob.db.updateRow(
          session,
          job.copyWith(
            status: IngestStatus.cancelled,
            finishedAt: DateTime.now().toUtc(),
            message: '사용자 취소',
          ),
          transaction: tx,
        );
      });

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
  ///
  /// 행을 잠그고 읽은 뒤 쓰므로, 읽기와 쓰기 사이에 커밋된 취소도 덮어쓰지 않는다.
  static Future<IngestJob> save(Session session, IngestJob job) =>
      session.db.transaction((tx) async {
        var next = job;
        {
          final current = await IngestJob.db.findById(
            session,
            next.id!,
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          if (current?.status == IngestStatus.cancelled) {
            next = next.copyWith(
              status: IngestStatus.cancelled,
              finishedAt: current!.finishedAt,
              message: current.message,
            );
          }
        }
        return IngestJob.db.updateRow(session, next, transaction: tx);
      });

  /// 작업을 실패로 끝낸다.
  static Future<void> fail(
    Session session,
    int jobId,
    String message, {
    int? apiCalls,
  }) => session.db.transaction((tx) async {
    final job = await IngestJob.db.findById(
      session,
      jobId,
      transaction: tx,
      lockMode: LockMode.forUpdate,
    );
    if (job == null ||
        job.status == IngestStatus.cancelled ||
        job.status == IngestStatus.succeeded) {
      return;
    }
    await IngestJob.db.updateRow(
      session,
      job.copyWith(
        status: IngestStatus.failed,
        apiCalls: apiCalls ?? job.apiCalls,
        finishedAt: DateTime.now().toUtc(),
        message: message,
      ),
      transaction: tx,
    );
  });
}
