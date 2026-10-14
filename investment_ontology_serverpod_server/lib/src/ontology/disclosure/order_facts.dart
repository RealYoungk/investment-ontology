import 'segment_revenue.dart';
import 'literal_table_number.dart';

typedef OrderFactSourceRow = ({
  String label,
  double total,
  double delivered,
  double backlog,
  String unit,
  String evidence,
});

typedef OrderFactPrintedValues = ({
  String label,
  double? total,
  double? delivered,
  double? backlog,
  String unit,
  String totalHeader,
  String deliveredHeader,
  String backlogHeader,
});

/// 사업보고서 본문의 "수주상황" 표를 규칙으로 읽는다 (AI 없음).
///
/// 기업공시서식이 정한 꼴 — 머리글에 수주총액·기납품액·수주잔고가 같이 있는 표 — 만 받고,
/// 한 줄의 숫자 가운데 **수주총액 − 기납품액 = 수주잔고**가 맞는 세 칸만 값으로 쓴다.
/// 수량·금액 칸이 번갈아 있는 표에서는 수량끼리도 같은 식이 맞으므로, 맞는 조합이
/// 여럿이면 명시 금액 하위열을 먼저 고르고 그 열에서만 검산한다. 수주잔고 부호는 유지한다.
/// 금액 열 식이 틀리면 수량 열로 대신하지 않는다.
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

  /// 날짜·각주 표시("2022.06.2", "'25.12.31", "*2")는 품목 이름이 아니다.
  static final _dateLike = RegExp(
    r"^'?\d{2,4}[.\-/]\s?\d{1,2}([.\-/]\s?\d{1,2})?[.일]?\s*(까지|일까지)?$|^\*\d+$|^~",
  );

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
  parse(
    String text, {
    Set<String>? rejectedEvidence,
    List<OrderFactSourceRow>? verifiedRows,
    Map<String, OrderFactPrintedValues>? printedValues,
    Set<String>? ambiguousEvidence,
  }) {
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
    List<int>? amountOffsets;
    var numericWidth = 0;
    List<String> financialHeaders = [];
    var headerCellCount = 0;
    var namedTrailingColumns = 0;
    var flatMoneySubheader = false;
    var mixedUnits = false;
    var headerCurrency = false;
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

    String? tableScope;
    String? currentScope;
    var hasTotals = false;
    final nonTotals = <String>{};
    String? lastLabel;
    var continuation = 1;
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
          hasTotals = true;
          out.add((
            label: unique(tableScope == null ? '합계' : '$tableScope · 합계'),
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
            final label = unique(r.label);
            nonTotals.add(label);
            out.add((
              label: label,
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
      lastLabel = null;
    }

    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('## ') || RegExp(r'^\[[^\]]+\]$').hasMatch(line)) {
        flush();
        currentScope = null;
        lastUnit = null;
        lastUnitAt = -1000;
      }
      // Explicit company/segment heading, never the table's position number.
      if (!line.contains('|') && RegExp(r'회사명\s*[:：]').hasMatch(line)) {
        flush();
        currentScope = line
            .split(RegExp(r'\(?회사명\s*[:：]'))
            .first
            .replaceAll(RegExp(r'\[[^\]]+\]|\s+'), '')
            .trim();
      }
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
        tableScope = currentScope;
        flow = header == _HeaderKind.flow;
        amountOffsets = null;
        flatMoneySubheader = false;
        namedTrailingColumns = 0;
        numericWidth = 0;
        final headers = line
            .split('|')
            .map((c) => c.replaceAll(' ', ''))
            .toList();
        headerCellCount = headers.length;
        final firstMetric = headers.indexWhere(
          (h) => RegExp(r'기초|이월|전기말|20\d{2}년말|수주총액|당기수주|기본도급|도급액').hasMatch(h),
        );
        final lastMetric = headers.lastIndexWhere(
          (h) => RegExp(r'수주잔고|계약잔액|기말잔고').hasMatch(h),
        );
        financialHeaders = firstMetric >= 0 && lastMetric >= firstMetric
            ? headers.sublist(firstMetric, lastMetric + 1)
            : [];
        if (lastMetric >= 0 &&
            lastMetric < headers.length - 1 &&
            headers
                .sublist(lastMetric + 1)
                .every((h) => {'거래처명', '비고'}.contains(h))) {
          namedTrailingColumns = headers.length - lastMetric - 1;
        }
        unit = i - lastUnitAt <= unitDistance ? _pickUnit(lastUnit) : '';
        mixedUnits =
            lastUnit != null &&
            RegExp(r'수량|톤|Ton|TON|MT|T\b|천개|천㎡|대|건|세트').hasMatch(lastUnit);
        headerCurrency = financialHeaders.every(
          (h) => RegExp(r'금액|백만원|천원|억원|원\)').hasMatch(h),
        );
        lastUnit = null;
        continue;
      }
      if (!inTable) continue;
      final cells = [for (final c in line.split('|')) c.trim()];
      if (line.startsWith('※')) {
        flush();
        continue;
      }
      if (cells.length < 3) {
        // "(2024.12.31) | (2025.12.31)" 같은 기준일 줄은 표의 일부다.
        bool dateCell(String c) =>
            c.isEmpty ||
            _dateLike.hasMatch(c.replaceAll(RegExp(r'^\(|\)$'), ''));
        if (cells.every(dateCell)) continue;
        flush();
        continue;
      }
      // 두 번째 머리글 줄 ("수량 | 금액 | 수량 | 금액 …")은 값이 아니다.
      // "(10,322,942)"처럼 괄호로 적은 기납품액은 뺀 금액이다 — 크기만 쓴다 (식으로 검산된다).
      if (cells.any((c) => c.replaceAll(' ', '') == '금액') &&
          cells.every(
            (c) => {'수량', '금액', ''}.contains(c.replaceAll(' ', '')),
          )) {
        numericWidth = cells.length;
        flatMoneySubheader =
            cells.every((c) => c.replaceAll(' ', '') == '금액') &&
            cells.length == financialHeaders.length;
        amountOffsets = [
          for (var k = 0; k < cells.length; k++)
            if (cells[k].replaceAll(' ', '') == '금액') k,
        ];
        continue;
      }
      final numbers = <double>[];
      // 괄호 수는 뺀 금액이다. 흐름형에서는 기초·신규 사이의 "계약금액 변경 (1,353,700)"처럼
      // 부호가 뜻을 가지므로 따로 기억한다.
      final signed = <double>[];
      final literals = <double?>[];
      var invalidNumber = false;
      final selected =
          flatMoneySubheader &&
              namedTrailingColumns > 0 &&
              cells.length >= numericWidth + namedTrailingColumns + 1
          ? cells.sublist(
              cells.length - namedTrailingColumns - numericWidth,
              cells.length - namedTrailingColumns,
            )
          : amountOffsets != null && cells.length >= numericWidth
          ? [
              for (final k in amountOffsets)
                cells[cells.length - numericWidth + k],
            ]
          : financialHeaders.length >= 3 &&
                cells.length <= headerCellCount &&
                cells.length >= financialHeaders.length
          ? cells.sublist(cells.length - financialHeaders.length)
          : cells;
      for (final c in selected) {
        if (c == '-' ||
            c == '—' ||
            (c.isEmpty && !identical(selected, cells))) {
          numbers.add(0);
          signed.add(0);
          literals.add(null);
        } else {
          final v = _num(
            unit == r'$' && c.startsWith(r'$') ? c.substring(1).trim() : c,
          );
          if (v != null) {
            numbers.add(v);
            signed.add(v);
            literals.add(v);
          } else if ((unit == r'$' && c.startsWith(r'$')) ||
              _number.hasMatch(c) ||
              _parens.hasMatch(c) ||
              RegExp(r'^[△▲+−\-]?[\d,]+(?:\.\d+)?$').hasMatch(c)) {
            invalidNumber = true;
            break;
          }
        }
      }
      if (invalidNumber || numbers.length < 3) {
        if (invalidNumber && unit.isNotEmpty) rejectedEvidence?.add(line);
        continue;
      }
      if (amountOffsets == null &&
          (financialHeaders.isEmpty ||
              numbers.length != financialHeaders.length ||
              (mixedUnits && !headerCurrency))) {
        if (unit.isNotEmpty) ambiguousEvidence?.add(line);
        continue;
      }
      // Retain unambiguous literal monetary observations even when the balance
      // equation fails. They are source-only observations, never arithmetic facts.
      if (unit.isNotEmpty) {
        final direct =
            numbers.length == financialHeaders.length &&
            financialHeaders.length >= 3;
        final deliveredIndex = flow && direct
            ? financialHeaders.indexWhere(
                (h) => RegExp(r'기납품|납품액|완성공사|매출계상|매출인식|당기수익|수익인식').hasMatch(h),
              )
            : !flow && numbers.length == 3
            ? 1
            : -1;
        final backlogIndex = flow && direct
            ? financialHeaders.length - 1
            : !flow && numbers.length == 3
            ? 2
            : -1;
        if (deliveredIndex >= 0 &&
            backlogIndex >= 0 &&
            (direct || amountOffsets != null)) {
          printedValues?[line] = (
            label: tableScope == null
                ? cells.first
                : '$tableScope · ${cells.first}',
            total: flow ? null : literals.first,
            delivered: literals[deliveredIndex],
            backlog: literals[backlogIndex],
            unit: unit,
            totalHeader: financialHeaders.isEmpty
                ? '수주총액'
                : financialHeaders.first,
            deliveredHeader: financialHeaders.length > deliveredIndex
                ? financialHeaders[deliveredIndex]
                : '기납품액',
            backlogHeader: financialHeaders.length > backlogIndex
                ? financialHeaders[backlogIndex]
                : '수주잔고',
          );
        }
      }
      // Missing markers may be arithmetic placeholders, never disclosed zeros.
      if ((!flow && literals.contains(null)) ||
          (flow &&
              financialHeaders.length == literals.length &&
              [
                for (var k = 0; k < financialHeaders.length; k++)
                  if (RegExp(r'기납품|납품액|완성공사|매출계상|매출인식|당기수익|수익인식|기말|수주잔고|계약잔액')
                          .hasMatch(financialHeaders[k]) &&
                      k > 0)
                    literals[k],
              ].contains(null))) {
        if (unit.isNotEmpty) rejectedEvidence?.add(line);
        if (cells.first.isNotEmpty &&
            cells.first != '-' &&
            _num(cells.first) == null &&
            !_dateLike.hasMatch(cells.first)) {
          lastLabel = cells.first;
          continuation = 1;
        }
        continue;
      }
      final triple = flow
          ? _flowTriple(
              signed,
              amountOnly: amountOffsets != null,
              headers: financialHeaders,
            )
          : _triple(numbers);
      if (triple == null) {
        if (unit.isNotEmpty && (amountOffsets != null || numbers.length == 3)) {
          rejectedEvidence?.add(line);
        }
        continue;
      }
      final labels = [
        for (final c in cells)
          if (c.isNotEmpty &&
              c != '-' &&
              _num(c) == null &&
              !_dateLike.hasMatch(c))
            c,
      ];
      // 품목 칸이 빈 이어지는 줄("| 2022.06.2 | 2024.05.8 | …")은 앞 줄의 품목이다.
      String name;
      if (labels.isNotEmpty) {
        name = labels.first;
        lastLabel = name;
        continuation = 1;
      } else if (lastLabel case final l?) {
        name = '$l (${++continuation})';
      } else {
        name = '합계';
      }
      final row = (
        label: name.length > 60 ? name.substring(0, 60) : name,
        total: triple.$1,
        delivered: triple.$2,
        backlog: triple.$3,
        line: line,
      );
      if (unit.isNotEmpty) {
        verifiedRows?.add((
          label: row.label,
          total: row.total,
          delivered: row.delivered,
          backlog: row.backlog,
          unit: unit,
          evidence: line,
        ));
      }
      if (_totalLabels.contains(name.replaceAll(' ', ''))) {
        total = row;
      } else {
        rows.add(row);
      }
    }
    flush();
    // 합계 표가 하나라도 있으면, 합계 없는 표의 줄(자회사·부문의 한 줄짜리 표)은 그 회사 값이
    // 아닐 때가 많다 — 합계만 남긴다. 합계 표가 없는 작은 회사는 줄마다 그대로 둔다.
    if (hasTotals) {
      out.removeWhere((r) => nonTotals.contains(r.label));
    }
    return out;
  }

  /// 머리글이 어느 꼴인지. 표준(수주총액·기납품액·수주잔고), 건설(기본도급액·완성공사액·계약잔액)은
  /// 세 칸 식이 같고, 흐름형(기초·신규·기납품액·기말잔고)은 기초 + 신규 − 기납품 = 잔고다.
  static _HeaderKind? _headerKind(String line) {
    final delivered = RegExp(
      r'기납품액|납품액|완성공사액|매출계상액|매출인식액|당기수익|수익인식',
    ).hasMatch(line);
    if (!delivered) return null;
    final closing = RegExp(r'수주\s*잔고|계약\s*잔액|기말\s*잔고').hasMatch(line);
    if (!closing) return null;
    // 기초·이월(전기 잔고)이나 신규·증감 칸이 있으면 흐름형이다 — "수주총액"이 함께 있어도
    // (LG CNS: 기초계약잔액 | 수주총액 | 기납품액 | 수주잔고) 그 수주총액은 당기 신규분이다.
    final opening = RegExp(r'기초|이월|전기말|20\d{2}\s*년말').hasMatch(line);
    final added =
        line.contains('신규') || line.contains('산규') || line.contains('증감');
    if (opening || added) return _HeaderKind.flow;
    final total =
        line.contains('수주총액') ||
        RegExp(r'당기\s*수주').hasMatch(line) ||
        line.contains('기본도급액') ||
        line.contains('기본 도급금액') ||
        line.contains('도급액');
    return total ? _HeaderKind.standard : null;
  }

  static final _projectTable = RegExp(
    r'공\s*사\s*명|현\s*장\s*명|프로젝트\s*명|사\s*업\s*명|계\s*약\s*명|수주처명',
  );

  /// 흐름형 줄: 마지막 두 수가 (기납품, 잔고)이고 나머지(기초·사업결합·신규)를 더한 것이 총액.
  /// 수량 칸("-")의 0은 빼고 센다. 식이 안 맞으면(수량이 섞인 줄) 버린다.
  static (double, double, double)? _flowTriple(
    List<double> numbers, {
    bool amountOnly = false,
    List<String> headers = const [],
  }) {
    if (headers.length == numbers.length && headers.isNotEmpty) {
      final deliveredIndex = headers.indexWhere(
        (h) => RegExp(r'기납품|납품액|완성공사|매출계상|매출인식|당기수익|수익인식').hasMatch(h),
      );
      final closingIndex = headers.lastIndexWhere(
        (h) => RegExp(r'수주잔고|계약잔액|기말잔고').hasMatch(h),
      );
      if (deliveredIndex >= 0 &&
          closingIndex >= 0 &&
          deliveredIndex != closingIndex) {
        final delivered = numbers[deliveredIndex].abs();
        final backlog = numbers[closingIndex];
        var total = 0.0;
        for (var i = 0; i < numbers.length; i++) {
          if (i != deliveredIndex && i != closingIndex) total += numbers[i];
        }
        return total > 0 &&
                (total - delivered - backlog).abs() <=
                    (total * tolerance).clamp(1, double.infinity)
            ? (total, delivered, backlog)
            : null;
      }
    }
    final n = [
      for (final v in numbers)
        if (amountOnly || v != 0) v,
    ];
    // 수량 칸이 "-"가 아니라 숫자면 금액과 번갈아 온다 (24 | 2,251,142 | 6 | 691,323 …).
    // 전체, 홀수 자리, 짝수 자리 가운데 식이 맞는 쪽을 쓴다 (금액이 커서 총액이 큰 쪽).
    final candidates = [
      n,
      if (!amountOnly && n.length >= 6 && n.length.isEven) ...[
        [for (var i = 1; i < n.length; i += 2) n[i]],
        [for (var i = 0; i < n.length; i += 2) n[i]],
      ],
    ];
    (double, double, double)? best;
    for (final c in candidates) {
      if (c.length < 3) continue;
      // 기납품과 잔고는 크기만 (괄호로 적기도 한다). 기초·변경·신규는 부호대로 더한다.
      final backlog = c.last;
      final delivered = c[c.length - 2].abs();
      final total = c.sublist(0, c.length - 2).fold(0.0, (a, b) => a + b);
      if (total <= 0) continue;
      if ((total - delivered - backlog).abs() >
          (total * tolerance).clamp(1, double.infinity)) {
        continue;
      }
      if (best == null || total > best.$1) best = (total, delivered, backlog);
    }
    return best;
  }

  /// 총액 − 기납품 = 잔고가 맞는 (총액, 기납품, 잔고). 여럿이면 총액이 가장 큰 것.
  static (double, double, double)? _triple(List<double> n) {
    (double, double, double)? best;
    for (var i = 0; i < n.length; i++) {
      for (var j = i + 1; j < n.length; j++) {
        for (var k = j + 1; k < n.length; k++) {
          final a = n[i], b = n[j].abs(), c = n[k];
          if (a <= 0) continue;
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

  static double? _num(String s) =>
      s.contains('%') ? null : literalTableNumber(s.replaceAll('▲', '-'));
}

enum _HeaderKind { standard, flow }
