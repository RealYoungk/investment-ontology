import 'printed_period_columns.dart';
import 'segment_revenue.dart';

/// A merged export/domestic table. Accept only explicit revenue-type subtotals,
/// each reconciled to its two destination rows and then to the company total.
abstract final class RevenueTypeRows {
  static List<({String label, double amount, String unit, String evidence})>
  parse(String text) {
    final out =
        <({String label, double amount, String unit, String evidence})>[];
    final lines = text.split('\n');
    for (var i = 1; i < lines.length; i++) {
      final header = lines[i].split('|').map((c) => c.trim()).toList();
      if (header.length < 5 || header.take(3).join('|') != '사업부문|매출유형|품목') {
        continue;
      }
      final years = header.skip(3).toList();
      if (!years.every((c) => RegExp(r'20\d{2}|제\s*\d+\s*기').hasMatch(c))) {
        continue;
      }
      final context = lines[i - 1];
      if (!context.contains('연결') && !context.contains('별도')) continue;
      final unit = SegmentRevenue.pickUnit(
        RegExp(r'단위\s*[:：]\s*([^)\]]+)').firstMatch(context)?.group(1),
      );
      if (unit.isEmpty) continue;
      final period = newestPrintedPeriod(years) ?? 0;
      final rows = <(String, double)>[];
      String? group;
      var sum = 0.0;
      var destinations = <String>{};
      double? total;
      var end = i;
      var valid = true;
      for (var j = i + 1; j < lines.length && j <= i + 30; j++) {
        final cells = lines[j].split('|').map((c) => c.trim()).toList();
        final labelsEnd = cells.length - years.length;
        if (labelsEnd < 1) break;
        final labels = cells.take(labelsEnd).toList();
        final raw = cells[labelsEnd + period];
        final value = raw == '-'
            ? 0.0
            : double.tryParse(raw.replaceAll(',', ''));
        if (value == null || value < 0) {
          valid = false;
          break;
        }
        final newGroup = labels
            .where((c) => const {'상품', '제품', '용역', '기타매출'}.contains(c))
            .firstOrNull;
        if (newGroup != null) {
          if (group != null || rows.any((r) => r.$1 == newGroup)) {
            valid = false;
            break;
          }
          group = newGroup;
          sum = 0;
          destinations = {};
        }
        final destination = labels.last.replaceAll(' ', '');
        if (destination == '수출' || destination == '내수') {
          // The final company export/domestic group is not a revenue type.
          if (labels.first.replaceAll(' ', '') == '합계' && labels.length == 2) {
            if (group != null) {
              valid = false;
              break;
            }
            group = '__total';
            sum = 0;
            destinations = {};
          }
          if (group == null || !destinations.add(destination)) {
            valid = false;
            break;
          }
          sum += value;
        } else if (destination == '합계' && group != null) {
          if (destinations.length != 2 || (sum - value).abs() > 1) {
            valid = false;
            break;
          }
          if (group == '__total') {
            total = value;
            end = j;
            break;
          }
          rows.add((group, value));
          group = null;
        } else {
          valid = false;
          break;
        }
      }
      if (!valid ||
          total == null ||
          rows.length < 2 ||
          total <= 0 ||
          (rows.fold<double>(0, (sum, r) => sum + r.$2) - total).abs() > 1) {
        continue;
      }
      final evidence = lines.sublist(i - 1, end + 1).join('\n');
      for (final row in rows) {
        out.add((
          label: row.$1,
          amount: row.$2,
          unit: unit,
          evidence: evidence,
        ));
      }
    }
    return out;
  }
}
