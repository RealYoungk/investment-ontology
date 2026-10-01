import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../peers/industry_discovery_catalog.dart';
import '../peers/all_industry_catalog.dart';

class IndustryEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// All listed companies with explicitly separated classification evidence.
  Future<IndustryDiscovery> browse(Session session) =>
      AllIndustryCatalog.read(session);

  /// Evidence-backed semiconductor pilot. Shared company information is public.
  Future<IndustryDiscovery> discover(Session session) =>
      IndustryDiscoveryCatalog.read(session);
}
