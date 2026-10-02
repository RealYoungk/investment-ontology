import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';

DartFiling filing(
  int id,
  int year,
  FinancialReportCode code, {
  int month = 12,
  FilingFetchStatus status = FilingFetchStatus.pending,
  int attempts = 0,
}) => DartFiling(
  id: id,
  companyId: 1,
  corpCode: '00115694',
  rceptNo: id.toString().padLeft(14, '0'),
  bsnsYear: year,
  reportCode: code,
  reportName:
      '${code == FinancialReportCode.annual ? '사업' : '반기'}보고서 ($year.${month.toString().padLeft(2, '0')})',
  consolidatedStatus: status,
  separateStatus: FilingFetchStatus.noData,
  attempts: attempts,
  discoveredAt: DateTime.utc(2026),
);
void main() {
  test('only five annual years and latest interim, final correction first', () {
    final rows = [
      for (var y = 2020; y <= 2025; y++)
        filing(y, y, FinancialReportCode.annual),
      filing(3000, 2024, FinancialReportCode.halfYear, month: 6),
      filing(3001, 2026, FinancialReportCode.q1, month: 3),
      filing(3002, 2026, FinancialReportCode.halfYear, month: 6),
      filing(
        4000,
        2023,
        FinancialReportCode.annual,
        status: FilingFetchStatus.stored,
      ),
    ];
    expect(
      FinancialEndpoint.activePendingFilingCount(rows),
      5,
    ); // four annual pending + latest half.
    expect(
      rows.length,
      10,
    ); // full historical filing count remains independent.
  });
  test('active failed retry remains pending count, exhausted is excluded', () {
    expect(
      FinancialEndpoint.activePendingFilingCount([
        filing(
          1,
          2025,
          FinancialReportCode.annual,
          status: FilingFetchStatus.failed,
          attempts: 2,
        ),
      ]),
      1,
    );
    expect(
      FinancialEndpoint.activePendingFilingCount([
        filing(
          1,
          2025,
          FinancialReportCode.annual,
          status: FilingFetchStatus.failed,
          attempts: 3,
        ),
      ]),
      0,
    );
  });
  test(
    'two annual closing months in same fiscal year remain separate targets',
    () {
      expect(
        FinancialEndpoint.activePendingFilingCount([
          filing(1, 2025, FinancialReportCode.annual, month: 3),
          filing(2, 2025, FinancialReportCode.annual, month: 9),
        ]),
        2,
      );
    },
  );
}
