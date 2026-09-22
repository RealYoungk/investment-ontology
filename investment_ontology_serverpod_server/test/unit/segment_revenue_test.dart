import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:test/test.dart';

/// 실제 사업보고서 표 모양으로 확인한다.
void main() {
  const samsung = '''
(단위 : 억원, %)
부 문 | 주요 제품 | 매출액 | 비중
DX 부문 | TV, 모니터, 냉장고 등 | 1,879,673 | 56.3%
DS 부문 | DRAM, NAND Flash 등 | 1,301,282 | 39.0%
SDC | 스마트폰용 OLED패널 등 | 298,417 | 8.9%
Harman | 디지털 콕핏 등 | 157,833 | 4.7%
기타 | 부문간 내부거래 제거 등 | △301,146 | △8.9%
총 계 | 3,336,059 | 100.00%
※ 각 부문별 매출액은 부문 등 간 내부거래를 포함하고 있습니다.
''';

  test('부문별 매출액과 단위를 읽는다', () {
    final rows = SegmentRevenue.parse(samsung);
    expect(rows.map((r) => r.label), [
      'DX 부문',
      'DS 부문',
      'SDC',
      'Harman',
      '기타',
    ]);
    expect(rows.first.amount, 1879673);
    expect(rows.first.unit, '억원');
    expect(rows.last.amount, -301146, reason: '△는 음수');
  });

  test('단위 표기를 돈 단위 하나로 정리한다', () {
    expect(SegmentRevenue.pickUnit('건, 백만원'), '백만원');
    expect(SegmentRevenue.pickUnit('USD 1,000'), 'USD천');
    expect(SegmentRevenue.pickUnit('1,000원'), '천원');
    expect(SegmentRevenue.pickUnit('천USD,천원'), '', reason: '통화 둘');
    expect(SegmentRevenue.pickUnit('개'), '', reason: '수량은 매출 단위가 아니다');
    expect(SegmentRevenue.pickUnit('VND억'), 'VND억');
    expect(SegmentRevenue.pickUnit('천U\$'), '천U\$');
  });

  test('비중이 매출액 ÷ 합계와 어긋나면 그 표를 버린다', () {
    const wrong = '''
(단위 : 억원, %)
부 문 | 매출액 | 비중
가 부문 | 100 | 90.0%
나 부문 | 100 | 10.0%
합 계 | 200 | 100.0%
''';
    expect(SegmentRevenue.parse(wrong), isEmpty);
  });

  test('단위를 못 찾으면 읽지 않는다', () {
    const noUnit = '''
부 문 | 매출액 | 비중
가 부문 | 100 | 50.0%
나 부문 | 100 | 50.0%
''';
    expect(SegmentRevenue.parse(noUnit), isEmpty);
  });

  test('기를 여러 개 적은 표에서는 당기 칸만 읽는다', () {
    // 삼성물산 사업보고서 모양: 당기 · 전기 · 전전기가 나란히 있다.
    const multi = '''
(단위 : 백만원, %)
사업부문 | 매출유형 | 품목 | 제53기 매출액 | 비중 | 제52기 매출액 | 비중 | 제51기 매출액 | 비중
건 설 | 공사 등 | 건축ㆍ토목 | 19,336,000 | 44.80% | 14,591,000 | 42.34% | 11,536,000 | 38.18%
상 사 | 상/제품 | 에너지ㆍ환경 | 20,217,539 | 46.84% | 17,354,478 | 50.37% | 13,251,583 | 43.86%
패 션 | 상/제품 | 의류 | 2,019,620 | 4.68% | 2,004,233 | 5.82% | 2,051,027 | 6.79%
합 계 | 43,159,000 | 100.00% | 34,455,000 | 100.00% | 30,213,000 | 100.00%
''';
    final rows = SegmentRevenue.parse(multi);
    expect(rows.map((r) => r.label), ['건 설', '상 사', '패 션']);
    expect(rows[1].amount, 20217539, reason: '전전기(13,251,583)가 아니라 당기');
    expect(rows.first.unit, '백만원');
  });

  test('앞 표의 단위가 다음 표로 새지 않는다', () {
    const twoTables = '''
(단위 : 톤)
품목 | 생산능력 | 실적
가 | 100 | 90

부 문 | 매출액 | 비중
가 부문 | 100 | 50.0%
나 부문 | 100 | 50.0%
''';
    expect(
      SegmentRevenue.parse(twoTables),
      isEmpty,
      reason: '두 번째 표에는 단위가 없다',
    );
  });

  test('매출처별 표는 부문 매출이 아니다 (씨에스윈드)', () {
    const t = '''
(단위: 백만원, %)
매출처 | 매출품목 | 매출유형 | 제20기(2025년) | 제19기(2024년) | 제18기(2023년)
매출액 | 비중 | 매출액 | 비중 | 매출액 | 비중
주요고객사 | A사 | 풍력타워 등 | 제품 등 | 525,881 | 17.9% | 327,181 | 10.6% | 133,680 | 8.8%
B사 | 풍력타워 등 | 제품 등 | 101,316 | 3.5% | 173,477 | 5.6% | 200,000 | 10.0%
합계 | 2,931,600 | 100.0% | 3,072,500 | 100.0% | 1,500,000 | 100.0%
''';
    expect(SegmentRevenue.parse(t), isEmpty);
  });
}
