import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 관계망', (sessionBuilder, endpoints) {
    late Session session;
    final ids = <String, int>{};

    Future<void> relation(
      RelationPredicate p, {
      int? subjectCompany,
      int? subjectPerson,
      String subjectName = '',
      int? objectCompany,
      String objectName = '',
      double? weight,
      RelationOrigin origin = RelationOrigin.api,
      RelationStatus status = RelationStatus.verified,
    }) => OntologyRelation.db
        .insertRow(
          session,
          OntologyRelation(
            predicate: p,
            subjectCompanyId: subjectCompany,
            subjectPersonId: subjectPerson,
            subjectName: subjectName,
            objectCompanyId: objectCompany,
            objectName: objectName,
            bsnsYear: 2025,
            weight: weight,
            factKind: RelationFactKind.shareholderEntry,
            factId: 0,
            extractedBy: origin,
            status: status,
          ),
        )
        .then((_) {});

    setUp(() async {
      session = sessionBuilder.build();
      for (final (code, name) in [
        ('A', '에이'),
        ('B', '비'),
        ('C', '씨'),
        ('D', '디'),
        ('E', '이'),
      ]) {
        ids[code] = (await Company.db.insertRow(
          session,
          Company(corpCode: code, name: name, market: Market.kospi),
        )).id!;
      }
      final person = await Person.db.insertRow(
        session,
        Person(name: '홍길동', personKey: 'cluster:홍길동:A', estimated: true),
      );
      ids['P'] = person.id!;
      // B → A (주주), A → C (출자), C → D (출자, 3단계), 홍길동 → A (추정),
      // A → 해외법인 (이름뿐), 거절한 관계와 검수 전 AI 관계는 빠진다.
      await relation(
        RelationPredicate.shareholderOf,
        subjectCompany: ids['B'],
        objectCompany: ids['A'],
        weight: 20,
      );
      await relation(
        RelationPredicate.investsIn,
        subjectCompany: ids['A'],
        objectCompany: ids['C'],
        weight: 30,
      );
      await relation(
        RelationPredicate.investsIn,
        subjectCompany: ids['C'],
        objectCompany: ids['D'],
        weight: 50,
      );
      await relation(
        RelationPredicate.shareholderOf,
        subjectPerson: ids['P'],
        subjectName: '홍길동',
        objectCompany: ids['A'],
        weight: 5,
        status: RelationStatus.draft,
      );
      await relation(
        RelationPredicate.investsIn,
        subjectCompany: ids['A'],
        objectName: 'SDMA',
        weight: 75,
      );
      await relation(
        RelationPredicate.suppliesTo,
        subjectCompany: ids['D'],
        objectCompany: ids['A'],
        origin: RelationOrigin.ai,
        status: RelationStatus.draft,
      );
      await relation(
        RelationPredicate.competesWith,
        subjectCompany: ids['A'],
        objectCompany: ids['D'],
        origin: RelationOrigin.ai,
        status: RelationStatus.rejected,
      );
    });

    test('기업을 가운데 두고 단계별로 넓히고, 주주·출자의 이름뿐인 노드는 넓히지 않는다', () async {
      final g = (await endpoints.graph.neighborhood(sessionBuilder, 'A'))!;
      final byKey = {for (final n in g.nodes) n.key: n};
      expect(g.centerKey, 'c${ids['A']}');
      expect(byKey['c${ids['B']}']!.depth, 1);
      expect(byKey['c${ids['C']}']!.depth, 1);
      expect(byKey['c${ids['D']}']!.depth, 2);
      expect(byKey['nsdma']!.kind, 'name');
      expect(byKey['nsdma']!.label, 'SDMA', reason: '표시는 관계에 적힌 이름');
      expect(byKey['p${ids['P']}']!.label, '홍길동');
      // 검수 전 AI 관계(D → A 공급)와 거절한 관계는 없다.
      expect(g.edges.where((e) => e.ai), isEmpty);
      expect(
        g.edges.firstWhere((e) => e.from == 'p${ids['P']}').estimated,
        isTrue,
      );

      final one = (await endpoints.graph.neighborhood(
        sessionBuilder,
        'A',
        depth: 1,
        includeNames: false,
      ))!;
      expect(
        {for (final n in one.nodes) n.key},
        {
          'c${ids['A']}',
          'c${ids['B']}',
          'c${ids['C']}',
          'p${ids['P']}',
        },
      );

      final small = (await endpoints.graph.neighborhood(
        sessionBuilder,
        'A',
        maxNodes: 10,
      ))!;
      expect(small.truncated, isFalse);
    });

    test('본문에서 뽑은 관계의 이름은 표기가 달라도 한 노드이고, 그 이름을 건너 다른 기업이 보인다', () async {
      // Sony → A, SONY → E (둘 다 승인한 공급 관계). E는 이름 노드를 통해서만 A와 이어진다.
      await relation(
        RelationPredicate.suppliesTo,
        subjectName: 'Sony',
        objectCompany: ids['A'],
        origin: RelationOrigin.ai,
      );
      await relation(
        RelationPredicate.suppliesTo,
        subjectName: 'SONY',
        objectCompany: ids['E'],
        origin: RelationOrigin.ai,
      );
      final g = (await endpoints.graph.neighborhood(sessionBuilder, 'A'))!;
      final byKey = {for (final n in g.nodes) n.key: n};
      expect(byKey['nsony']!.depth, 1);
      expect(byKey['nsony']!.label, 'Sony');
      expect(byKey['c${ids['E']}']!.depth, 2, reason: '같은 공급사를 쓰는 기업');
      expect(byKey.containsKey('nSONY'), isFalse, reason: '표기가 달라도 한 노드');

      // 이름을 빼면 E도 안 보인다.
      final noNames = (await endpoints.graph.neighborhood(
        sessionBuilder,
        'A',
        includeNames: false,
      ))!;
      expect({
        for (final n in noNames.nodes) n.key,
      }, isNot(contains('c${ids['E']}')));
    });
  });
}
