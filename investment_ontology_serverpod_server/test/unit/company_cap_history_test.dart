import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/market/company_cap_history.dart';
import 'package:test/test.dart';

void main() {
  final jan = DateTime.utc(2025, 1, 31), feb = DateTime.utc(2025, 2, 28);
  Security security(int id) => Security(
    id: id,
    isinCode: '$id',
    shortCode: '$id',
    name: '$id',
    lastSeenDate: feb,
  );
  MarketSnapshot quote(int id, DateTime date, int cap) => MarketSnapshot(
    securityId: id,
    baseDate: date,
    marketCap: BigInt.from(cap),
    sourceId: 1,
  );
  test('월말 보통주와 우선주 합산, 한 종목이 사라지면 합계 미확보', () {
    final rows = CompanyCapHistory.build(
      marketDates: [feb, jan],
      securities: [security(1), security(2)],
      snapshots: [quote(1, jan, 100), quote(2, jan, 20), quote(1, feb, 120)],
      coverage: {1: (jan, feb), 2: (jan, jan)},
    );
    expect(rows.first.marketCap, BigInt.from(120));
    expect(rows.last.marketCap, isNull);
    expect(rows.last.securities.length, 2);
  });
  test('미래 신규 종목을 이전 달에 요구하지 않고 누락 월도 유지', () {
    final mar = DateTime.utc(2025, 3, 31);
    final rows = CompanyCapHistory.build(
      marketDates: [jan, feb, mar],
      securities: [security(1), security(2)],
      snapshots: [quote(1, jan, 100), quote(1, mar, 200), quote(2, mar, 30)],
      coverage: {1: (jan, mar), 2: (mar, mar)},
    );
    expect(rows.map((r) => r.marketCap), [
      BigInt.from(100),
      null,
      BigInt.from(230),
    ]);
  });
  test('시장 장부에 월 전체가 없어도 빈 달을 건너뛰지 않는다', () {
    final mar = DateTime.utc(2025, 3, 31);
    final rows = CompanyCapHistory.build(
      marketDates: [jan, mar],
      securities: [security(1)],
      snapshots: [quote(1, jan, 100), quote(1, mar, 200)],
      coverage: {1: (jan, mar)},
    );
    expect(rows.map((r) => r.baseDate), [jan, feb, mar]);
    expect(rows[1].marketCap, isNull);
  });
}
