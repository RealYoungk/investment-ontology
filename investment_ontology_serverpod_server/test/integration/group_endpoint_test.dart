import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 지분으로 이어진 상장사', (sessionBuilder, endpoints) {
    late Session session;
    late Map<String, int> ids;

    setUp(() async {
      session = sessionBuilder.build();
      final now = DateTime.utc(2026, 9, 19);
      final source = await Source.db.insertRow(
        session,
        Source(kind: SourceKind.dartApi, title: 't', retrievedAt: now),
      );
      ids = {};
      var n = 0;
      for (final name in ['지주', '자회사', '손자회사', '남남']) {
        n++;
        ids[name] = (await Company.db.insertRow(
          session,
          Company(
            corpCode: '0000000$n',
            name: name,
            stockCode: '00000$n',
            market: Market.kospi,
          ),
        )).id!;
      }
      final owner = await Person.db.insertRow(
        session,
        Person(name: '홍길동', personKey: 'p:홍길동', estimated: true),
      );

      var rcept = 0;
      Future<int> report(String company, DartSection section, int year) async =>
          (await DisclosureReport.db.insertRow(
            session,
            DisclosureReport(
              companyId: ids[company]!,
              section: section,
              rceptNo: '${++rcept}',
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              rowCount: 1,
              sourceId: source.id!,
              fetchedAt: now,
            ),
          )).id!;

      Future<void> holder(
        String company,
        int reportId, {
        int? holderCompanyId,
        int? personId,
        double ratio = 30,
        int year = 2025,
      }) => ShareholderEntry.db.insertRow(
        session,
        ShareholderEntry(
          reportId: reportId,
          companyId: ids[company]!,
          bsnsYear: year,
          ord: 1,
          holderName: 'x',
          ratioEnd: ratio,
          isTotal: false,
          holderCompanyId: holderCompanyId,
          holderPersonId: personId,
        ),
      );

      // 지주 → 자회사 (주주 명단), 자회사 → 손자회사 (경영참여 출자 40%).
      final sub = await report('자회사', DartSection.largestShareholders, 2025);
      await holder('자회사', sub, holderCompanyId: ids['지주']);
      // 같은 주주의 우선주 행과 자기주식 행은 연결을 늘리지 않는다.
      await holder('자회사', sub, holderCompanyId: ids['지주'], ratio: 3);
      await holder('자회사', sub, holderCompanyId: ids['자회사'], ratio: 1);
      await holder('자회사', sub, personId: owner.id);
      final parent = await report('지주', DartSection.largestShareholders, 2025);
      await holder('지주', parent, personId: owner.id);
      final inv = await report('자회사', DartSection.investments, 2025);
      await InvestmentEntry.db.insertRow(
        session,
        InvestmentEntry(
          reportId: inv,
          companyId: ids['자회사']!,
          bsnsYear: 2025,
          ord: 1,
          investeeName: '손자회사',
          purpose: '경영참여',
          ratioEnd: 40,
          isTotal: false,
          investeeCompanyId: ids['손자회사'],
        ),
      );
      // 옛 보고서에서만 이어진 기업은 묶지 않는다 (가장 최근 보고서 기준).
      final old = await report('남남', DartSection.largestShareholders, 2023);
      await holder('남남', old, holderCompanyId: ids['지주'], year: 2023);
      final latest = await report('남남', DartSection.largestShareholders, 2025);
      await holder('남남', latest, personId: null, ratio: 5);
    });

    test('지분 연결로 묶고, 여러 기업의 주주인 인물을 보인다', () async {
      final groups = await endpoints.group.list(sessionBuilder);
      expect(groups, hasLength(1));
      final g = groups.single;
      expect(
        {for (final m in g.members) m.company.name},
        {'지주', '자회사', '손자회사'},
      );
      expect(g.edges, hasLength(2));
      expect(
        g.edges
            .singleWhere((e) => e.predicate == RelationPredicate.shareholderOf)
            .ratio,
        30,
      );
      expect(
        g.edges.map((e) => e.predicate),
        containsAll([
          RelationPredicate.shareholderOf,
          RelationPredicate.investsIn,
        ]),
      );
      expect(g.sharedPersons.single.name, '홍길동');
      expect(g.sharedPersons.single.companyCount, 2);
    });

    test('기업이 속한 묶음을 찾고, 없으면 null', () async {
      final g = await endpoints.group.of(sessionBuilder, '00000003');
      expect(g, isNotNull);
      expect(await endpoints.group.of(sessionBuilder, '00000004'), isNull);
    });
  });
}
