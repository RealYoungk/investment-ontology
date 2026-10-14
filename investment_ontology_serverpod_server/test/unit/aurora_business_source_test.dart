import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_segment_revenue.dart';
import 'package:test/test.dart';

void main() {
  final annual = File('test/fixtures/business/aurora-2025.txt')
      .readAsStringSync();
  final half = File('test/fixtures/business/aurora-2026-half.txt')
      .readAsStringSync();
  test('split product header: values, labels, ratios, units and customer exclusion', () {
    expect(SegmentRevenue.parse(annual).map((r) => r.amount), [
      310299154,
      6819330,
      10961487,
    ]);
    final h = SegmentRevenue.parse(half);
    expect(h.map((r) => r.amount), [179128990, 3178215, 6312990]);
    expect(h.map((r) => r.label), ['캐릭터완구', '임대수입', '기타 수입 등']);
    expect(h.every((r) => r.unit == '천원'), isTrue);
    expect(SegmentRevenue.parse(half.replaceFirst('95.0%', '50.0%')), isEmpty);
    expect(
      SegmentRevenue.parse(half.replaceAll('(단위 : 천원)', '(단위 : 개)')),
      isEmpty,
    );
    expect(
      SegmentRevenue.parse(half.replaceFirst('매출유형 | 품목', '매출처 | 품목')),
      isEmpty,
    );
  });
  test(
    'office periods and material names stay separate from undisclosed numbers',
    () {
      final insights = BusinessTableInsights.parse(
        half,
        reportPeriod: '2026 반기',
      );
      final office = insights.singleWhere(
        (t) => t.topic == 'businessOfficeRevenue',
      );
      expect(
        office.measures.where((m) => m.label == '미국 사업본부').map((m) => m.value),
        [135932218, 224859149, 179922271],
      );
      expect(office.measures.first.period, '제42기 반기');
      expect(
        BusinessTableInsights.parse(
          half.replaceFirst('135,932,218', '135,932,200'),
          reportPeriod: '2026 반기',
        ).where((t) => t.topic == 'businessOfficeRevenue'),
        isEmpty,
      );
      final material = insights.singleWhere(
        (t) => t.topic == 'materialContext',
      );
      expect(material.rows.map((r) => r.label), ['fabric', 'cotton']);
      expect(material.measures, isEmpty);
      final limits = insights.singleWhere(
        (t) => t.topic == 'disclosureLimitsSource',
      );
      expect(limits.rows.length, 4);
      expect(limits.measures, isEmpty);
      for (final row in limits.rows) {
        expect(half, contains(row.cells.last));
      }
    },
  );
  test('projection retains interim date and rejects mismatched or superseded source', () {
    final r = DisclosureReport(
      id: 1,
      companyId: 557,
      section: DartSection.businessContent,
      rceptNo: '20260814002692',
      bsnsYear: 2026,
      reportCode: FinancialReportCode.halfYear,
      rowCount: 0,
      sourceId: 215645,
      fetchedAt: DateTime.utc(2026, 10, 1),
    );
    final d = BusinessDocument(
      id: 2,
      reportId: 1,
      companyId: 557,
      bsnsYear: 2026,
      rceptNo: r.rceptNo,
      title: 'II. 사업의 내용',
      text: half,
      charCount: half.length,
    );
    final f = StoredSegmentRevenue.project(d, r);
    expect(f.length, 3);
    expect(
      f.every(
        (f) => f.asOf == DateTime.utc(2026, 6, 30) && f.sourceId == 215645,
      ),
      isTrue,
    );
    expect(
      StoredSegmentRevenue.project(d, r.copyWith(rceptNo: 'wrong')),
      isEmpty,
    );
    expect(
      StoredSegmentRevenue.project(d, r.copyWith(supersededById: 3)),
      isEmpty,
    );
  });
}
