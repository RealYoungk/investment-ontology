import '../../generated/protocol.dart';
import 'order_facts.dart';

/// Printed monetary observations remain visible without asserting an equation.
abstract final class OrderUnreconciledSourceTables {
  static List<BusinessTableInsight> parse(String text, String period) {
    final rejected = <String>{};
    final ambiguous = <String>{};
    final printed = <String, OrderFactPrintedValues>{};
    OrderFacts.parse(
      text,
      rejectedEvidence: rejected,
      printedValues: printed,
      ambiguousEvidence: ambiguous,
    );
    return [
      for (final line in ambiguous)
        BusinessTableInsight(
          topic: 'orderSourceAmbiguous',
          title: '수주 원문 · 금액 열 구분 불가',
          columns: ['원문 행'],
          rows: [
            BusinessTableRecord(
              label: line.split('|').first.trim(),
              cells: [line],
            ),
          ],
          measures: [],
          evidence: line,
          validation: '수량·금액 열 대응이 명시되지 않아 금액을 산출하지 않음 · 원문 보존',
          scope: period,
        ),
      for (final entry in printed.entries)
        if (rejected.contains(entry.key))
          BusinessTableInsight(
            topic: 'orderSourceUnreconciled',
            title: '수주 원문 금액 · 차감식 미검산',
            columns: ['원문 행'],
            rows: [
              BusinessTableRecord(label: entry.value.label, cells: [entry.key]),
            ],
            measures: [
              if (entry.value.total case final total?)
                BusinessTableMeasure(
                  label: entry.value.label,
                  metric: entry.value.totalHeader,
                  period: period,
                  value: total,
                  unit: entry.value.unit,
                ),
              if (entry.value.delivered case final delivered?)
                BusinessTableMeasure(
                  label: entry.value.label,
                  metric: entry.value.deliveredHeader,
                  period: period,
                  value: delivered,
                  unit: entry.value.unit,
                ),
              if (entry.value.backlog case final backlog?)
                BusinessTableMeasure(
                  label: entry.value.label,
                  metric: entry.value.backlogHeader,
                  period: period,
                  value: backlog,
                  unit: entry.value.unit,
                ),
            ],
            evidence: entry.key,
            validation: '명시 금액 열 원문 관측 · 수주총액−기납품액=수주잔고 검산 불일치 또는 미공시 칸으로 미검산 · 원문 부호 유지 · 수량을 금액으로 사용하지 않음',
            scope: period,
          ),
    ];
  }
}
