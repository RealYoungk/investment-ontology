import 'package:serverpod/serverpod.dart';

import 'package:serverpod/protocol.dart' as sp;

import '../../generated/future_calls.dart';
import 'billing_provider_config.dart';

/// Only lib/server.dart imports this generated-dispatcher-dependent file.
abstract final class BillingSchedule {
  static const identifier = 'alfinder-billing-renewal';
  static Future<void> ensure(Session session) async {
    final pod = session.serverpod;
    if (!BillingSandboxConfig.enabled(session)) {
      await pod.futureCalls.cancel(identifier);
      return;
    }
    final exists = await sp.FutureCallEntry.db.findFirstRow(
      session,
      where: (t) => t.identifier.equals(identifier),
    );
    if (exists == null) {
      await pod.futureCalls
          .callRecurring(identifier: identifier)
          .every(const Duration(minutes: 5))
          .billing
          .run();
    }
  }
}
