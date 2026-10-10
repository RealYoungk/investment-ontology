import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'rnd_facts.dart';

abstract final class InterimRndFacts {
  /// Read-only rule projection for interim documents omitted by the legacy annual-only ingest.
  static Future<List<DocumentFact>> read(
    Session session,
    BusinessDocument doc,
    DisclosureReport report,
  ) async {
    if (report.reportCode == FinancialReportCode.annual) return [];
    final table = RndFacts.parse(doc.text, bsnsYear: doc.bsnsYear);
    if (table == null || table.years.first != doc.bsnsYear) return [];
    final scale = const {
      '원': 1.0,
      '천원': 1e3,
      '백만원': 1e6,
      '억원': 1e8,
      '십억원': 1e9,
      '조원': 1e12,
    }[table.unit];
    final ratio = table.ratio?.values.first;
    if (scale == null || ratio == null) return [];
    final revenueFacts = await FinancialFact.db.find(
      session,
      where: (t) =>
          t.companyId.equals(doc.companyId) &
          t.bsnsYear.equals(doc.bsnsYear) &
          t.reportCode.equals(report.reportCode) &
          t.accountId.equals('ifrs-full_Revenue') &
          t.supersededById.equals(null),
    );
    final revenues = [
      if (table.revenue?.first case final value? when value > 0) value,
      for (final fact in revenueFacts)
        if ((fact.cumulativeAmount ?? fact.amount) case final amount?
            when amount > BigInt.zero)
          amount.toDouble() / scale,
    ];
    final chosen = table.totals.where((total) {
      final value = total.values.first;
      return value != null &&
          value >= 0 &&
          revenues.any(
            (r) => (ratio - 100 * value / r).abs() <= RndFacts.tolerance,
          );
    }).firstOrNull;
    if (chosen == null) return [];
    final month = switch (report.reportCode) {
      FinancialReportCode.q1 => 3,
      FinancialReportCode.halfYear => 6,
      FinancialReportCode.q3 => 9,
      FinancialReportCode.annual => 12,
    };
    return [
      for (final (kind, label, value, unit) in [
        (
          DocumentFactKind.rndExpense,
          RndFacts.expenseLabel,
          chosen.values.first!,
          table.unit,
        ),
        (DocumentFactKind.rndRatio, RndFacts.ratioLabel, ratio, '%'),
      ])
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: kind,
          label: label,
          value: value,
          unit: unit,
          asOf: DateTime.utc(doc.bsnsYear, month + 1, 0),
          evidence: '${chosen.evidence}\n${table.ratio!.evidence}',
          sourceId: report.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedBy: RndFacts.model,
          createdAt: DateTime.now().toUtc(),
        ),
    ];
  }
}
