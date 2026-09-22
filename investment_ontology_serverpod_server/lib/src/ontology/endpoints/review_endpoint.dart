import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';

/// AI 관계 검수 큐: 근거 인용을 보고 승인(verified)·거절(rejected)한다.
///
/// 읽기(list · context · checks · facts · forCompany)는 로그인한 누구나 —
/// 사업의 내용 탭이 실측 정확도를 보여 준다. 결정·추천·기록은 관리자만.
class ReviewEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

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
    bool approve, {

    /// 누가 결정했는지. 사람이 화면에서 누르면 비워 둔다.
    String? by,
  }) async {
    OntologyAccess.requireAdmin(session);
    final r = await OntologyRelation.db.findById(session, relationId);
    if (r == null || r.extractedBy != RelationOrigin.ai) return null;
    return OntologyRelation.db.updateRow(
      session,
      r.copyWith(
        status: approve ? RelationStatus.verified : RelationStatus.rejected,
        reviewedAt: DateTime.now().toUtc(),
        reviewedBy: by,
      ),
    );
  }

  /// 여러 건을 한 번에. 원문과 대조한 결과를 넣을 때 쓴다.
  Future<int> decideMany(
    Session session,
    List<int> relationIds,
    bool approve, {
    String? by,
  }) async {
    OntologyAccess.requireAdmin(session);
    var done = 0;
    for (final id in relationIds) {
      if (await decide(session, id, approve, by: by) != null) done++;
    }
    return done;
  }

  /// 값도 여러 건을 한 번에.
  Future<int> decideFactsMany(
    Session session,
    List<int> factIds,
    bool approve, {
    String? by,
  }) async {
    OntologyAccess.requireAdmin(session);
    var done = 0;
    for (final id in factIds) {
      if (await decideFact(session, id, approve, by: by) != null) done++;
    }
    return done;
  }

  /// 근거 문장을 원문 앞뒤 [around]자와 함께 돌려준다. [scope]는 relation · fact.
  ///
  /// 사람이 원문 탭으로 옮겨 가 문장을 찾는 시간을 없앤다 — 검수에서 가장 오래 걸리는 일이다.
  Future<ReviewContext?> context(
    Session session,
    String scope,
    int id, {
    int around = 500,
  }) async {
    final String? evidence;
    final int? documentId;
    if (scope == 'fact') {
      final f = await DocumentFact.db.findById(session, id);
      evidence = f?.evidence;
      documentId = f?.documentId;
    } else {
      final r = await OntologyRelation.db.findById(session, id);
      evidence = r?.evidence;
      documentId = r?.factKind == RelationFactKind.businessDocument
          ? r?.factId
          : null;
    }
    if (evidence == null || documentId == null) return null;
    final doc = await BusinessDocument.db.findById(session, documentId);
    if (doc == null) return null;
    final text = doc.text;
    final at = text.indexOf(evidence);
    if (at < 0) {
      return ReviewContext(
        before: '',
        evidence: evidence,
        after: '',
        heading: null,
        found: false,
      );
    }
    final span = around.clamp(100, 3000);
    final start = (at - span).clamp(0, text.length);
    final end = (at + evidence.length + span).clamp(0, text.length);
    // 근거 앞에서 가장 가까운 절 제목.
    String? heading;
    for (final m in RegExp(r'^## .*$', multiLine: true).allMatches(text)) {
      if (m.start > at) break;
      heading = m.group(0)!.substring(3).trim();
    }
    return ReviewContext(
      before: text.substring(start, at),
      evidence: evidence,
      after: text.substring(at + evidence.length, end),
      heading: heading,
      found: true,
    );
  }

  /// 원문과 대조한 쪽이 사람에게 추천을 남긴다 (승인·거절과 그 이유). 결정은 바꾸지 않는다.
  Future<int> recommend(
    Session session,
    String scope,
    List<int> ids,
    RelationStatus recommendation,
    String note,
  ) async {
    OntologyAccess.requireAdmin(session);
    if (recommendation == RelationStatus.draft) return 0;
    var done = 0;
    if (scope == 'fact') {
      for (final f in await DocumentFact.db.find(
        session,
        where: (t) => t.id.inSet(ids.toSet()),
      )) {
        await DocumentFact.db.updateRow(
          session,
          f.copyWith(recommendation: recommendation, reviewNote: note),
        );
        done++;
      }
      return done;
    }
    for (final r in await OntologyRelation.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    )) {
      await OntologyRelation.db.updateRow(
        session,
        r.copyWith(recommendation: recommendation, reviewNote: note),
      );
      done++;
    }
    return done;
  }

  /// 검수 대기 중 추천이 있는 것을 추천대로 한 번에 결정한다. 사람이 누른 것이므로
  /// `reviewedBy`는 "추천대로 일괄"로 남겨 하나씩 본 것과 구분한다.
  Future<int> applyRecommended(Session session, String scope) async {
    OntologyAccess.requireAdmin(session);
    const by = '추천대로 일괄 적용';
    final now = DateTime.now().toUtc();
    var done = 0;
    if (scope == 'fact') {
      for (final f in await DocumentFact.db.find(
        session,
        where: (t) =>
            t.status.equals(RelationStatus.draft) &
            (t.recommendation.equals(RelationStatus.verified) |
                t.recommendation.equals(RelationStatus.rejected)),
      )) {
        await DocumentFact.db.updateRow(
          session,
          f.copyWith(status: f.recommendation, reviewedAt: now, reviewedBy: by),
        );
        done++;
      }
      return done;
    }
    for (final r in await OntologyRelation.db.find(
      session,
      where: (t) =>
          t.extractedBy.equals(RelationOrigin.ai) &
          t.status.equals(RelationStatus.draft) &
          (t.recommendation.equals(RelationStatus.verified) |
              t.recommendation.equals(RelationStatus.rejected)),
    )) {
      await OntologyRelation.db.updateRow(
        session,
        r.copyWith(status: r.recommendation, reviewedAt: now, reviewedBy: by),
      );
      done++;
    }
    return done;
  }

  /// 대조 검수 기록을 남긴다 (정확률을 숫자로).
  Future<ReviewCheck> recordCheck(
    Session session,
    String scope,
    int checked,
    int correct,
    int leftToPerson,
    String checkedBy, {
    String? note,
  }) async {
    OntologyAccess.requireAdmin(session);
    return ReviewCheck.db.insertRow(
      session,
      ReviewCheck(
        scope: scope,
        checked: checked,
        correct: correct,
        leftToPerson: leftToPerson,
        checkedBy: checkedBy,
        note: note,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// 남겨 둔 대조 검수 기록 (최근 것부터).
  Future<List<ReviewCheck>> checks(Session session) => ReviewCheck.db.find(
    session,
    orderBy: (t) => t.createdAt.desc(),
    limit: 20,
  );

  /// 본문에서 뽑은 값 검수 목록 (수주잔고·가동률·점유율 등).
  Future<FactPage> facts(
    Session session, {
    RelationStatus? status,
    DocumentFactKind? kind,
    int? offset,
    int? limit,
  }) async {
    Expression where(DocumentFactTable t) {
      Expression e = t.status.equals(status ?? RelationStatus.draft);
      if (kind != null) e = e & t.kind.equals(kind);
      return e;
    }

    final rows = await DocumentFact.db.find(
      session,
      where: where,
      orderByList: (t) => [t.companyId.asc(), t.kind.asc(), t.id.asc()],
      offset: offset ?? 0,
      limit: (limit ?? 50).clamp(1, 200),
    );
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final f in rows) f.companyId}),
      ))
        c.id!: c,
    };
    Future<int> count(RelationStatus s) =>
        DocumentFact.db.count(session, where: (t) => t.status.equals(s));
    return FactPage(
      items: [
        for (final f in rows)
          if (companies[f.companyId] case final c?)
            FactItem(fact: f, corpCode: c.corpCode, companyName: c.name),
      ],
      total: await DocumentFact.db.count(session, where: where),
      draftCount: await count(RelationStatus.draft),
      verifiedCount: await count(RelationStatus.verified),
      rejectedCount: await count(RelationStatus.rejected),
    );
  }

  /// 값 하나를 승인·거절한다.
  Future<DocumentFact?> decideFact(
    Session session,
    int factId,
    bool approve, {
    String? by,
  }) async {
    OntologyAccess.requireAdmin(session);
    final f = await DocumentFact.db.findById(session, factId);
    if (f == null) return null;
    return DocumentFact.db.updateRow(
      session,
      f.copyWith(
        status: approve ? RelationStatus.verified : RelationStatus.rejected,
        reviewedAt: DateTime.now().toUtc(),
        reviewedBy: by,
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
      for (final d
          in docIds.isEmpty
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
      for (final c
          in companyIds.isEmpty
              ? const <Company>[]
              : await Company.db.find(
                  session,
                  where: (t) => t.id.inSet(companyIds),
                ))
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
