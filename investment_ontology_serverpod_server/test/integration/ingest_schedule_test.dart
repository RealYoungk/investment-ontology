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
  });
}
