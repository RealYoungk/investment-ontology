import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ai/ai_extraction_service.dart';
import '../ai/anthropic_client.dart';
import '../ingest/ingest_jobs.dart';
import '../ingest/ingest_schedule.dart';

/// AI 관계 추출 (4단계). Anthropic 키가 있어야 추출하고, 결과는 모두 검수 대기(draft)다.
class AiEndpoint extends Endpoint {
  Future<AiStatus> status(Session session) async {
    final latest = await AiExtractionService.latestDocuments(session);
    final latestIds = {for (final d in latest) d.id!};
    final extracted = {
      for (final e in await AiExtraction.db.find(
        session,
        where: (t) => t.succeeded.equals(true),
      ))
        if (latestIds.contains(e.documentId)) e.companyId,
    };
    Future<int> count(RelationStatus s) => OntologyRelation.db.count(
      session,
      where: (t) =>
          t.extractedBy.equals(RelationOrigin.ai) & t.status.equals(s),
    );
    return AiStatus(
      keyConfigured: AnthropicConfig.key(session) != null,
      model: AnthropicConfig.model,
      documentCompanies: latest.length,
      extractedCompanies: extracted.length,
      draftCount: await count(RelationStatus.draft),
      verifiedCount: await count(RelationStatus.verified),
      rejectedCount: await count(RelationStatus.rejected),
    );
  }

  /// 기업 하나의 가장 최근 사업보고서 본문을 바로 읽는다 (수십 초 걸린다).
  Future<AiExtraction> extractCompany(Session session, String corpCode) async {
    final key = _requireKey(session);
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    final doc = company == null
        ? null
        : await BusinessDocument.db.findFirstRow(
            session,
            where: (t) => t.companyId.equals(company.id!),
            orderByList: (t) => [t.bsnsYear.desc(), t.id.desc()],
          );
    if (doc == null) {
      throw IngestException(message: '이 기업의 사업의 내용을 아직 받지 않았습니다.');
    }
    final client = AnthropicClient(key, model: AnthropicConfig.model);
    try {
      return await AiExtractionService(session, client).extract(doc);
    } finally {
      client.close();
    }
  }

  /// 아직 읽지 않은 기업의 최근 본문을 [limit]개까지 읽는 작업을 시작한다.
  Future<IngestJob> startBatch(Session session, {int? limit}) async {
    _requireKey(session);
    final running = await IngestJobs.running(session, AiExtractionService.kind);
    if (running != null) return running;
    final job = (await IngestJobs.start(session, AiExtractionService.kind))!;
    await IngestSchedule.aiExtractionNow(
      session,
      job.id!,
      (limit ?? 20).clamp(1, 500),
    );
    return job;
  }

  static String _requireKey(Session session) {
    final key = AnthropicConfig.key(session);
    if (key == null) {
      throw IngestException(
        message: AnthropicConfig.secret.missingMessage('Anthropic API'),
      );
    }
    return key;
  }
}
