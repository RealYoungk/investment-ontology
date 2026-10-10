import '../../generated/protocol.dart';

/// Explicit issuer investment statements. This amount is not cash-flow CAPEX.
abstract final class InvestmentExecutionProse {
  static List<BusinessTableInsight> parse(String text, String reportPeriod) {
    final out = <BusinessTableInsight>[];
    var active = false;
    final pattern = RegExp(
      r'당사의\s*(20\d{2})년\s*(반기|상반기|1분기|3분기)?\s*(연결|별도)기준\s*유형자산\s*투자금액은\s*([\d,]+(?:\.\d+)?)\s*(억원|백만원|천원|원)입니다',
    );
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        active = RegExp(r'생산|설비|투자').hasMatch(line);
        continue;
      }
      if (!active || line.contains('|')) continue;
      for (final match in pattern.allMatches(line)) {
        final year = match.group(1)!;
        // Prevent a comparative or future year from acquiring the report period.
        if (!reportPeriod.startsWith(year)) continue;
        final interim = match.group(2);
        if (interim == null && !reportPeriod.contains('연간')) continue;
        if (interim != null &&
            !reportPeriod.contains(interim == '상반기' ? '반기' : interim)) {
          continue;
        }
        final value = double.tryParse(match.group(4)!.replaceAll(',', ''));
        if (value == null || value < 0) continue;
        final evidence = match.group(0)!;
        out.add(
          BusinessTableInsight(
            topic: 'investmentExecution',
            title: '유형자산 투자실적',
            columns: ['구분', '기간', '투자금액', '단위', '기준'],
            rows: [
              BusinessTableRecord(
                label: '유형자산 투자',
                cells: [
                  '유형자산 투자',
                  reportPeriod,
                  match.group(4)!,
                  match.group(5)!,
                  match.group(3)!,
                ],
              ),
            ],
            measures: [
              BusinessTableMeasure(
                label: '유형자산 투자',
                metric: '투자금액',
                period: reportPeriod,
                value: value,
                unit: match.group(5)!,
              ),
            ],
            evidence: evidence,
            validation: '회사가 명시한 기간·기준·유형자산 투자금액을 원문에서 추출했습니다. 현금흐름표 유형자산 취득액과 범위가 다를 수 있습니다.',
            scope: '${match.group(3)!} 기준',
          ),
        );
      }
    }
    return out;
  }
}
