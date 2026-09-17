import 'package:serverpod/serverpod.dart';

import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import 'financial_facts_sync.dart';
import 'ingest_jobs.dart';
import 'ingest_schedule.dart';

class FinancialFactsFutureCall extends FutureCall {
  Future<void> run(Session session, int jobId) async {
    final key = DartApiKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await FinancialFactsSync(
      session,
      DartClient(key),
      jobId,
      scheduleResume: (at) => IngestSchedule.financialsResume(session, at),
    ).run();
  }

  /// 기업 하나의 정기보고서만 찾아 받는다.
  Future<void> runCompany(Session session, int jobId, String corpCode) async {
    final key = DartApiKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await FinancialFactsSync(
      session,
      DartClient(key),
      jobId,
      corpCode: corpCode,
    ).run();
  }

  /// 일일 호출 예산을 다 써서 멈춘 수집을 이어서 받는다.
  Future<void> resume(Session session) async {
    final job = await IngestJobs.start(session, FinancialFactsSync.kind);
    if (job == null) return;
    await run(session, job.id!);
  }
}
