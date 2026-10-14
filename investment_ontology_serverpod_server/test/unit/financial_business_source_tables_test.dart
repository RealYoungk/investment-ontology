import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/financial_business_source_tables.dart';

void main() {
  test('merged malformed comma cells never become financial measures', () {
    final tables = FinancialBusinessSourceTables.parse(
      '(단위: 백만원)\n구분 | 2026 | 2025\n영업수익 | 255,2255,5058,08599732,621 | 1,234\n영업비용 | (12,345) | 1,23',
      '2026',
      industryCode: '651',
    );
    final measures = tables.expand((t) => t.measures).toList();
    expect(measures.map((m) => m.value), unorderedEquals([1234.0, -12345.0]));
    expect(tables.single.rows.first.cells[1], '255,2255,5058,08599732,621');
  });
  test('unit cannot cross section or another table boundary', () {
    for (final barrier in ['## 2. 별도 표', '구분 | 회사명\n부문 | 금융']) {
      expect(
        FinancialBusinessSourceTables.parse(
          '(단위: 백만원)\n$barrier\n구분 | 2026 | 2025\n영업수익 | 100 | 90',
          '2026',
          industryCode: '651',
        ),
        isEmpty,
      );
    }
  });
  test('industry metadata required to avoid manufacturing asset tables', () {
    final source = File('test/fixtures/business_financial/00111722.txt')
        .readAsStringSync();
    expect(
      FinancialBusinessSourceTables.parse(source, '2026', industryCode: '201'),
      isEmpty,
    );
    expect(FinancialBusinessSourceTables.parse(source, '2026'), isEmpty);
  });
  test('fixture evidence and row/measure invariants', () {
    for (final code in ['00126256', '00139214', '00111722']) {
      final text = File('test/fixtures/business_financial/$code.txt')
          .readAsStringSync();
      final tables = FinancialBusinessSourceTables.parse(
        text,
        '2026 반기',
        industryCode: '651',
      );
      expect(tables, isNotEmpty);
      for (final t in tables) {
        expect(text.contains(t.evidence), isTrue);
        expect(t.rows.every((r) => r.cells.length == t.columns.length), isTrue);
        for (final m in t.measures) {
          expect(
            m.value.isFinite && m.metric.isNotEmpty && m.period.isNotEmpty,
            isTrue,
          );
          expect(['원', '천원', '백만원', '억원', '%'].contains(m.unit), isTrue);
        }
      }
    }
  });
  test(
    'Samsung Life reserves preserve newest period, percentages and currency',
    () {
      final tables = FinancialBusinessSourceTables.parse(
        File('test/fixtures/business_financial/00126256.txt')
            .readAsStringSync(),
        '2026 반기',
        industryCode: '651',
      );
      final m = tables
          .expand((t) => t.measures)
          .firstWhere((m) => m.metric == '준비금평잔' && m.value == 267802310);
      expect(m.unit, '백만원');
      expect(m.period, contains('2026'));
      expect(
        tables
            .expand((t) => t.measures)
            .any((m) => m.metric == '부리이율' && m.unit == '%'),
        isTrue,
      );
    },
  );
  test(
    'Mirae operating income and signed expenses are distinct and total checked',
    () {
      final tables = FinancialBusinessSourceTables.parse(
        File('test/fixtures/business_financial/00111722.txt')
            .readAsStringSync(),
        '2026 반기',
        industryCode: '651',
      );
      expect(
        tables
            .expand((t) => t.measures)
            .any((m) => m.metric == '영업비용' && m.value == -32195185),
        isTrue,
      );
      expect(tables.any((t) => t.validation.contains('검산 일치')), isTrue);
    },
  );
  test(
    'Samsung Fire preserves insurance revenue separately from service costs',
    () {
      final tables = FinancialBusinessSourceTables.parse(
        File('test/fixtures/business_financial/00139214.txt')
            .readAsStringSync(),
        '2026 반기',
        industryCode: '651',
      );
      expect(
        tables
            .expand((t) => t.measures)
            .any(
              (m) => m.metric == '보험수익' && m.value == 33578 && m.unit == '백만원',
            ),
        isTrue,
      );
      expect(
        tables.expand((t) => t.measures).any((m) => m.metric == '보험서비스비용'),
        isTrue,
      );
    },
  );
  test('bare amount/ratio does not manufacture yield', () {
    expect(
      FinancialBusinessSourceTables.parse(
        '(단위: 백만원, %)\n구분 | 2026 | 2025\n금액 | 비율 | 금액 | 비율\n대출 | 100 | 3 | 90 | 4',
        '2026',
        industryCode: '651',
      ),
      isEmpty,
    );
  });
  test('missing unit rejects numeric financial table', () {
    expect(
      FinancialBusinessSourceTables.parse(
        '구분 | 2026 | 2025\n영업수익 | 100 | 90',
        '2026',
        industryCode: '651',
      ),
      isEmpty,
    );
  });
}
