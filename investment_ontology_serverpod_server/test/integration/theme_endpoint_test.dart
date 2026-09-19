import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 테마', (sessionBuilder, endpoints) {
    late Session session;
    final ids = <String, int>{};

    setUp(() async {
      session = sessionBuilder.build();
      for (final (corp, name) in [
        ('00000001', '(주)배터리'),
        ('00000002', '(주)소재'),
      ]) {
        ids[corp] = (await Company.db.insertRow(
          session,
          Company(corpCode: corp, name: name, market: Market.kosdaq),
        )).id!;
      }
      // 시세: 배터리 300억(보통주+우선주), 소재 100억.
      final day = DateTime.utc(2026, 9, 18);
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(baseDate: day, rowCount: 3, fetchedAt: day),
      );
      var n = 0;
      for (final (corp, cap) in [
        ('00000001', 20000000000),
        ('00000001', 10000000000),
        ('00000002', 10000000000),
      ]) {
        n++;
        final sec = await Security.db.insertRow(
          session,
          Security(
            isinCode: 'KR700000000$n',
            shortCode: '00000$n',
            name: 'S$n',
            companyId: ids[corp],
            lastSeenDate: day,
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: sec.id!,
            baseDate: day,
            marketCap: BigInt.from(cap),
            sourceId: (await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dataGoKrApi,
                title: 't',
                retrievedAt: day,
              ),
            )).id!,
          ),
        );
      }
    });

    test('테마를 만들고 기업을 넣으면 출처(manual)와 시가총액이 함께 나온다', () async {
      final theme = await endpoints.theme.create(
        sessionBuilder,
        ' 2차전지 ',
        description: '양극재·음극재',
      );
      expect(theme.name, '2차전지');
      // 같은 이름은 새로 만들지 않는다.
      expect(
        (await endpoints.theme.create(sessionBuilder, '2차전지')).id,
        theme.id,
      );

      await endpoints.theme.addCompany(
        sessionBuilder,
        theme.id!,
        '00000002',
        note: '음극재',
      );
      final member = (await endpoints.theme.addCompany(
        sessionBuilder,
        theme.id!,
        '00000001',
      ))!;
      final source = (await Source.db.findById(session, member.sourceId))!;
      expect(source.kind, SourceKind.manual);

      final detail = (await endpoints.theme.detail(
        sessionBuilder,
        theme.id!,
      ))!;
      expect(
        [for (final m in detail.members) (m.company.corpCode, m.marketCap)],
        [
          ('00000001', BigInt.from(30000000000)),
          ('00000002', BigInt.from(10000000000)),
        ],
      );
      expect(detail.members.last.member.note, '음극재');

      final list = await endpoints.theme.list(sessionBuilder);
      expect(list.single.memberCount, 2);
      expect(list.single.marketCap, BigInt.from(40000000000));
      expect(list.single.topNames, ['(주)배터리', '(주)소재']);

      expect(
        [
          for (final t in await endpoints.theme.themesOf(
            sessionBuilder,
            '00000001',
          ))
            t.name,
        ],
        ['2차전지'],
      );
      await endpoints.theme.removeCompany(
        sessionBuilder,
        theme.id!,
        '00000001',
      );
      expect(
        (await endpoints.theme.detail(sessionBuilder, theme.id!))!.members,
        hasLength(1),
      );
      await endpoints.theme.delete(sessionBuilder, theme.id!);
      expect(await endpoints.theme.list(sessionBuilder), isEmpty);
    });
  });
}
