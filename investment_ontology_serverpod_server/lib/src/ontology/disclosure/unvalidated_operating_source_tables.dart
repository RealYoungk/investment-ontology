import '../../generated/protocol.dart';
import 'production_facts.dart';
import 'literal_table_number.dart';

/// Explicit source observations that are never promoted to verified facts.
abstract final class UnvalidatedOperatingSourceTables {
  static String _key(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static double? _number(String s) {
    final value = literalTableNumber(s);
    return value != null && value >= 0 ? value : null;
  }

  static bool _percentUnitAbove(List<String> lines, int index) {
    for (var n = index - 1; n >= 0 && n >= index - 3; n--) {
      final line = lines[n].trim();
      if (line.startsWith('##') || line.contains('|')) return false;
      if (RegExp(r'단위\s*[:：]\s*%\s*[)）]').hasMatch(line)) return true;
    }
    return false;
  }

  static List<BusinessTableInsight> parse(String text, String period) {
    final lines = text.split('\n');
    final compact = _key(text);
    final verifiedEvidence =
        compact.contains('사업소|평균가동률') ||
            compact.contains('생산실적|생산능력대비가동률|생산실적|생산실적')
        ? ProductionFacts.parse(text).map((r) => r.evidence).join('\n')
        : '';
    final out = <BusinessTableInsight>[];
    String section = '';
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('##')) section = lines[i];
      final h = lines[i].split('|').map((s) => s.trim()).toList();
      final k = h.map(_key).join('|');
      final simple = k == '사업소|평균가동률';
      final explicitPercent = simple && _percentUnitAbove(lines, i);
      final splitProduction =
          k.startsWith('구분|단위|') &&
          i + 1 < lines.length &&
          _key(lines[i + 1]) == '생산실적|생산능력대비가동률|생산실적|생산실적' &&
          h.length == 5;
      if (simple || splitProduction) {
        final rows = <BusinessTableRecord>[];
        final measures = <BusinessTableMeasure>[];
        var j = i + (splitProduction ? 2 : 1);
        for (; j < lines.length && lines[j].contains('|'); j++) {
          final c = lines[j].split('|').map((s) => s.trim()).toList();
          if (simple) {
            if (c.length != 2 || _number(c[1]) == null) break;
            rows.add(BusinessTableRecord(label: c[0], cells: c));
            if ((explicitPercent || c[1].endsWith('%')) &&
                !verifiedEvidence.contains(lines[j])) {
              measures.add(
                BusinessTableMeasure(
                  label: c[0],
                  metric: '평균가동률',
                  period: period,
                  value: _number(c[1])!,
                  unit: '%',
                ),
              );
            }
          } else {
            // One additional leading category cell is explicit, not a shifted value.
            if (c.length != 6 && c.length != 7) break;
            final offset = c.length - 4;
            final unit = c[offset - 1];
            if (!{'천배럴', '천톤'}.contains(unit) ||
                !c.skip(offset).every((v) => _number(v) != null) ||
                !c[offset + 1].endsWith('%') ||
                c.skip(offset).where((v) => v.endsWith('%')).length != 1) {
              break;
            }
            final label = c.take(offset - 1).join(' · ');
            rows.add(
              BusinessTableRecord(
                label: label,
                cells: [label, unit, ...c.skip(offset)],
              ),
            );
            if (!verifiedEvidence.contains(lines[j])) {
              for (var n = 0; n < 4; n++) {
                measures.add(
                  BusinessTableMeasure(
                    label: label,
                    metric: n == 1 ? '생산능력 대비 가동률' : '생산실적',
                    period: h[n < 2 ? 2 : n + 1],
                    value: _number(c[offset + n])!,
                    unit: n == 1 ? '%' : unit,
                  ),
                );
              }
            }
          }
        }
        if (rows.isNotEmpty && measures.isNotEmpty) {
          out.add(
            BusinessTableInsight(
              topic: 'operatingSourceObservation',
              title: simple ? '공시 평균가동률' : '공시 생산실적·가동률',
              columns: simple
                  ? h
                  : [
                      '사업부문',
                      '단위',
                      '${h[2]} 생산실적',
                      '${h[2]} 가동률',
                      '${h[3]} 생산실적',
                      '${h[4]} 생산실적',
                    ],
              rows: rows,
              measures: measures,
              evidence: lines.sublist(i > 2 ? i - 2 : 0, j).join('\n'),
              validation: '원문에 인쇄된 값 · 생산능력/산출 분모와의 검산 미수행 · 검증된 생산 사실과 구분',
              scope: '$period · $section · 표에 명시된 사업부문·사업소 범위',
            ),
          );
        }
        i = j - 1;
        continue;
      }
      // Preserve the exact scoped statement; never infer company-wide absence.
      if (lines[i].contains('|') ||
          !RegExp(r'생산능력|생산실적|가동률|수주|연구개발비').hasMatch(_key(lines[i]))) {
        continue;
      }
      final statement = lines[i];
      final withheld =
          RegExp(r'비공개|영업비밀|보안관계|보안 관계|기밀').hasMatch(statement) &&
          RegExp(r'생략|공시하지|기재하지|비공개').hasMatch(statement);
      final unquantified = RegExp(
        r'산출[^.。]*곤란|산출[^.。]*한계|별도[^.。]*계상[^.。]*않|별도로[^.。]*계상[^.。]*않|계산[^.。]*곤란',
      ).hasMatch(statement);
      if (!withheld && !unquantified) continue;
      final label = withheld ? '해당 항목·범위 비공개' : '해당 범위 정량 산출·별도 계상 제한';
      out.add(
        BusinessTableInsight(
          topic: 'operatingDisclosureLimit',
          title: label,
          columns: ['공시 상태', '원문 설명'],
          rows: [
            BusinessTableRecord(label: label, cells: [label, statement]),
          ],
          measures: [],
          evidence: statement,
          validation: '회사의 명시적 공시 설명 · 숫자 0이나 회사 전체 데이터 부재로 해석하지 않음',
          scope: '$period · $section · 원문에 명시된 대상 범위',
        ),
      );
    }
    return out;
  }
}
