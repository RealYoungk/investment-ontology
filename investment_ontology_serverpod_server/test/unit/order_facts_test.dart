import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:test/test.dart';

/// 실제 사업보고서 표 모양으로 확인한다.
void main() {
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

  test('합계 줄이 없으면 줄마다, 빈 칸(-)은 0 (SK이터닉스)', () {
    const sk = '''
(기준일 : 2025.12.31) | (단위 : 백만원)
회사명 | 발주처 | 수주내용 | 수주일자 | 납기 | 수주총액 | 기납품액 | 수주잔고
SK이터닉스㈜ | 풍백풍력발전㈜ | 풍백풍력발전단지 EPC공사 | 2022.06 | 2025.06 | 180,000 | 154,795 | 25,205
충주에코파크㈜ | 충주에코파크 연료전지 EPC공사 | 2024.09 | 2026.04 | 171,949 | 171,949 | -
파주에코그린에너지㈜ | 파주에코그린에너지 연료전지 EPC공사 | 2025.08 | 2026.11 | 141,495 | - | 141,495
''';
    final rows = OrderFacts.parse(sk);
    expect(rows.map((r) => r.backlog), [25205, 0, 141495]);
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
}
