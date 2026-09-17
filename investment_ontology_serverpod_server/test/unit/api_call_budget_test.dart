import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:test/test.dart';

void main() {
  group('ApiCallBudget', () {
    test('KST 날짜로 센다', () {
      expect(
        ApiCallBudget.kstDay(DateTime.utc(2026, 9, 17, 14, 59)),
        '2026-09-17',
      );
      expect(ApiCallBudget.kstDay(DateTime.utc(2026, 9, 17, 15)), '2026-09-18');
    });

    test('다음 KST 자정', () {
      expect(
        ApiCallBudget.nextKstMidnight(DateTime.utc(2026, 9, 17, 3)),
        DateTime.utc(2026, 9, 17, 15),
      );
      expect(
        ApiCallBudget.nextKstMidnight(DateTime.utc(2026, 9, 17, 15)),
        DateTime.utc(2026, 9, 18, 15),
      );
    });
  });
}
