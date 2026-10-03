import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_header.dart';

import 'package:investment_ontology_serverpod_flutter/features/financials/financial_section.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

import 'financial_metrics_test.dart' as fixtures;

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('분기 전환은 3개월 현금흐름과 결측 사유를 보여준다 ($width)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FinancialLine cashLine(String key, int value) =>
          fixtures.line(key, value)
            ..statement = FinancialStatementKind.cashFlow;
      final value = fixtures.financials([
        fixtures.period(2025, FinancialReportCode.q1, [
          fixtures.line('revenue', 100),
          cashLine('operatingCashFlow', 20),
          cashLine('capex', 5),
        ]),
        fixtures.period(2025, FinancialReportCode.halfYear, [
          fixtures.line('revenue', 110, cumulative: 210),
          cashLine('operatingCashFlow', -10),
        ]),
        fixtures.period(2025, FinancialReportCode.q3, [
          fixtures.line('revenue', 120, cumulative: 330),
          cashLine('operatingCashFlow', 30),
          cashLine('capex', 40),
        ]),
        fixtures.period(2025, FinancialReportCode.annual, [
          fixtures.line('revenue', 500),
          cashLine('operatingCashFlow', 50),
          cashLine('capex', 50),
        ]),
      ]);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FinancialSection(
                  corpCode: value.corpCode,
                  initialData: value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('분기'));
      await tester.pumpAndSettle();
      expect(find.text('현금흐름'), findsOneWidget);
      expect(find.textContaining('각 분기 3개월 동안'), findsOneWidget);
      final chartFinder = find.byType(AppColumnChart);
      final chart = tester.widget<AppColumnChart>(chartFinder);
      expect(chart.categories, ['25.1분기', '25.2분기', '25.3분기', '25.4분기']);
      expect(chart.series.first.values, [20, -30, 40, 20]);
      expect(chart.series.last.values, [15, null, null, 10]);
      expect(chart.extraTooltipSeries.single.values, [5, null, null, 10]);
      await tester.ensureVisible(chartFinder);
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopLeft(chartFinder) + Offset(64 + (width - 64) * .625, 100),
      );
      await tester.pump();
      expect(find.textContaining('2025 반기 유형자산 취득 누적값 없음'), findsOneWidget);
      await tester.ensureVisible(find.text('연간'));
      await tester.tap(find.text('연간'));
      await tester.pumpAndSettle();
      expect(find.textContaining('각 분기 3개월 동안'), findsNothing);
      expect(
        tester.widget<AppColumnChart>(chartFinder).series.last.values.first,
        0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('현금흐름 설명과 설비 투자 상세, 수집 버튼 제거 ($width)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FinancialLine cashLine(String key, int value) =>
          fixtures.line(key, value)
            ..statement = FinancialStatementKind.cashFlow;
      final value = fixtures.financials([
        fixtures.period(2025, FinancialReportCode.annual, [
          fixtures.line('revenue', 200),
          cashLine('operatingCashFlow', 120),
          cashLine('capex', -50),
        ]),
        fixtures.period(2026, FinancialReportCode.annual, [
          fixtures.line('revenue', 200),
          cashLine('operatingCashFlow', -10),
          cashLine('capex', 20),
        ]),
      ])..pendingFilingCount = 2;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FinancialSection(
                  corpCode: value.corpCode,
                  initialData: value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('이 기업 재무 지금 받기'), findsNothing);
      expect(find.textContaining('유형자산 취득:'), findsNothing);
      expect(find.text('사업에서 들어온 현금'), findsOneWidget);
      expect(find.text('설비 투자 후 남은 현금'), findsOneWidget);
      expect(find.text('정기보고서 2건 수집 대기'), findsNothing);
      final chart = tester.widget<AppColumnChart>(find.byType(AppColumnChart));
      expect(chart.series[1].values, [70, -30]);
      expect(chart.extraTooltipSeries.single.values, [50, 20]);
      await tester.ensureVisible(find.byType(AppColumnChart));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopLeft(find.byType(AppColumnChart)) +
            Offset(64 + (width - 64) / 4, 100),
      );
      await tester.pump();
      expect(find.text('설비 투자 · 유형자산 취득'), findsOneWidget);
      await tester.ensureVisible(
        find.byWidgetPredicate(
          (w) =>
              (w is Tooltip && w.message == '현금흐름 읽는 법') ||
              (w is ShadIconButton && w.semanticLabel == '현금흐름 읽는 법'),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              (w is Tooltip && w.message == '현금흐름 읽는 법') ||
              (w is ShadIconButton && w.semanticLabel == '현금흐름 읽는 법'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('사업에서 들어온 현금 · 영업활동 현금흐름'), findsOneWidget);
      expect(find.textContaining('음수면 영업에서'), findsOneWidget);
      expect(find.textContaining('빚을 갚거나 배당할 여력'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              (w is Tooltip && w.message == '닫기') ||
              (w is ShadIconButton && w.semanticLabel == '닫기'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('자료 기준·원문'), findsNothing);
      expect(find.text('정기보고서 2건 수집 대기'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('재무 탭 차트를 유지하며 실적 표를 펼치고 접는다', (tester) async {
    final value = fixtures.financials([
      for (final year in [2023, 2024, 2025])
        fixtures.period(year, FinancialReportCode.annual, [
          fixtures.line('revenue', 100),
          fixtures.line('operatingIncome', -20),
          fixtures.line('netIncome', -30),
        ]),
    ]);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinancialSection(
                corpCode: value.corpCode,
                initialData: value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final charts = tester
        .widgetList<AppComboChart>(find.byType(AppComboChart))
        .toList();
    expect(charts, hasLength(2));
    expect(charts.first.additionalLineSeries.single.values.first, -.3);
    expect(charts.last.additionalLineSeries.single.values, [-.3, -.3, -.3]);
    expect(charts.last.additionalLineSeries.single.isDashed, isTrue);
    expect(find.text('표로 보기'), findsNWidgets(3));
    expect(find.byType(AppDataTable), findsNothing);
    await tester.ensureVisible(find.text('표로 보기').first);
    await tester.tap(find.text('표로 보기').first);
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsOneWidget);
    expect(find.text('당기순이익'), findsWidgets);
    expect(find.text('-20.0%'), findsNWidgets(3));
    expect(find.textContaining('단위: 백만원'), findsOneWidget);
    await tester.tap(find.text('표로 보기').first);
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsNothing);
    await tester.ensureVisible(find.text('분기'));
    expect(find.text('수익성 · 최근 12개월'), findsNothing);
    await tester.tap(find.text('분기'));
    await tester.pumpAndSettle();
    expect(find.text('분기 재무가 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상단 지표는 재무 기준 전환 후 새 입력으로 계산한다', (tester) async {
    CompanyFinancials data(FsDiv div, int net) {
      final result = fixtures.financials([
        fixtures.period(2025, FinancialReportCode.annual, [
          fixtures.line('netIncome', net),
          fixtures.line('netIncomeOwners', net),
          fixtures.line('revenue', 500),
          fixtures.line('operatingIncome', 100),
        ]),
      ], cap: BigInt.from(1000));
      result.fsDiv = div;
      result.availableFsDivs = FsDiv.values;
      return result;
    }

    Future<void> pump(CompanyFinancials value) async {
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyHeader(
                  detail: CompanyDetail(
                    company: Company(corpCode: value.corpCode, name: '테스트'),
                    industryPath: [],
                    changes: [],
                  ),
                  financials: value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(data(FsDiv.consolidated, 100));
    await tester.tap(find.text('PER'));
    await tester.pumpAndSettle();
    expect(find.text('계산 방법'), findsOneWidget);
    expect(find.text('10.00배'), findsWidgets);
    expect(find.textContaining('연결 기준'), findsWidgets);
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            (w is Tooltip && w.message == '닫기') ||
            (w is ShadIconButton && w.semanticLabel == '닫기'),
      ),
    );
    await tester.pumpAndSettle();

    await pump(data(FsDiv.separate, 50));
    await tester.tap(find.text('PER'));
    await tester.pumpAndSettle();
    expect(find.text('계산 방법'), findsOneWidget);
    expect(find.text('20.00배'), findsWidgets);
    expect(find.textContaining('별도 기준'), findsWidgets);
    expect(find.text('10.00배'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
