import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../peers/all_industry_catalog.dart';

class IndustryEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// All listed companies with explicitly separated classification evidence.
  Future<IndustryDiscovery> browse(Session session, {String? industry}) async {
    final data = await AllIndustryCatalog.read(session);
    if (industry == null) return data;
    final businessCodes = data.activities
        .where(
          (a) =>
              a.classificationBasis != 'ksic' &&
              a.classificationBasis != 'unclassified',
        )
        .map((a) => a.corpCode)
        .toSet();
    return data.copyWith(
      activities: data.activities
          .where(
            (a) =>
                (a.industryKey ?? 'semiconductor') == industry &&
                (!(a.classificationBasis == 'ksic' ||
                        a.classificationBasis == 'unclassified') ||
                    !businessCodes.contains(a.corpCode)),
          )
          .toList(),
    );
  }

  /// Evidence-backed semiconductor pilot. Shared company information is public.
  Future<IndustryDiscovery> discover(Session session) =>
      AllIndustryCatalog.pilot(session);

  /// Explicit server classification maintenance remains protected even in local development.
  Future<IndustryDiscovery> rebuild(Session session) async {
    OntologyAccess.requireAdmin(session);
    final snapshot = await AllIndustryCatalog.rebuild(session);
    if (snapshot == null) throw StateError('기업 분류 갱신 중입니다.');
    return snapshot.catalog;
  }
}
