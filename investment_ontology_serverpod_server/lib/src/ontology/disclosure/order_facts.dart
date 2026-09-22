import 'segment_revenue.dart';

/// 사업보고서 본문의 "수주상황" 표를 규칙으로 읽는다 (AI 없음).
///
/// 기업공시서식이 정한 꼴 — 머리글에 수주총액·기납품액·수주잔고가 같이 있는 표 — 만 받고,
/// 한 줄의 숫자 가운데 **수주총액 − 기납품액 = 수주잔고**가 맞는 세 칸만 값으로 쓴다.
/// 수량·금액 칸이 번갈아 있는 표에서는 수량끼리도 같은 식이 맞으므로, 맞는 조합이
/// 여럿이면 가장 큰 쪽(금액)을 고른다. 식이 맞는 조합이 없으면 그 줄은 버린다.
///
/// 단위는 표 바로 앞(3줄 안)의 "(단위 : 백만원)"만 쓰고 한 번 쓰면 잊는다 — 앞 표의
/// 단위가 새지 않게. 통화가 여럿인 표(천 USD, 백만 KRW …)는 어느 줄이 어느 통화인지
/// 알 수 없어 통째로 버린다.
///
/// 합계 줄이 있으면 그 줄만 "합계"로 저장한다 (기간·품목별 줄은 이름이 해마다 달라
/// 계열이 안 된다). 합계 줄이 없으면 각 줄을 이름과 함께 저장한다.
abstract final class OrderFacts {
  /// 수주총액 − 기납품액 − 수주잔고가 이보다 크면 (총액의 비율) 식이 안 맞는 것으로 본다.
  static const tolerance = 0.005;

  /// 합계 줄이 없을 때 한 표에서 받아들이는 최대 줄 수.
  static const maxRows = 10;

  /// 단위 표기가 머리글에서 이보다 멀면 이 표의 단위로 보지 않는다 (줄 수).
  static const unitDistance = 3;

  static final _unitLine = RegExp(r'단위\s*[:：]\s*([^)\]]+)');
  static final _number = RegExp(r'^[△▲\-]?[\d,]+(?:\.\d+)?$');
  static final _parens = RegExp(r'^\([\d,]+(?:\.\d+)?\)$');
  static const _totalLabels = {'계', '합계', '소계', '총계', '총합계', '누계'};

  /// (이름, 수주총액, 기납품액, 수주잔고, 단위, 그 줄).
  static List<
    ({
      String label,
      double total,
      double delivered,
      double backlog,
      String unit,
      String evidence,
    })
  >
  parse(String text) {
    final out =
        <
          ({
            String label,
            double total,
            double delivered,
            double backlog,
            String unit,
            String evidence,
          })
        >[];
    String? lastUnit;
    var lastUnitAt = -1000;
    var inTable = false;
    var flow = false;
    var unit = '';
    var rows =
        <
          ({
            String label,
            double total,
            double delivered,
            double backlog,
            String line,
          })
        >[];
    ({
      String label,
      double total,
      double delivered,
      double backlog,
      String line,
    })?
    total;

    // 한 문서에 수주 표가 여럿이면(부문마다) 합계가 겹친다 — "합계 (2)"로 가른다.
    final used = <String>{};
    String unique(String label) {
      if (used.add(label)) return label;
      for (var n = 2; ; n++) {
        final l = '$label ($n)';
        if (used.add(l)) return l;
      }
    }

    void flush() {
      if (inTable && unit.isNotEmpty) {
        if (total case final t?) {
          out.add((
            label: unique('합계'),
            total: t.total,
            delivered: t.delivered,
            backlog: t.backlog,
            unit: unit,
            evidence: t.line,
          ));
        } else if (rows.length <= maxRows &&
            rows.map((r) => r.label).toSet().length == rows.length) {
          // 합계 줄 없이 줄이 많거나 이름이 겹치면(프로젝트별 표) 계열 이름을 붙일 수 없다.
          for (final r in rows) {
            out.add((
              label: unique(r.label),
              total: r.total,
              delivered: r.delivered,
              backlog: r.backlog,
              unit: unit,
              evidence: r.line,
            ));
          }
        }
      }
      inTable = false;
      unit = '';
      rows = [];
      total = null;
    }

    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final u = _unitLine.firstMatch(line);
      if (u != null) {
        lastUnit = u.group(1)!.trim();
        lastUnitAt = i;
      }
      final header = _headerKind(line);
      if (header != null) {
        flush();
        // 공사명·현장명이 있는 표는 프로젝트별 상세라 회사 전체 값이 아니다 (발주처 칸은 표준 표에도 있다).
        if (_projectTable.hasMatch(line)) continue;
        inTable = true;
        flow = header == _HeaderKind.flow;
        unit = i - lastUnitAt <= unitDistance ? _pickUnit(lastUnit) : '';
        lastUnit = null;
        continue;
      }
      if (!inTable) continue;
      final cells = [for (final c in line.split('|')) c.trim()];
      if (line.startsWith('※') || cells.length < 3) {
        flush();
        continue;
      }
      // 두 번째 머리글 줄 ("수량 | 금액 | 수량 | 금액 …")은 값이 아니다.
      // "(10,322,942)"처럼 괄호로 적은 기납품액은 뺀 금액이다 — 크기만 쓴다 (식으로 검산된다).
      final numbers = <double>[];
      for (final c in cells) {
        final bare = _parens.hasMatch(c) ? c.substring(1, c.length - 1) : c;
        if (c == '-' || c == '—') {
          numbers.add(0);
        } else if (_number.hasMatch(bare)) {
          numbers.add(_num(bare)!.abs());
        }
      }
      if (numbers.length < 3) continue;
      final triple = flow ? _flowTriple(numbers) : _triple(numbers);
      if (triple == null) continue;
      final labels = [
        for (final c in cells)
          if (c.isNotEmpty &&
              c != '-' &&
              !_number.hasMatch(c) &&
              !_parens.hasMatch(c))
            c,
      ];
      final name = labels.isEmpty ? '합계' : labels.first;
      final row = (
        label: name.length > 60 ? name.substring(0, 60) : name,
        total: triple.$1,
        delivered: triple.$2,
        backlog: triple.$3,
        line: line,
      );
      if (_totalLabels.contains(name.replaceAll(' ', ''))) {
        total = row;
      } else {
        rows.add(row);
      }
    }
    flush();
    // 합계 표가 하나라도 있으면, 합계 없는 표의 줄(자회사·부문의 한 줄짜리 표)은 그 회사 값이
    // 아닐 때가 많다 — 합계만 남긴다. 합계 표가 없는 작은 회사는 줄마다 그대로 둔다.
    if (out.any((r) => r.label.startsWith('합계'))) {
      out.removeWhere((r) => !r.label.startsWith('합계'));
    }
    return out;
  }

  /// 머리글이 어느 꼴인지. 표준(수주총액·기납품액·수주잔고), 건설(기본도급액·완성공사액·계약잔액)은
  /// 세 칸 식이 같고, 흐름형(기초·신규·기납품액·기말잔고)은 기초 + 신규 − 기납품 = 잔고다.
  static _HeaderKind? _headerKind(String line) {
    final delivered = line.contains('기납품액') || line.contains('완성공사액');
    final backlog =
        line.contains('수주잔고') ||
        line.contains('계약잔액') ||
        line.contains('수주잔액') && !line.contains('기초') && !line.contains('이월');
    if (!delivered) return null;
    final total =
        line.contains('수주총액') ||
        line.contains('기본도급액') ||
        line.contains('기본 도급금액') ||
        line.contains('도급액');
    if (total && backlog) return _HeaderKind.standard;
    final opening = line.contains('기초') || line.contains('이월');
    final added = line.contains('신규') || line.contains('당기');
    final closing =
        line.contains('수주잔고') ||
        line.contains('기말수주잔고') ||
        line.contains('기말잔고');
    if (opening && added && closing) return _HeaderKind.flow;
    return null;
  }

  static final _projectTable = RegExp(
    r'공\s*사\s*명|현\s*장\s*명|프로젝트\s*명|사\s*업\s*명|계\s*약\s*명|수주처명',
  );

  /// 흐름형 줄: 마지막 두 수가 (기납품, 잔고)이고 나머지(기초·사업결합·신규)를 더한 것이 총액.
  /// 수량 칸("-")의 0은 빼고 센다. 식이 안 맞으면(수량이 섞인 줄) 버린다.
  static (double, double, double)? _flowTriple(List<double> numbers) {
    final n = [
      for (final v in numbers)
        if (v != 0) v,
    ];
    if (n.length < 3) return null;
    final backlog = n.last;
    final delivered = n[n.length - 2];
    final total = n.sublist(0, n.length - 2).fold(0.0, (a, b) => a + b);
    if (total <= 0) return null;
    if ((total - delivered - backlog).abs() >
        (total * tolerance).clamp(1, double.infinity)) {
      return null;
    }
    return (total, delivered, backlog);
  }

  /// 총액 − 기납품 = 잔고가 맞는 (총액, 기납품, 잔고). 여럿이면 총액이 가장 큰 것.
  static (double, double, double)? _triple(List<double> n) {
    (double, double, double)? best;
    for (var i = 0; i < n.length; i++) {
      for (var j = i + 1; j < n.length; j++) {
        for (var k = j + 1; k < n.length; k++) {
          final a = n[i], b = n[j], c = n[k];
          if (a <= 0 || b < 0 || c < 0) continue;
          if ((a - b - c).abs() > (a * tolerance).clamp(1, double.infinity)) {
            continue;
          }
          if (best == null || a > best.$1) best = (a, b, c);
        }
      }
    }
    return best;
  }

  /// "(단위 : 건, 백만원)" → 백만원. 돈 단위가 없거나(수량만 적은 표) 둘 이상이면(어느 줄이
  /// 어느 통화인지 모른다) '' — 그 표는 받지 않는다. [SegmentRevenue.pickUnit]과 같은 규칙.
  static String _pickUnit(String? raw) => SegmentRevenue.pickUnit(raw);

  static double? _num(String s) {
    final t = s.trim();
    if (!_number.hasMatch(t)) return null;
    final negative =
        t.startsWith('△') || t.startsWith('▲') || t.startsWith('-');
    final v = double.tryParse(t.replaceAll(RegExp(r'[△▲,\-]'), ''));
    return v == null ? null : (negative ? -v : v);
  }
}

enum _HeaderKind { standard, flow }
