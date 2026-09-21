import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// AI 관계 검수 큐: 근거 인용을 보고 승인(verified)·거절(rejected)한다.
class ReviewEndpoint extends Endpoint {
  Future<ReviewPage> list(
    Session session, {
    RelationStatus? status,
    RelationPredicate? predicate,
    int? offset,
    int? limit,
  }) async {
    Expression where(OntologyRelationTable t) {
      Expression e =
          t.extractedBy.equals(RelationOrigin.ai) &
          t.status.equals(status ?? RelationStatus.draft);
      if (predicate != null) e = e & t.predicate.equals(predicate);
      return e;
    }

    final relations = await OntologyRelation.db.find(
      session,
      where: where,
      orderByList: (t) => [t.confidence.desc(), t.id.asc()],
      offset: offset ?? 0,
      limit: (limit ?? 50).clamp(1, 200),
    );
    Future<int> count(RelationStatus s) => OntologyRelation.db.count(
      session,
      where: (t) =>
          t.extractedBy.equals(RelationOrigin.ai) & t.status.equals(s),
    );
    return ReviewPage(
      items: await _items(session, relations),
      total: await OntologyRelation.db.count(session, where: where),
      draftCount: await count(RelationStatus.draft),
      verifiedCount: await count(RelationStatus.verified),
      rejectedCount: await count(RelationStatus.rejected),
    );
  }

  /// 승인하면 verified, 거절하면 rejected. 다시 추출해도 이 결정은 유지된다.
  Future<OntologyRelation?> decide(
    Session session,
    int relationId,
    bool approve,
  ) async {
    final r = await OntologyRelation.db.findById(session, relationId);
    if (r == null || r.extractedBy != RelationOrigin.ai) return null;
    return OntologyRelation.db.updateRow(
      session,
      r.copyWith(
        status: approve ? RelationStatus.verified : RelationStatus.rejected,
        reviewedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// 기업이 주어나 목적어인 AI 관계 (거절한 것 제외).
  Future<List<ReviewItem>> forCompany(Session session, String corpCode) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return [];
    final relations = await OntologyRelation.db.find(
      session,
      where: (t) =>
          t.extractedBy.equals(RelationOrigin.ai) &
          t.status.notEquals(RelationStatus.rejected) &
          (t.subjectCompanyId.equals(company.id!) |
              t.objectCompanyId.equals(company.id!)),
      orderByList: (t) => [t.predicate.asc(), t.confidence.desc()],
    );
    return _items(session, relations);
  }

  static Future<List<ReviewItem>> _items(
    Session session,
    List<OntologyRelation> relations,
  ) async {
    final docIds = {for (final r in relations) r.factId};
    final docs = {
      for (final d in docIds.isEmpty
          ? const <BusinessDocument>[]
          : await BusinessDocument.db.find(
              session,
              where: (t) => t.id.inSet(docIds),
            ))
        d.id!: d,
    };
    final companyIds = <int>{
      for (final d in docs.values) d.companyId,
      for (final r in relations) ...[?r.subjectCompanyId, ?r.objectCompanyId],
    };
    final companies = {
      for (final c in companyIds.isEmpty
          ? const <Company>[]
          : await Company.db.find(session, where: (t) => t.id.inSet(companyIds)))
        c.id!: c,
    };
    return [
      for (final r in relations)
        if (companies[docs[r.factId]?.companyId] case final c?)
          ReviewItem(
            relation: r,
            companyCorpCode: c.corpCode,
            companyName: c.name,
            subjectCorpCode: companies[r.subjectCompanyId]?.corpCode,
            objectCorpCode: companies[r.objectCompanyId]?.corpCode,
          ),
    ];
  }
}
