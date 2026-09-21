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
}
