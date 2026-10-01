import '../../generated/protocol.dart';
import 'discovery_offerings.dart';

/// Resolve source precedence before minimum coverage is added. Registration is
/// retained as provenance, but cannot add an obsolete second business sector.
abstract final class DiscoveryResolution {
  static List<IndustryActivity> resolve(List<IndustryActivity> rows) {
    final normalized = rows.map(DiscoveryOfferings.normalize).toList();
    final explicit = normalized
        .where(
          (r) => {
            'filing',
            'kind_product',
            'issuer_source',
          }.contains(r.classificationBasis),
        )
        .map((r) => r.corpCode)
        .toSet();
    final current = normalized
        .where(
          (r) => {'filing', 'issuer_source'}.contains(r.classificationBasis),
        )
        .map((r) => (r.corpCode, r.industryKey))
        .toSet();
    final reviewed = normalized
        .where((r) => r.productKey.startsWith('reviewed-filing:'))
        .map((r) => r.corpCode)
        .toSet();
    final dedup = <(String, String?, String, String), IndustryActivity>{};
    for (final a in normalized) {
      if ({
            'registered_activity',
            'kind_registered',
            'filing_activity',
          }.contains(a.classificationBasis) &&
          explicit.contains(a.corpCode)) {
        continue;
      }
      // A current filing supersedes the exchange's undated historical product
      // descriptor in that sector. Keep other sectors as separate evidence.
      if (a.classificationBasis == 'kind_product' &&
          (current.contains((a.corpCode, a.industryKey)) ||
              reviewed.contains(a.corpCode))) {
        continue;
      }
      final key = (a.corpCode, a.industryKey, a.role, a.productKey);
      final old = dedup[key];
      if (old == null ||
          (a.classificationBasis == 'filing' &&
              old.classificationBasis != 'filing')) {
        dedup[key] = a;
      }
    }
    return dedup.values.toList();
  }
}
