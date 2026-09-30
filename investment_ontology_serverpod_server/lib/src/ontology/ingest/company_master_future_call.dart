import 'package:serverpod/serverpod.dart';

import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import 'company_master_sync.dart';
import 'ingest_jobs.dart';

class CompanyMasterFutureCall extends FutureCall {
  /// 매일 기업 마스터 갱신. 같은 종류의 실행 중 작업이 있으면 중복하지 않는다.
  Future<void> resume(Session session) async {
    final full = await CompanyMasterSync.isFullRefreshDue(session);
    final job = await IngestJobs.start(
      session,
      CompanyMasterSync.kind,
      fullRefresh: full,
    );
    if (job == null) return;
    await run(session, job.id!, full);
  }

  Future<void> run(Session session, int jobId, bool force) async {
    final key = DartApiKey.read(session);
    if (key == null) {
      await CompanyMasterSync.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await CompanyMasterSync(session, DartClient(key), jobId).run(force: force);
  }
}
