/// 사업보고서 본문의 연도별 시장점유율 표를 규칙으로 읽는다 (AI 없음).
///
/// 받는 꼴은 하나다: 머리글에 연도가 둘 이상 있고("구 분 | 2025년 | 2024년 | 2023년"),
/// 이 회사 자신의 줄("당사 …" 또는 회사 이름)에 퍼센트 값이 있는 표. 표 앞 15줄 안에
/// "점유율"이라는 말이 있어야 한다. 경쟁사 줄, 순위표, 연도가 줄에 있는 표(뒤집힌 표)는
/// 읽지 않는다 — 틀린 값을 넣느니 비워 두는 쪽이 낫다.
///
/// 값은 % 기호가 붙은 칸만 쓰고(단위 줄이 %면 숫자만 있어도 받는다), 0~100 밖이면 버린다.
/// 칸은 머리글의 연도 자리를 오른쪽 끝 기준으로 다시 찾는다 (이름 칸이 둘로 나뉜 줄도 맞는다).
abstract final class MarketShareFacts {
  /// 표 머리글 앞에서 "점유율"을 찾는 범위 (줄 수).
  static const contextLines = 15;

  static final _year = RegExp(
    r"^(?:'?(\d{2})|((?:19|20)\d{2}))\s*년?(?:도)?\s*(상반기|반기|1분기|3분기)?(?:말)?$",
  );
  static final _percent = RegExp(r'^(\d{1,3}(?:\.\d+)?)\s*%$');
  static final _plain = RegExp(r'^(\d{1,3}(?:\.\d+)?)$');
  static final _unitPercent = RegExp(r'단위\s*[:：]\s*%');
  static final _amount = RegExp(r'^[\d,]+(?:\.\d+)?$');
  static final _subHeader = RegExp(
    r'점유율|수량|수주량|금액|매출액|대수|인가대수|판매량|생산량|잔액|건수|척|비중',
  );
  static final _self = RegExp(r'^(당\s*사|자\s*사|연결회사|연결실체|회사)(\s|$|\(|점유율)');

  /// (이름, 연도, 값 %, 그 줄).
  static List<
    ({
      String label,
      int year,
      int month,
      double value,
      String evidence,
      String basis,
      bool estimated,
    })
  >
  parse(
    String text, {
    required String owner,

    /// 보고서의 사업연도. 이보다 7년 넘게 앞선 연도 칸(옛 추이표)은 받지 않는다.
    int? bsnsYear,
  }) {
    final out =
        <
          ({
            String label,
            int year,
            int month,
            double value,
            String evidence,
            String basis,
            bool estimated,
          })
        >[];
    final ownerKey = _key(owner);
    final lines = text.split('\n');
    var lastShareAt = -1000;
    var unitPercentAt = -1000;
    // 머리글의 연도 자리: 머리글 칸 수, (칸 자리 → 연도).
    var columns = 0;
    var years = <int, int>{};
    var months = <int, int>{};
    // 연도마다 칸이 여럿일 때: 칸 수와 그중 점유율 칸의 자리.
    var span = 1, offset = 0;
    String? hint;
    var basis = '';
    var estimated = false;
    // 표에 이 회사 줄이 없고 값 줄이 하나뿐이면(제품별 표: "TV | 28.3% | 30.1% | 29.7%")
    // 그 한 줄이 이 회사의 점유율이다. 표가 끝날 때 판단하려고 모아 둔다.
    var tableRows = 0;
    List<
      ({
        String label,
        int year,
        int month,
        double value,
        String evidence,
        String basis,
        bool estimated,
      })
    >?
    single;
    void endTable() {
      if (tableRows == 1 && single != null) out.addAll(single!);
      tableRows = 0;
      single = null;
      years = {};
    }

    final used = <String>{};
    String unique(String label) {
      if (used.add(label)) return label;
      for (var n = 2; ; n++) {
        final l = '$label ($n)';
        if (used.add(l)) return l;
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.contains('점유율')) lastShareAt = i;
      if (_unitPercent.hasMatch(line)) unitPercentAt = i;
      final cells = [for (final c in line.split('|')) c.trim()];
      if (cells.length < 3) {
        endTable();
        continue;
      }
      // 머리글: 연도 칸이 둘 이상.
      final found = <int, int>{};
      final foundMonths = <int, int>{};
      for (var c = 0; c < cells.length; c++) {
        final m = _year.firstMatch(cells[c]);
        if (m == null) continue;
        final y = m.group(2) != null
            ? int.parse(m.group(2)!)
            : 2000 + int.parse(m.group(1)!);
        found[c] = y;
        foundMonths[c] = switch (m.group(3)) {
          '상반기' || '반기' => 6,
          '1분기' => 3,
          '3분기' => 9,
          _ => 12,
        };
      }
      if (found.length >= 2 && found.length == found.values.toSet().length) {
        endTable();
        // "점유율"은 표 위 제목이나 표 아래 주석("※ 시장점유율은 … 자료")에 있다.
        var shareNear = i - lastShareAt <= contextLines;
        for (var j = i + 1; j <= i + 6 && j < lines.length && !shareNear; j++) {
          shareNear = lines[j].contains('점유율');
        }
        if (!shareNear ||
            bsnsYear != null &&
                found.values.any((y) => y < bsnsYear - 7 || y > bsnsYear + 1)) {
          years = {};
          continue;
        }
        columns = cells.length;
        years = found;
        months = foundMonths;
        span = 1;
        offset = 0;
        hint = _hint(lines, i);
        final context = lines.skip(i).take(8).join('\n');
        basis = RegExp(r'금액\s*기준').hasMatch(context)
            ? '매출액 기준'
            : RegExp(r'수량\s*기준').hasMatch(context)
            ? '판매량 기준'
            : '';
        estimated = RegExp(r'당사\s*추정').hasMatch(context);
        // 둘째 머리글 줄("수주량 | 점유율 | 수주량 | 점유율 …")이 있으면 연도마다 칸이 여럿이다.
        // 점유율 칸의 자리를 기억한다.
        if (i + 1 < lines.length) {
          final sub = [for (final c in lines[i + 1].split('|')) c.trim()];
          if (sub.length >= 2 * found.length &&
              sub.every((c) => c.isEmpty || _subHeader.hasMatch(c))) {
            // 머리글의 이름 칸 뒤가 모두 연도여야 칸 수를 믿을 수 있다
            // ("2025년 3분기말"처럼 연도가 아닌 칸이 섞이면 자리를 셀 수 없다).
            final groups = cells.length - 1;
            final at = sub.indexWhere((c) => c.contains('점유율'));
            if (groups != found.length ||
                sub.length % groups != 0 ||
                at < 0 ||
                at >= sub.length ~/ groups) {
              years = {};
              continue;
            }
            span = sub.length ~/ groups;
            offset = at;
            i++;
          }
        }
        continue;
      }
      if (years.isEmpty) continue;

      // 값 줄: 이름 칸(앞쪽의 숫자 아닌 칸)이 이 회사여야 한다.
      final labelCells = <String>[];
      for (final c in cells) {
        if (_percent.hasMatch(c) ||
            _plain.hasMatch(c) ||
            _amount.hasMatch(c) ||
            c == '-') {
          break;
        }
        if (c.isNotEmpty) labelCells.add(c);
      }
      if (labelCells.isEmpty) continue;
      final label = labelCells.join(' ');
      // 이 회사인지는 칸 하나가 정확히 맞아야 한다 — "녹십자웰빙"은 "녹십자"가 아니다.
      final isSelf =
          _self.hasMatch(labelCells.first) && !label.contains('경쟁') ||
          labelCells.any((c) => _key(c) == ownerKey && ownerKey.length >= 2);
      // 이 회사 줄이 아니어도 값 줄로 센다 (한 줄뿐인 제품별 표를 가리려고).
      tableRows++;
      final candidate =
          !isSelf &&
          !RegExp(
            r'경쟁|기타|합계|계$|시장|산업|전체|증감|성장|증가|감소|비율|매출|이익|원가|비용|수익',
          ).hasMatch(label);
      if (!isSelf && !candidate) continue;
      // 이름 칸 뒤는 모두 값이어야 한다 ("대한조선 | 15.7% | HD현대중공업 | 10.2%" 같은
      // 순위 쌍 표는 칸이 어긋난다). 칸 수도 머리글과 맞아야 한다 (이름이 둘로 나뉜 줄은 +1).
      final valueCells = cells.sublist(labelCells.length);
      if (!valueCells.every(
        (c) =>
            c.isEmpty ||
            c == '-' ||
            _percent.hasMatch(c) ||
            _amount.hasMatch(c),
      )) {
        continue;
      }
      final expected = span == 1 ? columns : years.length * span;
      if (span == 1 && cells.length != columns && cells.length != columns + 1) {
        continue;
      }
      if (span > 1 && valueCells.length != years.length * span) continue;
      final percentUnit = i - unitPercentAt <= contextLines + 5;
      var any = false;
      final yearList = years.entries.toList();
      for (var k = 0; k < yearList.length; k++) {
        final e = yearList[k];
        final at = span == 1
            ? cells.length - (columns - e.key)
            : cells.length - expected + k * span + offset;
        if (at < 0 || at >= cells.length) continue;
        final cell = cells[at];
        final m =
            _percent.firstMatch(cell) ??
            (percentUnit ? _plain.firstMatch(cell) : null);
        if (m == null) continue;
        final v = double.parse(m.group(1)!);
        if (v < 0 || v > 100) continue;
        if (isSelf) {
          out.add((
            label: any ? out.last.label : unique(hint ?? '당사'),
            year: e.value,
            month: months[e.key]!,
            value: v,
            evidence: line,
            basis: basis,
            estimated: estimated && months[e.key]! != 12,
          ));
        } else {
          // 제품별 표의 한 줄: 이름은 그 줄의 제품.
          (single ??= []).add((
            label: any ? single!.last.label : unique(label),
            year: e.value,
            month: months[e.key]!,
            value: v,
            evidence: line,
            basis: basis,
            estimated: estimated && months[e.key]! != 12,
          ));
        }
        any = true;
      }
      // 이 회사 줄은 표마다 하나다 — 다음 줄부터는 경쟁사.
      if (any && isSelf) {
        tableRows = 0;
        single = null;
        years = {};
      }
    }
    endTable();
    return out;
  }

  /// 표 바로 위의 짧은 제목 줄("(1) 압축기", "가. 국내 시장") — 무엇의 점유율인지.
  static String? _hint(List<String> lines, int headerAt) {
    for (var j = headerAt - 1; j >= 0 && j >= headerAt - 3; j--) {
      final l = lines[j].trim();
      if (l.isEmpty) continue;
      if (l.contains('|') || l.startsWith('※') || l.startsWith('(단위')) {
        continue;
      }
      // 문장("…점유율 추이입니다.")은 제목이 아니다 — 짧은 제목 줄만.
      if (l.length > 30 || RegExp(r'[.다]$|습니다|입니다|,').hasMatch(l)) {
        continue;
      }
      final t = l
          .replaceAll(RegExp(r'^\[|\]$'), '')
          // "(1) ", "가. ", "② " 같은 번호는 뗀다 — 닫는 기호가 있을 때만.
          .replaceAll(
            RegExp(r'^\(?(\d{1,2}|[가-하]|[a-zA-Z])[\)\.]\s*|^[①-⑳]\s*'),
            '',
          )
          .replaceAll(RegExp(r'\s*(시장)?점유율(\s*등|\s*추이|\s*현황)?\s*$'), '')
          .trim();
      // 글자가 둘은 있어야 제목이고, 길면 제목이 아니라 설명이다 ("②", "□"는 아니다).
      if (RegExp(r'[가-힣a-zA-Z]').allMatches(t).length < 2 || t.length > 20) {
        return null;
      }
      return t;
    }
    return null;
  }

  static String _key(String name) => name
      .replaceAll(RegExp(r'\((주|유)\)|㈜|주식회사|유한회사|\s|\(.*?\)'), '')
      .toLowerCase();
}
