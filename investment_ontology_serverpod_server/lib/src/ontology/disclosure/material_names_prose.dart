import '../../generated/protocol.dart';

/// Names in a current issuer import statement; never infer an amount or share.
abstract final class MaterialNamesProse {
  static List<BusinessTableInsight> parse(String text) {
    var active = false;
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        active = RegExp(r'원재료|원자재').hasMatch(line);
        continue;
      }
      if (!active || !line.startsWith('당사는 ') || line.contains('|')) continue;
      final match = RegExp(
        r'거래업체로부터\s*([A-Z][A-Z0-9-]+)\s*(?:와|과)\s*([A-Z][A-Z0-9-]+)\s*등\s*제품생산에\s*필요한\s*원재료를\s*수입하고\s*있습니다',
      ).firstMatch(line);
      if (match == null) continue;
      return [
        BusinessTableInsight(
          topic: 'materialContext',
          title: '주요 원재료',
          columns: ['원재료', '조달 방법'],
          rows: [
            for (var i = 1; i <= 2; i++)
              BusinessTableRecord(
                label: match.group(i)!,
                cells: [match.group(i)!, '수입'],
              ),
          ],
          measures: [],
          evidence: line,
          validation:
              '본문에 명시한 원재료명과 조달 방법입니다. 매입액·비중이 공시되지 않은 경우 비중 차트를 만들지 않습니다.',
        ),
      ];
    }
    return [];
  }
}
