/// DART 원천 값을 온톨로지 스키마 형식으로 맞추는 변환.
///
/// 스키마가 형식을 정하고, 원천 데이터는 여기서 그 형식에 맞춘다.
/// 형식에 맞지 않는 값은 추측하지 않고 null로 둔다.
abstract final class DartValues {
  /// 앞뒤 공백을 지우고, 비어 있거나 DART의 빈 값 표기(`-`)면 null.
  static String? text(Object? value) {
    if (value is! String) return null;
    final v = value.trim();
    return (v.isEmpty || v == '-') ? null : v;
  }

  /// `YYYYMMDD` → UTC 자정. 실제로 존재하지 않는 날짜(`00000000`, `20230231` 등)는 null.
  static DateTime? ymd(Object? value) {
    final v = text(value);
    if (v == null || !RegExp(r'^\d{8}$').hasMatch(v)) return null;
    final y = int.parse(v.substring(0, 4));
    final m = int.parse(v.substring(4, 6));
    final d = int.parse(v.substring(6, 8));
    if (y < 1800) return null;
    final date = DateTime.utc(y, m, d);
    // DateTime은 13월·31일 초과를 다음 달로 넘기므로 되돌려 확인한다.
    if (date.year != y || date.month != m || date.day != d) return null;
    return date;
  }

  /// UTC 자정 날짜 → `YYYYMMDD`.
  static String formatYmd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  /// 결산월 `12` → 12. 1~12가 아니면 null.
  static int? month(Object? value) {
    final m = int.tryParse(text(value) ?? '');
    return (m != null && m >= 1 && m <= 12) ? m : null;
  }

  /// 원 단위 금액 `"-1,234"` → BigInt. 정수가 아니거나 비어 있으면 null.
  static BigInt? amount(Object? value) {
    final v = text(value)?.replaceAll(',', '');
    if (v == null || !RegExp(r'^-?\d+$').hasMatch(v)) return null;
    return BigInt.parse(v);
  }

  /// 원천 값이 있는데 [amount]로 바꿀 수 없는지. 정규화에서 버려진 값을 세는 데 쓴다.
  static bool isInvalidAmount(Object? value) =>
      text(value) != null && amount(value) == null;
}
