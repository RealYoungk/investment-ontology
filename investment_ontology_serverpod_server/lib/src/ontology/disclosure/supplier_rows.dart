/// 사업보고서 본문의 "주요 원재료" 표에서 매입처를 규칙으로 읽는다 (AI 없음).
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
    r'(\s*(등|외|外|기타)\s*$)|(\s*(인천|구미|아산|창원|울산|여수|천안)?\s*(공장|사업장|본사|외주)\s*$)',
  );

  static final _bad = RegExp(r'[0-9%]|^[-—·]+$|해당\s*없음|미기재|자체');

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
      final cell = cells[column];
      if (cell.isEmpty) continue;
      for (final piece in cell.split(RegExp(r'[,،/]|\s및\s'))) {
        // "동국제강(주) 인천공장 外"처럼 군더더기가 겹치면 없어질 때까지 뗀다.
        var name = piece.trim();
        for (var i = 0; i < 3; i++) {
          final next = name.replaceAll(_tail, '').trim();
          if (next == name) break;
          name = next;
        }
        if (name.length < 2 || name.length > 30) continue;
        if (_bad.hasMatch(name)) continue;
        if (!seen.add(name)) continue;
        out.add((name: name, evidence: line));
        if (out.length >= maxNames) return out;
      }
    }
    return out;
  }
}
