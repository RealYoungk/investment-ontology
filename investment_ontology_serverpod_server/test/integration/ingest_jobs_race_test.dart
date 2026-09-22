import 'dart:async';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 동시에 들어온 요청이 실제로 따로 커밋되어야 경합이 드러나므로 롤백을 끈다.
/// 그룹마다 데이터베이스가 따로라 다른 테스트에 새지 않는다. 테스트마다 종류를 달리해
/// 서로의 작업을 보지 않게 한다.
void main() {
  withServerpod(
    'Given 수집 작업이 없는 종류',
    (sessionBuilder, _) {
      Future<int> runningCount(String kind) => IngestJob.db.count(
        sessionBuilder.build(),
        where: (t) =>
            t.kind.equals(kind) & t.status.equals(IngestStatus.running),
      );

      test('when start를 동시에 여러 번 부르면 then 실행 중 작업은 하나만 생긴다', () async {
        const kind = 'race_start';
        final results = await Future.wait([
          for (var i = 0; i < 12; i++)
            IngestJobs.start(sessionBuilder.build(), kind),
        ]);

        expect(results.whereType<IngestJob>(), hasLength(1));
        expect(await runningCount(kind), 1);
      });

      test(
        'when startAndSchedule을 동시에 여러 번 부르면 then 모두 같은 작업을 받고 예약은 한 번이다',
        () async {
          const kind = 'race_schedule';
          var scheduled = 0;
          final jobs = await Future.wait([
            for (var i = 0; i < 12; i++)
              IngestJobs.startAndSchedule(
                sessionBuilder.build(),
                kind,
                (job) async {
                  scheduled++;
                },
              ),
          ]);

          expect(jobs.map((j) => j.id).toSet(), hasLength(1));
          expect(scheduled, 1);
          expect(await runningCount(kind), 1);
        },
      );

      test(
        'when 예약이 실패하면 then 만든 작업을 실패로 끝내 다음 시작을 막지 않는다',
        () async {
          const kind = 'race_schedule_fails';
          final session = sessionBuilder.build();

          await expectLater(
            IngestJobs.startAndSchedule(
              session,
              kind,
              (job) async => throw StateError('예약 함수 없음'),
            ),
            throwsA(isA<StateError>()),
          );

          final failed = (await IngestJobs.latest(session, kind))!;
          expect(failed.status, IngestStatus.failed);
          expect(failed.message, contains('예약 함수 없음'));
          expect(await IngestJobs.start(session, kind), isNotNull);
        },
      );

      test('when 실행 중인 작업이 오래됐으면 then start가 정리하고 새로 만든다', () async {
        const kind = 'race_stale';
        final session = sessionBuilder.build();
        final stale = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: kind,
            status: IngestStatus.running,
            startedAt: DateTime.now().toUtc().subtract(
              IngestJobs.staleAfter + const Duration(minutes: 1),
            ),
          ),
        );

        final fresh = await IngestJobs.start(session, kind);

        expect(fresh, isNotNull);
        expect(
          (await IngestJob.db.findById(session, stale.id!))!.status,
          IngestStatus.failed,
        );
        expect(await runningCount(kind), 1);
      });

      /// 다른 트랜잭션이 행을 잠근 채 취소를 써 두고, [whileLocked]를 그 사이에 시작한 뒤
      /// 커밋한다. 잠금 없이 읽으면 커밋 전 상태(취소 아님)를 보고 취소를 덮어쓴다.
      Future<T> raceWithCancel<T>(
        IngestJob job,
        Future<T> Function() whileLocked,
      ) async {
        final holder = sessionBuilder.build();
        final locked = Completer<void>();
        final release = Completer<void>();
        final cancelling = holder.db.transaction((tx) async {
          await IngestJob.db.findById(
            holder,
            job.id!,
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          await IngestJob.db.updateRow(
            holder,
            job.copyWith(
              status: IngestStatus.cancelled,
              finishedAt: DateTime.now().toUtc(),
              message: '사용자 취소',
            ),
            transaction: tx,
          );
          locked.complete();
          await release.future;
        });
        await locked.future;
        final racing = whileLocked();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        release.complete();
        await cancelling;
        return racing;
      }

      test('when 진행 저장 중에 취소가 커밋되면 then save가 취소를 덮어쓰지 않는다', () async {
        final session = sessionBuilder.build();
        final job = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: 'race_cancel_save',
            status: IngestStatus.running,
            startedAt: DateTime.now().toUtc(),
          ),
        );

        final saved = await raceWithCancel(
          job,
          () => IngestJobs.save(
            sessionBuilder.build(),
            job.copyWith(processed: 5),
          ),
        );

        expect(saved.status, IngestStatus.cancelled);
        expect(saved.processed, 5);
        final stored = (await IngestJob.db.findById(session, job.id!))!;
        expect(stored.status, IngestStatus.cancelled);
        expect(stored.message, '사용자 취소');
      });

      test('when 재실행 claim 중에 취소가 커밋되면 then 실행하지 않는다', () async {
        final session = sessionBuilder.build();
        final job = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: 'race_cancel_claim',
            status: IngestStatus.failed,
            startedAt: DateTime.now().toUtc(),
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final claimed = await raceWithCancel(
          job,
          () => IngestJobs.claim(sessionBuilder.build(), job.id!),
        );

        expect(claimed, isNull);
        expect(
          (await IngestJob.db.findById(session, job.id!))!.status,
          IngestStatus.cancelled,
        );
      });

      test('완료 저장과 오류 보고도 취소를 덮어쓰지 않으며 완료 작업은 재실행하지 않는다', () async {
        final session = sessionBuilder.build();
        final job = (await IngestJobs.start(session, 'terminal_cancel'))!;
        await IngestJobs.cancel(session, job.id!);
        await IngestJobs.save(
          session,
          job.copyWith(status: IngestStatus.succeeded),
        );
        await IngestJobs.fail(session, job.id!, 'late failure');
        expect(
          (await IngestJob.db.findById(session, job.id!))!.status,
          IngestStatus.cancelled,
        );
        final completed = (await IngestJobs.start(
          session,
          'terminal_success',
        ))!;
        await IngestJobs.save(
          session,
          completed.copyWith(status: IngestStatus.succeeded),
        );
        expect(await IngestJobs.claim(session, completed.id!), isNull);
        await IngestJobs.fail(session, completed.id!, 'late failure');
        expect(
          (await IngestJob.db.findById(session, completed.id!))!.status,
          IngestStatus.succeeded,
        );
      });

      test('when 실행 중인 작업을 cancel하면 then 취소로 바뀌고, 끝난 작업은 그대로다', () async {
        final session = sessionBuilder.build();
        final running = (await IngestJobs.start(session, 'race_cancel'))!;
        final done = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: 'race_cancel_done',
            status: IngestStatus.succeeded,
            startedAt: DateTime.now().toUtc(),
          ),
        );

        final cancelled = (await IngestJobs.cancel(session, running.id!))!;
        expect(cancelled.status, IngestStatus.cancelled);
        expect(cancelled.message, '사용자 취소');
        expect(
          (await IngestJobs.cancel(session, done.id!))!.status,
          IngestStatus.succeeded,
        );
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
