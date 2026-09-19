import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/business/business_tab.dart';

void main() {
  test('사업의 내용 글을 문단과 표 묶음으로 나눈다', () {
    final blocks = businessBlocks(
      '당사는 DRAM을 생산합니다.\n두 번째 줄\n부문 | 제품\nDS | DRAM\n끝',
    );
    expect(
      [for (final b in blocks) (b.table, b.lines.length)],
      [
        (false, 2),
        (true, 2),
        (false, 1),
      ],
    );
  });
}
