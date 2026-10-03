import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

void main() {
  test('printed revenue dash reason survives annual raw display without zero or prior', () {
    const reason = '2022 원문 영업수익 당기 금액 미기재(-) · 0으로 간주하지 않습니다';
    final p = FinancialPeriod(
      bsnsYear: 2022,
      reportCode: FinancialReportCode.annual,
      reportId: 3,
      rceptNo: '20230315000997',
      reportName: '사업보고서 (2022.12)',
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
          amount: BigInt.from(-55315450),
        ),
      ],
    );
    final view = FinancialView(
      CompanyFinancials(
        corpCode: '01601222',
        fsDiv: FsDiv.separate,
        availableFsDivs: [FsDiv.separate],
        periods: [
          FinancialPeriod(
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportId: 2,
            rceptNo: '20220300000000',
            reportName: '사업보고서 (2021.12)',
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
    final point = view.annual(now: DateTime(2022)).last;
    expect(point.revenue.value, isNull);
    expect(point.revenue.missing, reason);
    expect(point.operatingIncome.value, -55315450);
    expect(view.trailing('revenue', '매출액').value, isNull);
    expect(view.trailing('revenue', '매출액').missing, contains('미기재'));
    expect(point.revenue.value, isNot(30000000));
  });
}
