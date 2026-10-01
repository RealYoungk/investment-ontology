import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../watchlist/watchlist_service.dart';
import '../watchlist/web_push_sender.dart';

class WatchlistEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<WatchlistView> mine(Session session) => WatchlistService.view(session);
  Future<void> add(Session session, String corpCode) =>
      WatchlistService.add(session, corpCode);
  Future<void> remove(Session session, String corpCode) =>
      WatchlistService.remove(session, corpCode);

  Future<void> mute(Session session, String corpCode, bool muted) async {
    final id = WatchlistService.owner(session);
    final entry = await WatchlistEntry.db.findFirstRow(
      session,
      where: (t) => t.ownerId.equals(id) & t.corpCode.equals(corpCode),
    );
    if (entry == null) return;
    await WatchlistEntry.db.updateRow(session, entry.copyWith(muted: muted));
  }

  /// Move a saved company into the active tier after membership expiry.
  Future<void> prioritize(Session session, String corpCode) async {
    final id = WatchlistService.owner(session);
    await session.db.transaction((tx) async {
      await AuthUser.db.findById(
        session,
        id,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      final entries = await WatchlistEntry.db.find(
        session,
        where: (t) => t.ownerId.equals(id),
        transaction: tx,
        orderByList: (t) => [t.position, t.createdAt, t.id],
      );
      final target = entries.where((e) => e.corpCode == corpCode).firstOrNull;
      if (target == null) return;
      final limit = await WatchlistService.limitFor(
        session,
        id,
        transaction: tx,
      );
      final wasActive = entries.indexOf(target) < limit;
      final ordered = [target, ...entries.where((e) => e.id != target.id)];
      for (var i = 0; i < ordered.length; i++) {
        final e = ordered[i];
        // Reactivating a suspended company establishes a fresh baseline.
        final fresh = i < limit;
        await WatchlistEntry.db.updateRow(
          session,
          e.copyWith(
            position: i,
            baselineAt: fresh && !wasActive && e.id == target.id
                ? null
                : e.baselineAt,
          ),
          transaction: tx,
        );
      }
    });
  }

  Future<void> markRead(Session session, int noticeId) async {
    final id = WatchlistService.owner(session);
    final notice = await WatchlistNotice.db.findFirstRow(
      session,
      where: (t) => t.ownerId.equals(id) & t.id.equals(noticeId),
    );
    if (notice == null) return;
    await WatchlistNotice.db.updateRow(
      session,
      notice.copyWith(readAt: DateTime.now().toUtc()),
    );
  }

  Future<void> subscribePush(
    Session session,
    String endpoint,
    String p256dh,
    String auth,
  ) async {
    final id = WatchlistService.owner(session);
    if (WebPushSender.publicKey(session) == null) {
      throw WatchlistError(
        code: 'push',
        message: '기기 알림 설정을 준비 중입니다. 앱 알림함은 이용할 수 있습니다.',
      );
    }
    try {
      WebPushSender.validate(endpoint, p256dh, auth);
    } catch (_) {
      throw WatchlistError(code: 'push', message: '지원하지 않는 기기 알림 구독입니다.');
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
      // A subscription cannot be reassigned to another account. Account changes
      // create a fresh browser subscription after unsubscribing the old one.
      final existing = await WebPushSubscription.db.findFirstRow(
        session,
        where: (t) => t.endpoint.equals(endpoint),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (existing != null) {
        if (existing.ownerId != id) {
          throw WatchlistError(
            code: 'push',
            message: '이 기기의 알림을 해제한 뒤 다시 설정해 주세요.',
          );
        }
        await WebPushSubscription.db.updateRow(
          session,
          existing.copyWith(p256dh: p256dh, auth: auth),
          transaction: tx,
        );
        return;
      }
      if (await WebPushSubscription.db.count(
            session,
            where: (t) => t.ownerId.equals(id),
            transaction: tx,
          ) >=
          5) {
        throw WatchlistError(
          code: 'push',
          message: '알림 기기는 최대 5개까지 등록할 수 있습니다.',
        );
      }
      await WebPushSubscription.db.insertRow(
        session,
        WebPushSubscription(
          ownerId: id,
          endpoint: endpoint,
          p256dh: p256dh,
          auth: auth,
        ),
        transaction: tx,
      );
    });
  }

  Future<void> unsubscribePush(Session session, String endpoint) async {
    final id = WatchlistService.owner(session);
    await WebPushSubscription.db.deleteWhere(
      session,
      where: (t) => t.ownerId.equals(id) & t.endpoint.equals(endpoint),
    );
  }
}
