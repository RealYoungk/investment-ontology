import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/governance/ownership_history.dart';

DartFiling filing(int year, FinancialReportCode code, String receipt) =>
    DartFiling(
      corpCode: '1',
      rceptNo: receipt,
      reportName: '보고서',
      bsnsYear: year,
      reportCode: code,
      consolidatedStatus: FilingFetchStatus.pending,
      separateStatus: FilingFetchStatus.pending,
      attempts: 0,
      discoveredAt: DateTime.utc(2026),
    );
void main() {
  test('five consecutive annual slots and latest interim, corrections stay within period', () {
    final result = selectOwnershipFilings([
      filing(2025, FinancialReportCode.annual, '20260999'),
      filing(2023, FinancialReportCode.annual, '20240300'),
      filing(2026, FinancialReportCode.q1, '20260500'),
      filing(2026, FinancialReportCode.halfYear, '20260800'),
      filing(2025, FinancialReportCode.annual, '20260300'),
    ], '1');
    expect(result.map((f) => f.bsnsYear), [2021, 2022, 2023, 2024, 2025, 2026]);
    expect(result[3].rceptNo, isEmpty);
    expect(result[4].rceptNo, '20260999');
    expect(result.last.reportCode, FinancialReportCode.halfYear);
  });
  test('a new company with only an interim filing still appears', () {
    final result = selectOwnershipFilings([
      filing(2026, FinancialReportCode.q1, '20260500'),
    ], '1');
    expect(result.last.reportCode, FinancialReportCode.q1);
    expect(result.length, 6);
  });
  test(
    'no fabricated report for unknown company',
    () => expect(selectOwnershipFilings([], '1'), isEmpty),
  );
}
