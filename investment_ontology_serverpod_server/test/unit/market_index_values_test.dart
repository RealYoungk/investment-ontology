import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_sync.dart';
import 'package:test/test.dart';

void main() {
  group('MarketSnapshotSync.decimal (지수 값)', () {
    test('원문 소수·선행 점·음수·빈 값', () {
      expect(MarketSnapshotSync.decimal('1131.59'), 1131.59);
      // 포털은 1 미만을 ".47"처럼 준다.
      expect(MarketSnapshotSync.decimal('.47'), 0.47);
      expect(MarketSnapshotSync.decimal('-148'), -148);
      expect(MarketSnapshotSync.decimal('3,487.21'), 3487.21);
      expect(MarketSnapshotSync.decimal(''), isNull);
      expect(MarketSnapshotSync.decimal('-'), isNull);
      expect(MarketSnapshotSync.decimal(null), isNull);
      expect(MarketSnapshotSync.decimal('abc'), isNull);
    });
  });
}
