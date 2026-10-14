import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_segment_revenue.dart';

import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:test/test.dart';

String source(String name) =>
    File('test/fixtures/business_50/$name.txt').readAsStringSync();
void main() {
  test(
    'operating revenue total supports platform mix, not a fourth product',
    () {
      final rows = SegmentRevenue.parse(source('naver'));
      expect(rows.map((r) => r.amount), [
        3741951,
        930315,
        1957550,
        3741951,
        930315,
        1957550,
      ]);
      expect(rows.any((r) => r.label == '영업수익'), isFalse);
    },
  );

  test(
    'read projection recovers annotated totals and expanded split headers',
    () {
      final report = DisclosureReport(
        id: 1,
        companyId: 1,
        section: DartSection.businessContent,
        rceptNo: '20260814002692',
        bsnsYear: 2026,
        reportCode: FinancialReportCode.halfYear,
        rowCount: 0,
        sourceId: 1,
        fetchedAt: DateTime.utc(2026, 10, 12),
      );
      for (final (fixture, expected) in [
        ('hanwha', 5),
        ('hyundai-steel', 4),
        ('lges', 1),
        ('naver', 3),
      ]) {
        final text = source(fixture);
        final doc = BusinessDocument(
          id: 1,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2026,
          rceptNo: report.rceptNo,
          title: 'II. 사업의 내용',
          text: text,
          charCount: text.length,
        );
        final facts = StoredSegmentRevenue.project(doc, report);
        expect(facts.length, expected, reason: fixture);
        expect(facts.every((f) => f.asOf == DateTime.utc(2026, 6, 30)), isTrue);
      }
    },
  );

  test(
    'annotated consolidation totals are denominators, never product components',
    () {
      final rows = SegmentRevenue.parse(source('hanwha'));
      expect(rows.map((r) => r.label), ['항공', '방산', '해양', 'IT서비스 등', '항공우주']);
      expect(rows.map((r) => r.amount), [
        1459024,
        4465226,
        9614217,
        362436,
        124399,
      ]);
      expect(
        SegmentRevenue.parse(source('hyundai-steel')).map((r) => r.amount),
        [2961348, 9706570, 141205, 722137],
      );
      expect(rows.any((r) => SegmentRevenue.isTotalLabel(r.label)), isFalse);
    },
  );
  test(
    'merged two-column subheader supports an explicit operating division',
    () {
      final rows = SegmentRevenue.parse(source('lges'));
      expect(rows.single.label, '에너지솔루션');
      expect(rows.single.amount, 14115216);
      expect(SegmentRevenue.supportsStoredRecovery(source('lges')), isTrue);
      expect(
        SegmentRevenue.parse(source('lges').replaceFirst('100.0%', '50.0%')),
        isEmpty,
      );
    },
  );
  test('same time suffix permits a ratio above 100 and never creates product quantities', () {
    final rows = ProductionFacts.parse(source('hhi'));
    expect(rows.map((r) => r.utilization), [100.7, 122.9, 79.1, 112.8, 100]);
    expect(
      rows.every((r) => r.capacity == null && r.production == null),
      isTrue,
    );
    expect(rows.first.label, '조 선 · 선박 · HD현대중공업㈜');
    expect(
      ProductionFacts.parse(
        '구분 | 가동가능시간 | 실제가동시간 | 가동률\n조선 | 100천M/H | 80M/H | 80%',
      ),
      isEmpty,
    );
  });
  test('percent in the table unit validates bare ratios and separates domestic/overseas totals', () {
    final rows = ProductionFacts.parse(source('nongshim'));
    expect(rows.length, 11);
    expect(rows.first.utilization, 72.4);
    expect(rows.where((r) => r.label.endsWith('합 계')).map((r) => r.label), [
      '국내사업소 · 합 계',
      '해외사업소 · 합 계',
    ]);
    expect(
      rows.every((r) => r.capacity == null && r.production == null),
      isTrue,
    );
    expect(
      ProductionFacts.parse(
        '(단위 : 시간, %)\n구분 | 가동가능시간 | 실제가동시간 | 가동률\nA | 100 | 80 | 80\n## 다음 절\n구분 | 가동가능시간 | 실제가동시간 | 가동률\nB | 100 | 80 | 80',
      ).map((r) => r.label),
      ['A'],
    );
    final tables = BusinessTableInsights.parse(
      source('nongshim'),
      reportPeriod: '2026 반기',
    );
    expect(
      tables
          .singleWhere((t) => t.topic == 'activityUtilization')
          .measures
          .length,
      11,
    );
  });
  test('R&D recognizes relative terms, bare explicit total and merged total labels', () {
    final hanil = RndFacts.parse(source('hanil'), bsnsYear: 2026)!;
    expect(hanil.years, [2026, 2025]);
    expect(hanil.totals.first.values.first, 337677);
    expect(
      RndFacts.parse(
        source('gigavis'),
        bsnsYear: 2026,
      )!.totals.first.values.first,
      3115,
    );
    expect(
      RndFacts.parse(
        source('ls-electric'),
        bsnsYear: 2026,
      )!.totals.first.values.first,
      84742,
    );
    final sds = RndFacts.parse(source('sds'), bsnsYear: 2026)!;
    expect(sds.years, [2026, 2025, 2025, 2024]);
    expect(sds.totals.first.values.first, 97495832);
    expect(
      RndFacts.parse(
        source('sds').replaceAll('제41기 반기 | 제41기', '제41기 | 제41기'),
        bsnsYear: 2026,
      ),
      isNull,
    );
  });
}
