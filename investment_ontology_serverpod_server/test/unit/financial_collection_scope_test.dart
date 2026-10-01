import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';

DartFiling filing(
  int id,
  int year,
  FinancialReportCode code, {
  int company = 1,
  String? receipt,
  String? name,
}) => DartFiling(
  id: id,
  companyId: company,
  corpCode: '$company',
  rceptNo: receipt ?? '20260814${id.toString().padLeft(6, '0')}',
  reportName: name ?? '정기보고서',
  bsnsYear: year,
  reportCode: code,
  consolidatedStatus: FilingFetchStatus.pending,
  separateStatus: FilingFetchStatus.pending,
  discoveredAt: DateTime.utc(2026),
);

void main() {
  test('연간 5개년과 최신 반기만 선택하며 과거 중간보고서는 보존한다', () {
    final filings = [
      for (var year = 2017; year <= 2025; year++)
        filing(year, year, FinancialReportCode.annual),
      filing(1, 2025, FinancialReportCode.halfYear),
      filing(2, 2026, FinancialReportCode.q1),
      filing(3, 2026, FinancialReportCode.halfYear),
      filing(4, 2026, FinancialReportCode.halfYear, receipt: '20260901000001'),
    ];
    expect(FinancialFactsSync.financialScopeIds(filings), {
      2021,
      2022,
      2023,
      2024,
      2025,
      4,
    });
    expect(
      filings.every((f) => f.consolidatedStatus == FilingFetchStatus.pending),
      isTrue,
    );
  });
  test('리츠 같은 해 두 연간 기간을 남기고 해당 기간의 최종정정만 고른다', () {
    final reports = [
      for (var year = 2020; year <= 2025; year++) ...[
        filing(
          year * 10,
          year,
          FinancialReportCode.annual,
          name: '사업보고서 ($year.03)',
        ),
        filing(
          year * 10 + 1,
          year,
          FinancialReportCode.annual,
          name: '사업보고서 ($year.09)',
        ),
      ],
      filing(
        99,
        2025,
        FinancialReportCode.annual,
        name: '[기재정정]사업보고서 (2025.03)',
        receipt: '20260901000099',
      ),
      filing(100, 2025, FinancialReportCode.q3, name: '분기보고서 (2025.06)'),
    ];
    expect(FinancialFactsSync.financialScopeIds(reports), {
      for (var year = 2021; year <= 2024; year++) ...[year * 10, year * 10 + 1],
      99,
      20251,
    });
  });
  test('다른 결산월의 최신 연간이 있으면 이전 중간보고서는 선택하지 않는다', () {
    final filings = [
      for (var year = 2020; year <= 2026; year++)
        filing(year, year, FinancialReportCode.annual),
      filing(1, 2026, FinancialReportCode.q3),
      filing(2, 2026, FinancialReportCode.annual, receipt: '20260901000001'),
      filing(3, 2024, FinancialReportCode.halfYear, company: 2),
      filing(4, 2024, FinancialReportCode.q1, company: 2),
    ];
    expect(FinancialFactsSync.financialScopeIds(filings), {
      2022,
      2023,
      2024,
      2025,
      2,
      3,
    });
  });
}
