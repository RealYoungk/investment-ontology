import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ApiCallBudget', (sessionBuilder, endpoints) {
    late Session session;
    final now = DateTime.utc(2026, 9, 17, 3);

    setUp(() => session = sessionBuilder.build());

    test('같은 날 호출 수는 더해지고, 제공자·날짜별로 따로 센다', () async {
      await ApiCallBudget.record(session, ApiProvider.dart, 10, now: now);
      await ApiCallBudget.record(session, ApiProvider.dart, 5, now: now);
      await ApiCallBudget.record(session, ApiProvider.dataGoKr, 3, now: now);
      await ApiCallBudget.record(
        session,
        ApiProvider.dart,
        7,
        now: now.add(const Duration(days: 1)),
      );

      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dart, now: now),
        15,
      );
      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dataGoKr, now: now),
        3,
      );
    });

    test('KST 자정에 전날 소진한 예산이 다음 날로 넘어가지 않는다', () async {
      final before = DateTime.utc(2026, 9, 22, 14, 59, 59);
      final after = DateTime.utc(2026, 9, 22, 15);
      await ApiCallBudget.record(
        session,
        ApiProvider.dart,
        ApiCallBudget.dartFinancialBudget,
        now: before,
      );
      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dart, now: before),
        ApiCallBudget.dartFinancialBudget,
      );
      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dart, now: after),
        0,
      );
      await ApiCallBudget.record(session, ApiProvider.dart, 1, now: after);
      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dart, now: after),
        1,
      );
      expect(
        await ApiCallBudget.usedToday(session, ApiProvider.dart, now: before),
        ApiCallBudget.dartFinancialBudget,
      );
    });

    test('ApiCallMeter는 늘어난 만큼만 기록한다', () async {
      var calls = 0;
      final meter = ApiCallMeter(ApiProvider.dart, () => calls);
      calls = 4;
      await meter.flush(session);
      calls = 6;
      await meter.flush(session);
      await meter.flush(session);

      expect(await ApiCallBudget.usedToday(session, ApiProvider.dart), 6);
    });
  });
}
