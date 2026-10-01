/// 정기보고서 종류.
enum DartReportKind { annual, halfYear, quarter }

/// 공시 목록(`list.json`)의 정기보고서 이름. 예: `[기재정정]사업보고서 (2025.12)`.
class DartReportName {
  DartReportName({
    required this.kind,
    required this.periodYear,
    required this.periodMonth,
    required this.tags,
  });

  static final _pattern = RegExp(
    r'^((?:\[[^\]]+\]\s*)*)(사업보고서|반기보고서|분기보고서)\s*\((\d{4})\.(\d{2})\)$',
  );

  /// 정기보고서가 아니거나 형식이 다르면 null.
  static DartReportName? parse(String reportName) {
    final m = _pattern.firstMatch(reportName.trim());
    if (m == null) return null;
    final month = int.parse(m.group(4)!);
    if (month < 1 || month > 12) return null;
    return DartReportName(
      kind: switch (m.group(2)!) {
        '사업보고서' => DartReportKind.annual,
        '반기보고서' => DartReportKind.halfYear,
        _ => DartReportKind.quarter,
      },
      periodYear: int.parse(m.group(3)!),
      periodMonth: month,
      tags: [
        for (final t in RegExp(r'\[([^\]]+)\]').allMatches(m.group(1)!))
          t.group(1)!,
      ],
    );
  }

  final DartReportKind kind;

  /// 보고 기간 말의 연·월 (이름의 괄호 안).
  final int periodYear;
  final int periodMonth;

  /// `기재정정`, `첨부추가` 등 앞에 붙은 표시.
  final List<String> tags;

  /// 내부 공시 원장의 보고서 코드와 결산 종료 기준 회계연도.
  /// 재무 API 조회 연도는 이 bsnsYear가 아니라 실제 보고기간 말의 [periodYear]다.
  ///
  /// 사업연도는 그 회계연도가 끝나는 해다(결산월 4월인 회사의 `사업보고서 (2026.04)` →
  /// 2026). 기간 말 월이 결산월 기준으로 3·6·9·12개월째가 아니거나 보고서 종류와
  /// 맞지 않으면 추측하지 않고 null. [fiscalMonth]가 없으면 사업보고서만 판정한다.
  ({String reportCode, int bsnsYear})? resolve(int? fiscalMonth) {
    // Each business report declares its own period end. Master fiscal month
    // can change over time and REITs may publish multiple annual periods/year.
    if (kind == DartReportKind.annual) {
      return (reportCode: '11011', bsnsYear: periodYear);
    }
    final fm = fiscalMonth;
    if (fm == null) return null;
    // 회계연도 시작부터 기간 말까지의 개월 수 (1~12).
    final elapsed = (periodMonth - fm + 11) % 12 + 1;
    final code = switch ((kind, elapsed)) {
      (DartReportKind.annual, 12) => '11011',
      (DartReportKind.halfYear, 6) => '11012',
      (DartReportKind.quarter, 3) => '11013',
      (DartReportKind.quarter, 9) => '11014',
      _ => null,
    };
    if (code == null) return null;
    return (
      reportCode: code,
      bsnsYear: periodMonth <= fm ? periodYear : periodYear + 1,
    );
  }
}
