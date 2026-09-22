import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/disclosure_values.dart';
import '../market/market_caps.dart';

/// 관계망: 기업을 가운데 두고 관계 색인(OntologyRelation)을 따라 이웃을 넓힌다.
///
/// 기업·인물 노드를 넓히고, 이름뿐인 대상(비상장·해외 법인, 제품)도 **본문에서 뽑은
/// 관계(공급·매출·경쟁·제품)에 한해** 건너간다 — 같은 공급사를 쓰는 다른 상장사가
/// 보인다. 이름은 표기를 정규화해 묶는다 ("SONY"·"Sony"는 한 노드). 주주·출자의
/// 이름뿐인 대상은 끝 노드로만 둔다 (동명이인·수백 곳 폭발).
/// 거절한 관계와 검수 전 AI 관계(draft)는 빼고, 인물 추정 연결(draft)은 점선으로 넣는다.
class GraphEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

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
    var frontierNames = <String>{};
    nodes['c${center.id}'] = (kind: 'company', depth: 0);
    var truncated = false;

    // 이름을 건너가는 관계는 본문에서 뽑아 승인한 것뿐이다 (몇백 건). 한 번 읽어 둔다.
    final byName = names
        ? await _nameRelations(session)
        : const <OntologyRelation>[];
    final seen = <int>{};

    for (var d = 1; d <= hops; d++) {
      if (frontierCompanies.isEmpty &&
          frontierPersons.isEmpty &&
          frontierNames.isEmpty) {
        break;
      }
      final fc = frontierCompanies, fp = frontierPersons, fn = frontierNames;
      final relations = fc.isEmpty && fp.isEmpty
          ? <OntologyRelation>[]
          : await OntologyRelation.db.find(
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
      // 이름 노드에서 이어지는 관계 (같은 공급사·고객사·경쟁사를 적은 다른 기업).
      for (final r in byName) {
        if (fn.contains(_nameKey(r.subjectName)) ||
            fn.contains(_nameKey(r.objectName))) {
          relations.add(r);
        }
      }
      relations.removeWhere((r) => !seen.add(r.id!));
      // 사람이 승인한 관계(공급·경쟁·제품)를 먼저 넣고, 그다음 지분율이 큰 순서.
      // 출자가 백 곳이 넘는 기업에서는 지분율만으로 줄 세우면 승인한 관계가
      // 노드 수 제한에 밀려 하나도 안 보인다.
      int rank(OntologyRelation r) =>
          r.extractedBy == RelationOrigin.ai ? 0 : 1;
      relations.sort((a, b) {
        final byKind = rank(a).compareTo(rank(b));
        if (byKind != 0) return byKind;
        return (b.weight ?? -1).compareTo(a.weight ?? -1);
      });
      final nextCompanies = <int>{}, nextPersons = <int>{};
      final nextNames = <String>{};
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
          // 본문에서 뽑은 관계의 이름만 건너간다 (주주·출자 이름은 끝 노드).
          if (key.startsWith('n') && r.extractedBy == RelationOrigin.ai) {
            nextNames.add(key);
          }
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
      frontierNames = nextNames;
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

  /// 본문에서 뽑아 승인한 관계 가운데 한쪽이 이름뿐인 것.
  static Future<List<OntologyRelation>> _nameRelations(Session session) =>
      OntologyRelation.db.find(
        session,
        where: (t) =>
            t.extractedBy.equals(RelationOrigin.ai) &
            t.status.equals(RelationStatus.verified) &
            (t.subjectCompanyId.equals(null) | t.objectCompanyId.equals(null)),
      );

  /// 이름 노드 키. 표기가 달라도("SONY"·"Sony", "영풍전자㈜"·"영풍전자") 한 노드로.
  static String _nameKey(String name) {
    final k = DisclosureValues.companyName(name);
    return 'n${k.isEmpty ? name : k}';
  }

  static String _subjectKey(OntologyRelation r) => r.subjectCompanyId != null
      ? 'c${r.subjectCompanyId}'
      : r.subjectPersonId != null
      ? 'p${r.subjectPersonId}'
      : _nameKey(r.subjectName);

  static String _objectKey(OntologyRelation r) => r.objectCompanyId != null
      ? 'c${r.objectCompanyId}'
      : _nameKey(r.objectName);

  static String _kind(String key) => switch (key[0]) {
    'c' => 'company',
    'p' => 'person',
    _ => 'name',
  };
}
