import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/shareholder_return/shareholder_return_tab.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';

import '../support/shad_test_host.dart';

void main() {
  testWidgets(
    'latest half year is explicit and never enters annual dividend chart',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 1000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      DividendEntry row(int y, double v) => DividendEntry(
        reportId: y,
        companyId: 1,
        bsnsYear: y,
        ord: 0,
        item: '주당 현금배당금(원)',
        unit: '원',
        stockKind: '보통주',
        current: v,
      );
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ShareholderReturnTab(
                  corpCode: 'fixture',
                  loader: (_) async => ShareholderReturn(
                    corpCode: 'fixture',
                    dividends: [row(2025, 100)],
                    interimDividends: [row(2026, 20)],
                    interimReportName: '2026년 상반기',
                    latestReportName: '반기보고서 (2026.06)',
                    latestYear: 2026,
                    annualEndYear: 2025,
                    latestDividendStatus: 'stored',
                    latestTreasuryStatus: 'noData',
                    latestStockTotalStatus: 'pending',
                    treasury: [],
                    stockTotals: [],
                    sources: [],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('최근 중간보고서 · 반기보고서 (2026.06)'), findsOneWidget);
      expect(find.text('20원'), findsOneWidget);
      expect(find.text('100원'), findsWidgets);
      expect(find.text('FY2026'), findsNothing);
      expect(find.text('자기주식: DART API 응답 자료 없음'), findsOneWidget);
      expect(find.text('주식 총수: 자료 수집 대기'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  for (final width in [390.0, 1045.0]) {
    testWidgets(
      'null dividend values collapse and explicit zero remains at $width',
      (t) async {
        await t.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final empty = DividendEntry(
          reportId: 1,
          companyId: 1,
          bsnsYear: 2025,
          ord: 0,
          item: '주당 현금배당금(원)',
          stockKind: '보통주',
          unit: '원',
        );
        Future<void> show(DividendEntry entry) async {
          await t.pumpWidget(
            shadTestHost(
              MaterialApp(
                theme: buildAppTheme(ledgerBrand),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: ShareholderReturnTab(
                      key: UniqueKey(),
                      corpCode: 'fixture',
                      loader: (_) async => ShareholderReturn(
                        corpCode: 'fixture',
                        dividends: [entry],
                        treasury: [],
                        stockTotals: [],
                        sources: [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await show(empty);
        expect(find.text('한 주당 받은 현금배당'), findsNothing);
        expect(find.textContaining('공시의 빈 값은 0'), findsOneWidget);
        expect(find.textContaining('자기주식 취득·처분: 표시할'), findsOneWidget);
        expect(t.takeException(), isNull);
        await show(empty.copyWith(current: 0));
        expect(find.text('한 주당 받은 현금배당'), findsOneWidget);
        expect(find.text('0원'), findsWidgets);
        expect(t.takeException(), isNull);
      },
    );
  }
}
