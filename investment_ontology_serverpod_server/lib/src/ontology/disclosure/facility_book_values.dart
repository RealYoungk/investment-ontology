import '../../generated/protocol.dart';
import 'segment_revenue.dart';

/// The filing's domestic facilities table, grouped by asset class. Its closing
/// book values are not cash-flow capex and are accepted only after reconciliation.
abstract final class FacilityBookValues {
  static List<BusinessTableInsight> parse(String text, String period) {
    final lines = text.split('\n');
    final result = <BusinessTableInsight>[];
    for (var i = 1; i < lines.length; i++) {
      var header = lines[i].split('|').map((c) => c.trim()).toList();
      if (!header.contains('사업소') ||
          !header.contains('기초장부가액') ||
          !header.contains('당기장부가액')) {
        continue;
      }
      final context = lines[i - 1];
      final asset = RegExp(r'자산항목\s*[:：]\s*([^\]]+)')
          .firstMatch(context)
          ?.group(1)
          ?.trim();
      final unit = SegmentRevenue.pickUnit(
        RegExp(r'단위\s*[:：]\s*([^)\]]+)').firstMatch(context)?.group(1),
      );
      if (asset == null || unit.isEmpty) continue;
      var start = i + 1;
      if (header.contains('당기증감') &&
          start < lines.length &&
          lines[start].trim() == '증가 | 감소') {
        final index = header.indexOf('당기증감');
        header = [...header.take(index), '증가', '감소', ...header.skip(index + 1)];
        start++;
      }
      if (!header.contains('증가') ||
          !header.contains('감소') ||
          !header.contains('당기대체') ||
          !header.contains('당기상각')) {
        continue;
      }
      for (var j = start; j < lines.length && j < start + 60; j++) {
        if (!lines[j].contains('|')) break;
        final cells = lines[j].split('|').map((c) => c.trim()).toList();
        if (cells.first.replaceAll(' ', '') != '합계') continue;
        double? value(String name) {
          final index = cells.length - (header.length - header.indexOf(name));
          if (index < 1 || index >= cells.length) return null;
          var raw = cells[index].replaceAll(',', '');
          if (raw == '-') return 0;
          if (raw.startsWith('(') && raw.endsWith(')')) {
            raw = '-${raw.substring(1, raw.length - 1)}';
          }
          return double.tryParse(raw);
        }

        final opening = value('기초장부가액'),
            increase = value('증가'),
            decrease = value('감소');
        final transfer = value('당기대체'),
            depreciation = value('당기상각'),
            closing = value('당기장부가액');
        if (opening == null ||
            increase == null ||
            decrease == null ||
            transfer == null ||
            depreciation == null ||
            closing == null ||
            closing < 0 ||
            (opening + increase - decrease + transfer - depreciation - closing)
                    .abs() >
                1) {
          break;
        }
        final evidence = lines.sublist(i - 1, j + 1).join('\n');
        result.add(
          BusinessTableInsight(
            topic: 'facilitiesBookValueSource',
            title: '생산설비 장부가액 · $asset',
            columns: ['자산항목', '기말장부가액'],
            rows: [
              BusinessTableRecord(
                label: asset,
                cells: [asset, '$closing $unit'],
              ),
            ],
            measures: [
              BusinessTableMeasure(
                label: asset,
                metric: '기말장부가액',
                period: period,
                value: closing,
                unit: unit,
              ),
            ],
            evidence: evidence,
            validation: '기초 + 증가 − 감소 + 대체 − 상각 = 기말 검산 · 장부가액이며 현금 설비투자액과 구분',
            scope: '생산설비 원문 표',
          ),
        );
        break;
      }
    }
    if (result.isEmpty) return [];
    final first = result.first;
    final start = text.indexOf(first.evidence);
    final last = result.last;
    final end = text.indexOf(last.evidence) + last.evidence.length;
    return [
      BusinessTableInsight(
        topic: first.topic,
        title: '생산설비 장부가액 구성',
        columns: first.columns,
        rows: result.expand((r) => r.rows).toList(),
        measures: result.expand((r) => r.measures).toList(),
        evidence: text.substring(start, end),
        validation: first.validation,
        scope: first.scope,
      ),
    ];
  }
}
