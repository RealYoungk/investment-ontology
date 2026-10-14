import '../../generated/protocol.dart';
import 'production_facts.dart';

/// Source-backed activity ratios; hours are never product capacity or output.
abstract final class ActivityUtilizationTables {
  static List<BusinessTableInsight> parse(String text, String period) {
    final rows = ProductionFacts.parse(text)
        .where((r) => r.capacity == null && r.production == null)
        .toList();
    if (rows.isEmpty) return [];
    final seen = <String>{};
    final unique = rows
        .where((r) => seen.add('${r.label}|${r.utilization}|${r.evidence}'))
        .toList();
    return [
      BusinessTableInsight(
        topic: 'activityUtilization',
        title: '가동시간 기준 가동률',
        columns: ['사업소·품목', '가동률'],
        rows: [
          for (final row in unique)
            BusinessTableRecord(
              label: row.label,
              cells: [row.label, '${row.utilization}%'],
            ),
        ],
        measures: [
          for (final row in unique)
            BusinessTableMeasure(
              label: row.label,
              metric: '가동률',
              period: period,
              value: row.utilization,
              unit: '%',
            ),
        ],
        evidence: unique.map((r) => r.evidence).join('\n'),
        validation: '실제 가동시간 ÷ 가동가능시간과 인쇄 가동률 검산 · 인력 공수도 포함 · 제품 생산량과 구분',
        scope: period,
      ),
    ];
  }
}
