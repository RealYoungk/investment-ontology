import '../support/shad_test_host.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/overview_catalog.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_research_guide.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_model_guide.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_operating_section.dart';

FinancialPeriod period(int year, FinancialReportCode code, String receipt) =>
    FinancialPeriod(
      bsnsYear: year,
      reportCode: code,
      reportId: 1,
      rceptNo: receipt,
      reportName: '',
      supersededCount: 0,
      lines: [],
    );
DocumentFact fact(
  DocumentFactKind kind,
  String unit,
  int year, {
  RelationStatus status = RelationStatus.verified,
}) => DocumentFact(
  companyId: 1,
  documentId: 1,
  bsnsYear: year,
  kind: kind,
  label: '반도체',
  value: 70,
  unit: unit,
  evidence: '',
  extractedBy: RelationOrigin.api,
  status: status,
  createdAt: DateTime(2026),
);

void main() {
  test('backlog total stays visible ahead of product focus, while other metrics remain secondary', () {
    final dram = [
      fact(DocumentFactKind.marketShare, '%', 2025).copyWith(label: 'DRAM'),
    ];
    final part = [
      fact(DocumentFactKind.orderBacklog, '억원', 2025).copyWith(label: '기체부품'),
    ];
    final total = [
      fact(
        DocumentFactKind.orderBacklog,
        '억원',
        2025,
      ).copyWith(label: '합계 (별도)'),
    ];
    expect(primaryOperatingSeries([dram, part, total], focus: ['DRAM']), [
      total,
      dram,
    ]);
    expect(primaryOperatingSeries([dram, part, total]), [total, dram, part]);
    expect(primaryOperatingSeries([dram], focus: ['DRAM']), [dram]);
    expect(primaryOperatingSeries([], focus: ['DRAM']), isEmpty);
  });
  testWidgets(
    'backlog is visible without expanding the other business metrics',
    (tester) async {
      final dram = [
        fact(DocumentFactKind.marketShare, '%', 2025).copyWith(label: 'DRAM'),
      ];
      final backlog = [
        fact(
          DocumentFactKind.orderBacklog,
          '백만원',
          2025,
        ).copyWith(label: '반도체 기판 검사 및 수리장비', value: 13566),
      ];
      final tv = [
        fact(DocumentFactKind.marketShare, '%', 2025).copyWith(label: 'TV'),
      ];
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: OperatingMetricsList(
                  series: [dram, backlog, tv],
                  focus: ['DRAM'],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('수주잔고'), findsOneWidget);
      expect(find.text('반도체 기판 검사 및 수리장비'), findsOneWidget);
      expect(find.text('DRAM'), findsOneWidget);
      expect(find.text('TV'), findsNothing);
      final before = tester.getRect(find.byType(OperatingMetricCard).first);
      await tester.tap(find.text('그 밖의 사업 지표 1개 보기'));
      await tester.pumpAndSettle();
      expect(find.text('TV'), findsOneWidget);
      expect(tester.getRect(find.byType(OperatingMetricCard).first), before);
      expect(tester.takeException(), isNull);
    },
  );
  final catalog = OverviewCatalog.fromJson(
    jsonDecode(File('assets/overview/companies.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final samsung = catalog.forCompany('00126380')!;
  final profile = samsung.research!;
  test('current focus covers reviewed interim but never later reports or corrections', () {
    expect(
      profile.sources.map((s) => s['kind']),
      containsAll(['annual', 'interim']),
    );
    expect(
      profile.covers(
        period(2026, FinancialReportCode.halfYear, '20260814003699'),
      ),
      isTrue,
    );
    expect(
      profile.covers(period(2026, FinancialReportCode.q1, 'earlier')),
      isTrue,
    );
    expect(
      profile.covers(period(2026, FinancialReportCode.halfYear, 'corrected')),
      isFalse,
    );
    expect(
      profile.covers(period(2026, FinancialReportCode.q3, 'newer')),
      isFalse,
    );
    expect(
      profile.covers(period(2027, FinancialReportCode.q1, 'newer')),
      isFalse,
    );
    expect(profile.covers(null), isFalse);
  });
  test('memory focus prioritizes DRAM without mixing annual and interim observations', () {
    final annual = fact(
      DocumentFactKind.marketShare,
      '%',
      2025,
    ).copyWith(label: 'DRAM', value: 34, asOf: DateTime.utc(2025, 12, 31));
    final half = annual.copyWith(
      bsnsYear: 2026,
      value: 39.4,
      asOf: DateTime.utc(2026, 6, 30),
    );
    final tv = annual.copyWith(label: 'TV');
    final cockpit = annual.copyWith(label: '디지털 콕핏');
    final series = operatingSeries([
      tv,
      cockpit,
      half,
      annual,
    ], focus: profile.operatingFocus);
    expect(series.first.map((f) => f.value), [34, 39.4]);
    expect(matchesOperatingFocus(series.first, profile.operatingFocus), isTrue);
    expect(matchesOperatingFocus(series.last, profile.operatingFocus), isFalse);
    expect(businessPeriodLabel(half), '2026 상반기');
    expect(businessPeriodLabel(annual), '2025년');
  });
  test('business axis abbreviations keep annual, interim and cumulative periods distinct', () {
    final f = fact(DocumentFactKind.marketShare, '%', 2026);
    expect(businessAxisLabel(f), '26');
    expect(
      businessAxisLabel(f.copyWith(asOf: DateTime.utc(2026, 6, 30))),
      '26.1H',
    );
    expect(
      businessAxisLabel(
        f.copyWith(asOf: DateTime.utc(2026, 6, 30)),
        narrow: true,
      ),
      '26H1',
    );
    expect(
      businessAxisLabel(f.copyWith(asOf: DateTime.utc(2026, 3, 31))),
      '26.1Q',
    );
    expect(
      businessAxisLabel(f.copyWith(asOf: DateTime.utc(2026, 9, 30))),
      '26.9M',
    );
    expect(
      businessAxisLabel(f.copyWith(asOf: DateTime.utc(2026, 2, 28))),
      '26.02',
    );
  });
  test(
    'one known annual investment retains missing years without inventing zeros',
    () {
      final f = fact(DocumentFactKind.investmentActual, '억원', 2024);
      final periods = [
        BusinessFactPeriod(
          documentId: 1,
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          periodEnd: DateTime.utc(2024, 12, 31),
        ),
        BusinessFactPeriod(
          documentId: 2,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          periodEnd: DateTime.utc(2026, 6, 30),
        ),
      ];
      final points = operatingTimeline([f], periods: periods);
      expect(points.map((p) => p.label), [
        '2021년',
        '2022년',
        '2023년',
        '2024년',
        '2025년',
      ]);
      expect(points.map((p) => p.fact?.value), [null, null, null, 70, null]);
    },
  );
  test(
    'cumulative half-year investment is not drawn as a full annual observation',
    () {
      final annual = fact(DocumentFactKind.investmentActual, '억원', 2025);
      final half = annual.copyWith(
        documentId: 2,
        bsnsYear: 2026,
        asOf: DateTime.utc(2026, 6, 30),
        value: 30,
      );
      final periods = [
        BusinessFactPeriod(
          documentId: 1,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          periodEnd: DateTime.utc(2025, 12, 31),
        ),
        BusinessFactPeriod(
          documentId: 2,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          periodEnd: DateTime.utc(2026, 6, 30),
        ),
      ];
      final points = operatingTimeline([annual, half], periods: periods);
      expect(points.last.label, '2025년');
      expect(points.last.fact!.value, 70);
      expect(points.any((p) => p.fact == half), isFalse);
    },
  );
  test('non-December annual reporting uses document basis rather than guessing interim from month', () {
    final f = fact(
      DocumentFactKind.investmentActual,
      '억원',
      2025,
    ).copyWith(asOf: DateTime.utc(2026, 3, 31));
    final points = operatingTimeline(
      [f],
      periods: [
        BusinessFactPeriod(
          documentId: 1,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          periodEnd: DateTime.utc(2026, 3, 31),
        ),
      ],
    );
    expect(points.last.label, '2025년');
    expect(points.last.fact, f);
  });
  testWidgets(
    'interim market share shows actual period and estimate basis at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final annual = fact(
        DocumentFactKind.marketShare,
        '%',
        2025,
      ).copyWith(label: 'DRAM', value: 34, asOf: DateTime.utc(2025, 12, 31));
      final half = annual.copyWith(
        bsnsYear: 2026,
        value: 39.4,
        asOf: DateTime.utc(2026, 6, 30),
        reviewNote: '매출액 기준 · 회사 추정',
      );
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(body: OperatingMetricCard(facts: [annual, half])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026 상반기'), findsOneWidget);
      expect(find.text('매출액 기준 · 회사 추정'), findsOneWidget);
      final chartFinder = find.byType(AppColumnChart);
      final chart = tester.widget<AppColumnChart>(chartFinder);
      expect(chart.categories, [
        '2021년',
        '2022년',
        '2023년',
        '2024년',
        '2025년',
        '2026 상반기',
      ]);
      expect(chart.formatCategory!('2025년'), '25');
      expect(chart.formatCategory!('2026 상반기'), '26H1');
      final origin = tester.getTopLeft(chartFinder);
      final width = tester.getSize(chartFinder).width;
      await tester.tapAt(
        origin +
            Offset(
              64 +
                  (width - 64) *
                      (chart.categories.length - .5) /
                      chart.categories.length,
              70,
            ),
      );
      await tester.pump();
      expect(find.text('2026 상반기'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'one annual value still exposes missing years and the missing latest period',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final value = fact(
        DocumentFactKind.investmentActual,
        '억원',
        2024,
      ).copyWith(value: 0, asOf: DateTime.utc(2024, 12, 31));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: OperatingMetricCard(
                facts: [value],
                periods: [
                  BusinessFactPeriod(
                    documentId: 99,
                    bsnsYear: 2026,
                    reportCode: FinancialReportCode.halfYear,
                    periodEnd: DateTime.utc(2026, 6, 30),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026 상반기 값 미확보'), findsOneWidget);
      expect(find.text('연간 추이 · — 값 미확보'), findsOneWidget);
      final finder = find.byType(AppColumnChart);
      final chart = tester.widget<AppColumnChart>(finder);
      expect(chart.categories, ['2021년', '2022년', '2023년', '2024년', '2025년']);
      expect(chart.series.single.values, [null, null, null, 0, null]);
      expect(chart.showMissingMarkers, isTrue);
      final origin = tester.getTopLeft(finder),
          width = tester.getSize(finder).width;
      await tester.tapAt(origin + Offset(64 + (width - 64) * .9, 70));
      await tester.pump();
      expect(find.text('2025년'), findsOneWidget);
      expect(find.text('해당 기간 값 미확보'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets(
      'expansion keeps primary geometry and groups mixed metrics at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final dram = [
          fact(DocumentFactKind.marketShare, '%', 2024).copyWith(label: 'DRAM'),
          fact(DocumentFactKind.marketShare, '%', 2025).copyWith(label: 'DRAM'),
        ];
        final tv = [for (final f in dram) f.copyWith(label: 'TV')];
        final investment = [
          fact(
            DocumentFactKind.investmentActual,
            '억원',
            2025,
          ).copyWith(label: '시설투자 (첨단공정 증설 및 인프라)'),
        ];
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1200),
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: OperatingMetricsList(
                        series: [dram, investment, tv],
                        focus: const ['DRAM'],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final primary = find.byType(OperatingMetricCard).first;
        final before = tester.getRect(primary);
        expect(find.text('TV'), findsNothing);
        await tester.tap(find.text('그 밖의 사업 지표 2개 보기'));
        await tester.pumpAndSettle();
        expect(tester.getRect(primary), before);
        expect(find.text('그 밖의 시장점유율'), findsOneWidget);
        expect(find.text('TV'), findsOneWidget);
        final cards = find.byType(OperatingMetricCard);
        for (var i = 1; i < 3; i++) {
          final previous = tester.getRect(cards.at(i - 1));
          final current = tester.getRect(cards.at(i));
          expect(current.left, before.left);
          expect(current.width, before.width);
          expect(current.top, greaterThanOrEqualTo(previous.bottom));
        }
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('그 밖의 사업 지표 접기'));
        await tester.pumpAndSettle();
        expect(cards, findsOneWidget);
        expect(tester.getRect(primary), before);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('operating metrics keep units and plans distinct and reject drafts and duplicates of revenue', () {
    final series = operatingSeries([
      fact(DocumentFactKind.utilization, '%', 2025),
      fact(DocumentFactKind.utilization, '%', 2024),
      fact(DocumentFactKind.investmentActual, '억원', 2025),
      fact(DocumentFactKind.investmentPlan, '억원', 2026),
      fact(DocumentFactKind.investmentActual, '백만 달러', 2025),
      fact(DocumentFactKind.segmentRevenue, '억원', 2025),
      fact(DocumentFactKind.rndExpense, '억원', 2025),
      fact(
        DocumentFactKind.orderBacklog,
        '억원',
        2025,
        status: RelationStatus.draft,
      ),
    ]);
    expect(series.length, 4);
    expect(series.first.map((f) => f.bsnsYear), [2024, 2025]);
    expect(
      series
          .where((s) => s.first.kind == DocumentFactKind.investmentActual)
          .length,
      2,
    );
    expect(series.last.single.kind, DocumentFactKind.investmentPlan);
  });
  test(
    'identical annotated labels collapse but differing values stay distinct',
    () {
      final short = fact(
        DocumentFactKind.marketShare,
        '%',
        2025,
      ).copyWith(label: 'TV');
      final annotated = short.copyWith(label: 'TV (금액 기준, Omdia)');
      expect(
        operatingSeries([short, annotated]).single.single.label,
        annotated.label,
      );
      expect(operatingSeries([short, annotated.copyWith(value: 71)]).length, 2);
      expect(
        operatingSeries([short, short.copyWith(bsnsYear: 2024), annotated])
            .single
            .length,
        2,
      );
    },
  );
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets(
      'issuer diagram and operating metrics fit $width at enlarged text',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1200),
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CompanyResearchGuide(profile: profile),
                          OperatingMetricCard(
                            facts: [
                              fact(DocumentFactKind.utilization, '%', 2024),
                              fact(DocumentFactKind.utilization, '%', 2025),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('HBM'), findsNWidgets(2));
        await tester.tap(find.text('DRAM'));
        await tester.pump();
        expect(find.text('DRAM · 작업용 메모리'), findsOneWidget);
        expect(find.text('GPU\nAI 계산'), findsNothing);
        await tester.tap(find.text('NAND'));
        await tester.pump();
        expect(find.text('NAND · 데이터 저장'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'compact overview puts issuer explanation ahead of hidden generic business model',
    (tester) async {
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: BusinessModelGuide(
                lesson: samsung,
                summary: '기업별 사업 설명',
                compact: true,
                showGrowth: false,
              ),
            ),
          ),
        ),
      );
      expect(find.text('기업별 사업 설명'), findsOneWidget);
      expect(find.text('사업모델 이해하기'), findsOneWidget);
      expect(find.text(samsung.models.first.driver), findsNothing);
    },
  );
}
