import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  test('same material name stays separate by explicit subsidiary', () {
    const text =
        "## 3. 원재료 및 생산설비\n냉난방 부문 (회사명 : 오텍캐리어)\n나. 주요 원재료 가격\n(단위 : 원)\n품목 | 2026년 | 2025년\n철판 | 10 | 20\n냉동냉장 부문 (회사명 : 씨알케이)\n나. 주요 원재료 가격\n(단위 : 원)\n품목 | 2026년 | 2025년\n철판 | 30 | 40";
    final tables = BusinessTableInsights.parse(text, reportPeriod: '2026 반기');
    final names = tables.expand((t) => t.measures).map((m) => m.label).toSet();
    expect(names, hasLength(2));
    expect(names.any((n) => n.contains('냉난방부문')), isTrue);
    expect(names.any((n) => n.contains('냉동냉장부문')), isTrue);
  });

  test('MiCo repeated ratio headers inherit their own preceding period', () {
    const text = '''## 주요 원재료 현황
[단위 : 백만원]
부문 | 품목 | 제28기 2분기매입액 | 비율 | 제27기매입액 | 비율 | 주요 매입처
반도체 | Mount | 13,347 | 13.40% | 35,045 | 16.33% | 나노켐
에너지 | Frame | 86,228 | 86.60% | 179,561 | 83.67% | 나노엑스
합계 | 99,575 | 100% | 214,605 | 100% | -
''';
    final table = BusinessTableInsights.parse(
      text,
      reportPeriod: '2026 반기',
    ).single;
    final shares = table.measures.where((m) => m.unit == '%').toList();
    expect(shares.map((m) => m.period).toSet(), {'제28기 2분기매입액', '제27기매입액'});
    expect(table.rows.last.label, '합계');
  });
  test('field-value licensing tables are structured without interpreting milestone prose', () {
    const text = '''## 주요 계약
(단위 : 백만달러)
품목 | ALT-B4
계약상대방 | A
계약체결일 | 2026.01.01
총계약금액 | 100
진행상황 | 임상 진행 중
''';
    final table = BusinessTableInsights.parse(
      text,
      reportPeriod: '2026 반기',
    ).single;
    expect(table.topic, 'majorContracts');
    expect(table.rows.single.cells.last, '임상 진행 중');
    expect(table.measures.single.value, 100);
  });
  test(
    'two-line year headers bind each amount and share to its printed period',
    () {
      const text = '''## 시설투자 계획
(단위 : 백만원, %)
투자대상 | 2027년 | 2028년
투자액 | 비중 | 투자액 | 비중
공장 | 400 | 40% | 500 | 50%
''';
      final table = BusinessTableInsights.parse(
        text,
        reportPeriod: '2026',
      ).single;
      expect(table.measures.map((m) => m.value), [400, 40, 500, 50]);
      expect(table.measures.last.period, '2028년 · 비중');
    },
  );
  test('a preceding price section never reclassifies the production table', () {
    const source = '''나. 원재료 가격변동 추이
가격변동 원인입니다.
다. 생산능력, 생산실적, 가동률
(단위 : 배치)
구분 | 2026년 | 2025년
생산능력 | 541 | 1034
생산실적 | 100 | 200
''';
    expect(
      BusinessTableInsights.parse(source, reportPeriod: '2026 반기'),
      isEmpty,
    );
  });
  String fixture(String name) =>
      File('test/fixtures/business_tables/$name.txt').readAsStringSync();
  test('actual biologics table preserves merged cells, unit and totals without double counting', () {
    final source = fixture('biologics-materials');
    final table = BusinessTableInsights.parse(
      source,
      reportPeriod: '2026 반기',
    ).single;
    expect(table.topic, 'materialPurchase');
    expect(table.measures.map((m) => m.value), [3085, 2456]);
    expect(table.measures.every((m) => m.unit == '억원'), isTrue);
    expect(table.rows[1].cells.first, 'CDMO');
    expect(table.rows.last.cells.join(' '), contains('5,541'));
    expect(source.contains(table.evidence), isTrue);
  });
  test('actual sales channels retain export/domestic and printed rounding discrepancy', () {
    final table = BusinessTableInsights.parse(
      fixture('cmtx-sales'),
      reportPeriod: '2025 연간',
    ).single;
    expect(table.topic, 'salesChannel');
    final amounts = table.measures.where((m) => m.unit == '백만원').toList();
    expect(amounts.first.value, 68071);
    expect(amounts[1].label, contains('수출'));
    expect(amounts[2].label, contains('국내'));
    expect(amounts.any((m) => m.label.contains('소계')), isFalse);
    expect(table.validation, contains('검산 미수행'));
  });
  test('actual research projects are field records, never inferred business summaries', () {
    final table = BusinessTableInsights.parse(
      fixture('cmtx-research'),
      reportPeriod: '2025 연간',
    ).single;
    expect(table.topic, 'researchProjects');
    expect(table.rows.first.cells.last, '2019년~2020년');
    expect(table.rows.length, greaterThan(1));
    expect(table.measures, isEmpty);
  });
  test('prices preserve periods and per-quantity units; plans remain distinct from execution', () {
    const source = '''## 주요 원재료 가격변동
(단위 : 원/kg)
품목 | 2026년 반기 | 2025년
철강 | 120 | 100
## 시설투자 계획
(단위 : 백만원)
투자대상 | 2027년 | 2028년
공장 | 400 | 600
''';
    final tables = BusinessTableInsights.parse(source, reportPeriod: '2026 반기');
    expect(tables.map((t) => t.topic), ['materialPrice', 'investmentPlan']);
    expect(tables.first.measures.first.unit, '원/kg');
    expect(tables.first.measures.first.period, '2026년 반기');
    expect(tables.last.measures.last.period, '2028년');
  });
  test('contracts, negative fair values and sensitivity effects keep explicit fields', () {
    const source = '''## 주요 계약
계약상대방 | 계약명 | 계약기간 | 계약금액(USD)
A | 공급 | 2026~2028 | 100
## 파생상품
(단위 : 백만원)
상품명 | 명목금액 | 공정가치 | 만기일
통화선도 | 200 | (10) | 2027.12.31
## 환위험 민감도
(단위 : 백만원)
구분 | 10% 상승 | 10% 하락
USD | △50 | 50
''';
    final tables = BusinessTableInsights.parse(source, reportPeriod: '2026 반기');
    expect(tables.map((t) => t.topic), [
      'majorContracts',
      'derivatives',
      'riskSensitivity',
    ]);
    expect(tables[1].measures.last.value, -10);
    expect(tables.last.measures.first.value, -50);
  });
  test('missing/ambiguous units, percent limits, development prose and section boundaries are safe', () {
    const noUnit = '품목 | 매입액\nA | 100';
    expect(
      BusinessTableInsights.parse(noUnit, reportPeriod: '2026').single.measures,
      isEmpty,
    );
    expect(
      BusinessTableInsights.parse(
        '(단위 : 원, USD)\n$noUnit',
        reportPeriod: '2026',
      ).single.measures,
      isEmpty,
    );
    expect(
      BusinessTableInsights.parse(
        '(단위 : 억원 / 백만달러)\n$noUnit',
        reportPeriod: '2026',
      ).single.measures,
      isEmpty,
    );
    expect(
      BusinessTableInsights.parse(
        '투자 계획은 없습니다.\n설명 | 내용\n사업 | 연구과제명 및 계약상대방',
        reportPeriod: '2026',
      ),
      isEmpty,
    );
    const boundary = '(단위 : 억원)\n## 새 절\n품목 | 매입액\nA | 100';
    expect(
      BusinessTableInsights.parse(
        boundary,
        reportPeriod: '2026',
      ).single.measures,
      isEmpty,
    );
    final invalidRatio = BusinessTableInsights.parse(
      '판매경로 | 비중\n직판 | 120',
      reportPeriod: '2026',
    ).single;
    expect(invalidRatio.measures, isEmpty);
  });
}
