import '../../generated/protocol.dart';
import 'production_facts.dart';
import 'order_facts.dart';
import 'facility_book_values.dart';
import 'literal_table_number.dart';

/// Explicit source tables that must remain readable even when arithmetic or
/// merged cells prevent verified numeric facts. Chart explicit observations
/// separately from the persisted, arithmetic-verified facts.
abstract final class BusinessSourceTables {
  static double? _number(String s) {
    final value = literalTableNumber(s);
    return value != null && value >= 0 ? value : null;
  }

  static List<BusinessTableMeasure> _measures(
    String topic,
    List<String> rows,
    String period,
    String evidence,
  ) {
    final out = <BusinessTableMeasure>[];
    void add(String label, String metric, String p, double value, String unit) {
      out.add(
        BusinessTableMeasure(
          label: label,
          metric: metric,
          period: p,
          value: value,
          unit: unit,
        ),
      );
    }

    if (topic == 'materialShareSource') {
      String? printedPeriod;
      final groups = <String, List<(String, double)>>{};
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length < 2) continue;
        if (RegExp(r'^20\d{2}').hasMatch(c.first)) printedPeriod = c.first;
        final value = _number(c.last);
        if (printedPeriod == null ||
            value == null ||
            value > 100 ||
            !c.last.endsWith('%')) {
          continue;
        }
        groups.putIfAbsent(printedPeriod, () => []).add((
          c[c.length - 2],
          value,
        ));
      }
      for (final entry in groups.entries) {
        if ((entry.value.fold<double>(0, (sum, row) => sum + row.$2) - 100)
                .abs() >
            1) {
          continue;
        }
        for (final row in entry.value) {
          add(row.$1, '원재료 비중', entry.key, row.$2, '%');
        }
      }
    } else if (topic == 'salesChannelShareSource') {
      final shares = <(String, double)>[];
      for (final row in rows) {
        final cells = row.split('|').map((c) => c.trim()).toList();
        final values = cells.where((c) => c.endsWith('%')).toList();
        if (!row.contains('→') || values.length != 1) continue;
        final value = _number(values.single);
        if (value == null || value > 100) continue;
        shares.add((cells.first.replaceAll(' ', ''), value));
      }
      if (shares.length >= 2 &&
          (shares.fold<double>(0, (s, r) => s + r.$2) - 100).abs() <= 1) {
        for (final row in shares) {
          add(row.$1, '판매경로 비중', period, row.$2, '%');
        }
      }
    } else if (topic == 'salesChannelSource') {
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length < 4 || !row.contains('→')) continue;
        final share = _number(c.last);
        final amount = _number(c[c.length - 2]);
        if (share == null || amount == null || !c.last.endsWith('%')) continue;
        final label = c.length == 6 ? c[1] : c.first;
        add(label, '판매 제품군 비중', period, share, '%');
        if (evidence.contains('단위 : 천원')) {
          add(label, '판매 제품군 매출', period, amount, '천원');
        }
      }
    } else if (topic == 'orderSource' && evidence.contains('단위 : 백만원')) {
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length != 4 || c.first.replaceAll(' ', '') != '합계') continue;
        for (var k = 1; k < 4; k++) {
          final value = _number(c[k]);
          if (value != null) {
            add(
              ['수주총액', '기납품액', '수주잔고'][k - 1],
              '공시 합계 (차감식 미검증)',
              period,
              value,
              '백만원',
            );
          }
        }
      }
    } else if (topic == 'facilitiesSource' && evidence.contains('단위 : 천원')) {
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length != 6 || c.first == '합계') continue;
        final value = _number(c.last);
        if (value != null) add(c.first, '기말 장부가액', period, value, '천원');
      }
    } else if (topic == 'researchStaffSource') {
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length != 5 || c.first == '계') continue;
        final value = _number(c.last);
        if (value != null) add(c.first, '기말 연구인력', period, value, '명');
      }
    } else if (topic == 'intellectualPropertySource') {
      final counts = <String, int>{};
      for (final row in rows) {
        final c = row.split('|').map((s) => s.trim()).toList();
        if (c.length != 7 || !RegExp(r'\((출원|등록)\)').hasMatch(c[1])) continue;
        counts.update(c[1], (v) => v + 1, ifAbsent: () => 1);
      }
      for (final entry in counts.entries) {
        add(entry.key, '공시 목록 건수', period, entry.value.toDouble(), '건');
      }
    }
    return out;
  }

  static List<BusinessTableInsight> parse(
    String text, {
    String reportPeriod = '',
  }) {
    final lines = text.split('\n');
    final out = <BusinessTableInsight>[];
    for (var i = 0; i < lines.length; i++) {
      final cells = lines[i]
          .split('|')
          .map((s) => s.trim().replaceAll(RegExp(r'\s+'), ''))
          .toSet();
      final (topic, title, validation) = switch (cells) {
        final c when c.contains('판매경로') && c.contains('매출액비중') => (
          'salesChannelShareSource',
          '판매경로 비중',
          '인쇄된 경로 묶음 비율 · 합계 100% 검산 · 개별 고객 매출로 분해하지 않음',
        ),
        final c
            when c.contains('판매경로') &&
                c.contains('비중') &&
                lines
                    .skip(i + 1)
                    .take(6)
                    .any((s) => !s.contains('|') && s.contains('→')) =>
          (
            'salesChannelSource',
            '판매 제품군 구성',
            '복수 판매경로의 묶음 금액 · 경로별·고객별 매출로 나누어 확정하지 않음',
          ),
        final c
            when c.containsAll({'수주총액', '기납품액'}) &&
                c.any((s) => s.startsWith('수주잔고')) =>
          (
            'orderSource',
            '수주 공시 합계',
            '원문 수치 · 계약별 초과 납품·병합 셀을 포함할 수 있어 합계 차감식으로 확정하지 않음',
          ),
        final c
            when c.contains('구분') &&
                (c.contains('부문') || c.containsAll({'고객사', '품목명'})) &&
                c.where((s) => RegExp(r'20\d{2}|제\d+기').hasMatch(s)).length >=
                    2 =>
          (
            'productionSource',
            '생산·가동률',
            '원문 수치 · 검산을 통과한 값만 생산 지표로 확정하며 불일치·산정기준 변경은 원문과 구분',
          ),
        final c when c.containsAll({'사업년도', '품목명', '원재료명', '원재료비중(%)'}) => (
          'materialShareSource',
          '원재료 비중',
          '인쇄된 연도 묶음·원재료·비율 사용 · 연도별 합계 100% 검산 · 생략된 품목명은 추정하지 않음',
        ),
        final c when c.containsAll({'구분', '기초가액', '당기증감', '당기상각', '기말가액'}) => (
          'facilitiesSource',
          '생산설비 구성',
          '장부가액 증감 원문 · 재무 현금흐름의 설비투자액과 구분',
        ),
        final c
            when c.contains('직위') &&
                c.containsAll({'증가', '감소'}) &&
                c.any((s) => s.startsWith('기말(')) =>
          ('researchStaffSource', '연구개발 인력', '원문 인원 · 직위와 기초·기말 기준일 보존'),
        final c
            when c.containsAll({
              '번호',
              '구분',
              '내용',
              '권리자',
              '출원일',
              '적용제품',
              '출원국',
            }) =>
          (
            'intellectualPropertySource',
            '지적재산권 공시 목록',
            '공시 원문 · 출원과 등록을 구분하며 현재 법적 유효성을 판단하지 않음',
          ),
        _ => ('', '', ''),
      };
      if (topic.isEmpty) continue;
      var end = i + 1;
      while (end < lines.length &&
          (lines[end].contains('|') ||
              (topic == 'salesChannelSource' && lines[end].contains('→'))) &&
          !lines[end].startsWith('##')) {
        end++;
      }
      final rows = lines.sublist(i + 1, end);
      if (rows.isEmpty ||
          (topic == 'productionSource' &&
              !rows.any((s) => s.contains('생산능력')))) {
        continue;
      }
      // Keep each printed row intact: flattening rowspan cells does not prove
      // which missing cell belongs to an order date, amount or product.
      final start = i > 3 ? i - 3 : 0;
      final evidence = lines.sublist(start, end).join('\n');
      // A verified total already appears in operating trends; raw evidence is
      // retained there. Keep this fallback only for unverified source tables.
      if (topic == 'orderSource' && OrderFacts.parse(evidence).isNotEmpty) {
        continue;
      }
      final verified = topic == 'productionSource'
          ? ProductionFacts.parse(evidence)
          : const [];
      out.add(
        BusinessTableInsight(
          topic: topic,
          title: title,
          columns: [lines[i].trim()],
          rows: [
            for (final row in rows)
              BusinessTableRecord(label: row.trim(), cells: [row.trim()]),
          ],
          measures: [
            ..._measures(topic, rows, reportPeriod, evidence),
            for (final row in verified) ...[
              BusinessTableMeasure(
                label: row.label,
                metric: '가동률',
                period: reportPeriod,
                value: row.utilization,
                unit: '%',
              ),
              if (row.capacity != null && row.unit.isNotEmpty)
                BusinessTableMeasure(
                  label: row.label,
                  metric: '생산능력',
                  period: reportPeriod,
                  value: row.capacity!,
                  unit: row.unit,
                ),
              if (row.production != null && row.unit.isNotEmpty)
                BusinessTableMeasure(
                  label: row.label,
                  metric: '생산실적',
                  period: reportPeriod,
                  value: row.production!,
                  unit: row.unit,
                ),
            ],
          ],
          evidence: evidence,
          validation: validation,
        ),
      );
      i = end - 1;
    }
    out.addAll(FacilityBookValues.parse(text, reportPeriod));
    return out;
  }
}
