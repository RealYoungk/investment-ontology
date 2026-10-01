import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'billing_sandbox_config.dart';

class BillingFutureCall extends FutureCall {
  Future<void> run(Session session) => scan(session);
  Future<void> scan(Session session) async {
    final client = http.Client();
    try {
      final service = BillingSandboxConfig.service(session, client);
      if (service == null) return;
      final cleanup = await BillingSubscription.db.find(
        session,
        where: (t) => t.encryptedKeyPendingDeletion.notEquals(null),
      );
      for (final row in cleanup) {
        try {
          await service.reconcileKeyDeletion(session, row.id!);
        } catch (_) {
          session.log('Billing key cleanup pending', level: LogLevel.warning);
        }
      }
      // Refunds are reconciled even after deletion removed the billing key.
      final refunds = await BillingPaymentAttempt.db.find(
        session,
        where: (t) => t.status.inSet({'refundRequired', 'unknown'}),
      );
      for (final id in refunds.map((r) => r.subscriptionId).toSet()) {
        try {
          await service.reconcileUnknowns(session, id);
        } catch (_) {
          session.log(
            'Billing reconciliation pending',
            level: LogLevel.warning,
          );
        }
      }
      var offset = 0;
      while (true) {
        final rows = await BillingSubscription.db.find(
          session,
          where: (t) =>
              t.deleted.equals(false) &
              t.cancelAtPeriodEnd.equals(false) &
              t.encryptedBillingKey.notEquals(null),
          orderBy: (t) => t.id,
          limit: 100,
          offset: offset,
        );
        for (final row in rows) {
          try {
            await service.run(session, row.id!);
          } catch (_) {
            session.log(
              'Billing worker failed; inspect durable ledger',
              level: LogLevel.warning,
            );
          }
        }
        if (rows.length < 100) return;
        offset += rows.length;
      }
    } finally {
      client.close();
    }
  }
}
