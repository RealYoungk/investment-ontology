/// 사업보고서 본문의 "부문별 매출" 표를 규칙으로 읽는다 (AI 없음).
///
/// 머리글에 매출액과 비중(비율)이 같이 있는 표만 받는다. 표에 적힌 비중이
/// 매출액 ÷ 합계와 맞아야 하므로 스스로 검산된다. 어긋나면 그 표를 통째로 버린다.
abstract final class SegmentRevenue {
  /// 비중이 이보다 어긋나면 열을 잘못 읽은 것으로 본다 (%p).
  static const tolerance = 1.0;

  /// 한 표에서 받아들이는 최대 부문 수.
  static const maxRows = 20;

  static final _amountHeader = RegExp(r'매출액|매출');
  static final _ratioHeader = RegExp(r'비중|비율');
  static final _unitLine = RegExp(r'단위\s*[:：]\s*([^,)\]]+)');
  static final _number = RegExp(r'^[△▲\-]?[\d,]+(?:\.\d+)?$');
  static const _totalLabels = {'계', '합계', '소계', '총계', '총 계', '합 계'};

  /// (부문 이름, 매출액, 단위, 그 줄).
  static List<({String label, double amount, String unit, String evidence})>
  parse(String text) {
    final out =
        <({String label, double amount, String unit, String evidence})>[];
    var unit = '';
    var amountAt = -1;
    var rows = <({String label, double amount, double ratio, String line})>[];
    double? total;

    void flush() {
      // 비중이 매출액 ÷ 합계와 맞는 표만 받는다.
      final sum = total ?? rows.fold<double>(0, (a, r) => a + r.amount.abs());
      if (rows.isNotEmpty && sum > 0 && unit.isNotEmpty) {
        final ok = rows.every(
          (r) =>
              (r.ratio.abs() - 100 * r.amount.abs() / sum).abs() <= tolerance,
        );
        if (ok) {
          for (final r in rows.take(maxRows)) {
            out.add((
              label: r.label,
              amount: r.amount,
              unit: unit,
              evidence: r.line,
            ));
          }
        }
      }
      rows = [];
      total = null;
      amountAt = -1;
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final u = _unitLine.firstMatch(line);
      if (u != null) unit = u.group(1)!.trim();
      final cells = [for (final c in line.split('|')) c.trim()];

      final a = cells.indexWhere(_amountHeader.hasMatch);
      final r = cells.indexWhere(_ratioHeader.hasMatch);
      if (a >= 0 && r > a && cells.length >= 3) {
        flush();
        amountAt = a;
        continue;
      }
      if (amountAt < 0) continue;
      if (line.startsWith('※') || cells.length < 2) {
        flush();
        continue;
      }

      final labels = [
        for (final c in cells)
          if (c.isNotEmpty && !_number.hasMatch(c) && !c.endsWith('%')) c,
      ];
      final numbers = [for (final c in cells) ?_num(c)];
      if (labels.isEmpty || numbers.length < 2) continue;
      final name = labels.first;
      final amount = numbers[numbers.length - 2];
      final ratio = numbers.last;
      if (_totalLabels.contains(name.replaceAll(' ', ''))) {
        total = amount.abs();
        continue;
      }
      rows.add((label: name, amount: amount, ratio: ratio, line: line));
    }
    flush();
    return out;
  }

  /// "△301,146"(음수), "56.3%" → 수. 아니면 null.
  static double? _num(String s) {
    final t = s.replaceAll('%', '').trim();
    if (!_number.hasMatch(t)) return null;
    final negative = t.startsWith('△') || t.startsWith('▲');
    final v = double.tryParse(t.replaceAll(RegExp(r'[△▲,]'), ''));
    return v == null ? null : (negative ? -v : v);
  }
}
