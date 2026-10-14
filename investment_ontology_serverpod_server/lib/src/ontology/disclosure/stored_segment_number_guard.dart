import '../../generated/protocol.dart';
import 'literal_table_number.dart';
import 'segment_revenue.dart';

typedef SegmentFinancialRevenueReference = ({
  int companyId,
  int bsnsYear,
  FinancialReportCode reportCode,
  FsDiv fsDiv,
  String rceptNo,
  BigInt revenueWon,
});
typedef SegmentNumberDecision = ({bool keep, bool suspect, String reason});

/// Read-only validation of old facts whose source has malformed commas.
/// Never changes values, quotes, units, statuses, or stored rows. A caller may
/// fetch active financial revenue only for candidate company/year/period keys.
abstract final class StoredSegmentNumberGuard {
  static final _tokens = RegExp(r'[△▲\-]?\d[\d,]*(?:\.\d+)?');
  static List<String> _bad(DocumentFact fact) => [
    for (final m in _tokens.allMatches(fact.evidence))
      if (m[0]!.contains(',') &&
          literalTableNumber(m[0]!) == null &&
          double.tryParse(
                m[0]!
                    .replaceAll(',', '')
                    .replaceAll('△', '-')
                    .replaceAll('▲', '-'),
              ) ==
              fact.value)
        m[0]!,
  ];
  static bool isCandidate(DocumentFact fact) =>
      fact.kind == DocumentFactKind.segmentRevenue &&
      fact.extractedBy == RelationOrigin.api &&
      _bad(fact).isNotEmpty;

  static SegmentNumberDecision assess(
    DocumentFact fact,
    BusinessDocument doc,
    DisclosureReport report, {
    List<SegmentFinancialRevenueReference> financialRevenues = const [],
  }) {
    SegmentNumberDecision result(bool keep, String reason) =>
        (keep: keep, suspect: true, reason: reason);
    if (!isCandidate(fact)) {
      return (
        keep: true,
        suspect: false,
        reason: 'not a malformed scalar candidate',
      );
    }
    if (fact.documentId != doc.id ||
        fact.companyId != doc.companyId ||
        fact.bsnsYear != doc.bsnsYear ||
        doc.reportId != report.id ||
        report.companyId != doc.companyId ||
        report.bsnsYear != doc.bsnsYear ||
        report.rceptNo != doc.rceptNo ||
        report.supersededById != null ||
        report.section != DartSection.businessContent) {
      return result(
        false,
        'document/report/company/year or active receipt mismatch',
      );
    }
    final sourceLine = fact.evidence.split('\n').first.trim();
    final lines = doc.text.split('\n');
    final at = lines.indexWhere((s) => s.trim() == sourceLine);
    if (at < 0) return result(false, 'source row absent');
    final bad = _bad(fact).toSet();
    // Normalization exists only in this scratch validation. Source and fact
    // values remain untouched; the digits are never edited or reinterpreted.
    String normalize(String s) {
      for (final token in bad) {
        s = s.replaceAll(token, token.replaceAll(',', ''));
      }
      return s;
    }

    final projected = SegmentRevenue.parse(normalize(doc.text));
    if (!projected.any(
      (r) =>
          r.label == fact.label &&
          r.unit == fact.unit &&
          r.amount == fact.value &&
          r.evidence.split('\n').first.trim() == normalize(sourceLine),
    )) {
      return result(
        false,
        'own printed period, unit, label or source ratio does not replay',
      );
    }
    final sourceCells = sourceLine.split('|').map((s) => s.trim()).toList();
    final cellAt = sourceCells.indexWhere((s) => bad.any(s.contains));
    if (cellAt < 0) return result(false, 'candidate amount cell absent');
    final fromRight = sourceCells.length - cellAt;
    final combined =
        sourceCells[cellAt].contains('(') && sourceCells[cellAt].contains('%');
    double? amount(List<String> cells) {
      final index = cells.length - fromRight;
      if (index < 0 || index >= cells.length) return null;
      final raw = normalize(cells[index]);
      return literalTableNumber(combined ? raw.split('(').first.trim() : raw);
    }

    double? share(List<String> cells) {
      final index = cells.length - fromRight;
      if (index < 0 || index >= cells.length) return null;
      if (combined) {
        final m = RegExp(r'\((\d+(?:\.\d+)?)\s*%\)').firstMatch(cells[index]);
        return m == null ? null : literalTableNumber(m[1]!);
      }
      return index + 1 < cells.length
          ? literalTableNumber(cells[index + 1])
          : null;
    }

    var start = at, end = at + 1;
    while (start > 0 &&
        lines[start - 1].contains('|') &&
        !lines[start - 1].startsWith('##')) {
      start--;
    }
    while (end < lines.length &&
        lines[end].contains('|') &&
        !lines[end].startsWith('##')) {
      end++;
    }
    final targetShare = share(sourceCells);
    if (targetShare == null) {
      return result(false, 'printed source share absent');
    }
    double sum = 0;
    final totals = <double>[];
    var rows = 0;
    for (final line in lines.sublist(start, end)) {
      final cells = line.split('|').map((s) => s.trim()).toList();
      final value = amount(cells);
      if (value == null || share(cells) == null) continue;
      if (cells.any(SegmentRevenue.isTotalLabel)) {
        totals.add(value);
        continue;
      }
      if (RegExp(r'연결조정|내부거래|영업이익|자산|부채|자본').hasMatch(line) || value < 0) {
        return result(
          false,
          'mixed scope or adjustment needs source-only display',
        );
      }
      sum += value;
      rows++;
    }
    final closed =
        rows > 1 && totals.length == 1 && (totals.single - sum).abs() <= 0.5;
    if (closed) {
      final observed = 100 * fact.value / totals.single;
      if ((observed - targetShare).abs() > 0.055) {
        return result(
          false,
          'printed share does not match independently closed source total',
        );
      }
      return result(
        true,
        'original digits + own printed period/share + independent row sum and total confirmed; source punctuation remains malformed',
      );
    }
    // A lone 100% row has no independent arithmetic denominator. It needs an
    // active same-receipt financial reference on an unambiguous printed basis.
    if (rows != 1 || (targetShare - 100).abs() > 0.005) {
      return result(false, 'source total is not independently closed');
    }
    final context = lines.sublist(start > 8 ? start - 8 : 0, end).join('\n');
    final basis = context.contains('별도') || context.contains('개별')
        ? FsDiv.separate
        : context.contains('연결')
        ? FsDiv.consolidated
        : null;
    final scale = switch (fact.unit) {
      '원' => 1,
      '천원' => 1000,
      '백만원' => 1000000,
      '억원' => 100000000,
      _ => null,
    };
    if (basis == null || scale == null) {
      return result(
        false,
        'single-row 100% needs explicit financial basis and won scale',
      );
    }
    final matching = financialRevenues
        .where(
          (r) =>
              r.companyId == doc.companyId &&
              r.bsnsYear == doc.bsnsYear &&
              r.reportCode == report.reportCode &&
              r.fsDiv == basis &&
              r.rceptNo == doc.rceptNo,
        )
        .toList();
    if (matching.length != 1) {
      return result(
        false,
        'single-row 100% financial reference unavailable or ambiguous',
      );
    }
    return (fact.value * scale - matching.single.revenueWon.toDouble()).abs() <=
            scale / 2
        ? result(
            true,
            'same receipt/year/period/basis financial revenue corroborates single-row amount',
          )
        : result(
            false,
            'single-row source digits conflict with same-period financial revenue',
          );
  }
}
