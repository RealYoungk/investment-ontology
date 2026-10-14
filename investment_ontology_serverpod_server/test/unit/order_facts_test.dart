import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:test/test.dart';

/// 실제 사업보고서 표 모양으로 확인한다.
void main() {
  test('currency unit cannot cross section boundary', () {
    expect(
      OrderFacts.parse(
        '(단위: 백만원)\n## 다음 절\n품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 100 | 40 | 60',
      ),
      isEmpty,
    );
  });
  test('amount header outranks quantity and signed backlog is retained', () {
    const noroo =
        '(단위: 백만원, Ton)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n합 계 | 18,331 | 79,022 | 18,445 | 79,300 | (114) | (278)';
    final rows = OrderFacts.parse(noroo);
    expect(rows.single.total, 79022);
    expect(rows.single.delivered, 79300);
    expect(rows.single.backlog, -278);
    const youngpoong =
        '(단위: MT, 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n영풍 | 348,000 | 1,239,960 | 315,682 | 1,507,386 | -32,318 | 267,426';
    final rejected = <String>{};
    expect(OrderFacts.parse(youngpoong, rejectedEvidence: rejected), isEmpty);
    expect(
      rejected,
      isNotEmpty,
      reason: 'money equation contradicts printed backlog; quantity must not be used',
    );
  });
  test('merged comma amount is rejected even if other quantity triples reconcile', () {
    const source =
        '(단위: 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n합계 | 100 | 1,2345 | 40 | 800 | 60 | 400';
    expect(OrderFacts.parse(source), isEmpty);
  });
  test('explicit company scope survives changing table order', () {
    const a =
        '특장차량 부문 (회사명 : 오텍)\n(단위 : 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 100 | 40 | 60';
    const b =
        '냉동냉장 부문 (회사명 : 씨알케이)\n(단위 : 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n합계 | 200 | 50 | 150';
    final first = OrderFacts.parse('$a\n$b');
    final reverse = OrderFacts.parse('$b\n$a');
    expect(
      {for (final r in first) r.label: r.backlog},
      {for (final r in reverse) r.label: r.backlog},
    );
    expect(first.map((r) => r.label), everyElement(contains('부문')));
  });

  test('GigaVis current-order header is supported only when the balance equation reconciles', () {
    const table =
        "(단위 : 백만원)\n품목 | 당기수주 | 납품액 | 수주잔고\n반도체 기판 검사 및 수리장비 | 55,735 | 42,169 | 13,566";
    final rows = OrderFacts.parse(table);
    expect(rows, hasLength(1));
    expect(rows.single.backlog, 13566);
    expect(rows.single.unit, '백만원');
    expect(OrderFacts.parse(table.replaceAll('13,566', '30,000')), isEmpty);
    expect(OrderFacts.parse(table.replaceAll('백만원', '대')), isEmpty);
  });
  test('malformed numeric cells neither crash a replay nor create quantity-derived amounts', () {
    const text =
        "(단위 : 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n가 | , | 100 | 50 | 50\n나 | 100 | 40 | 60";
    final result = OrderFacts.parse(text);
    expect(result.map((r) => r.label), ['나']);
    expect(result.single.backlog, 60);
  });
  test('국내·해외 줄과 합계 줄이 있으면 합계만 (비에이치아이)', () {
    const bhi = '''
다. 수주상황
(단위 : 건, 백만원)
발주처구분 | 수주총액 | 기납품액 | 수주잔고
수 량 | 금 액 | 금 액 | 금 액
국내 | 34 | 1,374,990 | 483,721 | 891,268
해외 | 20 | 1,930,341 | 434,093 | 1,496,248
합계 | 54 | 3,305,331 | 917,814 | 2,387,516
주1) 2025년 12월 31일 기준 자료입니다.
''';
    final rows = OrderFacts.parse(bhi);
    expect(rows, hasLength(1));
    expect(rows.single.label, '합계');
    expect(rows.single.total, 3305331);
    expect(rows.single.delivered, 917814);
    expect(rows.single.backlog, 2387516);
    expect(rows.single.unit, '백만원', reason: '건은 통화가 아니라 백만원을 고른다');
  });

  test('수량·금액이 번갈아 있으면 금액 쪽을 고른다 (코리아써키트)', () {
    const kc = '''
| (단위 : 천㎡, 백만원)
품목 | 수주일자 | 납기 | 수주총액 | 기납품액 | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액
PCB | 2025.01.01~2025.12.31 | 2025.01.01~2025.12.31 | 1,281 | 1,087,319 | 1,177 | 905,401 | 104 | 181,918
FPCB | 2025.01.01~2025.12.31 | 2025.01.01~2025.12.31 | 930 | 228,816 | 857 | 211,579 | 73 | 17,237
합 계 | 2,211 | 1,316,135 | 2,034 | 1,116,980 | 177 | 199,155
''';
    final rows = OrderFacts.parse(kc);
    expect(rows, hasLength(1));
    expect(rows.single.total, 1316135);
    expect(rows.single.backlog, 199155);
    expect(rows.single.unit, '백만원');
  });

  test('합계 줄이 없어도 미공시 칸(-)은 확정 0으로 만들지 않는다 (SK이터닉스)', () {
    const sk = '''
(기준일 : 2025.12.31) | (단위 : 백만원)
회사명 | 발주처 | 수주내용 | 수주일자 | 납기 | 수주총액 | 기납품액 | 수주잔고
SK이터닉스㈜ | 풍백풍력발전㈜ | 풍백풍력발전단지 EPC공사 | 2022.06 | 2025.06 | 180,000 | 154,795 | 25,205
충주에코파크㈜ | 충주에코파크 연료전지 EPC공사 | 2024.09 | 2026.04 | 171,949 | 171,949 | -
파주에코그린에너지㈜ | 파주에코그린에너지 연료전지 EPC공사 | 2025.08 | 2026.11 | 141,495 | - | 141,495
''';
    final rows = OrderFacts.parse(sk);
    expect(rows.map((r) => r.backlog), [25205]);
    expect(rows.first.label, 'SK이터닉스㈜');
  });

  test('식이 안 맞는 줄은 버리고, 통화가 여럿인 표는 통째로 버린다', () {
    const wrong = '''
(단위 : 백만원)
품목 | 수주총액 | 기납품액 | 수주잔고
가 | 1,000 | 300 | 800
나 | 1,000 | 300 | 700
''';
    final rows = OrderFacts.parse(wrong);
    expect(rows.map((r) => r.label), ['나']);

    const multi = '''
(단위: 천 USD, 천 CHF, 백만 KRW)
품목 | 수주총액 | 기납품액 | 수주잔고
A | 1,000 | 300 | 700
''';
    expect(OrderFacts.parse(multi), isEmpty);
  });

  test('괄호로 적은 기납품액은 뺀 금액이다 (HD한국조선해양)', () {
    const hd = '''
| (단위 : 백만원)
품목 | 수주일자 | 납기 | 수주총액(*1) | 기납품액(*2) | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액
상선 | 2025.12.31일까지 | - | - | 36,326,613 | - | (10,322,942) | - | 26,003,671
합 계 | - | 47,522,125 | - | (13,027,061) | - | 34,495,064
''';
    final rows = OrderFacts.parse(hd);
    expect(rows, hasLength(1));
    expect(rows.single.delivered, 13027061);
    expect(rows.single.backlog, 34495064);
  });

  test('수량 단위뿐인 표와 이름이 겹치는 프로젝트별 표는 받지 않는다', () {
    const tons = '''
(단위 : T)
품목 | 수주총액 | 기납품액 | 수주잔고
합계 | 33,545,482 | 17,743,688 | 15,801,794
''';
    expect(OrderFacts.parse(tons), isEmpty);

    const projects = '''
(단위 : 백만원)
품목 | 수주일자 | 납기 | 수주총액 | 기납품액 | 수주잔고
제조장비 | 2025-01-01 | 2026-12-31 | 90,000 | 0 | 90,000
제조장비 | 2025-06-01 | 2027-12-31 | 50,000 | 10,000 | 40,000
''';
    expect(OrderFacts.parse(projects), isEmpty);
  });

  test('단위가 표 바로 앞에 없으면 받지 않는다', () {
    const noUnit = '''
(단위 : 백만원)
가. 다른 표 이야기
줄1
줄2
줄3
품목 | 수주총액 | 기납품액 | 수주잔고
A | 1,000 | 300 | 700
''';
    expect(OrderFacts.parse(noUnit), isEmpty);
  });

  test('흐름형(기초·신규·기납품·기말잔고) 표는 기초 + 신규 − 기납품 = 잔고로 검산한다', () {
    const t = '''
(기준일: 2025년 12월 31일) | (단위 : 백만원)
품목 | 수주일자 | 납기 | 기초수주잔액 | 사업결합 | 신규증감 | 기납품액 | 기말수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
조 선 | '25.12.31일까지 | - | - | 33,937,341 | - | 11,376,357 | - | 11,500,524 | - | (12,463,097) | - | 44,351,125
합 계 | - | 46,931,768 | - | 11,376,357 | - | 15,656,980 | - | (17,580,633) | - | 56,384,472
※ 기말수주잔고 = 기초수주잔액 + 신규증감 - 기납품액
| (단위 : 억원)
사업본부 | 품목 | 수주일자 | 납기 | 이월 수주잔액 | 당기 수주금액 | 기납품액 | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
전력 | T&D | ~'25.12 | '25.01~ | - | 32,692 | - | 36,742 | - | 20,532 | - | 48,902
합 계 | - | 34,477 | - | 37,364 | - | 21,687 | - | 50,154
| (단위 : 톤, 억원 )
사업본부 | 품목 | 수주일자 | 납기 | 이월 수주잔액 | 당기 수주금액 | 기납품액 | 수주잔고
금속 | STS관 | ~'25.12 | '25.01~ | 8,889 | 453 | 15,011 | 851 | 16,506 | 936 | 7,394 | 368
''';
    final rows = OrderFacts.parse(t);
    expect(rows.map((r) => r.label), ['합계', '합계 (2)']);
    expect(rows[0].total, 46931768 + 11376357 + 15656980);
    expect(rows[0].delivered, 17580633);
    expect(rows[0].backlog, 56384472);
    expect(rows[0].unit, '백만원');
    expect(rows[1].backlog, 50154);
    expect(rows[1].unit, '억원');

    // 합계 표가 있는 문서에서 합계 없는 자회사 표의 한 줄은 그 회사 값이 아니다.
    const t2 = '''
| (단위 : 억원)
사업본부 | 품목 | 수주일자 | 납기 | 이월 수주잔액 | 당기 수주금액 | 기납품액 | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
전력 | T&D | ~'25.12 | '25.01~ | - | 32,692 | - | 36,742 | - | 20,532 | - | 48,902
합 계 | - | 34,477 | - | 37,364 | - | 21,687 | - | 50,154
[LS ELECTRIC Vietnam]
| (단위 : 억원 )
사업본부 | 품목 | 수주일자 | 납기 | 이월 수주잔액 | 당기 수주금액 | 기납품액 | 수주잔고
전력 | 배전반 외 | ~'25.12 | '25.01~ | - | 531 | - | 1,050 | - | 1,133 | | 448
''';
    expect(OrderFacts.parse(t2).map((r) => r.label), ['합계']);
  });

  test('건설형(기본도급액·완성공사액·계약잔액)은 받되, 공사명·발주처가 있는 상세표는 받지 않는다', () {
    const t = '''
(단위 : 백만원)
구 분 | 발 주 처 | 공 사 명 | 계 약 일 | 준공예정일 | 기본도급액 | 완성공사액 | 계약잔액 | 비고
해외 | 발주처A | 프로젝트A | 2023-01-01 | 2027-12-31 | 100,000 | 59,729 | 40,271 | -
구분 | 수주처명 | 사업명 | 최초계약일 | 완공예정일 | 기본도급액 | 완성공사액 | 계약잔액
ICT설비유지보수 등 | 한국수력원자력(주) | 정보시스템 유지관리 | 2025.08.25 | 2027.08.24 | 78,120 | 14,068 | 64,052
합계 | 432,351 | 219,404 | 212,949
공사명 | 발주처 | 공사착공일 | 완공예정일 | 기본도급액 | 완성공사액 | 계약잔액
힐스테이트 레이크 송도 4차 (A16) | 송도랜드마크시티 | 2022-03-07 | 2025-06-30 | 1,247,851 | 1,230,302 | 17,549
합계 | 1,982,500 | 1,348,752 | 633,749
(기준일 : 2025년 12월 31일) | (단위 : 백만원)
구분 | 기본도급액 | 완성공사액 | 계약잔액
국내 | 56,238,767 | 11,234,577 | 45,004,190
해외 | 19,416,337 | 13,823,709 | 5,592,628
합계 | 75,655,104 | 25,058,286 | 50,596,818
''';
    final rows = OrderFacts.parse(t);
    expect(rows, hasLength(1));
    expect(rows.single.label, '합계');
    expect(rows.single.backlog, 50596818);
  });

  test('품목 칸이 빈 이어지는 줄은 앞 줄의 품목이고, 날짜는 이름이 아니다 (현대제철)', () {
    const t = '''
(단위 : 백만원)
품목 | 수주일자 | 납기 | 수주총액 | 기납품액 | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액
철근 | 2020.03.26 | 2022.04.25 | 779 | 715,837 | 779 | 715,837 | - | -
2022.06.2 | 2024.05.8 | 826 | 1,007,182 | 172 | 194,356 | 654 | 812,826
''';
    final rows = OrderFacts.parse(t);
    expect(rows.map((r) => r.label), ['철근 (2)']);
    expect(rows.single.backlog, 812826);
  });

  test('기초·신규 칸이 있으면 수주총액이 있어도 흐름형이고, 매출계상액도 기납품액이다', () {
    const t = '''
| (단위 : 백만원)
품목 | 수주일자 | 납기 | 수주총액 | 산규계약 | 기납품액 | 수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
친환경솔루션(FSRU, FSU, EPLO, EGCS 등) | 25.12.31일 까지 | - | - | 189,745 | - | 198,695 | - | 157,848 | - | 230,592
합 계 | - | 189,745 | - | 198,695 | - | 157,848 | - | 230,592
(단위 : 억원)
사업부문 | 수주일자 | 납 기 | 전기이월 수주잔고 | 증감액 | 매출계상액 | 수주잔고
선박엔진 | - | - | 33,563 | 19,442 | 12,299 | 40,706
합계 | - | - | 33,842 | 19,894 | 12,309 | 41,427
| (단위 : 백만원)
품목 | 수주일자 | 납기 | 기초계약잔액 | 수주총액 | 기납품액 | 수주잔고
(2024.12.31) | (2025.12.31)
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
시스템구축 및 운영 | - | - | - | 3,452,105 | - | 2,924,396 | - | 2,422,376 | - | 3,954,126
합 계 | - | 3,452,105 | - | 2,924,396 | - | 2,422,376 | - | 3,954,126
''';
    final rows = OrderFacts.parse(t);
    expect(rows.map((r) => r.label), ['합계', '합계 (2)', '합계 (3)']);
    expect(rows.map((r) => r.backlog), [230592, 41427, 3954126]);
    expect(rows.map((r) => r.unit), ['백만원', '억원', '백만원']);
  });

  test('수량이 숫자로 섞인 흐름형, 전기말·당기수익 머리글, 괄호 부호 (대한조선·파크시스템스·HD현대에너지솔루션)', () {
    // 합계 줄 없는 한 표뿐인 문서 (합계 표가 있으면 줄 단위 값은 버려진다).
    const ship = '''
| (단위 : 백만원)
품목 | 수주일자 | 납기 | 기초수주잔액 | 신규증감 | 기납품액 | 기말수주잔고
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
선박 | 25년 12월 31일까지 | - | 24 | 2,251,142 | 6 | 691,323 | 11 | 1,219,336 | 19 | 1,723,129
''';
    final shipRows = OrderFacts.parse(ship);
    expect(shipRows.map((r) => (r.label, r.backlog)), [('선박', 1723129.0)]);
    expect(shipRows[0].total, 2251142 + 691323);

    const t = '''
| (단위 : 백만원)
품목 | 전기말수주잔고 | 당기수주총액 | 당기납품액 | 당기말수주잔고
산업용 | 46,740 | 149,124 | 146,185 | 49,679
합 계 | 61,225 | 208,021 | 205,613 | 63,633
| (단위 : 천원)
품목 | 수주일자 | 납기 | 기초계약잔액 | 계약금액 변경 | 신규계약액 | 당기수익 | 기말계약 잔액
수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액 | 수량 | 금액
모듈설치 공사 | '25.12.31 까지 | - | - | 23,807,433 | - | (1,353,700) | - | 11,510,100 | - | (28,584,243) | - | 5,379,590
합 계 | - | 23,807,433 | - | (1,353,700) | - | 11,510,100 | - | (28,584,243) | - | 5,379,590
''';
    final rows = OrderFacts.parse(t);
    expect(rows.map((r) => (r.label, r.backlog)), [
      ('합계', 63633.0),
      ('합계 (2)', 5379590.0),
    ]);
    expect(rows[1].total, 23807433 - 1353700 + 11510100);
  });
  test('explicit monetary span excludes trailing counterparty and numeric notes', () {
    const source =
        '(단위: 백만원)\n품목 | 수주일자 | 납기기간 | 수주총액 | 기납품액 | 수주잔고 | 거래처명 | 비고\n금액 | 금액 | 금액\n제품 | 2024.01.01~2038.12.31 | 2024.01.01~2024.12.31 | 382,000 | 9,442 | 372,557 | 거래처 | 2023.08.16 공시기간내 3,820억원';
    final result = OrderFacts.parse(source);
    expect(result.single.total, 382000);
    expect(result.single.delivered, 9442);
    expect(result.single.backlog, 372557);
    expect(result.single.unit, '백만원');
    expect(
      OrderFacts.parse(source.replaceFirst('382,000', '382,0000')),
      isEmpty,
    );
  });
  test(
    'complete original cash-span fixture selects amount fields before notes',
    () {
      final components = <OrderFactSourceRow>[];
      OrderFacts.parse(
        File(
          'test/fixtures/business_orders/cash_span_with_counterparty_note.txt',
        ).readAsStringSync(),
        verifiedRows: components,
      );
      final actual = components.singleWhere(
        (r) => r.evidence.startsWith('가성소다 |'),
      );
      expect(
        (actual.total, actual.delivered, actual.backlog),
        (382000.0, 9442.0, 372557.0),
      );
      expect(actual.unit, '백만원');
    },
  );
}
