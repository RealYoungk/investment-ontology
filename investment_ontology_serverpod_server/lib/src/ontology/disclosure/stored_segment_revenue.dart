import '../../generated/protocol.dart';
import 'segment_revenue.dart';

/// Read-only recovery for stored documents predating the split-header rule.
/// Uses the document's own period, never the years repeated in other filings.
abstract final class StoredSegmentRevenue {
  static List<DocumentFact> project(
    BusinessDocument doc,
    DisclosureReport report,
  ) {
    if (doc.reportId != report.id ||
        doc.companyId != report.companyId ||
        doc.rceptNo != report.rceptNo ||
        doc.bsnsYear != report.bsnsYear ||
        report.section != DartSection.businessContent ||
        report.supersededById != null) {
      return [];
    }
    // Restrict recovery to the newly supported shape; persisted readers of
    // other table shapes retain their existing source and review decisions.
    final recoveredHeader = RegExp(r'(?:매출유형|사업부문)[^\n]+\n매출액\s*\|\s*비율')
        .hasMatch(doc.text);
    final recoveredTotal = RegExp(
      r'^(?:단순\s*합계|합\s*계\s*\(연결\s*조정\s*(?:전|후)\))\s*\|',
      multiLine: true,
    ).hasMatch(doc.text);
    final operatingRevenue =
        RegExp(r'^영업수익\s*\|', multiLine: true).hasMatch(doc.text) &&
        RegExp(r'금액\s*\|\s*비중\s*\|\s*금액\s*\|\s*비중').hasMatch(doc.text);
    if (!recoveredHeader && !recoveredTotal && !operatingRevenue) return [];
    final month = switch (report.reportCode) {
      FinancialReportCode.annual => 12,
      FinancialReportCode.halfYear => 6,
      FinancialReportCode.q1 => 3,
      FinancialReportCode.q3 => 9,
    };
    final rows = SegmentRevenue.parse(doc.text);
    final values = <String, Set<double>>{};
    for (final row in rows) {
      values.putIfAbsent('${row.label}|${row.unit}', () => {}).add(row.amount);
    }
    // Different source tables may use the same label on different bases.
    // Do not choose a table or denominator by its position in the document.
    if (values.values.any((v) => v.length > 1)) return [];
    final seen = <String>{};
    return [
      for (final row in rows.where(
        (r) => seen.add('${r.label}|${r.unit}|${r.amount}'),
      ))
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: DocumentFactKind.segmentRevenue,
          label: row.label,
          value: row.amount,
          unit: row.unit,
          asOf:
              report.settlementDate ?? DateTime.utc(doc.bsnsYear, month + 1, 0),
          evidence: row.evidence,
          sourceId: report.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedBy: '표 규칙 (비중 = 매출액 ÷ 합계 확인)',
          createdAt: report.fetchedAt,
        ),
    ];
  }
}
