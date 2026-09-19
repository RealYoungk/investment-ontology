import 'package:serverpod/serverpod.dart';

import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import 'disclosure_sync.dart';
import 'ingest_jobs.dart';
import 'ingest_hooks.dart';

class DisclosureFutureCall extends FutureCall {
  Future<void> run(Session session, int jobId) async {
    final key = DartApiKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await DisclosureSync(
      session,
      DartClient(key),
      jobId,
      scheduleResume: switch (IngestHooks.disclosures) {
        final hook? => (at) => hook(session, at),
        null => null,
      },
    ).run();
  }

  /// 기업 하나의 사업보고서 주요정보만 받는다.
  Future<void> runCompany(Session session, int jobId, String corpCode) async {
    final key = DartApiKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await DisclosureSync(
      session,
      DartClient(key),
      jobId,
      corpCode: corpCode,
    ).run();
  }

  /// 매일 예약·이어받기. 같은 수집이 돌고 있으면 건너뛴다.
  Future<void> resume(Session session) async {
    final job = await IngestJobs.start(session, DisclosureSync.kind);
    if (job == null) return;
    await run(session, job.id!);
  }
}
