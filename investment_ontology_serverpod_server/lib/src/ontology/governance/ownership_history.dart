import '../../generated/protocol.dart';

/// Five consecutive fiscal year ends, with missing slots and latest interim.
List<DartFiling> selectOwnershipFilings(
  List<DartFiling> input,
  String corpCode,
) {
  final filings = input
      .where((f) => f.bsnsYear != null && f.reportCode != null)
      .toList();
  int rank(FinancialReportCode code) => switch (code) {
    FinancialReportCode.q1 => 1,
    FinancialReportCode.halfYear => 2,
    FinancialReportCode.q3 => 3,
    FinancialReportCode.annual => 4,
  };
  filings.sort((a, b) {
    final year = b.bsnsYear!.compareTo(a.bsnsYear!);
    if (year != 0) return year;
    final period = rank(b.reportCode!).compareTo(rank(a.reportCode!));
    return period != 0 ? period : b.rceptNo.compareTo(a.rceptNo);
  });
  final annualYear =
      filings
          .where((f) => f.reportCode == FinancialReportCode.annual)
          .firstOrNull
          ?.bsnsYear ??
      (filings.isEmpty ? 0 : filings.first.bsnsYear! - 1);
  if (filings.isEmpty) return [];
  final selected = <DartFiling>[];
  for (var y = annualYear - 4; y <= annualYear; y++) {
    final filing = filings
        .where(
          (f) => f.bsnsYear == y && f.reportCode == FinancialReportCode.annual,
        )
        .firstOrNull;
    // Missing annual periods remain explicit empty slots.
    selected.add(
      filing ??
          DartFiling(
            rceptNo: '',
            corpCode: corpCode,
            bsnsYear: y,
            reportCode: FinancialReportCode.annual,
            reportName: '$y 사업보고서',
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            attempts: 0,
            discoveredAt: DateTime.now().toUtc(),
          ),
    );
  }
  final interim = filings
      .where(
        (f) =>
            f.bsnsYear! > annualYear &&
            f.reportCode != FinancialReportCode.annual,
      )
      .firstOrNull;
  if (interim != null) selected.add(interim);
  return selected;
}
