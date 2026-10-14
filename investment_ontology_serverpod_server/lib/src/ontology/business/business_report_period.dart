import '../../generated/protocol.dart';

/// Fiscal reporting codes stay fiscal even when their calendar year differs.
String businessReportPeriod(DisclosureReport report, int fiscalYear) {
  final kind = switch (report.reportCode) {
    FinancialReportCode.annual => '연간',
    FinancialReportCode.halfYear => '반기',
    FinancialReportCode.q1 => '1분기',
    FinancialReportCode.q3 => '3분기 누적',
  };
  final date = report.settlementDate;
  return date != null && date.year != fiscalYear
      ? '${date.year}.${date.month.toString().padLeft(2, '0')} 보고서 · 회계연도 $fiscalYear $kind'
      : '$fiscalYear $kind';
}
