import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// Local presentation adapter, not a persisted fact or a new extraction job.
/// Fail closed unless the current profile and a complete printed product mix agree.
class PowerProductLesson {
  const PowerProductLesson({required this.year, required this.shares});
  final int year;
  final List<({String label, double share})> shares;

  static PowerProductLesson? resolve(
    BusinessUnderstanding profile,
    BusinessContent? content,
  ) {
    if (profile.status != 'ready' ||
        content == null ||
        profile.rceptNo != content.rceptNo ||
        profile.bsnsYear != content.bsnsYear) {
      return null;
    }
    final sections = content.sections.where(
      (s) => RegExp(r'주요\s*제품').hasMatch(s.title),
    );
    for (final section in sections) {
      final lines = section.text.split('\n');
      for (var i = 1; i < lines.length; i++) {
        if (!RegExp(r'주요\s*제품\s*매출\s*비중').hasMatch(lines[i - 1])) {
          continue;
        }
        final header = lines[i].split('|').map((s) => s.trim()).toList();
        if (header.length < 2 || header.first != '구분') continue;
        final yearIndex = header.indexOf('${content.bsnsYear}년');
        if (yearIndex < 1 || header.toSet().length != header.length) continue;
        final rows = <String, double>{};
        double? total;
        for (var j = i + 1; j < lines.length; j++) {
          final cells = lines[j].split('|').map((s) => s.trim()).toList();
          if (cells.length != header.length) break;
          final raw = cells[yearIndex];
          if (!RegExp(r'^\d+(?:\.\d+)?%$').hasMatch(raw)) break;
          final value = double.parse(raw.replaceAll('%', ''));
          if (value > 100) break;
          if (cells.first == '합계') {
            total = value;
            break;
          }
          if (rows.containsKey(cells.first)) break;
          rows[cells.first] = value;
        }
        // This lesson covers a specific product combination, not every capacitor
        // or every SMPS maker. Never infer films from an MLCC or a material purchase.
        if (rows.length != 3 ||
            !rows.keys.toSet().containsAll({'PSU', '필름콘덴서', '증착필름'}) ||
            total != 100 ||
            (rows.values.fold(0.0, (a, b) => a + b) - 100).abs() > .15) {
          continue;
        }
        return PowerProductLesson(
          year: content.bsnsYear,
          shares: [
            (label: 'PSU · 전원공급장치', share: rows['PSU']!),
            (label: '필름콘덴서 · 전기를 잠깐 저장하는 부품', share: rows['필름콘덴서']!),
            (label: '증착필름 · 콘덴서의 재료', share: rows['증착필름']!),
          ],
        );
      }
    }
    return null;
  }
}
