import '../../generated/protocol.dart';

/// Source-only fallback: never sums hierarchy rows or guesses rowspan cells.
abstract final class ComplexRevenueSourceTables {
  static List<BusinessTableInsight> parse(
    String text, {
    String reportPeriod = '',
  }) {
    final lines = text.split('\n');
    final out = <BusinessTableInsight>[];
    final period = RegExp(r'20\d{2}|제\s*\d+\s*기');
    final revenue = RegExp(r'매\s*출|영업\s*수익');
    final revenueMetric = RegExp(r'^\s*(매\s*출(액)?|영업\s*수익)\s*$');
    for (var i = 0; i < lines.length; i++) {
      final header = lines[i];
      if (!header.contains('|') ||
          header.split('|').where(period.hasMatch).length < 2 ||
          !RegExp(r'구\s*분|사업\s*부문|매출유형|품\s*목').hasMatch(header)) {
        continue;
      }
      var end = i + 1;
      while (end < lines.length &&
          lines[end].contains('|') &&
          !lines[end].startsWith('##') &&
          !period.hasMatch(lines[end].split('|').first) &&
          !(lines[end].split('|').where(period.hasMatch).length >= 2 &&
              RegExp(r'구\s*분|사업\s*부문|매출유형|품\s*목').hasMatch(lines[end]))) {
        end++;
      }
      final rows = lines.sublist(i + 1, end);
      if (rows.length < 3 || !rows.any((r) => RegExp(r'\d').hasMatch(r))) {
        continue;
      }
      var start = i;
      while (start > 0 && i - start < 4) {
        final previous = lines[start - 1];
        if (previous.contains('|') && !previous.contains('단위')) break;
        start--;
        if (previous.startsWith('##')) break;
      }
      final context = lines.sublist(start, i + 1).join('\n');
      // A sales denominator in an R&D or purchasing table is not a sales
      // composition. Preserve it through its own topic instead.
      if (RegExp(r'연구개발|연구\s*개발|원재료|매입액|매입유형|투자대상|투자계획|투자효과|기대효과')
              .hasMatch(context) ||
          rows.any(
            (r) =>
                RegExp(r'^연구\s*개발\s*비용?\s*(계|총계)?\s*\||연구개발비.*매출|매출.*대비.*연구개발')
                    .hasMatch(r),
          )) {
        continue;
      }
      if (!revenue.hasMatch(context) &&
          !rows.any(
            (r) => r
                .split('|')
                .where((c) => !RegExp(r'\d').hasMatch(c))
                .any(revenueMetric.hasMatch),
          )) {
        continue;
      }
      final hasAdjustment = rows.any(
        (r) => RegExp(r'연결조정|내부거래|단순.*합계').hasMatch(r),
      );
      final hasMixedMetrics = rows.any(
        (r) => RegExp(r'영업이익|자\s*산').hasMatch(r),
      );
      final hasHierarchy =
          rows.where((r) => RegExp(r'소\s*계|합\s*계').hasMatch(r)).length >= 2;
      if (!hasAdjustment &&
          !hasMixedMetrics &&
          !hasHierarchy &&
          !header.contains('회사명')) {
        continue;
      }
      out.add(
        BusinessTableInsight(
          topic: 'complexRevenueSource',
          title: '매출·영업수익 구성 원문',
          columns: ['공시 표 원문 (병합 셀·계층 보존)'],
          rows: [
            BusinessTableRecord(label: header, cells: [header]),
            for (final row in rows)
              BusinessTableRecord(label: row, cells: [row]),
          ],
          measures: [],
          evidence: lines.sublist(start, end).join('\n'),
          validation: '원문 표 · 검산 미확정 · 자회사·품목·소계·합계를 이중 합산하지 않음 · 연결조정·내부거래 제거·단순합계 및 매출·영업수익을 원문 그대로 구분 · 별도 표 비중과 금액을 결합하지 않음 · 단위 변환 없음',
          scope: '인쇄된 표 기간·회사 범위 · 병합 셀은 원문 행으로 표시',
        ),
      );
      i = end - 1;
    }
    return out;
  }
}
