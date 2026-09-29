import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_schedule.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given IngestSchedule', (sessionBuilder, endpoints) {
    late Session session;

    setUp(() => session = sessionBuilder.build());

    Future<List<sp.FutureCallEntry>> daily() => sp.FutureCallEntry.db.find(
      session,
      where: (t) => t.identifier.inSet({
        IngestSchedule.marketSnapshotDailyId,
        IngestSchedule.financialsDailyId,
      }),
    );

    test('재시도 예약 없이 남은 실패는 시작 시 한 번만 복구 예약한다', () async {
      final session = sessionBuilder.build();
      await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.failed,
          startedAt: DateTime.now().toUtc(),
          failed: 1,
        ),
      );
      await IngestSchedule.onServerStart(session);
      await IngestSchedule.onServerStart(session);
      expect(
        await sp.FutureCallEntry.db.count(
          session,
          where: (t) => t.identifier.equals(IngestSchedule.financialsResumeId),
        ),
        1,
      );
    });

    test('매일 예약을 한 번만 건다 (서버를 여러 번 켜도 쌓이지 않음)', () async {
      await IngestSchedule.ensureDaily(session);
      await IngestSchedule.ensureDaily(session);

      final entries = await daily();
      expect(
        entries.map((e) => e.identifier),
        unorderedEquals([
          IngestSchedule.marketSnapshotDailyId,
          IngestSchedule.financialsDailyId,
        ]),
      );
      final market = entries.firstWhere(
        (e) => e.identifier == IngestSchedule.marketSnapshotDailyId,
      );
      expect(market.time.toUtc().hour, 9, reason: '18:00 KST = 09:00 UTC');
      expect(market.time.toUtc().minute, 0);
      expect(market.time.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('서버가 켜지면 끊긴 작업을 정리하고 재무는 바로 이어받기를 예약한다', () async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 30),
          ),
          total: 45550,
          processed: 180,
          apiCalls: 973,
        ),
      );

      await IngestSchedule.onServerStart(session);

      final after = (await IngestJob.db.findById(session, job.id!))!;
      expect(after.status, IngestStatus.failed);
      expect(after.message, contains('180/45550'));
      expect(
        await IngestJobs.running(session, FinancialFactsSync.kind),
        isNull,
        reason: '새 수집을 막지 않는다',
      );
      final resume = await sp.FutureCallEntry.db.find(
        session,
        where: (t) => t.identifier.equals(IngestSchedule.financialsResumeId),
      );
      expect(resume, hasLength(1));
      expect(
        resume.single.time.difference(DateTime.now().toUtc()).inMinutes,
        lessThan(1),
      );
      expect(
        await sp.FutureCallEntry.db.count(
          session,
          where: (t) =>
              t.identifier.equals(IngestSchedule.marketSnapshotResumeId),
        ),
        0,
        reason: '끊기지 않은 시세는 예약하지 않는다',
      );
    });

    test('Serverpod가 다시 실행할 끊긴 작업은 두고, 남은 이어받기 예약은 지운다', () async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      final past = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      await sp.FutureCallEntry.db.insert(session, [
        // 끊긴 실행: 서버가 켜지면 Serverpod가 다시 실행한다.
        sp.FutureCallEntry(
          name: 'FinancialFactsRunFutureCall',
          time: past,
          serverId: 'test',
          serializedObject: '{"jobId":${job.id}}',
        ),
        // 지난번에 걸어 둔 이어받기: 위 실행과 겹친다.
        sp.FutureCallEntry(
          name: 'FinancialFactsResumeFutureCall',
          time: past,
          serverId: 'test',
          identifier: IngestSchedule.financialsResumeId,
        ),
      ]);

      await IngestSchedule.onServerStart(session);

      expect(
        (await IngestJob.db.findById(session, job.id!))!.status,
        IngestStatus.running,
      );
      expect(
        await sp.FutureCallEntry.db.count(
          session,
          where: (t) => t.identifier.equals(IngestSchedule.financialsResumeId),
        ),
        0,
      );
    });

    test('다시 실행되는 작업은 실행 중으로 되돌리고, 취소된 작업은 실행하지 않는다', () async {
      final failed = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.failed,
          startedAt: DateTime.now().toUtc(),
          finishedAt: DateTime.now().toUtc(),
          message: '서버가 꺼지며 중단됨',
        ),
      );
      final cancelled = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.cancelled,
          startedAt: DateTime.now().toUtc(),
        ),
      );

      final revived = (await IngestJobs.claim(session, failed.id!))!;
      expect(revived.status, IngestStatus.running);
      expect(revived.finishedAt, isNull);
      expect(revived.message, isNull);
      expect(await IngestJobs.claim(session, cancelled.id!), isNull);
    });

    test('기한 지난 매일·이어받기 예약만 있으면 끊긴 작업의 재실행으로 보지 않는다', () async {
      // 정상 종료로 실행 예약이 지워진 뒤, 꺼져 있는 동안 18:30 매일 예약이 지난 경우.
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        ),
      );
      await sp.FutureCallEntry.db.insertRow(
        session,
        sp.FutureCallEntry(
          name: 'FinancialFactsResumeFutureCall',
          time: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          serverId: 'test',
          identifier: IngestSchedule.financialsDailyId,
        ),
      );

      await IngestSchedule.onServerStart(session);

      expect(
        (await IngestJob.db.findById(session, job.id!))!.status,
        IngestStatus.failed,
        reason: '죽은 작업이 새 수집을 막지 않게 정리한다',
      );
      expect(
        await sp.FutureCallEntry.db.count(
          session,
          where: (t) => t.identifier.equals(IngestSchedule.financialsResumeId),
        ),
        1,
      );
    });
  });
}
