import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  String fixture(String name) =>
      File('test/fixtures/business_tables/diverse/$name.txt')
          .readAsStringSync();
  for (final (name, topic, rows, amount, unit) in [
    ('ibk-funding', 'bankFunding', 17, 1229000, '억원'),
    ('ibk-capital', 'financialSoundness', 6, 406495, '억원'),
    ('ibk-liquidity', 'financialSoundness', 2, 104.01, '%'),
    ('shinhan-capital', 'financialSoundness', 11, 17.7, '%'),
    ('alteogen-licenses', 'majorContracts', 12, 1373000000, 'USD'),
    ('nexstin-projects', 'researchProjects', 4, 8505, '백만원'),
    ('taekyung-prices', 'materialPrice', 9, 17076, '원/ton'),
    ('c-and-c-materials', 'materialPurchase', 3, 35511, '백만원'),
    ('lino-channels', 'salesChannel', 7, 295239088, '천원'),
  ]) {
    test('actual $name preserves source fields, units and purpose', () {
      final source = fixture(name);
      final table = BusinessTableInsights.parse(
        source,
        reportPeriod: '원문 보고기간',
      ).where((t) => t.topic == topic).last;
      expect(table.rows, hasLength(rows));
      expect(table.measures.first.value, amount);
      expect(table.measures.first.unit, unit);
      expect(source.contains(table.evidence), isTrue);
      if (name == 'ibk-funding') {
        expect(table.measures[1].value, 1.24);
        expect(table.measures[1].unit, '%');
        expect(table.measures[2].value, 27.20);
        expect(table.measures[0].period, '제66기 반기 · 평균잔액');
        expect(table.measures[1].period, '제66기 반기 · 이자율');
      }
      if (name == 'alteogen-licenses') {
        expect(table.measures[1].value, 13000000);
        expect(table.measures[1].metric, contains('수취금액'));
        final confidential = table.rows.firstWhere(
          (r) => r.cells[1].contains('Sandoz'),
        );
        expect(confidential.cells[5], contains('비공개'));
        expect(table.measures.any((m) => m.label.contains('Sandoz')), isFalse);
        expect(table.rows[1].cells.first, contains('ALT-B4'));
      }
      if (name == 'ibk-liquidity') {
        expect(table.measures.map((m) => m.value), contains(141.30));
      }
    });
  }
  for (final (name, count) in [
    ('wonik-projects', 43),
    ('vitzrocell-projects', 35),
  ]) {
    test(
      'actual $name retains every project without manufacturing financial metrics',
      () {
        final tables = BusinessTableInsights.parse(
          fixture(name),
          reportPeriod: '원문 보고기간',
        );
        final table = tables.where((t) => t.topic == 'researchProjects').last;
        expect(table.rows, hasLength(count));
        expect(table.measures, isEmpty);
      },
    );
  }
  test('conditional biotech licensing amounts stay literal and never become received cash', () {
    final table = BusinessTableInsights.parse(
      fixture('abl-licenses'),
      reportPeriod: '2025 연간',
    ).where((t) => t.topic == 'majorContracts').last;
    expect(table.rows, hasLength(8));
    expect(table.rows.first.cells[4], contains('로열티 별도'));
    expect(table.rows.first.cells[5], contains('반환의무 없음'));
    expect(table.measures, isEmpty);
  });
  test(
    'bank income rows and product descriptions are never derivative headers',
    () {
      const source = '''## 5. 파생상품
(단위: 백만원)
위험회피회계 파생상품 관련손익 | - | - | -
외환거래손익 | (10,012) | 5,746 | 174,235
연결당기순이익 | 271,585 | 205,956 | 223,972
주식형펀드 | 펀드자산의 60%이상을 주식 및 주식관련파생상품에 투자하는 상품
해외펀드 | 해외의 주식, 채권에 투자하는 펀드
''';
      expect(
        BusinessTableInsights.parse(source, reportPeriod: '2026 반기'),
        isEmpty,
      );
    },
  );
  test(
    'contract footnotes and period subheaders never become company facts',
    () {
      const source = '''## 주요 계약
계약상대방 | 계약체결일 | 계약금액(USD)
A | 2026.01.01 | 10
(주1) | 상세 내용은 비공개
## 환위험 민감도
구분 | 10% 상승 | 10% 하락
당반기 | 전기
''';
      final tables = BusinessTableInsights.parse(
        source,
        reportPeriod: '2026 반기',
      );
      expect(tables, hasLength(1));
      expect(tables.single.rows, hasLength(1));
    },
  );
}
