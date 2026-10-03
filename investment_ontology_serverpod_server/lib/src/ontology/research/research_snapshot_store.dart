import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// Shared immutable snapshot storage; caller must establish admin or scheduled-worker authority.
abstract final class ResearchSnapshotStore {
  static Future<int> store(
    Session session,
    Company c,
    String kind,
    List<Map<String, dynamic>> rows,
    String provider,
    String url,
    String reference,
    SourceKind sourceKind, {
    String? sourceTitle,
    DateTime? sourceRetrievedAt,
    Future<bool> Function()? cancelled,
  }) async {
    final payload = jsonEncode(rows);
    final digest = sha256
        .convert(utf8.encode('$provider|$url|$reference|$payload'))
        .toString();
    return session.db.transaction((tx) async {
      // Serialize same-company writers, retaining previous batches for audit.
      await session.db.unsafeQuery(
        'SELECT id FROM company WHERE id = @id FOR UPDATE',
        parameters: QueryParameters.named({'id': c.id!}),
        transaction: tx,
      );
      final latest = await ResearchSnapshot.db.findFirstRow(
        session,
        where: (t) => t.companyId.equals(c.id!) & t.kind.equals(kind),
        orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
        transaction: tx,
      );
      final previousSource = latest == null
          ? null
          : await Source.db.findById(session, latest.sourceId, transaction: tx);
      if (latest?.payload == payload &&
          latest?.provider == provider &&
          previousSource?.kind == sourceKind &&
          previousSource?.url == url &&
          previousSource?.reference == reference) {
        return latest!.id!;
      }
      if (cancelled != null && await cancelled()) {
        throw StateError('공식 원문 수집이 취소되었습니다.');
      }
      final now = DateTime.now().toUtc();
      // Reverting to an older payload is a new observation, not a stale return.
      final observationDigest = sha256
          .convert(utf8.encode('$digest|${latest?.id ?? 0}'))
          .toString();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: sourceKind,
          title: sourceTitle ?? '$provider · $kind',
          reference: reference,
          url: url,
          retrievedAt: sourceRetrievedAt ?? now,
        ),
        transaction: tx,
      );
      final result = await ResearchSnapshot.db.insertRow(
        session,
        ResearchSnapshot(
          companyId: c.id!,
          kind: kind,
          provider: provider,
          payload: payload,
          sourceId: source.id!,
          digest: observationDigest,
          createdAt: now,
        ),
        transaction: tx,
      );
      return result.id!;
    });
  }
}
