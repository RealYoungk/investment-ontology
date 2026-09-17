import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../data_go_kr/data_go_kr_client.dart';
import '../data_go_kr/data_go_kr_service_key.dart';
import 'ingest_jobs.dart';
import 'market_snapshot_sync.dart';

class MarketSnapshotFutureCall extends FutureCall {
  static const resumeIdentifier = 'market_snapshot_resume';

  Future<void> run(Session session, int jobId) async {
    final key = DataGoKrServiceKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, '공공데이터포털 서비스키가 설정되지 않았습니다.');
      return;
    }
    await MarketSnapshotSync(
      session,
      DataGoKrClient(key),
      jobId,
      scheduleResume: (at) async {
        await session.serverpod.futureCalls.cancel(resumeIdentifier);
        await session.serverpod.futureCalls
            .callAtTime(at, identifier: resumeIdentifier)
            .marketSnapshot
            .resume();
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
