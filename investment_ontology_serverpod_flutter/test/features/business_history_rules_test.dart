import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_history.dart';

BusinessTableMeasure value(String unit) => BusinessTableMeasure(
  label: '부품 (KG당)',
  metric: '가격',
  period: '제24기',
  value: 147443,
  unit: unit,
);
void main() {
  test('missing reports retain five annual slots plus latest interim', () {
    final latest = BusinessContent(
      bsnsYear: 2026,
      rceptNo: '2026',
      title: '사업의 내용',
      charCount: 0,
      sections: [],
      years: [2025, 2026],
    );
    final old = latest.copyWith(bsnsYear: 2025, rceptNo: '2025');
    final slots = businessHistorySlots(latest, [old, latest]);
    expect(slots.map((s) => s.year), [2021, 2022, 2023, 2024, 2025, 2026]);
    expect(slots.first.report, isNull);
    expect(slots[4].report?.rceptNo, '2025');
    expect(slots.last.report?.rceptNo, '2026');
    final annual = old.copyWith(
      source: Source(
        kind: SourceKind.dartReport,
        title: '사업보고서 (2025.12)',
        retrievedAt: DateTime.utc(2026),
      ),
    );
    expect(businessAnnualYears(annual), [2021, 2022, 2023, 2024, 2025]);
  });

  test('latest third quarter remains blank when only annual source exists', () {
    final latest = BusinessContent(
      bsnsYear: 2025,
      rceptNo: '2025',
      title: '사업의 내용',
      charCount: 0,
      sections: [],
      years: [2025],
      source: Source(
        kind: SourceKind.dartReport,
        title: '사업보고서 (2025.12)',
        retrievedAt: DateTime.utc(2026),
      ),
    );
    final expected = FinancialPeriod(
      bsnsYear: 2026,
      reportCode: FinancialReportCode.q3,
      reportId: 1,
      rceptNo: '2026Q3',
      reportName: '분기보고서 (2026.09)',
      supersededCount: 0,
      lines: [],
    );
    final slots = businessHistorySlots(latest, [
      latest,
    ], latestReport: expected);
    expect(slots.map((s) => s.year), [2021, 2022, 2023, 2024, 2025, 2026]);
    expect(slots.last.period, '2026 3분기 누적');
    expect(slots.last.report, isNull);
    final staleHalf = latest.copyWith(
      bsnsYear: 2026,
      rceptNo: '2026H1',
      source: Source(
        kind: SourceKind.dartReport,
        title: '반기보고서 (2026.06)',
        retrievedAt: DateTime.utc(2026),
      ),
    );
    expect(
      businessHistorySlots(staleHalf, [
        latest,
        staleHalf,
      ], latestReport: expected).last.report,
      isNull,
    );
    expect(
      businessHistoryAxisLabel(slots.last.year, slots.last.period),
      '26.3Q 누적',
    );
  });

  test(
    'research history uses each filing own year without comparative duplicates',
    () {
      BusinessContent report(int year, List<int> years) => BusinessContent(
        bsnsYear: year,
        rceptNo: '$year',
        title: '사업의 내용',
        charCount: 0,
        sections: [],
        years: [2021, 2022],
        tableInsights: [
          BusinessTableInsight(
            topic: 'researchProjects',
            title: '과제',
            columns: ['연도', '주요 연구과제명', '기대효과'],
            rows: [
              for (final y in years)
                BusinessTableRecord(label: '과제$y', cells: ['$y년', '과제$y', '-']),
            ],
            measures: [],
            evidence: '',
            validation: '',
          ),
        ],
      );
      final history = businessRecordHistory([
        report(2021, [2020, 2021]),
        report(2022, [2021, 2022]),
      ], 'researchProjects');
      expect(history.keys, [2021, 2022]);
      expect(history[2021]!.single.cells[1], '과제2021');
      expect(history[2022]!.single.cells[1], '과제2022');
    },
  );

  test(
    'bank metrics retain a shared period while their meanings stay separate',
    () {
      expect(
        businessTablePeriodKey('제66기 반기 · 평균잔액'),
        businessTablePeriodKey('제66기 반기 · 이자율'),
      );
      expect(
        businessTablePeriodKey('제66기 반기 · 평균잔액'),
        isNot(businessTablePeriodKey('제65기 · 평균잔액')),
      );
    },
  );
  test(
    'scale conflict differs from genuinely different measurement denominators',
    () {
      expect(conflictingPriceUnit(value('백만원'), [value('원')]), isTrue);
      expect(conflictingPriceUnit(value('천원/kg'), [value('천원/m')]), isFalse);
      expect(
        conflictingPriceUnit(value('원'), [value('원').copyWith(value: 100)]),
        isFalse,
      );
    },
  );
  test('axis never labels bare second quarter as cumulative half year', () {
    expect(businessHistoryAxisLabel(2026, '제28기 2분기매입액'), '26.2Q');
    expect(businessHistoryAxisLabel(2026, '2026 반기'), '26.1H');
    expect(businessHistoryAxisLabel(2025, '제27기'), '25년');
    expect(businessHistoryAxisLabel(2026, '2025년(제6기)'), '25년');
  });
  test('오름차순 표에서도 실제 최신 기간을 선택한다', () {
    expect(
      newestBusinessTablePeriod(['2024년', '2025년', '2026년 반기']),
      '2026년 반기',
    );
    expect(newestBusinessTablePeriod(['제5기', '제6기', '제7기 반기']), '제7기 반기');
    expect(
      newestBusinessTablePeriod(['2026년 반기 · 매입액', '2025년 · 매입액']),
      '2026년 반기',
    );
  });
}
