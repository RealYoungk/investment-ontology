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
  });
}
