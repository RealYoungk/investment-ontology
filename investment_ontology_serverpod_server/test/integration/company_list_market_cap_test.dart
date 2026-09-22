import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 기업 목록 시가총액', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asReader;
    late Session session;

    setUp(() async {
      session = sessionBuilder.build();
      final day = DateTime.utc(2026, 9, 18);
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(baseDate: day, rowCount: 2, fetchedAt: day),
      );
      final source = await Source.db.insertRow(
        session,
        Source(kind: SourceKind.dataGoKrApi, title: 't', retrievedAt: day),
      );
      var n = 0;
      for (final (name, cap) in [
        ('가나', 100),
        ('다라', null),
        ('마바', 300),
      ]) {
        n++;
        final c = await Company.db.insertRow(
          session,
          Company(corpCode: '0000000$n', name: name, market: Market.kospi),
        );
        if (cap == null) continue;
        final s = await Security.db.insertRow(
          session,
          Security(
            isinCode: 'KR70000000$n',
            shortCode: '00000$n',
            name: name,
            companyId: c.id,
            lastSeenDate: day,
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: s.id!,
            baseDate: day,
            marketCap: BigInt.from(cap),
            sourceId: source.id!,
          ),
        );
      }
    });

    test('시가총액 큰 순으로 정렬하고, 시세 없는 기업은 뒤로 보낸다', () async {
      final page = await endpoints.company.list(
        sessionBuilder,
        sort: CompanySort.marketCap,
      );
      expect(
        [for (final i in page.items) (i.name, i.marketCap?.toInt())],
        [
          ('마바', 300),
          ('가나', 100),
          ('다라', null),
        ],
      );
      final second = await endpoints.company.list(
        sessionBuilder,
        sort: CompanySort.marketCap,
        offset: 1,
        limit: 1,
      );
      expect([for (final i in second.items) i.name], ['가나']);
      final byName = await endpoints.company.list(sessionBuilder);
      expect(byName.items.first.marketCap?.toInt(), 100);
    });
  });
}
