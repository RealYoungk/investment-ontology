import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_order_fact_projection.dart';

DocumentFact fact(
  String evidence,
  double value, {
  DocumentFactKind kind = DocumentFactKind.orderBacklog,
  RelationOrigin origin = RelationOrigin.api,
}) => DocumentFact(
  companyId: 1,
  documentId: 1,
  bsnsYear: 2021,
  kind: kind,
  label: '합계',
  value: value,
  unit: '백만원',
  evidence: evidence,
  extractedBy: origin,
  status: RelationStatus.verified,
  createdAt: DateTime.utc(2021),
);
void main() {
  test('quantity larger than cash cannot become monetary facts', () {
    const row = '합 계 | 72,030 | 4,734 | 62,742 | 4,171 | 9,288 | 563';
    final old = [
      fact(row, 72030, kind: DocumentFactKind.orderTotal),
      fact(row, 62742, kind: DocumentFactKind.orderDelivered),
      fact(row, 9288),
    ];
    final result = StoredOrderFactProjection.revalidate(
      old,
      '(단위: 백만원, 천개)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n$row',
    );
    expect(result.map((f) => f.value), [4734.0, 4171.0, 563.0]);
  });
  test('closed contract missing backlog is not converted into a disclosed zero', () {
    const row = '합 계 | 24 | 17,820 | 24 | 17,820 | - | -';
    final result = StoredOrderFactProjection.revalidate(
      [fact(row, 17820), fact(row, 24, kind: DocumentFactKind.orderDelivered)],
      '(단위: 세트, 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n$row',
    );
    expect(result, isEmpty);
  });
  test('cash literal with failed equation leaves verified list for source-only observation', () {
    const row = '합계 | 100 | 20 | 50';
    expect(
      StoredOrderFactProjection.revalidate([
        fact(row, 50),
      ], '(단위: 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n$row'),
      isEmpty,
    );
  });
  test(
    'calendar opening column and other adjustment do not replace backlog',
    () {
      const row = '민수사업 | - | - | 3,011 | 4,648 | 2,899 | -115 | 4,645';
      final result = StoredOrderFactProjection.revalidate(
        [fact(row, 115)],
        '(단위: 억원)\n사업부문 | 수주일자 | 납기 | 2024년말 | 기수주총액 | 기납품액 | 기타 | 수주잔고\n$row',
      );
      expect(result.single.value, 4645);
      expect(result.single.unit, '억원');
    },
  );
  test('signed amount projection leaves persisted object untouched', () {
    const row = '합 계 | 18,331 | 79,022 | 18,445 | 79,300 | (114) | (278)';
    final stored = fact(row, 114);
    final result = StoredOrderFactProjection.revalidate(
      [stored],
      '(단위: 백만원, Ton)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n$row',
    );
    expect(result.single.value, -278);
    expect(stored.value, 114);
  });
  test('FX after revenue is not delivered revenue, including historical component', () {
    const row =
        '사출금형사업부 | 53,402,794 | 107,298,723 | - | (94,523,059) | (71) | 66,178,387';
    const total =
        '합 계 | 100,943,604 | 143,465,158 | (1,681,192) | (141,180,475) | 1,472,654 | 103,019,749';
    final result = StoredOrderFactProjection.revalidate(
      [fact(row, 71, kind: DocumentFactKind.orderDelivered)],
      '(단위: 천원)\n사업부 | 기초계약잔액 | 신규계약액 | 계약변경액 | 공사수익인식액 | 환율차이 | 기말계약잔액\n$row\n$total',
    );
    expect(result.single.value, 94523059);
    expect(result.single.unit, '천원');
  });
  test(
    'missing evidence or unsupported prose is not rejected, AI unchanged',
    () {
      final old = fact('현재 원문에 없는 과거 증거', 100);
      final ai = fact('기존 AI 증거', 20, origin: RelationOrigin.ai);
      final result = StoredOrderFactProjection.revalidate([old, ai], '새 원문');
      expect(result.first.value, old.value);
      expect(result.first.reviewedBy, contains('재검산 미확인'));
      expect(result.last, ai);
    },
  );
  test('Korea BTB dollar-prefixed amounts replace quantity with exact cash equation', () {
    const row =
        '합 계 | 19,343,200 | \$31,673,120 | 386,803 | \$4,900,803 | 18,956,397 | \$26,772,317';
    final old = [
      fact(row, 19343200, kind: DocumentFactKind.orderTotal),
      fact(row, 386803, kind: DocumentFactKind.orderDelivered),
      fact(row, 18956397),
    ];
    final result = StoredOrderFactProjection.revalidate(
      old,
      '(단위: BOX, \$)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n$row',
    );
    expect(result.map((f) => f.value), [31673120, 4900803, 26772317]);
    expect(result.every((f) => f.unit == '\$'), isTrue);
    expect(old.first.value, 19343200);
    expect(
      StoredOrderFactProjection.revalidate(
        [
          fact(
            row.replaceFirst('31,673,120', '31,6731,20'),
            19343200,
            kind: DocumentFactKind.orderTotal,
          ),
        ],
        '(단위: BOX, \$)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n${row.replaceFirst('31,673,120', '31,6731,20')}',
      ),
      isEmpty,
    );
  });
  test(
    'explicit subsidiary scopes are labeled while own issuer stays unchanged',
    () {
      const row = '합계 | 100 | 20 | 80';
      const header = '(단위: 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n';
      final e1 = StoredOrderFactProjection.revalidate(
        [fact(row, 80)],
        '수주현황은 아래와 같으며, (주)LS네트웍스는 수주산업을 영위하지 않습니다.\n$header$row',
        companyName: '(주)E1',
      );
      expect(e1.single.label, startsWith('(주)LS네트웍스 · '));
      expect(e1.single.reviewNote, contains('제출회사 전체 수주 합계로 단정하지 않음'));
      final emart = StoredOrderFactProjection.revalidate(
        [fact(row, 80)],
        '■ IT서비스업 부문 : ㈜신세계아이앤씨\n$header$row',
        companyName: '(주)이마트',
      );
      expect(emart.single.label, startsWith('㈜신세계아이앤씨 · '));
      final own = StoredOrderFactProjection.revalidate(
        [fact(row, 80)],
        '■ IT서비스업 부문 : ㈜신세계아이앤씨\n$header$row',
        companyName: '(주)신세계아이앤씨',
      );
      expect(own.single.label, '합계');
      final alias = StoredOrderFactProjection.revalidate(
        [fact(row, 80)],
        '## 종속기업 사업\n주식회사 LS네트웍스(이하 “당사”)는 브랜드사업을 합니다.\n다른표 | 3 | 2\n$header$row',
        companyName: '(주)E1',
      );
      expect(alias.single.label, startsWith('주식회사 LS네트웍스 · '));
      final bounded = StoredOrderFactProjection.revalidate(
        [fact(row, 80)],
        '■ IT서비스업 부문 : ㈜신세계아이앤씨\n## 새 범위\n$header$row',
        companyName: '(주)이마트',
      );
      expect(bounded.single.label, '합계');
    },
  );
  test('equivalent repeated tables preserve historical label without adding totals', () {
    const table = '(단위: 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 100 | 20 | 80';
    final old = fact(
      '합계 | 100 | 20 | 80',
      80,
    ).copyWith(label: '합계 (2)', asOf: DateTime(2021, 12, 31));
    final result = StoredOrderFactProjection.revalidate(
      [old],
      '$table\n설명\n$table',
      companyName: '제출회사',
    );
    expect(result.single.value, 80);
    expect(result.single.label, '합계 (2)');
    expect(result.single.reviewNote, contains('중복 근거를 하나로 확인'));
    expect(old.value, 80);
  });
  test('duplicate source currency, period or company scope conflict stays unresolved', () {
    const body = '품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 100 | 20 | 80';
    final old = fact(
      '합계 | 100 | 20 | 80',
      80,
    ).copyWith(asOf: DateTime(2021, 12, 31));
    for (final source in [
      '(단위: 백만원)\n$body\n(단위: USD)\n$body',
      '기준일: 2021.12.31\n(단위: 백만원)\n$body\n## 새 표\n기준일: 2020.12.31\n(단위: 백만원)\n$body',
      '■ 사업부문 : ㈜별도회사\n(단위: 백만원)\n$body\n## 새 표\n■ 사업부문 : ㈜다른회사\n(단위: 백만원)\n$body',
    ]) {
      final result = StoredOrderFactProjection.revalidate(
        [old],
        source,
        companyName: '제출회사',
      );
      expect(result.single.reviewedBy, contains('재검산 미확인'));
      expect(result.single.value, 80);
    }
  });
  test('stored complete summary/detail source fixture confirms once with same label', () {
    final text = File(
      'test/fixtures/business_orders/equivalent_summary_detail_totals.txt',
    ).readAsStringSync();
    const evidence = '합 계 | - | 5,486 | - | 3,143 | - | 2,343';
    final old = fact(
      evidence,
      2343,
    ).copyWith(label: '합계 (2)', bsnsYear: 2026, asOf: DateTime(2026, 6, 30));
    final out = StoredOrderFactProjection.revalidate(
      [old],
      text,
      companyName: '민테크',
    );
    expect(out.single.label, '합계 (2)');
    expect(out.single.value, 2343);
    expect(out.single.reviewNote, contains('중복 근거를 하나로 확인'));
  });
}
