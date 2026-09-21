import '../dart/dart_values.dart';

/// 정기보고서 주요정보 응답 값을 스키마 형식으로 맞춘다.
///
/// 주요정보 API는 같은 뜻의 값을 여러 표기로 준다 (`8.51` / `20.07%`, `10개월` / `10`,
/// `2025.03.31` / `2025년 03월 31일`). 해석할 수 없으면 추측하지 않고 null.
abstract final class DisclosureValues {
  /// 표시용 이름: 줄바꿈·겹공백을 한 칸으로.
  static String displayName(Object? value) =>
      (value is String ? value : '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 사람 이름 비교용: 공백을 모두 뗀다 (`이 재 용` → `이재용`).
  static String personName(Object? value) =>
      (value is String ? value : '').replaceAll(RegExp(r'\s+'), '');

  static final _corporateForm = RegExp(r'\((주|유)\)|㈜|주식회사|유한회사|\(유한\)');
  static final _footnote = RegExp(r'\((주|\*)\s*\d+\)|\*');
  static const _knownTags = ['(특별계정)'];

  /// 기업 이름 비교용: 법인 형태·각주·알려진 꼬리표·공백을 떼고 영문은 소문자로.
  /// 양쪽(주요정보의 이름, 상장사 이름)에 같은 규칙을 쓴다.
  static String companyName(Object? value) {
    var n = value is String ? value : '';
    for (final tag in _knownTags) {
      n = n.replaceAll(tag, '');
    }
    n = n.replaceAll(_corporateForm, '').replaceAll(_footnote, '');
    return n.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  /// 합계·소계 행의 표기 (공백을 뗀 뒤 비교).
  static const _totalLabels = {'계', '합계', '소계', '총계', '누계'};

  static bool isTotalLabel(Object? value) =>
      value is String &&
      _totalLabels.contains(value.replaceAll(RegExp(r'\s+'), ''));

  /// 수량·금액 `"1,234"`, `"-1,234"` → BigInt. 공백은 무시한다.
  static BigInt? integer(Object? value) =>
      DartValues.amount(value is String ? value.replaceAll(' ', '') : value);

  /// 비율·소수 `"8.51"`, `"20.07%"`, `"1,234.5"` → double.
  static double? decimal(Object? value) {
    final v = DartValues.text(
      value,
    )?.replaceAll(',', '').replaceAll('%', '').replaceAll(' ', '');
    if (v == null || !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v)) return null;
    return double.parse(v);
  }

  /// 날짜 `2025.03.31`, `2025-03-31`, `2025년 03월 31일`, `20250331` → UTC 자정.
  static DateTime? date(Object? value) {
    final v = DartValues.text(value);
    if (v == null) return null;
    final m = RegExp(
      r'^(\d{4})\s*[.\-년]\s*(\d{1,2})\s*[.\-월]\s*(\d{1,2})\s*일?\.?$',
    ).firstMatch(v);
    if (m != null) {
      return DartValues.ymd(
        '${m[1]}${m[2]!.padLeft(2, '0')}${m[3]!.padLeft(2, '0')}',
      );
    }
    return DartValues.ymd(v);
  }

  /// 출생년월 `1960년 12월`, `1960.12` → (1960, 12).
  static ({int year, int month})? yearMonth(Object? value) {
    final v = DartValues.text(value);
    if (v == null) return null;
    final m = RegExp(r'^(\d{4})\s*[.\-년]\s*(\d{1,2})\s*월?$').firstMatch(v);
    if (m == null) return null;
    final year = int.parse(m[1]!), month = int.parse(m[2]!);
    if (year < 1900 || month < 1 || month > 12) return null;
    return (year: year, month: month);
  }

  /// 재직기간 `46개월`, `46` → 46.
  static int? months(Object? value) {
    final v = DartValues.text(value)?.replaceAll(' ', '');
    final m = v == null ? null : RegExp(r'^(\d+)(개월)?$').firstMatch(v);
    return m == null ? null : int.parse(m[1]!);
  }

  /// 상근 `상근` → true, `비상근` → false.
  static bool? fullTime(Object? value) => switch (DartValues.text(value)) {
    '상근' => true,
    '비상근' => false,
    _ => null,
  };

  /// 항목 이름 끝 괄호의 단위: `(연결)당기순이익(백만원)` → `백만원`, `현금배당성향(%)` → `%`.
  static String? unitOf(String item) {
    final m = RegExp(r'\(([^()]*)\)\s*$').firstMatch(item);
    final unit = m?[1]?.trim();
    if (unit == null) return null;
    const units = {'원', '백만원', '천원', '억원', '%', '주', '배', '명'};
    return units.contains(unit) ? unit : null;
  }

  /// 행의 값(공통 필드 제외)이 모두 비었거나 `-`인지. 자료가 없을 때 DART가 주는 빈 줄.
  static bool isEmptyRow(Map<String, dynamic> row, Set<String> commonFields) {
    for (final e in row.entries) {
      if (commonFields.contains(e.key)) continue;
      if (DartValues.text(e.value) != null) return false;
    }
    return true;
  }

  /// 합계·소계 행인지: 공통 필드를 뺀 문자 값 가운데 하나가 합계 표기다.
  static bool isTotalRow(Map<String, dynamic> row, Set<String> commonFields) {
    for (final e in row.entries) {
      if (commonFields.contains(e.key)) continue;
      if (isTotalLabel(e.value)) return true;
    }
    return false;
  }
}
