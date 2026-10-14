import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'stored_rnd_facts.dart';

abstract final class InterimRndFacts {
  /// Current interim projection uses the source's actual settlement date.
  /// Fiscal-year labels never move a 2026.06 source observation into 2027.
  static Future<List<DocumentFact>> read(
    Session session,
    BusinessDocument doc,
    DisclosureReport report,
  ) async {
    if (report.reportCode == FinancialReportCode.annual) return [];
    final end = StoredRndFacts.currentDate(doc, report);
    final validated = await StoredRndFacts.read(session, doc, report);
    return validated.where((fact) => fact.asOf == end).toList();
  }
}
