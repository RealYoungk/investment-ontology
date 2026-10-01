import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_breakdown_facts.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  const segment = '''사업부문별 요약 재무 현황
(단위 : 억원, %)
부문 | 구 분 | 제57기 | 제56기 | 제55기
금액 | 비중 | 금액 | 비중 | 금액 | 비중
DX 부문 | 매출액 | 1,879,673 | 56.3% | 1,748,877 | 58.1% | 1,699,923 | 65.7%
영업이익 | 128,527 | 29.5% | 124,399 | 38.0% | 143,847 | 219.0%
총자산 | 1 | 1% | 1 | 1% | 1 | 1%
DS 부문 | 매출액 | 1,301,282 | 39.0% | 1,110,663 | 36.9% | 665,945 | 25.7%
영업이익 | 248,581 | 57.0% | 150,945 | 46.1% | △148,795 | △226.6%
SDC | 매출액 | 298,417 | 8.9% | 1 | 1% | 1 | 1%
영업이익 | 41,163 | 9.4% | 1 | 1% | 1 | 1%
Harman | 매출액 | 157,833 | 4.7% | 1 | 1% | 1 | 1%
영업이익 | 15,311 | 3.5% | 1 | 1% | 1 | 1%
※ 각 사업부문별 요약 재무 현황은 부문 등 간 내부거래를 포함하고 있습니다.
''';
  const geography = '''(3) 주요 지역별 매출 현황
(단위 : 억원)
구 분 | 제57기 | 제56기 | 제55기
내수 | 국내 | 216,560 | 202,978 | 205,196
수출 | 미주 | 678,942 | 613,533 | 510,934
유럽 | 312,307 | 290,967 | 239,342
아시아ㆍ아프리카 | 456,870 | 333,769 | 326,262
중국 | 715,751 | 649,275 | 422,007
계 | 2,380,430 | 2,090,522 | 1,703,741
※ 별도 기준의 내수ㆍ수출 매출 현황입니다.
''';
  List<BreakdownFact> parse(String text) =>
      BusinessBreakdownFacts.parse(text, year: 2025);

  test('실제 삼성 표: 현재 열, 같은 표의 손익, 내부거래 원문을 유지', () {
    final rows = parse(segment);
    expect(rows.length, 8);
    expect(rows.first.value, 1879673);
    expect(rows[1].value, 128527);
    expect(rows.first.evidence, rows[1].evidence);
    expect(segment.contains(rows.first.evidence), isTrue);
    expect(rows.last.kind, DocumentFactKind.segmentOperatingProfit);
  });
  test('비중 모순, 과거 우선 열, 단위 없음, 다른 회사 표 거절', () {
    expect(parse(segment.replaceFirst('29.5%', '40.0%')), isEmpty);
    expect(parse(segment.replaceFirst('제57기 | 제56기', '제56기 | 제57기')), isEmpty);
    expect(parse(segment.replaceFirst('(단위 : 억원, %)', '')), isEmpty);
    expect(
      BusinessBreakdownFacts.parse(
        '[다른회사]\n$segment',
        year: 2025,
        owner: '삼성전자',
        otherCompanies: {'다른회사'},
      ),
      isEmpty,
    );
  });
  test('손실을 절대값으로 바꾸지 않고 보존', () {
    const loss = '''(단위 : 백만원, %)
사업부문 | 구분 | 2025년 | 2024년
금액 | 비율 | 금액 | 비율
A | 매출액 | 100 | 50% | 1 | 1%
영업이익 | 30 | 150% | 1 | 1%
B | 매출액 | 100 | 50% | 1 | 1%
영업이익 | △10 | △50% | 1 | 1%
''';
    expect(parse(loss).last.value, -10);
    expect(parse(loss.replaceFirst('2025년 | 2024년', '2024년 | 2023년')), isEmpty);
  });
  test('지역: 별도 기준과 수출 병합 셀을 이어받고 합계로 검산', () {
    final rows = parse(geography);
    expect(rows.length, 5);
    expect(rows.first.label, '내수 · 국내 · 별도');
    expect(rows.last.label, '수출 · 중국 · 별도');
    expect(rows.last.value, 715751);
    expect(rows.first.unit, '억원');
    expect(geography.contains(rows.first.evidence), isTrue);
    expect(parse(geography.replaceFirst('2,380,430', '2,300,430')), isEmpty);
    expect(parse(geography.replaceFirst('지역별 매출', '고객별 매출')), isEmpty);
  });
  test('중복 표와 복수 통화는 임의 선택하지 않는다', () {
    expect(parse('$geography\n$geography'), isEmpty);
    expect(
      parse('$geography\n${geography.replaceFirst('미주', '아메리카')}'),
      isEmpty,
    );
    expect(parse(geography.replaceFirst('억원', '억원, USD')), isEmpty);
  });
}
