import 'dart:math' as math;

import '../../generated/protocol.dart';
import 'disclosure_values.dart';
import 'segment_revenue.dart';

typedef BreakdownFact = ({
  DocumentFactKind kind,
  String label,
  double value,
  String unit,
  String evidence,
  String note,
});

/// Conservative readers for two explicit filing tables. Never infer a reporting
/// basis from company financials, or calculate margins across different tables.
abstract final class BusinessBreakdownFacts {
  static String _key(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static double? _number(String s) {
    final clean = s.trim().replaceAll(',', '').replaceAll(RegExp('[△▲]'), '-');
    if (!RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(clean)) return null;
    return double.tryParse(clean);
  }

  static List<BreakdownFact> parse(
    String text, {
    required int year,
    String? owner,
    Set<String> otherCompanies = const {},
  }) {
    final lines = text.split('\n');
    final result = <BreakdownFact>[];
    var other = false;
    for (var i = 0; i < lines.length; i++) {
      final title = RegExp(r'^\s*\[([^\]]+)\]').firstMatch(lines[i]);
      if (title != null) {
        final name = DisclosureValues.companyName(title.group(1)!);
        other =
            name != DisclosureValues.companyName(owner ?? '') &&
            otherCompanies.contains(name);
      }
      if (other || !lines[i].contains('|')) continue;
      final head = lines[i].split('|').map(_key).toList();
      final dates = head
          .skipWhile((c) => !RegExp(r'^(?:20\d{2}년?|제\d+기)').hasMatch(c))
          .toList();
      if (dates.length < 2 || dates.length > 3) continue;
      final ordinals = dates
          .map(
            (c) => int.tryParse(RegExp(r'\d+').firstMatch(c)?.group(0) ?? ''),
          )
          .toList();
      if (ordinals.any((n) => n == null)) continue;
      if (ordinals.first! >= 2000 && ordinals.first != year) continue;
      if (!List.generate(
        ordinals.length - 1,
        (j) => ordinals[j]! > ordinals[j + 1]!,
      ).every((v) => v)) {
        continue;
      }
      final start = math.max(0, i - 3);
      final before = lines.sublist(start, i).join('\n');
      final unitMatch = RegExp(r'단위\s*[:：]\s*([^)\]]+)')
          .allMatches(before)
          .lastOrNull;
      final unit = SegmentRevenue.pickUnit(unitMatch?.group(1));
      if (unit.isEmpty) continue;
      var end = i + 1;
      while (end < lines.length && lines[end].contains('|')) {
        end++;
      }
      var evidenceEnd = end;
      while (evidenceEnd < math.min(lines.length, end + 3) &&
          (lines[evidenceEnd].trim().startsWith('※') ||
              lines[evidenceEnd].trim().startsWith('주)'))) {
        evidenceEnd++;
      }
      final evidence = lines.sublist(start, evidenceEnd).join('\n');
      final basis = RegExp(r'별도\s*기준|별도\s*재무').hasMatch(evidence)
          ? '별도'
          : RegExp(r'연결\s*기준|연결\s*재무').hasMatch(evidence)
          ? '연결'
          : '공시 표 기준';
      final note =
          '$basis${evidence.contains('내부거래') ? ' · 내부거래 포함 여부는 원문 참조' : ''}';
      final rows = lines
          .sublist(i + 1, end)
          .map((s) => s.split('|').map((c) => c.trim()).toList())
          .toList();
      if (head.any((c) => c.contains('부문')) && head.contains('구분')) {
        result.addAll(
          _segments(rows, dates.length, unit, evidence, note, basis),
        );
      } else if (RegExp(r'지역별.*매출|매출.*지역별').hasMatch(before)) {
        result.addAll(
          _geography(rows, dates.length, unit, evidence, note, basis),
        );
      }
      i = end - 1;
    }
    // Repeated tables of the same basis cannot silently overwrite one another.
    final counts = <String, int>{};
    for (final f in result) {
      final k = '${f.kind.name}|${f.label}';
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final ambiguousTables = {
      for (final f in result)
        if (counts['${f.kind.name}|${f.label}'] != 1) f.evidence,
    };
    // Dropping only the overlapping region would invalidate the table sum and
    // turn the remaining rows into an incorrect denominator in the UI.
    return result.where((f) => !ambiguousTables.contains(f.evidence)).toList();
  }

  static List<BreakdownFact> _segments(
    List<List<String>> rows,
    int years,
    String unit,
    String evidence,
    String note,
    String basis,
  ) {
    if (rows.isEmpty ||
        rows.first.map(_key).join('|') !=
                List.filled(years, '금액|비중').join('|') &&
            rows.first.map(_key).join('|') !=
                List.filled(years, '금액|비율').join('|')) {
      return [];
    }
    final revenues = <String, (double, double)>{};
    final profits = <String, (double, double)>{};
    String? segment;
    for (final cells in rows.skip(1)) {
      final index = cells.length - years * 2;
      if (index < 1 || index > 2) return [];
      if (index == 2) segment = cells.first;
      final metric = _key(cells[index - 1]);
      if (!{'매출액', '영업이익', '영업손익'}.contains(metric)) continue;
      if (segment == null || segment.isEmpty) return [];
      final amount = _number(cells[index]);
      final ratio = cells[index + 1].endsWith('%')
          ? _number(cells[index + 1].replaceAll('%', ''))
          : null;
      if (amount == null || ratio == null) return [];
      final dest = metric == '매출액' ? revenues : profits;
      if (dest.containsKey(segment)) return [];
      dest[segment] = (amount, ratio);
    }
    if (revenues.length < 2 ||
        profits.length != revenues.length ||
        !revenues.keys.every(profits.containsKey) ||
        !_consistentShares(revenues.values) ||
        !_consistentShares(profits.values)) {
      return [];
    }
    return [
      for (final label in revenues.keys)
        if (!RegExp(r'^(합계|총계|계|소계)$').hasMatch(_key(label)))
          for (final entry in [
            (DocumentFactKind.segmentOperatingRevenue, revenues[label]!.$1),
            (DocumentFactKind.segmentOperatingProfit, profits[label]!.$1),
          ])
            (
              kind: entry.$1,
              label: '$label · $basis',
              value: entry.$2,
              unit: unit,
              evidence: evidence,
              note: '$note · 금액과 공시 비중 교차 검증',
            ),
    ];
  }

  /// Each amount/share pair must imply the same denominator. ±0.05 percentage
  /// points permits one-decimal rounding; losses and shares above 100% survive.
  /// This does NOT assume segment sums equal consolidated sales (eliminations).
  static bool _consistentShares(Iterable<(double, double)> rows) {
    double low = double.negativeInfinity, high = double.infinity;
    var count = 0;
    for (final (amount, share) in rows) {
      if (share.abs() <= 0.05) continue;
      final a = amount * 100 / (share - 0.050001);
      final b = amount * 100 / (share + 0.050001);
      low = math.max(low, math.min(a, b));
      high = math.min(high, math.max(a, b));
      count++;
    }
    if (count < 2 || low > high || !low.isFinite || !high.isFinite) {
      return false;
    }
    final denominator = (low + high) / 2;
    return denominator != 0 &&
        rows.every((r) => (r.$1 / denominator * 100 - r.$2).abs() <= 0.05001);
  }

  static List<BreakdownFact> _geography(
    List<List<String>> rows,
    int years,
    String unit,
    String evidence,
    String note,
    String basis,
  ) {
    final values = <String, double>{};
    String? category;
    double? total;
    for (final cells in rows) {
      final index = cells.length - years;
      if (index < 1 || index > 2) return [];
      final label = cells[index - 1];
      final amount = _number(cells[index]);
      if (amount == null || amount < 0) return [];
      if (RegExp(r'^(계|합계|총계)$').hasMatch(_key(label))) {
        if (total != null) return [];
        total = amount;
        continue;
      }
      if (index == 2) {
        category = _key(cells.first);
        if (!{'내수', '수출'}.contains(category)) return [];
      }
      if (RegExp(r'소계|합계|총계').hasMatch(label)) return [];
      final key = '${category == null ? '' : '$category · '}$label · $basis';
      if (values.containsKey(key)) return [];
      values[key] = amount;
    }
    if (total == null ||
        total <= 0 ||
        values.length < 2 ||
        (values.values.fold(0.0, (a, b) => a + b) - total).abs() >
            values.length * 0.5) {
      return [];
    }
    return [
      for (final entry in values.entries)
        (
          kind: DocumentFactKind.geographicRevenue,
          label: entry.key,
          value: entry.value,
          unit: unit,
          evidence: evidence,
          note: '$note · 지역별 매출 합계 검증',
        ),
    ];
  }
}
