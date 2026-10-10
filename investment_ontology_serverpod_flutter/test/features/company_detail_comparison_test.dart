import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_operating_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_history.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

import '../support/shad_test_host.dart';
import 'business_understanding_test.dart' as fixtures;

BusinessContent report(int year, {String text = '', bool hasRows = true}) =>
    BusinessContent(
      bsnsYear: year,
      rceptNo: '$year',
      title: '사업의 내용',
      charCount: text.length,
      sections: [BusinessSection(title: '원재료 및 생산설비', text: text)],
      years: [2024, 2025],
      tableInsights: hasRows
          ? [
              BusinessTableInsight(
                topic: 'materialContext',
                title: '원재료',
                columns: ['원재료', '조달 방법'],
                rows: [
                  BusinessTableRecord(
                    label: 'CARBIDE',
                    cells: ['CARBIDE', '수입'],
                  ),
                ],
                measures: [],
                evidence: 'CARBIDE 수입',
                validation: '',
              ),
            ]
          : [],
    );

Widget host(Widget child) => shadTestHost(
  MaterialApp(
    theme: buildAppTheme(ledgerBrand),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  test('numeric physical unit remains distinct from the numeric value', () {
    expect(formatUnitAmount(53628, '1,000pcs'), '53,628 1,000pcs');
    expect(formatUnitAmount(53628, ''), '53,628');
  });
  test('explicit no-contract evidence differs from absent extraction', () {
    expect(
      businessTopicCoverage(
        report(
          2022,
          hasRows: false,
          text:
              '당기 현재 미결제 통화선도계약의 내역은 없습니다.\n보고기간 종료일 현재 미결제 금리스왑 계약의 내역은 없습니다.',
        ),
        'derivatives',
      ),
      '미결제 계약 없음',
    );
    expect(
      businessTopicCoverage(report(2023, hasRows: false), 'derivatives'),
      '자동 추출 항목 없음',
    );
  });
  for (final width in [390.0, 893.0]) {
    testWidgets(
      'identical records keep both source years without a year selector at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(
            BusinessRecordTimeline(
              reports: [report(2024), report(2025)],
              topic: 'materialContext',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('CARBIDE'), findsOneWidget);
        expect(find.text('2024 · 2025'), findsOneWidget);
        expect(find.byType(ShadSelect<int>), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'patents show all years in a compact list and preserve full details',
    (tester) async {
      final patent = report(2025).copyWith(
        tableInsights: [
          BusinessTableInsight(
            topic: 'intellectualProperty',
            title: '특허',
            columns: ['특허의명칭', '특허취득일', '특허내용', '특허출원국가'],
            rows: [
              BusinessTableRecord(
                label: '절삭 공구',
                cells: ['절삭 공구', '2024-03-13', '긴 기술 설명 원문', '대한민국'],
              ),
            ],
            measures: [],
            evidence: '절삭 공구',
            validation: '',
          ),
        ],
      );
      await tester.pumpWidget(
        host(
          BusinessRecordTimeline(
            reports: [patent, patent.copyWith(bsnsYear: 2026)],
            topic: 'intellectualProperty',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('절삭 공구'), findsOneWidget);
      expect(find.text('공시 확인 2025 · 2026'), findsOneWidget);
      expect(find.text('긴 기술 설명 원문'), findsNothing);
      await tester.tap(find.text('내용·활용 계획과 출원 국가'));
      await tester.pumpAndSettle();
      expect(find.text('긴 기술 설명 원문'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'capacity groups products while retaining annual and interim periods',
    (tester) async {
      DocumentFact fact(
        String label,
        int year, {
        DateTime? date,
        String unit = '1,000pcs',
      }) => fixtures
          .fact(year: year)
          .copyWith(
            kind: DocumentFactKind.capacity,
            label: label,
            unit: unit,
            asOf: date,
          );
      await tester.pumpWidget(
        host(
          OperatingMetricsList(
            series: [
              [fact('Drill', 2021), fact('Drill', 2022)],
              [
                fact('Round Tool', 2025),
                fact('Round Tool', 2026, date: DateTime.utc(2026, 6, 30)),
              ],
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('생산능력'), findsOneWidget);
      expect(find.byType(AppColumnChart), findsOneWidget);
      expect(find.text('최근 중간보고서'), findsOneWidget);
      expect(find.text('2026 상반기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
