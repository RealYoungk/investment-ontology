import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/market_caps.dart';

/// 관계망: 기업을 가운데 두고 관계 색인(OntologyRelation)을 따라 이웃을 넓힌다.
///
/// 넓히는 것은 기업·인물 노드만이고, 이름뿐인 대상(비상장·해외 법인, 제품)은 끝 노드로만 둔다.
/// 거절한 관계와 검수 전 AI 관계(draft)는 빼고, 인물 추정 연결(draft)은 점선으로 넣는다.
class GraphEndpoint extends Endpoint {
  static const maxDepth = 3;

  Future<CompanyGraph?> neighborhood(
    Session session,
    String corpCode, {
    int? depth,
    int? maxNodes,
    bool? includeNames,
  }) async {
    final center = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (center == null) return null;
    final limit = (maxNodes ?? 80).clamp(10, 300);
    final hops = (depth ?? 2).clamp(1, maxDepth);
    final names = includeNames ?? true;

    final nodes = <String, ({String kind, int depth})>{};
    final edges = <String, ({String from, String to, OntologyRelation r})>{};
    var frontierCompanies = <int>{center.id!};
    var frontierPersons = <int>{};
    nodes['c${center.id}'] = (kind: 'company', depth: 0);
    var truncated = false;

    for (var d = 1; d <= hops; d++) {
      if (frontierCompanies.isEmpty && frontierPersons.isEmpty) break;
      final fc = frontierCompanies, fp = frontierPersons;
      final relations = await OntologyRelation.db.find(
        session,
        where: (t) {
          Expression reach = Constant.bool(false);
          if (fc.isNotEmpty) {
            reach =
                reach |
                t.subjectCompanyId.inSet(fc) |
                t.objectCompanyId.inSet(fc);
          }
          if (fp.isNotEmpty) reach = reach | t.subjectPersonId.inSet(fp);
          return reach &
              t.status.notEquals(RelationStatus.rejected) &
              (t.extractedBy.equals(RelationOrigin.api) |
                  t.status.equals(RelationStatus.verified));
        },
        orderByList: (t) => [t.weight.desc()],
      );
      // 지분율이 큰 관계부터 넣어, 잘릴 때 약한 관계가 빠지게 한다.
      relations.sort((a, b) => (b.weight ?? -1).compareTo(a.weight ?? -1));
      final nextCompanies = <int>{}, nextPersons = <int>{};
      for (final r in relations) {
        final from = _subjectKey(r), to = _objectKey(r);
        if (!names && (from.startsWith('n') || to.startsWith('n'))) continue;
        for (final key in [from, to]) {
          if (nodes.containsKey(key)) continue;
          if (nodes.length >= limit) {
            truncated = true;
            continue;
          }
          nodes[key] = (kind: _kind(key), depth: d);
          if (key.startsWith('c')) {
            nextCompanies.add(int.parse(key.substring(1)));
          }
          if (key.startsWith('p')) nextPersons.add(int.parse(key.substring(1)));
        }
        if (nodes.containsKey(from) && nodes.containsKey(to)) {
          edges['${r.predicate.name}\u0000$from\u0000$to'] ??= (
            from: from,
            to: to,
            r: r,
          );
        }
      }
      frontierCompanies = nextCompanies;
      frontierPersons = nextPersons;
    }

    final companyIds = {
      for (final k in nodes.keys)
        if (k.startsWith('c')) int.parse(k.substring(1)),
    };
    final personIds = {
      for (final k in nodes.keys)
        if (k.startsWith('p')) int.parse(k.substring(1)),
    };
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) => t.id.inSet(companyIds),
      ))
        c.id!: c,
    };
    final persons = {
      for (final p
          in personIds.isEmpty
              ? const <Person>[]
              : await Person.db.find(
                  session,
                  where: (t) => t.id.inSet(personIds),
                ))
        p.id!: p,
    };
    final caps = await MarketCaps.latest(session, companyIds);
    // 이름뿐인 노드의 표시 이름은 관계에 적힌 이름이다.
    final labels = <String, String>{};
    for (final e in edges.values) {
      labels[e.from] ??= e.r.subjectName;
      labels[e.to] ??= e.r.objectName;
    }

    return CompanyGraph(
      centerKey: 'c${center.id}',
      truncated: truncated,
      nodes: [
        for (final MapEntry(key: key, value: n) in nodes.entries)
          GraphNode(
            key: key,
            kind: n.kind,
            depth: n.depth,
            label: switch (n.kind) {
              'company' => companies[int.parse(key.substring(1))]?.name ?? key,
              'person' => persons[int.parse(key.substring(1))]?.name ?? key,
              _ => labels[key] ?? key.substring(1),
            },
            corpCode: n.kind == 'company'
                ? companies[int.parse(key.substring(1))]?.corpCode
                : null,
            personId: n.kind == 'person' ? int.parse(key.substring(1)) : null,
            marketCap: n.kind == 'company'
                ? caps.caps[int.parse(key.substring(1))]
                : null,
          ),
      ],
      edges: [
        for (final e in edges.values)
          GraphEdge(
            from: e.from,
            to: e.to,
            predicate: e.r.predicate,
            weight: e.r.weight,
            estimated:
                e.r.extractedBy == RelationOrigin.api &&
                e.r.status == RelationStatus.draft,
            ai: e.r.extractedBy == RelationOrigin.ai,
          ),
      ],
    );
  }

  static String _subjectKey(OntologyRelation r) => r.subjectCompanyId != null
      ? 'c${r.subjectCompanyId}'
      : r.subjectPersonId != null
      ? 'p${r.subjectPersonId}'
      : 'n${r.subjectName}';

  static String _objectKey(OntologyRelation r) =>
      r.objectCompanyId != null ? 'c${r.objectCompanyId}' : 'n${r.objectName}';

  static String _kind(String key) => switch (key[0]) {
    'c' => 'company',
    'p' => 'person',
    _ => 'name',
  };
}
