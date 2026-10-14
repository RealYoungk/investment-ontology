import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_rnd_facts.dart';

void main() {
  test('same-basis conflicting revenue statements stay ambiguous, equal duplicates deduplicate', () {
    expect(
      StoredRndFacts.orderedRevenueCandidates({
        'consolidated': {1000, 1100},
        'separate': {2000},
      }),
      isEmpty,
    );
    expect(
      StoredRndFacts.orderedRevenueCandidates({
        'consolidated': {1000},
        'separate': {2000, 2100},
      }),
      [1000],
    );
    expect(
      StoredRndFacts.orderedRevenueCandidates({
        'consolidated': {1000.0},
        'separate': {2000},
      }),
      [1000, 2000],
    );
  });

  test(
    'consolidated denominator wins before gross separate matching total',
    () {
      final table = RndFacts.parse("""(단위 : 백만원)
과목 | 2025년 | 2024년
연구개발비용 총계 | 20 | 20
연구개발비용 계 | 10 | 10
연구개발비 / 매출액 비율 | 1% | 1%
""", bsnsYear: 2025)!;
      expect(
        StoredRndFacts.validatedColumns(table, {
          2025: [1000, 2000],
        }).single.expense,
        10,
      );
    },
  );
  test('different totals within printed rounding tolerance are ambiguous, equal totals deduplicate', () {
    final text = """(단위 : 백만원)
과목 | 2025년 | 2024년
연구개발비용 총계 | 20 | 20
연구개발비용 계 | 20.5 | 20.5
연구개발비 / 매출액 비율 | 1% | 1%
""";
    expect(
      StoredRndFacts.validatedColumns(RndFacts.parse(text, bsnsYear: 2025)!, {
        2025: [2000],
      }),
      isEmpty,
    );
    expect(
      StoredRndFacts.validatedColumns(
        RndFacts.parse(text.replaceAll('20.5', '20'), bsnsYear: 2025)!,
        {
          2025: [2000],
        },
      ),
      hasLength(1),
    );
  });

  test('FY2027 interim remains at original 2026.06 settlement', () {
    final doc = BusinessDocument(
      id: 1,
      reportId: 2,
      companyId: 3,
      bsnsYear: 2027,
      rceptNo: '20260812000330',
      title: '사업의 내용',
      text: '',
      charCount: 0,
    );
    final report = DisclosureReport(
      id: 2,
      companyId: 3,
      section: DartSection.businessContent,
      rceptNo: doc.rceptNo,
      bsnsYear: 2027,
      reportCode: FinancialReportCode.q1,
      settlementDate: DateTime.utc(2026, 6, 30),
      rowCount: 1,
      sourceId: 4,
      fetchedAt: DateTime.utc(2026, 8, 12),
    );
    expect(StoredRndFacts.currentDate(doc, report), DateTime.utc(2026, 6, 30));
    expect(StoredRndFacts.matchesSource(doc, report), isTrue);
    expect(
      StoredRndFacts.matchesSource(
        doc,
        report.copyWith(rceptNo: '20260812000331'),
      ),
      isFalse,
    );
    expect(
      StoredRndFacts.matchesSource(doc, report.copyWith(companyId: 4)),
      isFalse,
    );
    expect(
      StoredRndFacts.matchesSource(doc, report.copyWith(supersededById: 99)),
      isFalse,
    );
  });

  test('decimal comma is only percent and malformed money is unavailable', () {
    expect(RndFacts.number('0,94%'), .94);
    expect(RndFacts.number('14,06%'), 14.06);
    expect(RndFacts.number('1,000%'), 1000);
    expect(RndFacts.number('32,458,062,70'), isNull);
    expect(RndFacts.number('3,464,'), isNull);
    expect(RndFacts.number('0,94'), isNull);
  });
  test('current match cannot certify a mismatched historical ratio', () {
    final table = RndFacts.parse('''(단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
연구개발비용 계 | 10 | 20 | 30
매출액 | 1000 | 1000 | 1000
연구개발비 / 매출액 비율 | 1.0% | 9.0% | 3.0%
''', bsnsYear: 2025)!;
    final result = StoredRndFacts.validatedColumns(table, {});
    expect(result.map((c) => c.index), [0, 2]);
  });
  test(
    'each historical year uses its own financial revenue and decimal ratio',
    () {
      final table = RndFacts.parse('''(단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
연구개발비용 계 | 90 | 94 | 91
연구개발비 / 매출액 비율 | 0.90% | 0,94% | 0.91%
''', bsnsYear: 2025)!;
      expect(
        StoredRndFacts.validatedColumns(table, {
          2025: [10000],
        }).map((c) => c.index),
        [0],
      );
      final result = StoredRndFacts.validatedColumns(table, {
        2025: [10000],
        2024: [10000],
        2023: [10000],
      });
      expect(result.map((c) => c.ratio), [.9, .94, .91]);
    },
  );
  test('printed denominator has priority and malformed column does not erase valid years', () {
    final table = RndFacts.parse('''(단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
연구개발비용 계 | 10 | 32,458,062,70 | 30
매출액 | 1000 | 1000 | 1000
연구개발비 / 매출액 비율 | 1% | 2% | 3%
''', bsnsYear: 2025)!;
    expect(
      StoredRndFacts.validatedColumns(table, {
        2024: [162290313500],
      }).map((c) => c.index),
      [0, 2],
    );
  });
}
