import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// Serializes rule replacement for a document; reload after locking so a replay
/// cannot publish an older in-memory document over a newer stored version.
abstract final class RuleDocumentStore {
  static Future<int> run(
    Session session,
    BusinessDocument doc,
    Future<int> Function(BusinessDocument current, Transaction tx) store,
  ) => session.db.transaction((tx) async {
    final current = await BusinessDocument.db.findById(
      session,
      doc.id!,
      transaction: tx,
      lockMode: LockMode.forUpdate,
    );
    if (current == null) return 0;
    return store(current, tx);
  });
}
