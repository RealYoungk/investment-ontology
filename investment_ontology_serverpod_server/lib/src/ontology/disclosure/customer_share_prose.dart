import '../../generated/protocol.dart';

/// Keeps the aggregate share separate from individual anonymous customers.
abstract final class CustomerShareProse {
  static List<BusinessTableInsight> parse(String text, String period) {
    var active = false;
    final out = <BusinessTableInsight>[];
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) active = false;
      if (RegExp(r'^[가-힣]\.\s*주요\s*매출처').hasMatch(line)) {
        active = true;
        continue;
      }
      if (!active || line.contains('|')) continue;
      if (RegExp(r'^[가-힣]\.').hasMatch(line)) {
        active = false;
        continue;
      }
      final year = RegExp(r'^(20\d{2})년').firstMatch(line)?.group(1);
      if (year != null && !period.startsWith(year)) continue;
      final match = RegExp(
        r'당사의\s*주요\s*(\d+)대\s*매출처에\s*대한\s*매출비중은\s*전체\s*연결\s*매출액\s*대비\s*약\s*(\d+(?:\.\d+)?)%\s*수준',
      ).firstMatch(line);
      if (match == null) continue;
      final value = double.parse(match.group(2)!);
      if (value > 100) continue;
      out.add(
        BusinessTableInsight(
          topic: 'customerShareTotal',
          title: '주요 매출처 집중도',
          columns: ['구분', '매출비중'],
          rows: [
            BusinessTableRecord(
              label: '상위 ${match.group(1)}개 매출처',
              cells: ['상위 ${match.group(1)}개 매출처', '${match.group(2)}%'],
            ),
          ],
          measures: [
            BusinessTableMeasure(
              label: '상위 ${match.group(1)}개 매출처',
              metric: '연결 매출 비중',
              period: period,
              value: value,
              unit: '%',
            ),
          ],
          evidence: match.group(0)!,
          validation:
              '공시된 주요 매출처 합계 비중입니다. 개별 고객 비중으로 나누거나 전체 매출 100%로 확대하지 않습니다.',
          scope: '연결 기준',
        ),
      );
    }
    return out;
  }
}
