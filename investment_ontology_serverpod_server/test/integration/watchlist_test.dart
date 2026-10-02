import 'package:test/test.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/watchlist/watchlist_future_call.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Personal watchlist',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, endpoints) {
      test('enforces authentication, free limit, owner isolation and first-scan baseline', () async {
        final session = builder.build();
        addTearDown(session.close);
        final user = await const AuthUsers().create(session);
        final other = await const AuthUsers().create(session);
        final mine = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user.id.uuid,
            {},
          ),
        );
        final theirs = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            other.id.uuid,
            {},
          ),
        );
        await expectLater(endpoints.watchlist.mine(builder), throwsA(anything));
        for (var i = 1; i <= 4; i++) {
          await Company.db.insertRow(
            session,
            Company(
              corpCode: '0099000$i',
              name: 'Fixture $i',
              market: Market.kosdaq,
            ),
          );
        }
        await endpoints.watchlist.add(mine, '00990001');
        await endpoints.watchlist.add(mine, '00990001');
        await endpoints.watchlist.add(mine, '00990002');
        await endpoints.watchlist.add(mine, '00990003');
        await expectLater(
          endpoints.watchlist.add(mine, '00990004'),
          throwsA(isA<WatchlistError>()),
        );
        expect((await endpoints.watchlist.mine(mine)).companies.length, 3);
        await endpoints.watchlist.remove(theirs, '00990001');
        expect((await endpoints.watchlist.mine(mine)).companies.length, 3);
        expect((await endpoints.watchlist.mine(theirs)).companies, isEmpty);
        final now = DateTime.now().toUtc();
        final kst = now.add(const Duration(hours: 9));
        DartFilingItem filing(String receipt) => DartFilingItem(
          corpCode: '00990001',
          corpName: 'Fixture',
          stockCode: null,
          corpCls: null,
          reportName: '새 공시',
          rceptNo: receipt,
          rceptDate: DateTime.utc(kst.year, kst.month, kst.day),
        );
        var entries = await WatchlistEntry.db.find(session);
        await WatchlistEventStore.store(session, entries, [
          filing('20261001000001'),
        ], now);
        expect((await endpoints.watchlist.mine(mine)).updates, isEmpty);
        entries = await WatchlistEntry.db.find(session);
        await WatchlistEventStore.store(session, entries, [
          filing('20261001000002'),
        ], now.add(const Duration(seconds: 1)));
        await WatchlistEventStore.store(session, entries, [
          filing('20261001000002'),
        ], now.add(const Duration(seconds: 2)));
        final updates = (await endpoints.watchlist.mine(mine)).updates;
        expect(updates.length, 1);
        await endpoints.watchlist.markRead(theirs, updates.single.noticeId);
        expect(
          (await endpoints.watchlist.mine(mine)).updates.single.read,
          isFalse,
        );
        await endpoints.watchlist.markRead(mine, updates.single.noticeId);
        expect(
          (await endpoints.watchlist.mine(mine)).updates.single.read,
          isTrue,
        );
        await endpoints.watchlist.remove(mine, '00990001');
        expect((await endpoints.watchlist.mine(mine)).updates, isEmpty);
        await Company.db.insertRow(
          session,
          Company(
            corpCode: '00990005',
            name: 'Fixture 5',
            market: Market.kosdaq,
          ),
        );
        final outcomes = await Future.wait(
          ['00990004', '00990005'].map((code) async {
            try {
              await endpoints.watchlist.add(mine, code);
              return true;
            } on WatchlistError {
              return false;
            }
          }),
        );
        expect(outcomes.where((v) => v).length, 1);
        expect((await endpoints.watchlist.mine(mine)).companies.length, 3);
        final sub = await BillingSubscription.db.insertRow(
          session,
          BillingSubscription(ownerId: user.id, originUtc: now),
        );
        final payment = await BillingPaymentAttempt.db.insertRow(
          session,
          BillingPaymentAttempt(
            subscriptionId: sub.id!,
            period: 0,
            orderId: 'watchlist-order',
            idempotencyKey: 'watchlist-key',
            status: 'pending',
            paidFromUtc: now.subtract(const Duration(days: 1)),
            paidThroughUtc: now.add(const Duration(days: 1)),
          ),
        );
        expect((await endpoints.watchlist.mine(mine)).limit, 3);
        await BillingPaymentAttempt.db.updateRow(
          session,
          payment.copyWith(status: 'paid'),
        );
        expect((await endpoints.watchlist.mine(mine)).limit, 20);
        for (var i = 6; i <= 22; i++) {
          final code = '009900${i.toString().padLeft(2, '0')}';
          await Company.db.insertRow(
            session,
            Company(corpCode: code, name: 'Fixture $i', market: Market.kosdaq),
          );
          await endpoints.watchlist.add(mine, code);
        }
        expect((await endpoints.watchlist.mine(mine)).companies.length, 20);
        await expectLater(
          endpoints.watchlist.add(mine, '00990001'),
          throwsA(isA<WatchlistError>()),
        );
        await BillingPaymentAttempt.db.updateRow(
          session,
          payment.copyWith(status: 'refunded'),
        );
        final downgraded = await endpoints.watchlist.mine(mine);
        expect(downgraded.companies.length, 20);
        expect(downgraded.companies.where((c) => c.active).length, 3);
        await endpoints.watchlist.prioritize(mine, '00990022');
        expect(
          (await endpoints.watchlist.mine(mine)).companies.first.corpCode,
          '00990022',
        );
      });
    },
  );
}
