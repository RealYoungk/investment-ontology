/// 사업보고서 본문의 "부문별 매출" 표를 규칙으로 읽는다 (AI 없음).
///
/// 머리글에 매출액과 비중(비율)이 같이 있는 표만 받는다. 값은 **머리글에서 이름으로
/// 집은 칸**에서만 읽는다 — 여러 기(당기·전기·전전기)를 나란히 적는 표가 흔해서,
/// 아무 칸이나 마지막 두 개를 읽으면 전년 수치를 올해 값으로 저장하게 된다.
/// 표에 적힌 비중이 매출액 ÷ 합계와 맞아야 하므로 스스로 검산되지만, 같은 기의
/// 금액·비중을 함께 잘못 읽으면 검산도 통과한다.
abstract final class SegmentRevenue {
  /// 비중이 이보다 어긋나면 열을 잘못 읽은 것으로 본다 (%p).
  static const tolerance = 1.0;

  /// 한 표에서 받아들이는 최대 부문 수.
  static const maxRows = 20;

  static final _customerTable = RegExp(r'매출처|고객사|거래처|판매처');

  /// 단위 표기가 표 머리글에서 이보다 멀면 이 표의 단위로 보지 않는다 (줄 수).
  /// 실제 보고서는 표 바로 앞 줄에 "(단위 : 백만원)"을 적는다.
  static const unitDistance = 3;

  static final _amountHeader = RegExp(r'매출|금액');
  static final _amountExact = RegExp(r'매출액|금액');
  static final _ratioHeader = RegExp(r'비중|비율');

  /// "매출액(비율)"·"당기매출액(비율)"처럼 금액과 비율을 한 칸에 적는 머리글.
  static final _combinedHeader = RegExp(r'매출액\s*\(\s*(비율|비중)\s*\)');

  /// 그 한 칸의 값: "312,776,938 (79.4%)".
  static final _combinedCell = RegExp(
    r'^([△▲\-]?[\d,]+(?:\.\d+)?)\s*\(\s*([\d.]+)\s*%\s*\)$',
  );

  /// 부문별 재무 표에는 매출액 줄 사이에 영업이익·자산 줄이 있다 — 매출이 아니다.
  static final _notRevenueRow = RegExp(r'영업이익|영업손익|당기순이익|순이익|자산|부채|자본');

  /// 이름 칸에서 뺄 낱말 ("IT서비스 | 매출액 | …"의 매출액).
  static final _revenueWord = RegExp(r'^(매출액|매출|매출실적|당기매출액)$');
  static final _unitLine = RegExp(r'단위\s*[:：]\s*([^)\]]+)');
  static final _number = RegExp(r'^[△▲\-]?[\d,]+(?:\.\d+)?$');
  static const _totalLabels = {
    '계',
    '합계',
    '소계',
    '총계',
    '총합계',
    '매출총계',
    '매출합계',
    '매출액합계',
    '순매출액',
    '총매출액',
    '매출액계',
    '누계',
  };

  /// 돈 단위만 매출로 받는다 ("개"·"T"처럼 수량 단위가 붙은 표는 매출 표가 아니다).
  static final _money = RegExp(r'원|달러|USD|KRW|EUR|CHF|JPY|VND|CNY|\$|엔|유로|위안');

  /// "(단위 : 건, 백만원)" → 백만원, "USD 1,000" → 천USD. 돈 단위가 없거나 둘 이상이면 ''.
  static String pickUnit(String? raw) {
    if (raw == null) return '';
    // 자릿수 표기를 말로 바꾼 뒤 쉼표로 나눈다 ("1,000원"이 "1"과 "000원"으로 갈리지 않게).
    final spelled = raw
        .replaceAll(RegExp(r'1,000,000\s*'), '백만')
        .replaceAll(RegExp(r'1,000\s*'), '천');
    final parts = [
      for (final p in spelled.split(RegExp(r'[,，/]')))
        if (p.trim().isNotEmpty) p.trim(),
    ];
    final money = [
      for (final p in parts)
        if (_money.hasMatch(p)) p.replaceAll(' ', ''),
    ];
    if (money.length != 1) return '';
    // "USD천"처럼 통화 뒤에 자릿수가 붙는 표기는 공시에 흔하다 (천USD·USD천·VND억). 그대로 둔다.
    return money.single;
  }

  /// (부문 이름, 매출액, 단위, 그 줄).
  static List<({String label, double amount, String unit, String evidence})>
  parse(String text) {
    final out =
        <({String label, double amount, String unit, String evidence})>[];
    var unit = '';
    String? lastUnit;
    var lastUnitAt = -1000;
    var amountAt = -1, ratioAt = -1, columns = -1;
    // 금액과 비율이 한 칸("312,776,938 (79.4%)")인 표.
    var combined = false;
    var rows = <({String label, double amount, double ratio, String line})>[];
    double? total;

    void flush() {
      // 비중이 매출액 ÷ 합계와 맞는 표만 받는다. 합계 줄이 연결조정 뒤의 값이면 비중은
      // 조정 전 합(각 줄의 합)에 대한 것이니, 둘 중 하나와 맞으면 된다.
      final rowSum = rows.fold<double>(0, (a, r) => a + r.amount.abs());
      if (rows.isNotEmpty && unit.isNotEmpty) {
        bool fits(double sum) =>
            sum > 0 &&
            rows.every(
              (r) =>
                  (r.ratio.abs() - 100 * r.amount.abs() / sum).abs() <=
                  tolerance,
            );
        final ok = fits(total ?? rowSum) || total != null && fits(rowSum);
        if (ok) {
          for (final r in rows.take(maxRows)) {
            out.add((
              label: r.label,
              amount: r.amount,
              unit: unit,
              evidence: r.line,
            ));
          }
        }
      }
      rows = [];
      total = null;
      amountAt = -1;
      ratioAt = -1;
      columns = -1;
      combined = false;
      unit = '';
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
      final cells = [for (final c in line.split('|')) c.trim()];

      // 금액·비율이 한 칸인 머리글.
      final ci = cells.indexWhere(_combinedHeader.hasMatch);
      if (ci >= 0 && !cells.any((c) => _combinedCell.hasMatch(c))) {
        flush();
        if (_customerTable.hasMatch(line)) continue;
        combined = true;
        amountAt = ci;
        ratioAt = ci;
        columns = cells.length;
        unit = i - lastUnitAt <= unitDistance ? pickUnit(lastUnit) : '';
        lastUnit = null;
        continue;
      }

      final r = cells.indexWhere(_ratioHeader.hasMatch);
      // 비중 앞에서 금액 칸을 고른다. "매출유형"처럼 이름만 매출인 칸이 앞에 있으므로
      // 비중 바로 앞의 금액 칸을 쓴다 (기가 여러 개면 맨 앞이 당기다).
      final before = [
        for (var k = 0; k < r; k++)
          if (_amountHeader.hasMatch(cells[k])) k,
      ];
      final exact = [
        for (final k in before)
          if (_amountExact.hasMatch(cells[k])) k,
      ];
      final a = (exact.isNotEmpty ? exact : before).lastOrNull ?? -1;
      if (a >= 0 && r > a && cells.length >= 3 && !combined) {
        // "금액 | 비중"만 있는 둘째 머리글은 매출 표라는 말이 앞뒤 3줄 안에 있어야 한다
        // (원재료 매입 표도 같은 머리글을 쓴다).
        if (!line.contains('매출')) {
          var near = false;
          for (var j = i - 3; j <= i + 3 && !near; j++) {
            if (j >= 0 && j < lines.length && j != i) {
              near = lines[j].contains('매출');
            }
          }
          if (!near) continue;
        }
        flush();
        // 매출처별 표("매출처 | 매출품목 | … / 매출액 | 비중")는 부문이 아니라 고객이다.
        // 머리글이 두 줄이면 첫 줄이 바로 앞에 있다.
        if (_customerTable.hasMatch(line) ||
            i > 0 && _customerTable.hasMatch(lines[i - 1])) {
          amountAt = -1;
          continue;
        }
        amountAt = a;
        ratioAt = r;
        columns = cells.length;
        // 단위는 이 표 바로 앞에 적힌 것만, 한 번만 쓴다 (앞 표의 단위가 새지 않게).
        unit = i - lastUnitAt <= unitDistance ? pickUnit(lastUnit) : '';
        lastUnit = null;
        continue;
      }
      if (amountAt < 0) continue;
      if (line.startsWith('※') || cells.length < 2) {
        flush();
        continue;
      }
      // 둘째 머리글 줄("2025년 | 2024년")은 값이 아니다.
      if (cells.every(
        (c) => c.isEmpty || RegExp(r'^(\d{4}년?|제\s*\d+\s*기)').hasMatch(c),
      )) {
        continue;
      }
      final labels = [
        for (final c in cells)
          if (c.isNotEmpty &&
              !_number.hasMatch(c) &&
              !c.endsWith('%') &&
              !_combinedCell.hasMatch(c) &&
              !_revenueWord.hasMatch(c))
            c,
      ];
      double? amount, ratio;
      if (combined) {
        // 첫 번째 "금액 (비율)" 칸이 당기다. 합계 줄은 금액만 적기도 한다.
        final cc = cells.firstWhere(
          (c) => _combinedCell.hasMatch(c),
          orElse: () => '',
        );
        if (cc.isNotEmpty) {
          final m = _combinedCell.firstMatch(cc)!;
          amount = _num(m.group(1)!);
          ratio = double.tryParse(m.group(2)!);
        } else {
          final first = cells.firstWhere(_number.hasMatch, orElse: () => '');
          amount = first.isEmpty ? null : _num(first);
        }
      } else {
        // 칸은 오른쪽 끝을 기준으로 센다. 합계 줄처럼 앞쪽 이름 칸이 합쳐져 있어도
        // 기(期)별 숫자 묶음은 그대로라, 머리글에서 집은 칸을 다시 찾을 수 있다.
        amount = _num(_cell(cells, columns - amountAt));
        ratio = _num(_cell(cells, columns - ratioAt));
      }
      if (amount == null) continue;
      final name = labels.isEmpty ? '' : labels.first;
      if (labels.isNotEmpty &&
          _totalLabels.contains(name.replaceAll(' ', ''))) {
        total = amount.abs();
        continue;
      }
      if (labels.isEmpty || ratio == null) continue;
      // 영업이익·자산 줄이 매출 줄과 같은 비중 칸을 쓰는 표(부문별 재무정보).
      if (cells.any(_notRevenueRow.hasMatch)) continue;
      // 이름이 없는 줄("-")이나 음수 줄(부문간 내부거래 제거)은 부문이 아니다.
      if (RegExp(r'^[-—·]+$').hasMatch(name) || amount < 0) continue;
      rows.add((label: name, amount: amount, ratio: ratio, line: line));
    }
    flush();
    return out;
  }

  /// 오른쪽에서 [fromRight]번째 칸 (1이면 마지막). 없으면 빈 칸.
  static String _cell(List<String> cells, int fromRight) {
    final i = cells.length - fromRight;
    return i >= 0 && i < cells.length ? cells[i] : '';
  }

  /// "△301,146"(음수), "56.3%" → 수. 아니면 null.
  static double? _num(String s) {
    final t = s.replaceAll('%', '').trim();
    if (!_number.hasMatch(t)) return null;
    final negative = t.startsWith('△') || t.startsWith('▲');
    final v = double.tryParse(t.replaceAll(RegExp(r'[△▲,]'), ''));
    return v == null ? null : (negative ? -v : v);
  }
}
