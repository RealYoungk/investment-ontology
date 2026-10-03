import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_breakdown_panel.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/valuation_history.dart';

DocumentFact fact(DocumentFactKind kind, double value) => DocumentFact(
  companyId: 1,
  documentId: 1,
  bsnsYear: 2025,
  kind: kind,
  label: '사업 A · 별도',
  value: value,
  unit: '억원',
  asOf: DateTime.utc(2025, 12, 31),
  evidence: '같은 원문 표',
  extractedBy: RelationOrigin.api,
  status: RelationStatus.verified,
  createdAt: DateTime.utc(2026),
);

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('수익성·지역 매출 기간 선택과 근거 펼침 ($width)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rows = [
        fact(DocumentFactKind.segmentOperatingProfit, -10),
        fact(DocumentFactKind.segmentOperatingRevenue, 100),
        fact(
          DocumentFactKind.geographicRevenue,
          60,
        ).copyWith(label: '내수 · 국내 · 별도'),
        fact(
          DocumentFactKind.geographicRevenue,
          40,
        ).copyWith(label: '수출 · 미주 · 별도'),
      ];
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessBreakdownPanel(
                  facts: [
                    ...rows,
                    for (final f in rows)
                      f.copyWith(
                        documentId: 2,
                        bsnsYear: 2024,
                        asOf: DateTime.utc(2024, 12, 31),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('이익률 -10.0%'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
      expect(find.text('수출 비중 40.0% · 내수 60.0%'), findsOneWidget);
      await tester.tap(find.byType(ShadSelect<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2024년').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('연간 추이와 공시 근거'));
      await tester.tap(find.text('연간 추이와 공시 근거'));
      await tester.pumpAndSettle();
      expect(find.text('같은 원문 표'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('같은 표·기간·단위의 매출만 분모로 사용하고 손실률 보존', () {
    final profit = fact(DocumentFactKind.segmentOperatingProfit, -10);
    final revenue = fact(DocumentFactKind.segmentOperatingRevenue, 100);
    expect(segmentMargin(profit, [revenue]), -10);
    expect(segmentMargin(profit, [revenue.copyWith(unit: '백만원')]), isNull);
    expect(segmentMargin(profit, [revenue.copyWith(documentId: 2)]), isNull);
    expect(segmentMargin(profit, [revenue.copyWith(evidence: '다른 표')]), isNull);
    expect(
      segmentMargin(profit, [
        revenue.copyWith(asOf: DateTime.utc(2024, 12, 31)),
      ]),
      isNull,
    );
    expect(segmentMargin(profit, [revenue.copyWith(value: 0)]), isNull);
  });
  CompanyFinancials data(
    DateTime received, {
    int income = 100,
    int capex = 10,
  }) => CompanyFinancials(
    corpCode: '001',
    fsDiv: FsDiv.separate,
    availableFsDivs: [FsDiv.separate],
    filingCount: 1,
    pendingFilingCount: 0,
    periods: [
      FinancialPeriod(
        bsnsYear: 2025,
        reportCode: FinancialReportCode.annual,
        reportId: 1,
        rceptNo: '20260301000001',
        reportName: '사업보고서 (2025.12)',
        receivedDate: received,
        supersededCount: 0,
        lines: [
          for (final entry in {
            'revenue': 1000,
            'operatingIncome': 200,
            'netIncome': income,
            'equity': 500,
            'assets': 1000,
            'operatingCashFlow': 50,
            'capex': capex,
          }.entries)
            FinancialLine(
              key: entry.key,
              factId: 1,
              accountName: entry.key,
              statement: {'operatingCashFlow', 'capex'}.contains(entry.key)
                  ? FinancialStatementKind.cashFlow
                  : {'equity', 'assets'}.contains(entry.key)
                  ? FinancialStatementKind.balanceSheet
                  : FinancialStatementKind.incomeStatement,
              amount: BigInt.from(entry.value * 100000000),
              currency: 'KRW',
            ),
        ],
      ),
    ],
  );
  final cap = CompanyMarketCap(
    baseDate: DateTime.utc(2026, 3, 31),
    marketCap: BigInt.from(200000000000),
    securities: [],
  );
  test('월별 배수의 분모·공시 접수일·적자·FCF 검증', () {
    final financials = data(DateTime.utc(2026, 3, 1));
    expect(historicalMultiple(financials, cap, 'per').value, 20);
    expect(historicalMultiple(financials, cap, 'pbr').value, 4);
    expect(historicalMultiple(financials, cap, 'psr').value, 2);
    expect(historicalMultiple(financials, cap, 'por').value, 10);
    expect(historicalMultiple(financials, cap, 'pfcf').value, 50);
    expect(
      historicalMultiple(data(DateTime.utc(2026, 4, 1)), cap, 'per').value,
      isNull,
    );
    expect(historicalMultiple(data(cap.baseDate), cap, 'per').value, isNull);
    expect(
      historicalMultiple(
        data(DateTime.utc(2026, 3, 1), income: -100),
        cap,
        'per',
      ).value,
      isNull,
    );
    expect(
      historicalMultiple(
        data(DateTime.utc(2026, 3, 1), capex: 60),
        cap,
        'pfcf',
      ).value,
      isNull,
    );
  });
  test('미확보 시총과 너무 오래된 재무는 빈값', () {
    expect(
      historicalMultiple(
        data(DateTime.utc(2026, 3, 1)),
        CompanyMarketCap(baseDate: cap.baseDate, securities: []),
        'per',
      ).value,
      isNull,
    );
    expect(
      historicalMultiple(
        data(DateTime.utc(2026, 3, 1)),
        cap.copyWith(baseDate: DateTime.utc(2028, 3, 31)),
        'per',
      ).value,
      isNull,
    );
  });
}
