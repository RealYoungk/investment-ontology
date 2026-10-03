import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/macro_sources.dart';

/// Public official market context, read from direct sources with bounded caching.
class MacroEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<MacroSeriesView>> overview(Session session) =>
      MacroData.forSession(session).overview();
}
