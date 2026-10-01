import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import '../ingest/api_call_budget.dart';
import 'watchlist_service.dart';
import 'web_push_sender.dart';

class WatchlistFutureCall extends FutureCall {
  Future<void> run(Session session) => scan(session);

  Future<void> scan(Session session) async {
    final entries = await WatchlistService.activeEntries(session);
    if (entries.isEmpty) return;
    await session.db.unsafeExecute(
      'INSERT INTO watchlist_scan_state ("key", "status", "nextPage") VALUES (\'dart\', \'waiting\', 1) ON CONFLICT ("key") DO NOTHING',
    );
    final now = DateTime.now().toUtc();
    final state = await session.db.transaction((tx) async {
      final row = await WatchlistScanState.db.findFirstRow(
        session,
        where: (t) => t.key.equals('dart'),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (row!.leaseUntil?.isAfter(now) ?? false) return null;
      row.leaseUntil = now.add(const Duration(minutes: 30));
      row.status = 'running';
      return WatchlistScanState.db.updateRow(session, row, transaction: tx);
    });
    if (state == null) return;
    final key = DartApiKey.read(session);
    final dart = key == null ? null : DartClient(key);
    var status = 'ok';
    try {
      if (dart == null) {
        status = 'notConfigured';
        return;
      }
      final kst = now.add(const Duration(hours: 9));
      final today = DateTime.utc(kst.year, kst.month, kst.day);
      final day = state.scanDay ?? today;
      state.scanDay = day;
      // Persist each completed page. Interruptions never lose the cursor and
      // retries use receipt identity. A later pass rechecks today's early pages.
      for (var batch = 0; batch < 30; batch++) {
        if (await ApiCallBudget.reached(
          session,
          ApiProvider.dart,
          ApiCallBudget.dartDailyLimit - 100,
        )) {
          status = 'budgetWaiting';
          return;
        }
        await ApiCallBudget.record(session, ApiProvider.dart, 1);
        final page = await dart.fetchFilings(
          from: day,
          to: day,
          page: state.nextPage,
          typeCode: null,
          lastReportOnly: false,
        );
        await WatchlistEventStore.store(
          session,
          entries,
          page.items,
          now,
          initialize: false,
        );
        if (state.nextPage >= page.totalPages) {
          if (!day.isBefore(today)) {
            await WatchlistEventStore.store(session, entries, [], now);
            state.lastSuccessAt = now;
            status = 'ok';
          }
          state.scanDay = day.isBefore(today)
              ? day.add(const Duration(days: 1))
              : today;
          state.nextPage = 1;
          break;
        }
        state.nextPage++;
        await WatchlistScanState.db.updateRow(session, state);
        status = 'catchingUp';
      }
    } catch (_) {
      status = 'failed';
      session.log(
        'Watchlist disclosure scan failed; completed-page cursor retained',
        level: LogLevel.warning,
      );
    } finally {
      dart?.close();
      state.status = status;
      state.leaseUntil = null;
      await WatchlistScanState.db.updateRow(session, state);
    }
  }

  Future<void> deliver(Session session) async {
    if (WebPushSender.publicKey(session) == null) return;
    final now = DateTime.now().toUtc();
    // Recover a worker interrupted before it recorded the provider response.
    await WebPushDelivery.db.updateWhere(
      session,
      columnValues: (t) => [t.status('pending')],
      where: (t) => t.status.equals('sending') & (t.nextAttemptAt <= now),
    );
    for (var batch = 0; batch < 30; batch++) {
      final delivery = await session.db.transaction((tx) async {
        final row = await WebPushDelivery.db.findFirstRow(
          session,
          where: (t) => t.status.equals('pending') & (t.nextAttemptAt <= now),
          transaction: tx,
          lockMode: LockMode.forUpdate,
          lockBehavior: LockBehavior.skipLocked,
          orderBy: (t) => t.nextAttemptAt,
        );
        if (row == null) return null;
        row.status = 'sending';
        row.attempts++;
        row.nextAttemptAt = now.add(const Duration(minutes: 5));
        return WebPushDelivery.db.updateRow(session, row, transaction: tx);
      });
      if (delivery == null) break;
      final notice = await WatchlistNotice.db.findById(
        session,
        delivery.noticeId,
      );
      final sub = await WebPushSubscription.db.findById(
        session,
        delivery.subscriptionId,
      );
      if (notice == null || sub == null) continue;
      final active = await WatchlistService.activeEntries(session);
      final entry = active
          .where(
            (e) => e.ownerId == notice.ownerId && e.corpCode == notice.corpCode,
          )
          .firstOrNull;
      if (entry == null ||
          entry.muted ||
          notice.readAt != null ||
          notice.createdAt.isBefore(now.subtract(const Duration(days: 1)))) {
        delivery.status = 'cancelled';
      } else {
        try {
          final event = await CompanyUpdateEvent.db.findById(
            session,
            notice.eventId,
          );
          final response = await WebPushSender.send(session, sub, {
            'title': '관심종목 새 공시',
            'body': event!.title,
            'path': '/watchlist',
            'tag': 'filing-${event.receipt}',
          });
          if (response >= 200 && response < 300) {
            delivery.status = 'accepted';
          } else if (response == 404 || response == 410) {
            await WebPushSubscription.db.deleteRow(session, sub);
            continue;
          } else if (response >= 400 && response < 500 && response != 429) {
            delivery.status = 'failed';
          } else {
            delivery.status = 'pending';
          }
        } catch (_) {
          delivery.status = 'pending';
        }
        if (delivery.status == 'pending' && delivery.attempts >= 5) {
          delivery.status = 'failed';
        }
        delivery.nextAttemptAt = now.add(
          Duration(minutes: 1 << delivery.attempts),
        );
      }
      // Account deletion or unsubscribe may have cascaded the queue meanwhile.
      if (await WebPushDelivery.db.findById(session, delivery.id!) != null) {
        await WebPushDelivery.db.updateRow(session, delivery);
      }
    }
  }
}

abstract final class WatchlistEventStore {
  static Future<void> store(
    Session session,
    List<WatchlistEntry> entries,
    List<DartFilingItem> filings,
    DateTime now, {
    bool initialize = true,
  }) async {
    final codes = entries.map((e) => e.corpCode).toSet();
    await session.db.transaction((tx) async {
      // Covers the unique-receipt insert as well as notice/queue creation.
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(710010)',
        transaction: tx,
      );
      for (final filing in filings) {
        if (!codes.contains(filing.corpCode) ||
            filing.rceptDate == null ||
            !RegExp(r'^\d{14}$').hasMatch(filing.rceptNo)) {
          continue;
        }
        var event = await CompanyUpdateEvent.db.findFirstRow(
          session,
          where: (t) => t.receipt.equals(filing.rceptNo),
          transaction: tx,
        );
        event ??= await CompanyUpdateEvent.db.insertRow(
          session,
          CompanyUpdateEvent(
            corpCode: filing.corpCode,
            receipt: filing.rceptNo,
            title: filing.reportName,
            url:
                'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${filing.rceptNo}',
            publishedAt: filing.rceptDate!.subtract(const Duration(hours: 9)),
            discoveredAt: now,
          ),
          transaction: tx,
        );
        for (final entry in entries.where(
          (e) => e.corpCode == filing.corpCode && e.baselineAt != null,
        )) {
          final current = await WatchlistEntry.db.findById(
            session,
            entry.id!,
            transaction: tx,
          );
          if (current == null ||
              current.baselineAt == null ||
              !event.discoveredAt.isAfter(current.baselineAt!)) {
            continue;
          }
          final baseKst = current.baselineAt!.add(const Duration(hours: 9));
          if (filing.rceptDate!.isBefore(
            DateTime.utc(baseKst.year, baseKst.month, baseKst.day),
          )) {
            continue;
          }
          if (await WatchlistNotice.db.findFirstRow(
                session,
                where: (t) =>
                    t.ownerId.equals(entry.ownerId) &
                    t.eventId.equals(event!.id!),
                transaction: tx,
              ) !=
              null) {
            continue;
          }
          final notice = await WatchlistNotice.db.insertRow(
            session,
            WatchlistNotice(
              ownerId: entry.ownerId,
              eventId: event.id!,
              corpCode: entry.corpCode,
              createdAt: now,
            ),
            transaction: tx,
          );
          if (current.muted) continue;
          final subscriptions = await WebPushSubscription.db.find(
            session,
            where: (t) => t.ownerId.equals(entry.ownerId),
            transaction: tx,
          );
          for (final sub in subscriptions) {
            await WebPushDelivery.db.insertRow(
              session,
              WebPushDelivery(noticeId: notice.id!, subscriptionId: sub.id!),
              transaction: tx,
            );
          }
        }
      }
      if (initialize) {
        for (final entry in entries.where((e) => e.baselineAt == null)) {
          final current = await WatchlistEntry.db.findById(
            session,
            entry.id!,
            transaction: tx,
          );
          if (current != null && current.baselineAt == null) {
            await WatchlistEntry.db.updateRow(
              session,
              current.copyWith(baselineAt: now),
              transaction: tx,
            );
          }
        }
      }
    });
  }
}
