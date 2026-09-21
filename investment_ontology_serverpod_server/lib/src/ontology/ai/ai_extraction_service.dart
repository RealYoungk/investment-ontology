import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/disclosure_links.dart';
import '../ingest/ingest_jobs.dart';
import 'anthropic_client.dart';
import 'relation_extractor.dart';

/// 사업보고서 본문을 AI로 읽어 관계 후보(draft)를 만든다.
///
/// 화면 요청 중에는 절대 부르지 않는다. API 키로 배치를 돌리거나([extract]),
/// 밖(구독 세션 등)에서 미리 뽑은 결과를 넣는다([store]).
class AiExtractionService {
  AiExtractionService(this.session, this.client);

  /// 모델을 부르지 않고 저장만 할 때.
  AiExtractionService.offline(this.session) : client = null;

  static const kind = 'ai_extraction';

  final Session session;
  final AnthropicClient? client;

  /// 기업마다 가장 최근 사업보고서 본문.
  static Future<List<BusinessDocument>> latestDocuments(Session session) async {
    final docs = await BusinessDocument.db.find(
      session,
      orderByList: (t) => [t.bsnsYear.desc(), t.id.desc()],
    );
    final latest = <int, BusinessDocument>{};
    for (final d in docs) {
      latest.putIfAbsent(d.companyId, () => d);
    }
    return latest.values.toList();
  }

  /// 문서 하나를 읽는다. 이 문서의 이전 draft는 지우고, 사람이 이미 승인·거절한 관계는 다시 만들지 않는다.
  Future<AiExtraction> extract(BusinessDocument doc) async {
    final client = this.client!;
    final company = (await Company.db.findById(session, doc.companyId))!;
    final now = DateTime.now().toUtc();
    try {
      final answer = await client.complete(
        system: RelationExtractor.system,
        user: RelationExtractor.prompt(
          company.name,
          doc.bsnsYear,
          RelationExtractor.excerpt(doc.text),
        ),
      );
      return await store(doc, RelationExtractor.parse(answer), client.model);
    } on AnthropicException catch (e) {
      return AiExtraction.db.insertRow(
        session,
        AiExtraction(
          documentId: doc.id!,
          companyId: company.id!,
          model: client.model,
          succeeded: false,
          relationCount: 0,
          droppedCount: 0,
          error: e.message,
          createdAt: now,
        ),
      );
    }
  }

  /// 뽑아 온 후보를 저장한다. 인용이 원문에 그대로 있는 것만 남기고, 이 문서의 이전
  /// draft는 지우되 사람이 이미 승인·거절한 관계는 그대로 둔다.
  Future<AiExtraction> store(
    BusinessDocument doc,
    List<ExtractedRelation> parsed,
    String model,
  ) async {
    final company = (await Company.db.findById(session, doc.companyId))!;
    final report = (await DisclosureReport.db.findById(session, doc.reportId))!;
    final listed = await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
    );
    final now = DateTime.now().toUtc();
    {
      final result = RelationExtractor.toRelations(
        parsed,
        document: doc,
        company: company,
        sourceId: report.sourceId,
        model: model,
        companiesByName: DisclosureLinks.companiesByName(listed),
        companyNames: {for (final c in listed) c.id!: c.name},
      );
      final decided = {
        for (final r in await OntologyRelation.db.find(
          session,
          where: (t) =>
              t.factKind.equals(RelationFactKind.businessDocument) &
              t.factId.equals(doc.id!) &
              t.status.notEquals(RelationStatus.draft),
        ))
          _key(r),
      };
      final fresh = [
        for (final r in result.relations)
          if (!decided.contains(_key(r))) r,
      ];
      return await session.db.transaction((tx) async {
        await OntologyRelation.db.deleteWhere(
          session,
          where: (t) =>
              t.factKind.equals(RelationFactKind.businessDocument) &
              t.factId.equals(doc.id!) &
              t.status.equals(RelationStatus.draft),
          transaction: tx,
        );
        if (fresh.isNotEmpty) {
          await OntologyRelation.db.insert(session, fresh, transaction: tx);
        }
        return AiExtraction.db.insertRow(
          session,
          AiExtraction(
            documentId: doc.id!,
            companyId: company.id!,
            model: model,
            succeeded: true,
            relationCount: fresh.length,
            droppedCount: result.dropped,
            createdAt: now,
          ),
          transaction: tx,
        );
      });
    }
  }

  static String _key(OntologyRelation r) =>
      '${r.predicate.name}|${r.subjectName}|${r.objectName}';

  /// 아직 추출하지 않은 기업의 최근 본문을 [limit]개까지 읽는다 (수집 작업으로 실행).
  Future<void> runBatch(int jobId, int limit) async {
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) return;
    var job = claimed;
    var done = 0, relations = 0, failed = 0;
    try {
      final extracted = {
        for (final e in await AiExtraction.db.find(
          session,
          where: (t) => t.succeeded.equals(true),
        ))
          e.documentId,
      };
      final targets = [
        for (final d in await latestDocuments(session))
          if (!extracted.contains(d.id)) d,
      ].take(limit).toList();
      job = await IngestJobs.save(session, job.copyWith(total: targets.length));
      for (final doc in targets) {
        if (await IngestJobs.isCancelled(session, jobId)) {
          job = job.copyWith(status: IngestStatus.cancelled);
          break;
        }
        final r = await extract(doc);
        done++;
        relations += r.relationCount;
        if (!r.succeeded) failed++;
        job = await IngestJobs.save(
          session,
          job.copyWith(processed: done, updated: relations, failed: failed),
        );
      }
      await IngestJobs.save(
        session,
        job.copyWith(
          status: job.status == IngestStatus.cancelled
              ? IngestStatus.cancelled
              : IngestStatus.succeeded,
          finishedAt: DateTime.now().toUtc(),
          message: '본문 $done건을 읽어 관계 후보 $relations건 (검수 대기), 실패 $failed건',
        ),
      );
    } catch (e, st) {
      session.log(
        'AI 관계 추출 실패',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      await IngestJobs.fail(session, jobId, '$e');
    } finally {
      client?.close();
    }
  }
}
