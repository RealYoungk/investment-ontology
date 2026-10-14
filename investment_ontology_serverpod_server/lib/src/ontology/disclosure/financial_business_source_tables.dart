import '../../generated/protocol.dart';

/// Financial business measures retain their printed basis, entity and period.
/// A generic amount/ratio header never implies a yield or a revenue metric.
abstract final class FinancialBusinessSourceTables {
  static String _key(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static List<String> _cells(String s) =>
      s.split('|').map((v) => v.trim()).toList();
  static double? _number(String s) {
    s = s.trim().replaceAll('△', '-').replaceAll('−', '-');
    if (s.startsWith('(') && s.endsWith(')')) {
      s = '-${s.substring(1, s.length - 1)}';
    }
    if (!RegExp(r'^-?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$').hasMatch(s)) {
      return null;
    }
    final number = double.tryParse(s.replaceAll(',', ''));
    return number != null && number.isFinite ? number : null;
  }

  static final _metrics = RegExp(
    r'^(영업수익|영업비용|보험수익|보험영업수익|투자영업수익|수입보험료|원수보험료|보험료|준비금평잔|책임준비금|운용자산|총자산|자산운용률|이자수익|비이자수익|이자비용|비이자비용)(\([A-Z/]+\))?$',
  );

  static List<BusinessTableInsight> parse(
    String text,
    String reportPeriod, {
    String? industryCode,
  }) {
    if (industryCode == null || !RegExp(r'^6[456]').hasMatch(industryCode)) {
      return [];
    }
    final lines = text.split('\n');
    final out = <BusinessTableInsight>[];
    String entity = '보고서 내 회사·범위';
    for (var i = 0; i < lines.length; i++) {
      if (RegExp(r'^\[.+\]$').hasMatch(lines[i].trim())) {
        entity = lines[i].trim();
      }
      if (!lines[i].contains('|')) continue;
      final header = _cells(lines[i]);
      if (!{'구분', '종류'}.contains(_key(header.first))) continue;
      var contextStart = i;
      for (var c = i - 1; c >= 0 && c >= i - 5; c--) {
        if (lines[c].startsWith('## ') ||
            (lines[c].contains('|') && !lines[c].contains('단위'))) {
          break;
        }
        contextStart = c;
      }
      final context = lines.sublist(contextStart, i).join('\n');
      final match = RegExp(r'단위\s*[:：]\s*(백만원|천원|억원|원)').firstMatch(context);
      if (match == null) continue;
      final unit = match.group(1)!;
      final years = header
          .skip(1)
          .every((s) => RegExp(r'20\d{2}|제\s*\d+\s*기').hasMatch(s));
      if (header.length < 3) continue;
      var start = i + 1;
      List<String>? sub;
      if (start < lines.length && lines[start].contains('|')) {
        final c = _cells(lines[start]);
        if (c.every(
          (s) => {
            '준비금평잔',
            '부리이율',
            '비중',
            '금액',
            '비율',
            '보험수익',
            '보험서비스비용',
            '재보험수익',
            '재보험서비스비용',
          }.contains(_key(s)),
        )) {
          sub = c;
          start++;
        }
      }
      // A bare amount/ratio pair does not specify what the ratio measures.
      if (sub != null && !sub.any((s) => {'준비금평잔', '보험수익'}.contains(_key(s)))) {
        continue;
      }
      if (sub != null &&
          (sub.length < header.length - 1 ||
              sub.length % (header.length - 1) != 0)) {
        continue;
      }
      final columns = sub == null
          ? header
          : <String>[
              '범위·종류',
              for (var k = 0; k < sub.length; k++)
                '${header[1 + k ~/ (sub.length ~/ (header.length - 1))]} · ${sub[k]}',
            ];
      final checks = <String>[];
      final records = <BusinessTableRecord>[];
      final measures = <BusinessTableMeasure>[];
      var j = start;
      String group = '';
      for (; j < lines.length && lines[j].contains('|'); j++) {
        final cells = _cells(lines[j]);
        if (cells.length < 2) break;
        if (sub != null) {
          final width = sub.length ~/ (header.length - 1);
          final count = (header.length - 1) * width;
          if (width < 1 || !years) continue;
          if (sub.length != count ||
              cells.length < count + 1 ||
              cells.length > count + 2) {
            break;
          }
          final labels = cells.take(cells.length - count).toList();
          if (labels.length == 2) group = labels.first;
          final label = [
            entity,
            if (group.isNotEmpty) group,
            labels.last,
          ].join(' · ');
          final nums = cells.sublist(cells.length - count);
          for (var k = 0; k < count; k++) {
            final value = _number(nums[k]);
            if (value == null) continue;
            final metric = _key(sub[k]);
            if ({'부리이율', '비중'}.contains(metric) && !context.contains('%')) {
              continue;
            }
            measures.add(
              BusinessTableMeasure(
                label: label,
                metric: metric,
                period: header[1 + k ~/ width],
                value: value,
                unit: {'부리이율', '비중'}.contains(metric) ? '%' : unit,
              ),
            );
          }
          records.add(
            BusinessTableRecord(label: label, cells: [label, ...nums]),
          );
        } else {
          final metric = _key(cells.first);
          if (metric.startsWith('자산운용률') && !context.contains('%')) continue;
          if (!_metrics.hasMatch(metric) || cells.length != header.length) {
            continue;
          }
          if (!years) {
            final total = header.indexWhere(
              (s) => {'합계', '총계'}.contains(_key(s)),
            );
            if (total == header.length - 1) {
              final values = cells.skip(1).map(_number).toList();
              if (values.every((v) => v != null)) {
                final sum = values
                    .take(values.length - 1)
                    .fold<double>(0, (a, b) => a + b!);
                final delta = (sum - values.last!).abs();
                checks.add(
                  '${cells.first}: 합계 ${delta <= values.length ? '검산 일치(표시 반올림 허용)' : '검산 불일치 — 원문값 유지'}',
                );
              }
            }
          }
          for (var k = 1; k < cells.length; k++) {
            final value = _number(cells[k]);
            if (value == null) continue;
            measures.add(
              BusinessTableMeasure(
                label: years
                    ? '$entity · ${cells.first}'
                    : '$entity · ${header[k]}',
                metric: cells.first,
                period: years ? header[k] : '$reportPeriod · 표 내 기간 미특정',
                value: value,
                unit: metric.startsWith('자산운용률') ? '%' : unit,
              ),
            );
          }
          records.add(BusinessTableRecord(label: cells.first, cells: cells));
        }
      }
      if (measures.isEmpty) continue;
      if (sub != null) {
        for (final total in measures.where(
          (m) => RegExp(r' · (합계|계)$').hasMatch(m.label) && m.unit != '%',
        )) {
          final parts = measures.where(
            (m) =>
                m.metric == total.metric &&
                m.period == total.period &&
                !RegExp(r' · (합계|계|소계)$').hasMatch(m.label),
          );
          final sum = parts.fold<double>(0, (a, m) => a + m.value);
          if (parts.isNotEmpty) {
            checks.add(
              '${total.metric} ${total.period}: 합계 ${(sum - total.value).abs() <= parts.length ? '검산 일치(표시 반올림 허용)' : '검산 불일치 — 원문값 유지'}',
            );
          }
        }
      }
      final notes = lines
          .sublist(j, j + 2 < lines.length ? j + 2 : lines.length)
          .where((s) => s.startsWith('주') || s.startsWith('註'))
          .join('\n');
      final basis = [entity, context, notes].join('\n');
      out.add(
        BusinessTableInsight(
          topic: 'financialBusiness',
          title: '금융업 영업·보험·준비금 지표',
          columns: columns,
          rows: records,
          measures: measures,
          evidence: lines.sublist(contextStart, j).join('\n'),
          validation:
              '명시 지표·단위·열 대응 확인 · 인쇄값 유지 · 일반 제품매출과 구분${checks.isEmpty ? ' · 합계 검산 적용 불가' : ' · ${checks.join(' / ')}'}',
          scope: basis,
        ),
      );
      i = j - 1;
    }
    return out;
  }
}
