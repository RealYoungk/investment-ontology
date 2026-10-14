import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../financial/financial_basis.dart';
import 'rnd_facts.dart';

typedef RndParsedTable = ({
  List<int> years,
  bool consolidatedOnly,
  String unit,
  List<({String label, List<double?> values, String evidence})> totals,
  ({List<double?> values, String evidence})? ratio,
  List<double?>? revenue,
});

/// Revalidate every year in memory. No collection or database write.
abstract final class StoredRndFacts {
  static List<({int index, double expense, double ratio, String evidence})>
  validatedColumns(RndParsedTable table, Map<int, List<double>> revenues) {
    final out =
        <({int index, double expense, double ratio, String evidence})>[];
    yearLoop:
    for (var k = 0; k < table.years.length; k++) {
      final ratio = table.ratio?.values[k];
      if (ratio == null || !ratio.isFinite || ratio < 0) continue;
      final printed = table.revenue?[k];
      final denominators = printed != null && printed > 0
          ? [printed]
          : (revenues[table.years[k]] ?? const <double>[]);
      for (final denominator in denominators) {
        if (!denominator.isFinite || denominator <= 0) continue;
        final matches = <double, String>{};
        for (final total in table.totals) {
          final value = total.values[k];
          if (value == null || !value.isFinite || value < 0) continue;
          if ((ratio - 100 * value / denominator).abs() <= RndFacts.tolerance) {
            matches.putIfAbsent(value, () => total.evidence);
          }
        }
        // The same rounded printed ratio cannot choose between two totals.
        if (matches.length > 1) continue yearLoop;
        if (matches.isEmpty) continue;
        final chosen = matches.entries.single;
        out.add((
          index: k,
          expense: chosen.key,
          ratio: ratio,
          evidence: '${chosen.value}\n${table.ratio!.evidence}',
        ));
        break;
      }
    }
    return out;
  }

  /// The preferred basis must have one unambiguous revenue within its latest
  /// report. Conflicting statements cannot silently fall through to OFS.
  static List<double> orderedRevenueCandidates(
    Map<String, Set<double>> byBasis,
  ) {
    final cfs = byBasis['consolidated'];
    final ofs = byBasis['separate'];
    if (cfs != null && cfs.length > 1) return [];
    if (cfs?.isNotEmpty ?? false) {
      return [cfs!.single, if (ofs?.length == 1) ofs!.single];
    }
    return ofs?.length == 1 ? [ofs!.single] : [];
  }

  static DateTime currentDate(BusinessDocument doc, DisclosureReport report) {
    final month = switch (report.reportCode) {
      FinancialReportCode.annual => 12,
      FinancialReportCode.halfYear => 6,
      FinancialReportCode.q1 => 3,
      FinancialReportCode.q3 => 9,
    };
    return report.settlementDate ?? DateTime.utc(doc.bsnsYear, month + 1, 0);
  }

  static bool matchesSource(BusinessDocument doc, DisclosureReport report) =>
      doc.reportId == report.id &&
      doc.companyId == report.companyId &&
      doc.rceptNo == report.rceptNo &&
      doc.bsnsYear == report.bsnsYear &&
      report.section == DartSection.businessContent &&
      report.supersededById == null;

  static Future<List<DocumentFact>> read(
    Session session,
    BusinessDocument doc,
    DisclosureReport report, {
    Transaction? transaction,
  }) async {
    if (!matchesSource(doc, report)) return [];
    final table = RndFacts.parse(doc.text, bsnsYear: doc.bsnsYear);
    if (table == null) return [];
    final scale = const {
      '원': 1.0,
      '천원': 1e3,
      '백만원': 1e6,
      '억원': 1e8,
      '십억원': 1e9,
      '조원': 1e12,
    }[table.unit];
    if (scale == null) return [];
    final eligible = FinancialBasis.eligibleReportsCte.replaceFirst(
      'WHERE CASE WHEN',
      'WHERE r."companyId"=${doc.companyId} AND CASE WHEN',
    );
    final needsFinancialRevenue = List.generate(
      table.years.length,
      (k) => table.revenue?[k],
    ).any((v) => v == null || v <= 0);
    final List<List<dynamic>> rows = !needsFinancialRevenue
        ? []
        : await session.db.unsafeQuery(
            'WITH $eligible SELECT r."bsnsYear",r."reportCode",r."fsDiv", '
            'CASE WHEN r."reportCode"=\'annual\' THEN f.amount ELSE coalesce(f."cumulativeAmount",f.amount) END,r.id '
            'FROM eligible_reports r JOIN financial_fact f ON f."reportId"=r.id '
            'WHERE r."supersededById" IS NULL AND r."bsnsYear" IN (${{...table.years, doc.bsnsYear}.join(',')}) '
            'AND f."accountId"=\'ifrs-full_Revenue\' AND f."accountDetail" IS NULL '
            'AND f.statement IN (\'incomeStatement\',\'comprehensiveIncome\') '
            'AND f."supersededById" IS NULL AND f."companyId"=r."companyId" '
            'AND f."sourceId"=r."sourceId" AND f."bsnsYear"=r."bsnsYear" '
            'AND f."reportCode"=r."reportCode" AND f."fsDiv"=r."fsDiv" '
            'AND coalesce(f.currency,\'KRW\')=\'KRW\' '
            'ORDER BY r."rceptNo" DESC,r.id DESC',
            transaction: transaction,
          );
    final revenuesByBasis = <int, Map<String, Set<double>>>{};
    final seen = <String, int>{};
    for (final row in rows) {
      final fiscalYear = row[0] as int;
      final code = '${row[1]}';
      final basis = '${row[2]}';
      final current =
          fiscalYear == doc.bsnsYear && code == report.reportCode.name;
      final year = current ? table.years.first : fiscalYear;
      if ((!current && (code != 'annual' || year == table.years.first)) ||
          !table.years.contains(year) ||
          table.consolidatedOnly && basis != 'consolidated') {
        continue;
      }
      final key = '$year|$basis';
      final reportId = row[4] as int;
      final latestId = seen.putIfAbsent(key, () => reportId);
      if (latestId != reportId) continue;
      final value = double.tryParse('${row[3]}');
      if (value != null && value.isFinite && value > 0) {
        ((revenuesByBasis[year] ??= {})[basis] ??= {}).add(value / scale);
      }
    }
    final revenues = {
      for (final entry in revenuesByBasis.entries)
        entry.key: orderedRevenueCandidates(entry.value),
    };
    final now = DateTime.now().toUtc();
    return [
      for (final column in validatedColumns(table, revenues))
        for (final (kind, label, value, unit) in [
          (
            DocumentFactKind.rndExpense,
            RndFacts.expenseLabel,
            column.expense,
            table.unit,
          ),
          (DocumentFactKind.rndRatio, RndFacts.ratioLabel, column.ratio, '%'),
        ])
          DocumentFact(
            companyId: doc.companyId,
            documentId: doc.id!,
            bsnsYear: doc.bsnsYear,
            kind: kind,
            label: label,
            value: value,
            unit: unit,
            asOf: column.index == 0
                ? currentDate(doc, report)
                : DateTime.utc(table.years[column.index], 12, 31),
            evidence: kind == DocumentFactKind.rndExpense
                ? column.evidence.split('\n').first
                : column.evidence.split('\n').last,
            sourceId: report.sourceId,
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            reviewedBy: RndFacts.model,
            createdAt: now,
          ),
    ];
  }

  static bool isLegacyRuleFact(DocumentFact f, int documentId) =>
      f.documentId == documentId &&
      {
        DocumentFactKind.rndExpense,
        DocumentFactKind.rndRatio,
      }.contains(f.kind) &&
      f.extractedBy == RelationOrigin.api &&
      f.extractorModel == '표 규칙';

  static Future<List<DocumentFact>> project(
    Session session,
    BusinessDocument doc,
    DisclosureReport report,
    List<DocumentFact> stored,
  ) async => [
    for (final fact in stored)
      if (!isLegacyRuleFact(fact, doc.id!)) fact,
    ...await read(session, doc, report),
  ];
}
