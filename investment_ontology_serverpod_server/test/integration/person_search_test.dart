import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 관계가 있는 인물', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asReader;
    late Session session;

    setUp(() async {
      session = sessionBuilder.build();
      final a = await Company.db.insertRow(
        session,
        Company(corpCode: '00000001', name: '가나'),
      );
      final b = await Company.db.insertRow(
        session,
        Company(corpCode: '00000002', name: '다라'),
      );
      Future<Person> person(String name, String key) => Person.db.insertRow(
        session,
        Person(name: name, personKey: key, estimated: false),
      );
      final many = await person('홍길동', 'p1');
      final one = await person('홍길순', 'p2');
      await person('홍길남', 'p3'); // 관계 없음 → 나오지 않는다
      var fact = 0;
      Future<void> relate(Person p, Company c) => OntologyRelation.db.insertRow(
        session,
        OntologyRelation(
          predicate: RelationPredicate.shareholderOf,
          subjectPersonId: p.id,
          subjectName: p.name,
          objectCompanyId: c.id,
          objectName: c.name,
          bsnsYear: 2025,
          factKind: RelationFactKind.shareholderEntry,
          factId: ++fact,
          extractedBy: RelationOrigin.api,
          status: RelationStatus.verified,
        ),
      );
      await relate(many, a);
      await relate(many, b);
      await relate(one, a);
    });

    test('이름 앞부분으로 찾고, 이어진 기업이 많은 순서', () async {
      final hits = await endpoints.governance.searchPersons(
        sessionBuilder,
        '홍길',
      );
      expect([for (final h in hits) h.name], ['홍길동', '홍길순']);
      expect(hits.first.companyCount, 2);
      expect(hits.first.companyNames, ['가나', '다라']);
    });

    test('한 글자는 찾지 않는다', () async {
      expect(
        await endpoints.governance.searchPersons(sessionBuilder, '홍'),
        isEmpty,
      );
    });
  });
}
