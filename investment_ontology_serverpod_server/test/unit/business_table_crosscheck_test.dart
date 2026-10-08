import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  String fixture(String name) =>
      File('test/fixtures/business_tables/crosscheck/$name.txt')
          .readAsStringSync();
  for (final (name, topic, rows, measures, amount, unit) in [
    ('hyundai-prices', 'materialPrice', 5, 15, 108, 'USD/TON'),
    ('samsung-derivatives', 'derivatives', 1, 4, 140503, '백만원'),
    ('hyundai-materials', 'materialPurchase', 22, 38, 203216, '억원'),
    ('construction-materials', 'materialPurchase', 16, 26, 707777, '백만원'),
    ('construction-prices', 'materialPrice', 4, 12, 953500, '원/톤'),
    ('posco-materials', 'materialPurchase', 14, 28, 86419, '억원'),
    ('posco-prices', 'materialPrice', 11, 33, 144, '천원/톤'),
    ('posco-product-prices', 'productPrice', 5, 15, 895, '천원/톤'),
    ('posco-investment', 'investmentPlan', 3, 9, 60544, '억원'),
    ('posco-million-currency', 'derivatives', 5, 5, 1000, '백만USD'),
    ('posco-thousand-currency', 'derivatives', 3, 3, 72783, '천CHF'),
    ('lg-materials', 'materialPurchase', 6, 10, 6543663, '백만원'),
    ('lg-prices', 'materialPrice', 3, 9, 1195945, '원/톤'),
    ('lg-derivatives', 'derivatives', 48, 96, 500, '백만USD'),
    ('hynix-inputs', 'materialPurchase', 7, 10, 999418, '백만원'),
    ('hynix-investment', 'investmentExecution', 2, 1, 17595, '십억원'),
  ]) {
    test('actual $name preserves rows, named metrics and printed scale', () {
      final source = fixture(name);
      final table = BusinessTableInsights.parse(
        source,
        reportPeriod: '2026 반기',
      ).where((t) => t.topic == topic).last;
      expect(table.rows, hasLength(rows));
      expect(table.measures, hasLength(measures));
      expect(table.measures.first.value, amount);
      expect(table.measures.first.unit, unit);
      expect(source.contains(table.evidence), isTrue);
      expect(
        table.rows.every((r) => r.cells.length == table.columns.length),
        isTrue,
      );
      if (name == 'lg-materials') {
        expect(table.measures.first.period, '매입액(제26기 반기)');
      }
      if (name == 'lg-derivatives') {
        expect(table.measures[1].value, 187939);
        expect(table.measures[1].unit, '백만원');
        expect(table.measures.first.period, '당반기말 (2026 반기 보고서)');
        expect(table.rows.last.cells[1], '산업은행');
        expect(table.measures.last.value, 4565);
      }
      if (name == 'hynix-investment') expect(table.title, '투자 집행 현황');
    });
  }
  test(
    'a risk section never makes receivables or prose bullets derivative tables',
    () {
      const source = '''## 5. 위험관리 및 파생거래
(2) 신용위험
- | 상각후원가로 측정되는 기타금융자산
- | 기타포괄손익-공정가치로 측정되는 채무상품
(단위: 백만원)
구분 | 매출채권 | 계약자산
신용위험에 대한 최대 노출정도 | 10,208,198 | 165,053
''';
      expect(
        BusinessTableInsights.parse(source, reportPeriod: '2026 반기'),
        isEmpty,
      );
    },
  );
  test(
    'an ambiguous currency scale never falls back to an unscaled currency',
    () {
      const source = '''## 파생상품
(단위: 백만원, 외화 단위 미기재)
구분 | 통화 | 계약금액
통화스왑 | USD | 100
''';
      expect(
        BusinessTableInsights.parse(
          source,
          reportPeriod: '2026',
        ).single.measures,
        isEmpty,
      );
    },
  );
}
