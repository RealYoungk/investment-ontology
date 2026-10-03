import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  final cases = [
    (
      '01205514',
      '20250305000164',
      2024,
      [
        '15425583523',
        '8124107688',
        '7301475835',
        '5356867177',
        '-406123410',
        '-266546846',
        '-487952845',
      ],
    ),
    (
      '00666329',
      '20250331003105',
      2024,
      [
        '44763135678',
        '31576191998',
        '13186943680',
        '18937964022',
        '-3267484986',
        '-3280066803',
        '-4499407144',
      ],
    ),
    (
      '01205514',
      '20240306000708',
      2023,
      [
        '14574281323',
        '5756258642',
        '8818022681',
        '6884433210',
        '961059995',
        '714973677',
        '-101930996',
      ],
    ),
  ];
  const keys = [
    'assets',
    'liabilities',
    'equity',
    'revenue',
    'operatingIncome',
    'netIncome',
    'operatingCashFlow',
  ];
  for (final c in cases) {
    test('${c.$2} public seven-line contract keeps PPE and FCF missing', () {
      final p = FinancialPeriod(
        bsnsYear: c.$3,
        reportCode: FinancialReportCode.annual,
        reportId: 1,
        rceptNo: c.$2,
        reportName: '사업보고서 (${c.$3}.12)',
        supersededCount: 0,
        lines: [
          for (var i = 0; i < 7; i++)
            FinancialLine(
              key: keys[i],
              factId: i + 1,
              statement: i < 3
                  ? FinancialStatementKind.balanceSheet
                  : i < 6
                  ? FinancialStatementKind.incomeStatement
                  : FinancialStatementKind.cashFlow,
              accountName: keys[i],
              amount: BigInt.parse(c.$4[i]),
            ),
        ],
      );
      final v = FinancialView(
        CompanyFinancials(
          corpCode: c.$1,
          fsDiv: FsDiv.separate,
          availableFsDivs: [FsDiv.separate],
          periods: [p],
          filingCount: 1,
          pendingFilingCount: 0,
        ),
      );
      expect(FinancialView.line(p, 'capex'), isNull);
      expect(v.trailing('capex', '유형자산의 취득').value, isNull);
      expect(v.trailing('capex', '유형자산의 취득').missing, contains('계정 없음'));
      final points = v.cashFlowAnnual(now: DateTime.utc(2026, 10, 3));
      final cash = points.singleWhere((p) => p.label == '${c.$3}');
      expect(points.singleWhere((p) => p.label == '2026 없음').free, isNull);
      expect(cash.operating, BigInt.parse(c.$4[6]).toDouble());
      expect(cash.capex, isNull);
      expect(cash.free, isNull);
      expect(
        FinancialSourceScopeNotice.messageFor(
          'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · 사업보고서 (${c.$3}.12) · 별도',
        ),
        contains('핵심계정 일부'),
      );
    });
  }
}
