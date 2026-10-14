import '../../generated/protocol.dart';
import 'market_share_facts.dart';
import 'production_facts.dart';
import 'holding_source_scope.dart';

abstract final class RecoveredMarketShareFacts {
  static bool bareDataYearCollision(String evidence) {
    final years = evidence
        .split('|')
        .skip(1)
        .map((c) => c.trim())
        .where((c) => RegExp(r"^'?[0-9]{2}$").hasMatch(c))
        .toList();
    return years.length >= 2 && years.length == years.toSet().length;
  }

  /// Recover only the numeric-row-as-header bug shape, not all missing facts.
  static List<DocumentFact> project(
    BusinessDocument doc,
    DisclosureReport report,
    List<DocumentFact> existing, {
    required String owner,
    String? industryCode,
    bool holding = false,
  }) {
    if (holding ||
        HoldingSourceScope.declaresHolding(doc.text) ||
        industryCode == '64992' ||
        doc.reportId != report.id ||
        doc.companyId != report.companyId ||
        doc.bsnsYear != report.bsnsYear ||
        doc.rceptNo != report.rceptNo ||
        report.section != DartSection.businessContent ||
        report.supersededById != null) {
      return [];
    }
    final end = report.settlementDate ?? DateTime.utc(doc.bsnsYear, 12, 31);
    final out = <DocumentFact>[];
    for (final row in MarketShareFacts.parse(
      doc.text,
      owner: owner,
      bsnsYear: doc.bsnsYear,
    )) {
      if (!bareDataYearCollision(row.evidence)) continue;
      final date = ProductionFacts.marketShareDate(
        year: row.year,
        month: row.month,
        bsnsYear: doc.bsnsYear,
        periodEnd: end,
        reportCode: report.reportCode,
      );
      if (date.isAfter(end) ||
          existing.any(
            (f) =>
                f.kind == DocumentFactKind.marketShare &&
                f.label == row.label &&
                f.unit == '%' &&
                f.asOf == date,
          )) {
        continue;
      }
      out.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: DocumentFactKind.marketShare,
          label: row.label,
          value: row.value,
          unit: '%',
          asOf: date,
          evidence: row.evidence,
          sourceId: report.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedBy: '표 규칙 (연도별 시장점유율 표, 당사 줄)',
          reviewNote: [
            if (row.basis.isNotEmpty) row.basis,
            if (row.estimated && row.year == doc.bsnsYear) '회사 추정',
          ].join(' · '),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
    return out;
  }
}
