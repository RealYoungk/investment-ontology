import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

void main() {
  test('printed revenue dash reason survives annual raw display without zero or prior', () {
    const reason = '2025 원문 영업수익 당기 금액 미기재(-) · 0으로 간주하지 않습니다';
    final p = FinancialPeriod(
      bsnsYear: 2025,
      reportCode: FinancialReportCode.annual,
      reportId: 3,
      rceptNo: '20260330001850',
      reportName: '사업보고서 (2025.12)',
      supersededCount: 0,
      lines: [
        FinancialLine(
          key: 'revenue',
          factId: 1,
          statement: FinancialStatementKind.comprehensiveIncome,
          accountName: 'I. 영업수익',
          unavailableReason: reason,
        ),
        FinancialLine(
          key: 'operatingIncome',
          factId: 2,
          statement: FinancialStatementKind.comprehensiveIncome,
          accountName: '영업손실',
          amount: BigInt.from(-5621738512),
        ),
      ],
    );
    final view = FinancialView(
      CompanyFinancials(
        corpCode: '01579020',
        fsDiv: FsDiv.separate,
        availableFsDivs: [FsDiv.separate],
        periods: [
          FinancialPeriod(
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportId: 2,
            rceptNo: '20250300000000',
            reportName: '사업보고서 (2024.12)',
            supersededCount: 0,
            lines: [
              FinancialLine(
                key: 'revenue',
                factId: 9,
                statement: FinancialStatementKind.comprehensiveIncome,
                accountName: '영업수익',
                amount: BigInt.from(30000000),
              ),
            ],
          ),
          p,
        ],
        filingCount: 1,
        pendingFilingCount: 0,
      ),
    );
    final point = view.annual(now: DateTime(2025)).last;
    expect(point.revenue.value, isNull);
    expect(point.revenue.missing, reason);
    expect(point.operatingIncome.value, -5621738512);
    expect(view.trailing('revenue', '매출액').value, isNull);
    expect(view.trailing('revenue', '매출액').missing, contains('미기재'));
    expect(point.revenue.value, isNot(30000000));
  });
}
