import '../../generated/protocol.dart';
import 'disclosure_values.dart';
import 'segment_revenue.dart';

/// Executed facility investment tables only. Every component and the printed total retain their source values;
/// arithmetic disagreements are flagged, never corrected, the unit must be monetary, and dates must be actual.
abstract final class InvestmentFacts {
  static final _unit = RegExp(r'단위\s*[:：]\s*([^)\]]+)');
  static final _number = RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$');
  static final _period = RegExp(
    r'(20\d{2})[./](\d{1,2})\s*[~∼〜～-]\s*(20\d{2})[./](\d{1,2})',
  );
  static String key(String s) => s.replaceAll(RegExp(r'\s+'), '');

  static String _label(String original, String? owner) {
    final normalized = original.replaceAll(RegExp(r'\s+'), ' ');
    // Samsung renamed its reported divisions; keep the same economic series.
    if (DisclosureValues.companyName(owner ?? '') == '삼성전자') {
      if (key(original) == '반도체사업') return 'DS 부문';
      if (key(original) == 'DP사업') return 'SDC';
    }
    return key(original) == '기타' ? '기타' : normalized;
  }

  static List<
    ({
      String label,
      double value,
      String unit,
      DateTime asOf,
      String evidence,
      bool reconciled,
    })
  >
  parse(
    String text, {
    required DateTime periodEnd,
    String? owner,
    Set<String> otherCompanies = const {},
  }) {
    final lines = text.split('\n');
    final out =
        <
          ({
            String label,
            double value,
            String unit,
            DateTime asOf,
            String evidence,
            bool reconciled,
          })
        >[];
    var other = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final title = RegExp(r'^\[([^\]]+)\]').firstMatch(line);
      if (title != null) {
        final name = DisclosureValues.companyName(title.group(1)!);
        other =
            name != DisclosureValues.companyName(owner ?? '') &&
            otherCompanies.contains(name);
      }
      if (other || !line.contains('|')) continue;
      final header = line.split('|').map(key).toList();
      final amountAt = header.indexOf('투자액');
      final periodAt = header.indexOf('투자기간');
      if (amountAt < 0 || periodAt < 0 || !header.contains('대상자산')) continue;
      final context = lines.sublist(i > 3 ? i - 3 : 0, i).join('\n');
      if (RegExp(
        r'[(（]\s*시설\s*투자\s*계획|^\s*##[^\n]*투자\s*계획',
        multiLine: true,
      ).hasMatch(context)) {
        continue;
      }
      final unit = SegmentRevenue.pickUnit(
        _unit.allMatches(context).lastOrNull?.group(1),
      );
      if (unit.isEmpty) continue;
      final rows =
          <
            ({
              String label,
              double value,
              DateTime date,
              String evidence,
            })
          >[];
      double? total;
      var invalid = false;
      var j = i + 1;
      for (; j < lines.length; j++) {
        final row = lines[j].trim();
        if (row.isEmpty) continue;
        if (!row.contains('|') || row.startsWith('##') || _unit.hasMatch(row)) {
          break;
        }
        final cells = row.split('|').map((c) => c.trim()).toList();
        final label = key(cells.first);
        if ({'합계', '총계', '계'}.contains(label)) {
          final value = cells.last;
          if (!_number.hasMatch(value) || total != null) {
            invalid = true;
            break;
          }
          total = double.parse(value.replaceAll(',', ''));
          break;
        }
        if (cells.length != header.length ||
            rows.length >= 20 ||
            label.isEmpty) {
          invalid = true;
          break;
        }
        final amount = cells[cells.length - (header.length - amountAt)];
        final match = _period.firstMatch(
          cells[cells.length - (header.length - periodAt)],
        );
        if (!_number.hasMatch(amount) || match == null) {
          invalid = true;
          break;
        }
        final startYear = int.parse(match.group(1)!);
        final startMonth = int.parse(match.group(2)!);
        final endYear = int.parse(match.group(3)!);
        final endMonth = int.parse(match.group(4)!);
        if (startMonth < 1 ||
            startMonth > 12 ||
            endMonth < 1 ||
            endMonth > 12) {
          invalid = true;
          break;
        }
        final date = DateTime.utc(endYear, endMonth + 1, 0);
        final start = DateTime.utc(startYear, startMonth);
        if (start.isAfter(date) ||
            date != periodEnd ||
            start.isAfter(periodEnd) ||
            periodEnd.difference(start).inDays > 366) {
          invalid = true;
          break;
        }
        rows.add((
          label: '${_label(cells.first, owner)} 시설투자',
          value: double.parse(amount.replaceAll(',', '')),
          date: date,
          evidence: row,
        ));
      }
      final evidence = lines
          .sublist(i, (j + 1).clamp(0, lines.length))
          .join('\n');
      i = j;
      if (invalid ||
          total == null ||
          rows.isEmpty ||
          rows.map((r) => r.label).toSet().length != rows.length) {
        continue;
      }
      final sum = rows.fold(0.0, (v, r) => v + r.value);
      final reconciled =
          (sum - total).abs() <=
          (total.abs() * 0.000001).clamp(1.0, double.infinity);
      for (final r in rows) {
        out.add((
          label: r.label,
          value: r.value,
          unit: unit,
          asOf: r.date,
          evidence: evidence,
          reconciled: reconciled,
        ));
      }
      out.add((
        label: '시설투자 합계',
        value: total,
        unit: unit,
        asOf: rows.first.date,
        evidence: evidence,
        reconciled: reconciled,
      ));
    }
    return out;
  }

  /// Hide a legacy rounded prose total only when the same document now has a
  /// exact table total. Retain both records and all provenance.
  static bool redundantRoundedTotal(DocumentFact f, List<DocumentFact> facts) =>
      f.kind == DocumentFactKind.investmentActual &&
      f.extractedBy == RelationOrigin.ai &&
      f.unit == '조원' &&
      f.label.startsWith('시설투자 (') &&
      facts.any(
        (exact) =>
            exact.documentId == f.documentId &&
            exact.kind == f.kind &&
            exact.extractedBy == RelationOrigin.api &&
            exact.label == '시설투자 합계' &&
            exact.unit == '억원' &&
            exact.asOf == f.asOf &&
            ((exact.value / 10000 * 10).round() / 10 - f.value).abs() < .000001,
      );
}
