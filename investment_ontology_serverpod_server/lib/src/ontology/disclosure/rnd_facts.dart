import 'rule_document_store.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'segment_revenue.dart';

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
  static final _ratio = RegExp(r'연구개발비(용)?\s*/\s*매출액|매출액\s*대비\s*연구개발비');
  static final _revenue = RegExp(r'^매\s*출\s*액$');
  static final _number = RegExp(r'^[△▲\-]?\(?[\d,]+(?:\.\d+)?\)?%?$');

  /// 한 문서의 연구개발비 표 (없으면 null).
  static ({
    List<int> years,
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
      final years = _years(cells, bsnsYear);
      if (years == null) continue;
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
        final label = rc.first;
        final values = _values(rc.sublist(1), years.length);
        if (values == null) continue;
        if (_total.hasMatch(label) && !label.contains('비율')) {
          totals.add((label: label, values: values, evidence: row));
        } else if (_ratio.hasMatch(label)) {
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
    if (found.length < 2 || found.length > 4) return null;
    // 머리글은 연도 칸만으로 거의 채워진다 (과목·비고 칸 정도만 더 있다).
    if (cells.length - found.length > 2) return null;
    if (found.every((y) => y != null)) return found.cast<int>();
    // 제N기만 있으면 기 번호가 줄어드는 순서일 때만 당기·전기·전전기로 본다.
    for (var k = 1; k < periods.length; k++) {
      if (periods[k] != periods[k - 1] - 1) return null;
    }
    return [for (var k = 0; k < found.length; k++) bsnsYear - k];
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
      final neg =
          c.startsWith('△') ||
          c.startsWith('▲') ||
          c.startsWith('-') ||
          c.startsWith('(');
      final v = double.tryParse(c.replaceAll(RegExp(r'[△▲,()%\-]'), ''));
      if (v == null) return null;
      vals.add(neg ? -v : v);
    }
    if (vals.length != count) return null;
    return vals;
  }

  static const _wonPerUnit = {
    '원': 1.0,
    '천원': 1e3,
    '백만원': 1e6,
    '억원': 1e8,
    '십억원': 1e9,
    '조원': 1e12,
  };

  /// 한 문서에서 읽어 저장한다. 비율과 맞는 계 줄이 없으면 아무것도 넣지 않는다.
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
    final table = parse(doc.text, bsnsYear: doc.bsnsYear);
    if (table == null) return 0;
    final won = _wonPerUnit[table.unit];
    if (won == null) return 0;
    final year0 = table.years.first;
    // 당기 매출액: 표의 줄, 없으면 재무제표 (연결 → 별도).
    final revenues = <double>[];
    if (table.revenue?.first case final r? when r > 0) revenues.add(r);
    if (revenues.isEmpty) {
      for (final fs in [FsDiv.consolidated, FsDiv.separate]) {
        final f = await FinancialFact.db.findFirstRow(
          session,
          transaction: tx,
          where: (t) =>
              t.companyId.equals(doc.companyId) &
              t.bsnsYear.equals(year0) &
              t.reportCode.equals(FinancialReportCode.annual) &
              t.fsDiv.equals(fs) &
              t.accountId.equals('ifrs-full_Revenue') &
              t.supersededById.equals(null),
        );
        if (f?.amount case final a? when a > BigInt.zero) {
          revenues.add(a.toDouble() / won);
        }
      }
    }
    if (revenues.isEmpty) return 0;
    final printed = table.ratio!.values.first;
    if (printed == null) return 0;
    ({String label, List<double?> values, String evidence})? chosen;
    for (final t in table.totals) {
      final v = t.values.first;
      if (v == null || v <= 0) continue;
      if (revenues.any((r) => (printed - 100 * v / r).abs() <= tolerance)) {
        chosen = t;
        break;
      }
    }
    if (chosen == null) return 0;

    final report = await DisclosureReport.db.findById(
      session,
      doc.reportId,
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
    final now = DateTime.now().toUtc();
    final facts = <DocumentFact>[];
    for (var k = 0; k < table.years.length; k++) {
      final year = table.years[k];
      for (final (kind, label, value, unit, evidence) in [
        (
          DocumentFactKind.rndExpense,
          expenseLabel,
          chosen.values[k],
          table.unit,
          chosen.evidence,
        ),
        (
          DocumentFactKind.rndRatio,
          ratioLabel,
          table.ratio!.values[k],
          '%',
          table.ratio!.evidence,
        ),
      ]) {
        if (value == null || value < 0) continue;
        if (!existing.add('${kind.name}|$year')) continue;
        facts.add(
          DocumentFact(
            companyId: doc.companyId,
            documentId: doc.id!,
            bsnsYear: doc.bsnsYear,
            kind: kind,
            label: label,
            value: value,
            unit: unit,
            asOf: DateTime.utc(year, 12, 31),
            evidence: evidence,
            sourceId: report?.sourceId,
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            reviewedAt: now,
            reviewedBy: model,
            createdAt: now,
          ),
        );
      }
    }
    if (facts.isEmpty) return 0;
    await DocumentFact.db.insert(session, facts, transaction: tx);
    return facts.length;
  }
}
