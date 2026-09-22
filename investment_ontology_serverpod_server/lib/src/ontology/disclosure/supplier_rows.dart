/// 사업보고서 본문의 "주요 원재료" 표에서 매입처를 규칙으로 읽는다 (AI 없음).
///
/// 머리글에 "매입처"라고 적힌 칸만 쓴다. 어떤 회사는 거래처를 "비고" 칸에 적지만
/// 거기엔 부품 이름("Bushing 外")도 섞여 있어, 검수 없이 넣기에는 못 미덥다.
///
/// 머리글에 매입처·공급처·구입처가 있는 표만 받는다. 그 칸의 이름들만 쓰고,
/// "등·外"처럼 목록을 열어 두는 말과 사업장 이름은 떼어 낸다. 이름이 아닌 것
/// (숫자·용도 설명)은 버린다 — 틀린 관계를 넣느니 비워 두는 쪽이 낫다.
abstract final class SupplierRows {
  /// 한 문서에서 받아들이는 최대 이름 수.
  static const maxNames = 60;

  /// 이 글자가 들어간 머리글 칸을 매입처 칸으로 본다.
  static final _header = RegExp(r'매입처|공급처|구입처|매입업체|공급업체');

  /// 이름 뒤에 붙는 군더더기.
  static final _tail = RegExp(
    r'(\s*(등|외|外|기타|계열)\s*$)|(\s*(인천|구미|아산|창원|울산|여수|천안|거제|영암)?\s*(공장|사업장|본사|외주|조선소)\s*$)',
  );

  static final _bad = RegExp(
    // 숫자·기호, 없음, 그리고 이름이 아닌 칸 — "A사"처럼 익명 처리한 거래처,
    // "국내"·"수입" 같은 시장 구분, "비율"·"금액" 같은 두 번째 머리글.
    r'[0-9%]|^[-—·]+$|해당\s*없음|미기재|자체|^[A-Z]사$|^(국내|수입|해외|기타|국내외|비율|비중|금액|매입액|매입처|품목|구분|미국|유럽|호주|중국|일본|아시아|동남아|중동|있음|없음|비고|방법|상품|제품|원재료|자재|건재|농산|kg|톤|t|m|M)$',
  );

  /// 닫는 괄호만 남은 조각("톤)", "장)")은 표 칸이 어긋난 것이다.
  static bool _danglingParen(String name) =>
      name.endsWith(')') && !name.contains('(');

  /// 두 번째 머리글 줄("매입액 | 비율 | 매입액 | 비율")은 값이 아니다.
  static final _headerWord = RegExp(r'^(매입액|비율|비중|금액|수량|단가|구분|품목|용도)$');

  /// "주요 매출처는 A, B, C 등" 문장에서 매출처 이름. 이 꼴이 아니면 읽지 않는다
  /// ("주요 매출처는 자동차 OEM 업체로서…"처럼 이름이 아닌 문장이 많다).
  /// "주요 매출처는 A, B 등" · "주요 매출처로는 A, B 등이 있으며" · "주요 매출처는 A와 B입니다".
  static final _customers = RegExp(
    r'주요\s*매출처(?:는|로는)\s*([^.]{3,200}?)\s*(?:등|입니다|이며|이고)',
  );

  /// 이름 앞에 붙은 설명("자동차용 도료 거래선인 현대자동차") — 이름만 남긴다.
  static final _describer = RegExp(r'^.*?(거래선|거래처|업체|고객사|고객|제조사|회사)인\s+');

  /// 이름 목록의 구분: 쉼표, "및", "A와 B"·"A과 B"의 조사.
  static final _listSplit = RegExp(r'[,،]|\s및\s|(?<=[)\w가-힣])(?:와|과)\s+');

  static List<({String name, String evidence})> customers(String text) {
    final out = <({String name, String evidence})>[];
    final seen = <String>{};
    for (final line in text.split('\n')) {
      for (final m in _customers.allMatches(line)) {
        final sentence = line.trim();
        // 괄호 속 부연("폭스바겐 그룹(폭스바겐, 아우디)")은 떼고 나눈다.
        final list = m
            .group(1)!
            .replaceAll(
              RegExp(r'\((?![주유]\))[^)]*\)'),
              '',
            );
        for (final piece in list.split(_listSplit)) {
          // "내화물사업부문은 ㈜포스코"처럼 주제어가 앞에 붙으면 이름만 남긴다.
          final name = undouble(
            piece
                .trim()
                .replaceFirst(_describer, '')
                .replaceFirst(RegExp(r'^.*?[은는]\s+'), ''),
          );
          if (name.length < 2 || name.length > 30) continue;
          if (_bad.hasMatch(name)) continue;
          // 이름이 아니라 설명인 조각은 버린다 ("그 종속회사", "자동차 OEM 업체로서",
          // "반도체 제조"·"LED용 칩" 같은 품목).
          if (RegExp(
            r'업체|고객사|기업|회사로서|등지|종속회사|관계사|계열사|^그\s|소속|^\d|제조$|\S+용\s|잉곳|칩$|시장$|부문$',
          ).hasMatch(name)) {
            continue;
          }
          if (!seen.add(name)) continue;
          out.add((name: name, evidence: sentence));
          if (out.length >= maxNames) return out;
        }
      }
    }
    return out;
  }

  /// 표의 칸이 겹쳐 붙은 이름("SK지오센트릭SK지오센트릭")은 한 번만.
  static String undouble(String name) {
    if (name.length >= 4 && name.length.isEven) {
      final half = name.length ~/ 2;
      if (name.substring(0, half) == name.substring(half)) {
        return name.substring(0, half);
      }
    }
    return name;
  }

  /// 매출처 표의 머리글 칸. 매입처 표와 헷갈리지 않게 "매입"이 든 줄은 받지 않는다.
  /// "매출처"·"주요 매출처"·"주요매출처" 칸만 (거래처·고객은 판매경로·결제조건 표에도 쓰여 못 미덥다).
  static final _customerHeader = RegExp(r'^(주요\s*)?매출처(\s*명)?$');
  static final _shareHeader = RegExp(r'비중|비율|점유율');
  static final _amountHeader = RegExp(r'매출액|매출금액|금액|매출');
  static final _numeric = RegExp(r'^[\d,]+(?:\.\d+)?%?$');

  /// 이름이 아니라 구분·경로인 칸 — 이런 줄은 매출처가 아니다.
  static final _category = RegExp(
    r'^(국내|해외|내수|수출|유통|직영|직판|대리점|특약점|대리점\s*및\s*특약점|온라인|오프라인|홈쇼핑|B2B|B2C|기타|소계|합계|계|총계|제품|상품|용역|합\s*계|소\s*계|총\s*계)$',
  );

  /// 이름이 아닌 것들: "기타거래처"·"제조회사"·"조선 산업"·"폴란드 등완제기 수출국"·
  /// "조합관리보수", 그리고 표가 뒤집혀 있을 때 이름 칸에 오는 "매출비중".
  static final _generic = RegExp(
    r'거래처$|(^|\s)(회사|산업|업체|고객|고객사|수출국)$|보수$|수수료$|^(제조|판매|유통|협력)\s*회사$|비중|비율',
  );

  /// 이름을 쉼표로 나누되 ", Ltd."·", Inc" 같은 법인 접미사 앞의 쉼표는 나누지 않는다
  /// ("SK Energy International Pte., Ltd."가 "Ltd."로 쪼개지지 않게).
  static final _nameSplit = RegExp(
    r'[,،](?!\s*(?:Ltd|LTD|Inc|INC|Co|CO|Corp|CORP|LLC|Limited|LIMITED|S\.A|GmbH|PLC|plc)\b)|/|\s및\s',
  );

  /// "주요 매출처 | 매출액 | 비중" 표의 (매출처 이름, 비중 %, 그 줄).
  ///
  /// 머리글에서 매출처 칸과 비중 칸을 집는다. 비중 칸이 없으면 이름만 받는다.
  /// 오른쪽 끝 기준으로 칸을 다시 찾으므로 이름 칸이 합쳐져 있어도 비중은 맞게 읽힌다.
  static List<({String name, double? share, String evidence})> customerRows(
    String text,
  ) {
    final out = <({String name, double? share, String evidence})>[];
    final seen = <String>{};
    var nameAt = -1, shareAt = -1, columns = -1;
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('※')) continue;
      final cells = [for (final c in line.split('|')) c.trim()];
      if (cells.length < 2) {
        if (!line.contains('|')) nameAt = -1;
        continue;
      }
      // 매입처 표가 바로 이어지면 앞 매출처 표의 칸 자리를 잊는다.
      if (_header.hasMatch(line)) {
        nameAt = -1;
        continue;
      }
      final h = cells.indexWhere(_customerHeader.hasMatch);
      // 머리글: 매출처 칸과 금액·비중 칸이 같이 있고 숫자 칸은 없다.
      if (h >= 0 &&
          !cells.any(_numeric.hasMatch) &&
          cells.any(
            (c) => _shareHeader.hasMatch(c) || _amountHeader.hasMatch(c),
          )) {
        nameAt = h;
        shareAt = cells.indexWhere(_shareHeader.hasMatch);
        columns = cells.length;
        continue;
      }
      if (nameAt < 0) continue;
      // 둘째 머리글 줄("2025년 | 2024년", "금액 | 비중")은 값이 아니다.
      if (cells.every(
        (c) =>
            c.isEmpty ||
            _headerWord.hasMatch(c) ||
            _shareHeader.hasMatch(c) ||
            RegExp(r'^(제\s*\d+\s*기|\d{4}년?)').hasMatch(c),
      )) {
        continue;
      }
      // 값 줄에는 숫자 칸(금액이나 비중)이 있다. 없으면 표가 끝난 것이다.
      if (!cells.any(_numeric.hasMatch)) {
        nameAt = -1;
        continue;
      }
      if (nameAt >= cells.length) continue;
      final cell = cells[nameAt];
      if (cell.isEmpty || _category.hasMatch(cell)) continue;
      double? share;
      if (shareAt >= 0) {
        // 비고 칸이 비어 있으면 줄이 머리글보다 짧다. 머리글 자리와 오른쪽 끝 기준 자리 가운데
        // 비중처럼 보이는 값(%가 붙었거나 100 이하)을 고른다.
        for (final idx in {shareAt, cells.length - (columns - shareAt)}) {
          if (idx < 0 || idx >= cells.length) continue;
          final raw = cells[idx];
          final v = double.tryParse(raw.replaceAll(RegExp(r'[%,\s]'), ''));
          if (v == null) continue;
          if (raw.contains('%') || v <= 100) {
            share = v;
            break;
          }
        }
      }
      final pieces = [
        for (final p in cell.split(_nameSplit))
          if (p.trim().isNotEmpty) p.trim(),
      ];
      for (final piece in pieces) {
        var name = undouble(piece);
        for (var i = 0; i < 3; i++) {
          final next = name.replaceAll(_tail, '').trim();
          if (next == name) break;
          name = next;
        }
        if (name.length < 2 || name.length > 40) continue;
        if (_bad.hasMatch(name) ||
            _danglingParen(name) ||
            _category.hasMatch(name) ||
            _generic.hasMatch(name)) {
          continue;
        }
        if (!seen.add(name)) continue;
        // 한 칸에 여럿이면 비중은 그 묶음의 것이라 이름마다 붙이지 않는다.
        out.add((
          name: name,
          share: pieces.length > 1 ? null : share,
          evidence: line,
        ));
        if (out.length >= maxNames) return out;
      }
    }
    return out;
  }

  /// (매입처 이름, 그 줄) 목록. 줄은 근거로 그대로 남긴다.
  static List<({String name, String evidence})> parse(String text) {
    final out = <({String name, String evidence})>[];
    final seen = <String>{};
    var column = -1;
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('※')) continue;
      final cells = [for (final c in line.split('|')) c.trim()];
      if (cells.length < 3) {
        // 표가 끝나면 열 위치를 잊는다 (다음 표는 모양이 다르다).
        if (!line.contains('|')) column = -1;
        continue;
      }
      final headerAt = cells.indexWhere(_header.hasMatch);
      if (headerAt >= 0) {
        column = headerAt;
        continue;
      }
      if (column < 0 || column >= cells.length) continue;
      // 칸이 모두 머리글 낱말이면 (당기·전기 머리글의 둘째 줄) 건너뛴다.
      if (cells.every((c) => c.isEmpty || _headerWord.hasMatch(c))) continue;
      final cell = cells[column];
      if (cell.isEmpty) continue;
      for (final piece in cell.split(_nameSplit)) {
        // "동국제강(주) 인천공장 外"처럼 군더더기가 겹치면 없어질 때까지 뗀다.
        var name = undouble(piece.trim());
        for (var i = 0; i < 3; i++) {
          final next = name.replaceAll(_tail, '').trim();
          if (next == name) break;
          name = next;
        }
        if (name.length < 2 || name.length > 30) continue;
        if (_bad.hasMatch(name) ||
            _danglingParen(name) ||
            _category.hasMatch(name) ||
            name.contains('→')) {
          continue;
        }
        if (!seen.add(name)) continue;
        out.add((name: name, evidence: line));
        if (out.length >= maxNames) return out;
      }
    }
    return out;
  }
}
