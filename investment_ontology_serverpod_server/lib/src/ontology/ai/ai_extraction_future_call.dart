import 'package:serverpod/serverpod.dart';

import '../ingest/ingest_jobs.dart';
import 'ai_extraction_service.dart';
import 'anthropic_client.dart';

/// AI 관계 추출 일괄 실행. (이 파일은 IngestSchedule을 가져오지 않는다 — IngestHooks 참고.)
class AiExtractionFutureCall extends FutureCall {
  Future<void> run(Session session, int jobId, int limit) async {
    final key = AnthropicConfig.key(session);
    if (key == null) {
      await IngestJobs.fail(
        session,
        jobId,
        AnthropicConfig.secret.missingMessage('Anthropic API'),
      );
      return;
    }
    await AiExtractionService(
      session,
      AnthropicClient(key, model: AnthropicConfig.model),
    ).runBatch(jobId, limit);
  }
}
