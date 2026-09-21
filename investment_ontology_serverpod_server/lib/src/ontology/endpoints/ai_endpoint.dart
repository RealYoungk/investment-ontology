import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ai/ai_extraction_service.dart';
import '../ai/anthropic_client.dart';
import '../ai/relation_extractor.dart';
import '../ingest/ingest_jobs.dart';
import '../ingest/ingest_hooks.dart';

/// AI 관계 추출 (4단계).
///
/// 화면 요청 중에는 모델을 부르지 않는다. 미리 뽑아 저장해 두고 화면은 저장된 것만 읽는다.
/// 뽑는 방법은 둘이다. (1) Anthropic 키로 배치 실행, (2) 밖(구독 세션 등)에서 본문을 읽고
/// [submit]으로 결과를 넣기. 어느 쪽이든 결과는 검수 대기(draft)이고, 인용이 원문에 그대로
/// 있는 후보만 남는다.
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
    await IngestHooks.require(
      IngestHooks.aiExtractionNow,
      'aiExtractionNow',
    )(
      session,
      job.id!,
      (limit ?? 20).clamp(1, 500),
    );
    return job;
  }

  /// 아직 읽지 않은 기업의 최근 본문 목록. 밖에서 미리 뽑을 때 이 순서로 고른다
  /// (본문이 짧은 것부터 — 한 번에 읽기 좋다).
  Future<List<BusinessDocumentRef>> pending(
    Session session, {
    int? limit,
  }) async {
    final docs = await AiExtractionService.latestDocuments(session);
    final done = {
      for (final e in await AiExtraction.db.find(
        session,
        where: (t) => t.succeeded.equals(true),
      ))
        e.documentId,
    };
    final todo = [
      for (final d in docs)
        if (!done.contains(d.id)) d,
    ]..sort((a, b) => a.text.length.compareTo(b.text.length));
    final companies = {
      for (final c in await Company.db.find(session)) c.id!: c,
    };
    return [
      for (final d in todo.take((limit ?? 20).clamp(1, 200)))
        if (companies[d.companyId] case final c?)
          BusinessDocumentRef(
            documentId: d.id!,
            corpCode: c.corpCode,
            companyName: c.name,
            bsnsYear: d.bsnsYear,
            chars: d.text.length,
          ),
    ];
  }

  /// 본문 발췌 (모델에 넣는 것과 같은 범위).
  Future<String> documentText(Session session, int documentId) async {
    final doc = await BusinessDocument.db.findById(session, documentId);
    if (doc == null) {
      throw IngestException(message: '본문을 찾을 수 없습니다: $documentId');
    }
    return RelationExtractor.excerpt(doc.text);
  }

  /// 밖에서 뽑은 결과를 저장한다. [answer]는 배치 실행과 같은 JSON 형식이다.
  ///
  /// 인용이 원문에 그대로 없으면 그 후보는 버린다. 키가 없어도 된다.
  Future<AiExtraction> submit(
    Session session,
    int documentId,
    String answer, {
    String? model,
  }) async {
    final doc = await BusinessDocument.db.findById(session, documentId);
    if (doc == null) {
      throw IngestException(message: '본문을 찾을 수 없습니다: $documentId');
    }
    final parsed = RelationExtractor.parse(answer);
    return AiExtractionService.offline(session).store(
      doc,
      parsed,
      (model ?? 'claude-code').trim(),
    );
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
