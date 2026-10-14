import '../../generated/protocol.dart';
import 'segment_revenue.dart';

/// Bounded source shapes; office sales are not customer-country sales.
abstract final class OperatingSourceContext {
  static List<BusinessTableInsight> parse(String text, String period) {
    final lines = text.split('\n');
    final result = <BusinessTableInsight>[];
    for (var i = 2; i < lines.length; i++) {
      final header = lines[i].split('|').map((s) => s.trim()).toList();
      final context = lines.sublist(i - 2, i).join('\n');
      if (header.length < 3 ||
          header.first != '구분' ||
          !RegExp(r'사업본부별\s*매출').hasMatch(context)) {
        continue;
      }
      final terms = header
          .skip(1)
          .map((s) => RegExp(r'제\s*(\d+)\s*기').firstMatch(s))
          .toList();
      if (terms.any((m) => m == null)) continue;
      final unit = SegmentRevenue.pickUnit(
        RegExp(r'단위\s*[:：]\s*([^)]+)').firstMatch(context)?.group(1),
      );
      if (unit.isEmpty) continue;
      final rows = <BusinessTableRecord>[];
      var end = i + 1;
      for (; end < lines.length && lines[end].contains('|'); end++) {
        final cells = lines[end].split('|').map((s) => s.trim()).toList();
        if (cells.length != header.length) break;
        rows.add(BusinessTableRecord(label: cells.first, cells: cells));
        if (cells.first.replaceAll(' ', '') == '합계') {
          end++;
          break;
        }
      }
      if (rows.length < 3 ||
          rows.last.label.replaceAll(' ', '') != '합계' ||
          !rows.take(rows.length - 1).any((r) => r.label.contains('사업본부'))) {
        continue;
      }
      double? number(String s) => double.tryParse(s.replaceAll(',', ''));
      final measures = <BusinessTableMeasure>[];
      var valid = true;
      for (var col = 1; col < header.length; col++) {
        final values = rows.map((r) => number(r.cells[col])).toList();
        if (values.any((v) => v == null || v < 0) ||
            (values.take(values.length - 1).fold<double>(0, (s, v) => s + v!) -
                        values.last!)
                    .abs() >
                1) {
          valid = false;
          break;
        }
        for (var row = 0; row < rows.length - 1; row++) {
          measures.add(
            BusinessTableMeasure(
              label: rows[row].label,
              metric: '사업본부 매출',
              period: header[col],
              value: values[row]!,
              unit: unit,
            ),
          );
        }
      }
      if (!valid) continue;
      result.add(
        BusinessTableInsight(
          topic: 'businessOfficeRevenue',
          title: '사업본부별 매출',
          columns: header,
          rows: rows,
          measures: measures,
          evidence: lines.sublist(i - 2, end).join('\n'),
          validation: '각 인쇄 기간의 사업본부 매출 합계 검산 · 고객 소재국별 매출과 구분',
          scope: period,
        ),
      );
      i = end - 1;
    }
    // Show explicit withholding/absence statements as source context, not zeros.
    final limits = <BusinessTableRecord>[];
    String? section;
    for (final line in lines) {
      if (line.startsWith('##')) {
        section = line;
        continue;
      }
      if (line.contains('|')) continue;
      if (section != null && section.contains('기타 참고사항')) {
        final estimate = RegExp(r'이를 기준으로[^.]*?(?:\d+\.\d+%)[^.]*?추정되고 있습니다\.')
            .firstMatch(line);
        if (estimate != null) {
          limits.add(
            BusinessTableRecord(
              label: '시장점유율 · 회사 추정',
              cells: ['시장점유율 · 회사 추정', estimate.group(0)!],
            ),
          );
        }
      }
      if (section != null &&
          section.contains('주요계약') &&
          line.contains('비경상적인 중요계약') &&
          line.contains('체결하고 있지 않습니다')) {
        limits.add(
          BusinessTableRecord(
            label: '비경상적 중요계약 없음',
            cells: ['비경상적 중요계약 없음', line],
          ),
        );
      }
      if (section != null &&
          section.contains('매출 및 수주') &&
          RegExp(r'수주.*(?:잔고|총액)').hasMatch(line) &&
          line.contains('언급은 생략')) {
        limits.add(
          BusinessTableRecord(label: '수주 수치 비공개', cells: ['수주 수치 비공개', line]),
        );
      } else if (section != null &&
          section.contains('원재료 및 생산') &&
          line.contains('수작업') &&
          line.contains('생산시설이 미미')) {
        limits.add(
          BusinessTableRecord(label: '생산 규모 설명', cells: ['생산 규모 설명', line]),
        );
      }
    }
    if (limits.isNotEmpty) {
      result.add(
        BusinessTableInsight(
          topic: 'disclosureLimitsSource',
          title: '수치가 없는 항목의 공시 설명',
          columns: ['항목', '원문 설명'],
          rows: limits,
          measures: [],
          evidence: limits.map((r) => r.cells.last).join('\n'),
          validation: '공시 원문에 명시한 설명 · 미공개 수치를 0으로 처리하지 않음',
          scope: period,
        ),
      );
    }
    return result;
  }
}
