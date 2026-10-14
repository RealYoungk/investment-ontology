import 'rule_document_store.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'segment_revenue.dart';
import 'stored_rnd_facts.dart';

/// 사업보고서 본문의 "연구개발비용" 표를 규칙으로 읽는다 (AI 없음).
///
/// 기업공시서식이 정한 꼴이라 거의 모든 보고서에 같은 표가 있다: 연도 머리글
/// ("과목 | 2025년 | 2024년 | 2023년" 또는 "제26기(2025년) …"), "연구개발비용 계" 줄,
/// "연구개발비 / 매출액 비율" 줄, 그리고 가끔 "매출액" 줄.
///
/// 스스로 검산한다: 표에 적힌 비율이 연구개발비 ÷ 매출액과 맞아야 받는다. 매출액은
/// 표 안의 줄이 있으면 그것을, 없으면 재무제표(같은 해 사업보고서, 연결 → 별도)를 쓴다.
/// 계 줄이 여럿이면(정부보조금 차감 전·후) 비율과 맞는 쪽을 쓴다 — 회사마다 다르다.
abstract final class RndFacts {
  static const model = '표 규칙 (연구개발비 ÷ 매출액 = 비율 확인)';
  static const expenseLabel = '연구개발비용';
  static const ratioLabel = '매출액 대비';

  /// 비율(%p) 허용 오차. 표는 소수 첫째·둘째 자리까지 적는다.
  static const tolerance = 0.11;

  static final _unitLine = RegExp(r'단위\s*[:：]\s*([^)\]]+)');
  static final _year = RegExp(r'(20\d{2})\s*년?');
  static final _period = RegExp(r'제\s*(\d+)\s*기');
  static final _total = RegExp(
    r'^\(?연구개발비(용)?\s*(계|합계|총계|비용\s*계|비용\s*총계|비용\s*합계)',
  );
  static final _ratio = RegExp(r'연구개발비(용)?\s*/\s*(매출액|영업수익)|매출액\s*대비\s*연구개발비');
  static final _revenue = RegExp(r'^매\s*출\s*액$');
  static final _number = RegExp(r'^[△▲\-]?\(?[\d,]+(?:\.\d+)?\)?%?$');

  /// 한 문서의 연구개발비 표 (없으면 null).
  static ({
    List<int> years,
    bool consolidatedOnly,
    String unit,
    List<({String label, List<double?> values, String evidence})> totals,
    ({List<double?> values, String evidence})? ratio,
    List<double?>? revenue,
  })?
  parse(String text, {required int bsnsYear}) {
    final lines = text.split('\n');
    String? lastUnit;
    var lastUnitAt = -1000;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final u = _unitLine.firstMatch(line);
      if (u != null) {
        lastUnit = u.group(1)!.trim();
        lastUnitAt = i;
      }
      final cells = [for (final c in line.split('|')) c.trim()];
      if (cells.length < 3) continue;
      // Explicit consolidated/separate blocks may repeat the same year header.
      // Keep the first (consolidated) block; never mix the two bases.
      final previous = i > 0
          ? lines[i - 1].split('|').map((v) => v.trim()).toList()
          : <String>[];
      final paired =
          previous.length == 3 &&
          previous[1] == '연결' &&
          previous[2] == '별도' &&
          cells.length.isEven &&
          cells.length >= 4 &&
          cells.take(cells.length ~/ 2).join('|') ==
              cells.skip(cells.length ~/ 2).join('|');
      final years = _years(
        paired ? cells.take(cells.length ~/ 2).toList() : cells,
        bsnsYear,
      );
      if (years == null) continue;
      // A generic 합계/비율 is meaningful only in an explicitly headed R&D
      // cost subsection. Do not borrow a heading from another filing table.
      final heading = lines
          .take(i)
          .toList()
          .reversed
          .firstWhere(
            (s) =>
                s.trim().isNotEmpty &&
                !s.contains('|') &&
                !_unitLine.hasMatch(s),
            orElse: () => '',
          );
      final explicitCost =
          RegExp(r'연구개발\s*비용').hasMatch(heading) &&
          i - lines.lastIndexOf(heading) <= 3;
      // 연도 머리글 뒤 15줄 안에 연구개발비 줄이 있어야 이 표다.
      final totals =
          <({String label, List<double?> values, String evidence})>[];
      ({List<double?> values, String evidence})? ratio;
      List<double?>? revenue;
      for (var j = i + 1; j < lines.length && j <= i + 15; j++) {
        final row = lines[j].trim();
        if (row.isEmpty) continue;
        if (row.startsWith('※') || row.startsWith('주)')) break;
        final rc = [for (final c in row.split('|')) c.trim()];
        if (rc.length < 2) break;
        if (_years(rc, bsnsYear) != null) break; // 다음 표
        final mergedTotal =
            rc.length > 2 &&
            RegExp(r'^연구개발비(?:용)?$').hasMatch(rc.first.replaceAll(' ', '')) &&
            RegExp(r'^(계|합계|총계)$').hasMatch(rc[1].replaceAll(' ', ''));
        final label = mergedTotal ? '${rc.first} ${rc[1]}' : rc.first;
        final values = _values(
          mergedTotal
              ? rc.sublist(2)
              : paired && rc.length == 1 + years.length * 2
              ? rc.sublist(1, 1 + years.length)
              : rc.sublist(1),
          years.length,
        );
        if (values == null) continue;
        if ((_total.hasMatch(label.replaceAll(' ', '')) ||
                (explicitCost &&
                    RegExp(r'^(합계|총계|연구개발비|연구개발비용)$')
                        .hasMatch(label.replaceAll(' ', '')))) &&
            !label.contains('비율')) {
          totals.add((label: label, values: values, evidence: row));
        } else if (_ratio.hasMatch(label) ||
            (explicitCost &&
                RegExp(r'^\(?매출액\s*대비\s*비율\)?$').hasMatch(label))) {
          ratio ??= (values: values, evidence: row);
        } else if (_revenue.hasMatch(label)) {
          revenue ??= values;
        }
      }
      if (totals.isEmpty || ratio == null) continue;
      var unit = i - lastUnitAt <= 3 ? SegmentRevenue.pickUnit(lastUnit) : '';
      if (unit.isEmpty) {
        unit = SegmentRevenue.pickUnit(_unitLine.firstMatch(line)?.group(1));
      }
      if (unit.isEmpty) continue;
      return (
        years: years,
        consolidatedOnly: paired,
        unit: unit,
        totals: totals,
        ratio: ratio,
        revenue: revenue,
      );
    }
    return null;
  }

  /// 머리글의 연도들. "2025년"이나 "제26기(2025년)"면 그 해, "제26기"뿐이면 당기부터 내려간다.
  static List<int>? _years(List<String> cells, int bsnsYear) {
    final found = <int?>[];
    var periods = <int>[];
    for (final c in cells) {
      final y = _year.firstMatch(c);
      final p = _period.firstMatch(c);
      if (y != null) {
        found.add(int.parse(y.group(1)!));
        periods.add(p == null ? -1 : int.parse(p.group(1)!));
      } else if (p != null) {
        found.add(null);
        periods.add(int.parse(p.group(1)!));
      }
    }
    if (found.isEmpty) {
      final relative = cells
          .map((c) => c.replaceAll(' ', ''))
          .where((c) => RegExp(r'^(당기|당반기|당분기|전기|전반기|전분기|전전기)$').hasMatch(c))
          .toList();
      if (relative.length < 2 ||
          relative.length > 3 ||
          cells.length - relative.length > 2 ||
          !RegExp(r'^당').hasMatch(relative.first) ||
          relative[1] != '전기' ||
          relative.length == 3 && relative[2] != '전전기') {
        return null;
      }
      return [for (var k = 0; k < relative.length; k++) bsnsYear - k];
    }
    if (found.length < 2 || found.length > 4) return null;
    // 머리글은 연도 칸만으로 거의 채워진다 (과목·비고 칸 정도만 더 있다).
    if (cells.length - found.length > 2) return null;
    if (found.every((y) => y != null)) return found.cast<int>();
    // Repeated terms may explicitly distinguish prior interim and full-year
    // columns. Interim read projection consumes only the current column.
    final termCells = cells.where((c) => _period.hasMatch(c)).toList();
    if (periods.any((p) => p < 0) || termCells.length != periods.length) {
      return null;
    }
    for (var k = 1; k < periods.length; k++) {
      final difference = periods[k - 1] - periods[k];
      if (difference < 0 ||
          difference > 1 ||
          difference == 0 &&
              termCells[k - 1].replaceAll(' ', '') ==
                  termCells[k].replaceAll(' ', '')) {
        return null;
      }
    }
    return [for (final term in periods) bsnsYear - (periods.first - term)];
  }

  /// 값 칸 [count]개 (앞에서부터). 끝의 비고 "-"는 무시한다. 숫자가 아니면 null 칸.
  static List<double?>? _values(List<String> cells, int count) {
    final vals = <double?>[];
    for (final c in cells) {
      if (vals.length == count) break;
      if (c == '-' || c == '—' || c.isEmpty) {
        vals.add(null);
        continue;
      }
      if (!_number.hasMatch(c)) return null;
      vals.add(number(c));
    }
    if (vals.length != count) return null;
    return vals;
  }

  /// Comma decimal is allowed only on an explicitly printed percent.
  static double? number(String raw) {
    var text = raw.trim();
    final negative =
        text.startsWith('△') ||
        text.startsWith('▲') ||
        text.startsWith('-') ||
        text.startsWith('(');
    final percent = text.endsWith('%');
    text = text.replaceAll(RegExp(r'[△▲()%\-]'), '');
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$').hasMatch(text)) {
      if (!percent || !RegExp(r'^\d+,\d{1,2}$').hasMatch(text)) return null;
      text = text.replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
    final value = double.tryParse(text);
    return value == null || !value.isFinite
        ? null
        : (negative ? -value : value);
  }

  static Future<int> store(Session session, BusinessDocument doc) =>
      RuleDocumentStore.run(
        session,
        doc,
        (current, tx) => _store(session, current, tx),
      );

  static Future<int> _store(
    Session session,
    BusinessDocument doc,
    Transaction tx,
  ) async {
    final sourceReport = await DisclosureReport.db.findById(
      session,
      doc.reportId,
      transaction: tx,
    );
    if (sourceReport?.reportCode != FinancialReportCode.annual) return 0;
    await DocumentFact.db.deleteWhere(
      session,
      transaction: tx,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          t.extractedBy.equals(RelationOrigin.api) &
          t.extractorModel.equals('표 규칙') &
          t.reviewedBy.equals(model) &
          t.kind.inSet({
            DocumentFactKind.rndExpense,
            DocumentFactKind.rndRatio,
          }),
    );
    final report = await DisclosureReport.db.findById(
      session,
      doc.reportId,
      transaction: tx,
    );
    if (report == null) return 0;
    final candidates = await StoredRndFacts.read(
      session,
      doc,
      report,
      transaction: tx,
    );
    final existing = {
      for (final f in await DocumentFact.db.find(
        session,
        transaction: tx,
        where: (t) =>
            t.documentId.equals(doc.id!) &
            t.kind.inSet({
              DocumentFactKind.rndExpense,
              DocumentFactKind.rndRatio,
            }),
      ))
        '${f.kind.name}|${f.asOf?.year}',
    };
    final facts = candidates
        .where((f) => existing.add('${f.kind.name}|${f.asOf?.year}'))
        .toList();
    if (facts.isEmpty) return 0;
    await DocumentFact.db.insert(session, facts, transaction: tx);
    return facts.length;
  }
}
