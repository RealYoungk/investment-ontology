import 'package:serverpod/serverpod.dart';

import '../data_go_kr/data_go_kr_client.dart';
import '../data_go_kr/data_go_kr_service_key.dart';
import 'ingest_jobs.dart';
import 'ingest_hooks.dart';
import 'market_snapshot_sync.dart';
import 'market_security_relink.dart';
import '../../generated/protocol.dart';

class MarketSnapshotFutureCall extends FutureCall {
  Future<void> run(Session session, int jobId) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job?.kind == MarketSecurityRelink.kind) {
      await MarketSecurityRelink.run(session, jobId);
      return;
    }
    if (job?.kind != MarketSnapshotSync.kind) return;
    final key = DataGoKrServiceKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, '공공데이터포털 서비스키가 설정되지 않았습니다.');
      return;
    }
    await MarketSnapshotSync(
      session,
      DataGoKrClient(key),
      jobId,
      scheduleResume: switch (IngestHooks.marketSnapshotResume) {
        final hook? => (at) => hook(session, at),
        null => null,
      },
    ).run();
  }

  /// 일일 호출 예산을 다 써서 멈춘 수집을 이어서 받는다.
  Future<void> resume(Session session) async {
    final job = await IngestJobs.start(session, MarketSnapshotSync.kind);
    if (job == null) return;
    await run(session, job.id!);
  }
}
