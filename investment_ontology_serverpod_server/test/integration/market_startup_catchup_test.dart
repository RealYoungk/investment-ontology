import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_schedule.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_sync.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Market startup checks actual latest ledgers', (builder, _) {
    final now = DateTime.utc(2030, 10, 5, 2);
    final target = DateTime.utc(2030, 10, 4);
    late Session session;
    late IngestJob job;
    Future<List<sp.FutureCallEntry>> resumes() => sp.FutureCallEntry.db.find(
      session,
      where: (t) => t.identifier.equals(IngestSchedule.marketSnapshotResumeId),
    );
    Future<void> ledgers(
      DateTime day, {
      bool index = true,
      int rows = 1,
    }) async {
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(baseDate: day, rowCount: rows, fetchedAt: now),
      );
      if (index) {
        await MarketIndexDay.db.insertRow(
          session,
          MarketIndexDay(baseDate: day, rowCount: rows, fetchedAt: now),
        );
      }
    }

    setUp(() async {
      session = builder.build();
      // Generated scheduling owns an independent transaction. Isolate those
      // committed test-only entries explicitly instead of relying on rollback.
      await sp.FutureCallEntry.db.deleteWhere(
        session,
        where: (t) =>
            t.identifier.equals(IngestSchedule.marketSnapshotResumeId),
      );
      await MarketSnapshotDay.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await MarketIndexDay.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await IngestJob.db.deleteWhere(
        session,
        where: (t) => t.kind.equals(MarketSnapshotSync.kind),
      );
      job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: MarketSnapshotSync.kind,
          status: IngestStatus.succeeded,
          startedAt: now.subtract(const Duration(days: 1)),
          finishedAt: now.subtract(const Duration(days: 1)),
          updated: 1,
        ),
      );
    });

    test(
      'old success schedules one normal resume without API or fake holiday',
      () async {
        await ledgers(DateTime.utc(2030, 10, 3));
        final before = job.toJson();
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        final queued = await resumes();
        expect(queued, hasLength(1));
        expect(queued.single.name, 'MarketSnapshotResumeFutureCall');
        expect(queued.single.time, now.add(const Duration(seconds: 10)));
        expect(await MarketSnapshotDay.db.count(session), 1);
        expect(await MarketIndexDay.db.count(session), 1);
        expect(await ApiCallUsage.db.count(session), 0);
        expect(
          (await IngestJob.db.findById(session, job.id!))!.toJson(),
          before,
        );
      },
    );

    test(
      'missing index resumes without replacing the saved price ledger',
      () async {
        await ledgers(target, index: false);
        final before = (await MarketSnapshotDay.db.find(session)).single
            .toJson();
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        expect(await resumes(), hasLength(1));
        expect(
          (await MarketSnapshotDay.db.find(session)).single.toJson(),
          before,
        );
        expect(await MarketIndexDay.db.count(session), 0);
      },
    );

    test(
      'complete trading or confirmed holiday ledgers do not resume',
      () async {
        await ledgers(target, rows: 0);
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        expect(await resumes(), isEmpty);
        final price = (await MarketSnapshotDay.db.find(session)).single;
        await MarketSnapshotDay.db.updateRow(
          session,
          price.copyWith(rowCount: 2873),
        );
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        expect(await resumes(), isEmpty);
      },
    );

    test(
      'cancelled, running, failed and missing job keep existing retry policy',
      () async {
        for (final status in [
          IngestStatus.cancelled,
          IngestStatus.running,
          IngestStatus.failed,
        ]) {
          job = await IngestJob.db.updateRow(
            session,
            job.copyWith(status: status),
          );
          await IngestSchedule.resumeMissingLatestMarket(session, now: now);
          expect(await resumes(), isEmpty);
        }
        await IngestJob.db.deleteRow(session, job);
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        expect(await resumes(), isEmpty);
      },
    );

    test(
      'existing budget/publication resume keeps its original time',
      () async {
        final at = now.add(const Duration(hours: 8));
        await IngestSchedule.marketSnapshotResume(session, at);
        await IngestSchedule.resumeMissingLatestMarket(session, now: now);
        final queued = await resumes();
        expect(queued, hasLength(1));
        expect(queued.single.time, at);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
