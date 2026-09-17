import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import 'financial_facts_sync.dart';
import 'ingest_jobs.dart';

class FinancialFactsFutureCall extends FutureCall {
  /// 이어받기 예약 식별자. 같은 예약이 쌓이지 않도록 하나만 둔다.
  static const resumeIdentifier = 'financial_facts_resume';

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
      scheduleResume: (at) async {
        await session.serverpod.futureCalls.cancel(resumeIdentifier);
        await session.serverpod.futureCalls
            .callAtTime(at, identifier: resumeIdentifier)
            .financialFacts
            .resume();
      },
    ).run();
  }

  /// 일일 호출 예산을 다 써서 멈춘 수집을 이어서 받는다.
  Future<void> resume(Session session) async {
    final job = await IngestJobs.start(session, FinancialFactsSync.kind);
    if (job == null) return;
    await run(session, job.id!);
  }
}
