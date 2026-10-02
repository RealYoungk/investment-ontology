import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/bond_trends.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/bond_collection_scope.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

Map<String, dynamic> row(
  String balance, {
  String number = '제2회차',
  String? issue = '2023-01-01',
  String price = '1000',
  String unit = '원',
}) => {
  'type': 'CB',
  'series': number,
  'issueDate': issue,
  'stockKind': '보통주',
  'balance': balance,
  'unit': unit,
  'price': price,
  'shares': '10000',
  'balanceValidation': 'verified',
  'validation': 'verified',
};
Map<String, dynamic> period(
  String date,
  List<Map<String, dynamic>> entries, {
  String state = 'verified',
  String collected = 'ready',
}) => {
  'periodEnd': date,
  'receipt': '${date.replaceAll('-', '')}000001',
  'state': collected,
  'balanceStates': {'CB': state},
  'entries': entries,
};
Map<String, dynamic> result(List<Map<String, dynamic>> entries) =>
    BondTrends.build(entries);

void main() {
  test('face balance net decrease is exact; neither conversion nor redemption is invented', () {
    final data = result([
      period('2025-12-31', [row('10000000000')]),
      period('2026-06-30', [row('6000000000')]),
    ]);
    expect(data['points'].last['netDecreaseWon'], '4000000000');
    expect(data['changes'].single['unexplainedDecreaseWon'], '4000000000');
    expect(data['changes'].single['confirmedConversionWon'], isNull);
    expect(data['changes'].single['confirmedRedemptionWon'], isNull);
  });
  test(
    'price reset changing possible share count is not balance resolution',
    () {
      final a = row('1000000000'),
          b = row('1000000000', price: '500')..['shares'] = '2000000';
      final data = result([
        period('2025-12-31', [a]),
        period('2026-06-30', [b]),
      ]);
      expect(data['points'].last['netDecreaseWon'], '0');
      expect(data['changes'].single['unexplainedDecreaseWon'], isNull);
    },
  );
  test('unit conversion is exact even above double integer precision', () {
    final data = result([
      period('2025-12-31', [row('9007199254740993')]),
      period('2026-06-30', [row('9007199254740', unit: '천원')]),
    ]);
    expect(data['points'].last['netDecreaseWon'], '993');
  });
  test(
    'new issues and disappearing rows cannot be offset into company resolution',
    () {
      final data = result([
        period('2025-12-31', [row('100')]),
        period('2026-06-30', [row('50', number: '3')]),
      ]);
      expect(data['points'].last['netDecreaseWon'], isNull);
      expect(data['changes'].length, 2);
      expect(data['changes'].every((r) => r['netDecreaseWon'] == null), isTrue);
    },
  );
  test('same series with a different issue date is not the same bond', () {
    final data = result([
      period('2025-12-31', [row('100')]),
      period('2026-06-30', [row('50', issue: '2024-01-01')]),
    ]);
    expect(data['points'].last['matchedSeries'], 0);
  });
  test('unknown identity, duplicate series, foreign units and partial sources block comparisons', () {
    for (final rows in [
      [row('50', issue: null)],
      [row('50'), row('50')],
      [row('50', unit: 'USD')],
    ]) {
      final data = result([
        period('2025-12-31', [row('100')]),
        period('2026-06-30', rows),
      ]);
      expect(data['points'].last['netDecreaseWon'], isNull);
    }
    final data = result([
      period('2025-12-31', [row('100')], state: 'partial'),
      period('2026-06-30', [row('50')]),
    ]);
    expect(data['points'].first['balanceWon'], isNull);
    expect(data['changes'].single['netDecreaseWon'], isNull);
  });
  test(
    'uncollected correction produces a gap and never reuses a stale balance',
    () {
      final data = result([
        period('2024-12-31', [row('100')]),
        period('2025-12-31', [], collected: 'notCollected'),
        period('2026-06-30', [row('50')]),
      ]);
      expect(data['points'][1]['balanceWon'], isNull);
      expect(data['points'].last['netDecreaseWon'], isNull);
    },
  );
  test(
    'explicit no CB is zero total, not proof of an individual bond repayment',
    () {
      final data = result([
        period('2025-12-31', [row('100')]),
        period('2026-06-30', [], state: 'none'),
      ]);
      expect(data['points'].last['balanceWon'], '0');
      expect(data['points'].last['netDecreaseWon'], isNull);
      expect(data['changes'].single['afterWon'], isNull);
    },
  );
  test(
    'balance increase is signed and has no fabricated negative resolution',
    () {
      final data = result([
        period('2025-12-31', [row('50')]),
        period('2026-06-30', [row('100')]),
      ]);
      expect(data['points'].last['netDecreaseWon'], '-50');
      expect(data['changes'].single['unexplainedDecreaseWon'], isNull);
    },
  );
  test('headers bind face amount, issue date, and price without using accounting values', () {
    final data = CapitalStructureParser.parse(
      '''
      <p>미상환 전환사채 발행현황 (기준일: 2026.06.30) (단위: 백만원, 주)</p>
      <table><tr><th>회차</th><th>발행일자</th><th>만기일자</th><th>주식의 종류</th><th>미상환 권면총액</th><th>전환가액</th><th>전환가능주식수</th></tr>
      <tr><td>제2회차</td><td>2023.01.01</td><td>2028.01.01</td><td>보통주</td><td>6,000</td><td>1,000</td><td>6,000,000</td></tr></table>
      ''',
      receipt: '20260814000001',
      periodEnd: '2026-06-30',
      companyName: '테스트',
    );
    expect(data['balanceStates']['CB'], 'verified');
    expect(
      data['states']['CB'],
      'partial',
      reason: 'conversion ratio is absent, so shares remain unverified',
    );
    expect(data['entries'].single['issueDate'], '2023-01-01');
    expect(BondTrends.won(data['entries'].single), BigInt.from(6000000000));
  });
  test('collection selects five years, final corrections, and just one newer interim', () {
    DartFiling filing(
      int year,
      String receipt, {
      String kind = '사업보고서',
      String month = '12',
    }) => DartFiling(
      rceptNo: receipt,
      corpCode: '00000001',
      companyId: 1,
      reportName: '$kind ($year.$month)',
      bsnsYear: year,
      reportCode: kind == '사업보고서'
          ? FinancialReportCode.annual
          : FinancialReportCode.halfYear,
      consolidatedStatus: FilingFetchStatus.pending,
      separateStatus: FilingFetchStatus.pending,
      discoveredAt: DateTime.utc(2026),
    );
    final selected = BondCollectionScope.select([
      for (var y = 2016; y <= 2025; y++) filing(y, '${y + 1}0301000001'),
      filing(2025, '20260401000001'),
      filing(2025, '20250801000001', kind: '반기보고서', month: '06'),
      filing(2026, '20260501000001', kind: '분기보고서', month: '03'),
      filing(2026, '20260801000001', kind: '반기보고서', month: '06'),
    ]);
    expect(selected.length, 6);
    expect(selected.map((f) => f.reportName), [
      '사업보고서 (2021.12)',
      '사업보고서 (2022.12)',
      '사업보고서 (2023.12)',
      '사업보고서 (2024.12)',
      '사업보고서 (2025.12)',
      '반기보고서 (2026.06)',
    ]);
    expect(selected[4].rceptNo, '20260401000001');
  });
}
