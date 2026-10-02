import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'billing_provider_config.dart';
import 'billing_renewal_service.dart';

class BillingFutureCall extends FutureCall {
  Future<void> run(Session session) => scan(session);
  Future<void> scan(Session session) async {
    final client = http.Client();
    try {
      Future<BillingRenewalService?> serviceFor(
        int id, {
        String? provider,
      }) async {
        final sub = await BillingSubscription.db.findById(session, id);
        return sub == null
            ? null
            : BillingSandboxConfig.service(
                session,
                client,
                provider: provider ?? sub.provider,
              );
      }

      final cleanup = await BillingSubscription.db.find(
        session,
        where: (t) => t.encryptedKeyPendingDeletion.notEquals(null),
      );
      for (final row in cleanup) {
        try {
          await (await serviceFor(row.id!))
              ?.reconcileKeyDeletion(session, row.id!);
        } catch (_) {
          session.log('Billing key cleanup pending', level: LogLevel.warning);
        }
      }
      // Refunds are reconciled even after deletion removed the billing key.
      final refunds = await BillingPaymentAttempt.db.find(
        session,
        where: (t) =>
            t.status.inSet({'refundRequired', 'refundRequested', 'unknown'}),
      );
      for (final item
          in refunds
              .map((r) => (id: r.subscriptionId, provider: r.provider))
              .toSet()) {
        try {
          await (await serviceFor(
            item.id,
            provider: item.provider,
          ))?.reconcileUnknowns(session, item.id);
        } catch (_) {
          session.log(
            'Billing reconciliation pending',
            level: LogLevel.warning,
          );
        }
      }
      // Includes subscriptions canceled at period end: their paid access can
      // still be refunded directly by the provider while renewal is disabled.
      final now = DateTime.now().toUtc();
      final paid = await BillingPaymentAttempt.db.find(
        session,
        where: (t) =>
            t.status.equals('paid') &
            (t.paidFromUtc <= now) &
            (t.paidThroughUtc > now),
      );
      for (final item
          in paid
              .map((r) => (id: r.subscriptionId, provider: r.provider))
              .toSet()) {
        try {
          await (await serviceFor(
            item.id,
            provider: item.provider,
          ))?.reconcilePaid(session, item.id, at: now);
        } catch (_) {
          session.log(
            'Paid billing reconciliation pending',
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
            await (await serviceFor(row.id!))?.run(session, row.id!);
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
