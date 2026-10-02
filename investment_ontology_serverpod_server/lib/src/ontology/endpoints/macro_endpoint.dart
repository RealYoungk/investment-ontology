import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/macro_data.dart';

/// Public official market context, no mutations or account data.
class MacroEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<MacroSeriesView>> overview(Session session) =>
      MacroData.shared.overview();
}
