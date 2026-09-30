import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'business_text.dart';

/// Re-fetch only irreversibly malformed text from the same primary filing.
/// The endpoint owns authentication and the external-call budget.
abstract final class BusinessTextRepair {
  static Future<bool> repair(
    Session session,
    BusinessDocument document,
    Future<List<int>?> Function(String rceptNo) fetch,
  ) async {
    if (!document.text.contains('\uFFFD')) return false;
    final zip = await fetch(document.rceptNo);
    if (zip == null) return false;
    final decoded = BusinessText.fromZip(zip, document.rceptNo);
    if (decoded == null || decoded.text.contains('\uFFFD')) return false;
    return session.db.transaction((tx) async {
      final current = await BusinessDocument.db.findById(
        session,
        document.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (current == null || !current.text.contains('\uFFFD')) return false;
      await BusinessDocument.db.updateRow(
        session,
        current.copyWith(
          title: decoded.title,
          text: decoded.text,
          charCount: decoded.text.length,
        ),
        transaction: tx,
      );
      session.log('원문 인코딩 복구: ${document.rceptNo}');
      return true;
    });
  }
}
