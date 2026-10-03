import '../../generated/protocol.dart';
import '../dart/dart_report_name.dart';
import 'capital_structure_store.dart';

abstract final class BondCollectionScope {
  /// Latest five annual fiscal years, plus only the latest newer interim.
  /// Existing history is retained; final corrections supersede by receipt.
  static List<DartFiling> select(List<DartFiling> filings) {
    final finalPeriods = <String, DartFiling>{};
    for (final f in filings) {
      final name = DartReportName.parse(f.reportName);
      final end = CapitalStructureStore.period(f);
      if (name == null || end == null || f.reportCode == null) continue;
      final key =
          '${name.kind == DartReportKind.annual ? 'annual' : 'interim'}|$end';
      final old = finalPeriods[key];
      if (old == null || f.rceptNo.compareTo(old.rceptNo) > 0) {
        finalPeriods[key] = f;
      }
    }
    final annuals =
        finalPeriods.values
            .where(
              (f) =>
                  DartReportName.parse(f.reportName)!.kind ==
                  DartReportKind.annual,
            )
            .toList()
          ..sort(
            (a, b) =>
                CapitalStructureStore.period(b)!
                    .compareTo(CapitalStructureStore.period(a)!),
          );
    if (annuals.isEmpty) return [];
    final latestYear = DartReportName.parse(annuals.first.reportName)!
        .periodYear;
    final selected = annuals
        .where(
          (f) =>
              DartReportName.parse(f.reportName)!.periodYear >= latestYear - 4,
        )
        .toList();
    final interim =
        finalPeriods.values
            .where(
              (f) =>
                  DartReportName.parse(f.reportName)!.kind !=
                      DartReportKind.annual &&
                  CapitalStructureStore.period(f)!.compareTo(
                        CapitalStructureStore.period(annuals.first)!,
                      ) >
                      0,
            )
            .toList()
          ..sort(
            (a, b) =>
                CapitalStructureStore.period(b)!
                    .compareTo(CapitalStructureStore.period(a)!),
          );
    if (interim.isNotEmpty) selected.add(interim.first);
    selected.sort(
      (a, b) =>
          CapitalStructureStore.period(a)!
              .compareTo(CapitalStructureStore.period(b)!),
    );
    return selected;
  }
}
