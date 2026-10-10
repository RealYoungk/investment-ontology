import '../presentation/company_presentation.dart';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../billing/membership_ledger.dart';
import 'web_push_sender.dart';

abstract final class WatchlistService {
  static UuidValue owner(Session session) => MembershipLedger.owner(session);

  static Future<int> limitFor(
    Session session,
    UuidValue id, {
    Transaction? transaction,
  }) async {
    final now = DateTime.now().toUtc();
    final sub = await BillingSubscription.db.findFirstRow(
      session,
      where: (t) => t.ownerId.equals(id) & t.deleted.equals(false),
      transaction: transaction,
    );
    if (sub == null) return 3;
    final paid = await BillingPaymentAttempt.db.findFirstRow(
      session,
      where: (t) =>
          t.subscriptionId.equals(sub.id!) &
          t.status.equals('paid') &
          (t.paidFromUtc <= now) &
          (t.paidThroughUtc > now),
      transaction: transaction,
    );
    return paid == null ? 3 : 20;
  }

  static Future<List<WatchlistEntry>> activeEntries(Session session) async {
    final all = await WatchlistEntry.db.find(
      session,
      orderByList: (t) => [t.position, t.createdAt, t.id],
    );
    final active = <WatchlistEntry>[];
    for (final id in all.map((e) => e.ownerId).toSet()) {
      final user = await AuthUser.db.findById(session, id);
      if (user == null || user.blocked) continue;
      final limit = await limitFor(session, id);
      active.addAll(all.where((e) => e.ownerId == id).take(limit));
    }
    return active;
  }

  static Future<void> add(Session session, String corpCode) async {
    final id = owner(session);
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode) ||
        await Company.db.findFirstRow(
              session,
              where: (t) => t.corpCode.equals(corpCode),
            ) ==
            null) {
      throw WatchlistError(code: 'company', message: '기업을 찾을 수 없습니다.');
    }
    await session.db.transaction((tx) async {
      final user = await AuthUser.db.findById(
        session,
        id,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (user == null || user.blocked) {
        throw NotAuthorizedException(
          reason: AuthenticationFailureReason.unauthenticated,
        );
      }
      if (await WatchlistEntry.db.findFirstRow(
            session,
            where: (t) => t.ownerId.equals(id) & t.corpCode.equals(corpCode),
            transaction: tx,
          ) !=
          null) {
        return;
      }
      final limit = await limitFor(session, id, transaction: tx);
      final count = await WatchlistEntry.db.count(
        session,
        where: (t) => t.ownerId.equals(id),
        transaction: tx,
      );
      if (count >= limit) {
        throw WatchlistError(
          code: 'limit',
          message: '관심종목 $limit개를 모두 사용 중입니다. 기존 종목을 해제하거나 멤버십을 확인해 주세요.',
        );
      }
      await WatchlistEntry.db.insertRow(
        session,
        WatchlistEntry(ownerId: id, corpCode: corpCode, position: count),
        transaction: tx,
      );
    });
  }

  static Future<void> remove(Session session, String corpCode) async {
    final id = owner(session);
    await session.db.transaction((tx) async {
      await AuthUser.db.findById(
        session,
        id,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      await WatchlistEntry.db.deleteWhere(
        session,
        where: (t) => t.ownerId.equals(id) & t.corpCode.equals(corpCode),
        transaction: tx,
      );
      // Removal also cancels unread history and queued deliveries for this issuer.
      await WatchlistNotice.db.deleteWhere(
        session,
        where: (t) => t.ownerId.equals(id) & t.corpCode.equals(corpCode),
        transaction: tx,
      );
    });
  }

  static Future<WatchlistView> view(Session session) async {
    final id = owner(session);
    final limit = await limitFor(session, id);
    final entries = await WatchlistEntry.db.find(
      session,
      where: (t) => t.ownerId.equals(id),
      orderByList: (t) => [t.position, t.createdAt, t.id],
    );
    final companies = await Company.db.find(
      session,
      where: (t) => t.corpCode.inSet(entries.map((e) => e.corpCode).toSet()),
    );
    final names = {for (final c in companies) c.corpCode: c};
    final notices = await WatchlistNotice.db.find(
      session,
      where: (t) => t.ownerId.equals(id),
      orderBy: (t) => t.createdAt.desc(),
      limit: 100,
    );
    final events = await CompanyUpdateEvent.db.find(
      session,
      where: (t) => t.id.inSet(notices.map((n) => n.eventId).toSet()),
    );
    final byId = {for (final event in events) event.id: event};
    final state = await WatchlistScanState.db.findFirstRow(
      session,
      where: (t) => t.key.equals('dart'),
    );
    final key = WebPushSender.publicKey(session);
    return WatchlistView(
      companies: [
        for (var i = 0; i < entries.length; i++)
          WatchlistCompanyView(
            corpCode: entries[i].corpCode,
            name:
                names[entries[i].corpCode]?.displayName ?? entries[i].corpCode,
            stockCode: names[entries[i].corpCode]?.stockCode,
            muted: entries[i].muted,
            monitoringReady: i < limit && entries[i].baselineAt != null,
            active: i < limit,
            unreadCount: await WatchlistNotice.db.count(
              session,
              where: (t) =>
                  t.ownerId.equals(id) &
                  t.corpCode.equals(entries[i].corpCode) &
                  t.readAt.equals(null),
            ),
          ),
      ],
      updates: [
        for (final n in notices)
          if (byId[n.eventId] case final e?)
            WatchlistUpdateView(
              noticeId: n.id!,
              corpCode: n.corpCode,
              companyName: names[n.corpCode]?.displayName ?? n.corpCode,
              title: e.title,
              url: e.url,
              publishedAt: e.publishedAt,
              discoveredAt: e.discoveredAt,
              read: n.readAt != null,
            ),
      ],
      limit: limit,
      paid: limit == 20,
      scanStatus: state?.status ?? 'waiting',
      workerEnabled: session.serverpod.config.futureCallExecutionEnabled,
      lastCheckedAt: state?.lastSuccessAt,
      pushConfigured: key != null,
      vapidPublicKey: key,
    );
  }

  static Future<void> deleteOwner(
    Session session,
    UuidValue id,
    Transaction tx,
  ) async {
    await WebPushSubscription.db.deleteWhere(
      session,
      where: (t) => t.ownerId.equals(id),
      transaction: tx,
    );
    await WatchlistNotice.db.deleteWhere(
      session,
      where: (t) => t.ownerId.equals(id),
      transaction: tx,
    );
    await WatchlistEntry.db.deleteWhere(
      session,
      where: (t) => t.ownerId.equals(id),
      transaction: tx,
    );
  }
}
