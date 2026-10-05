import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../notes/investment_notes.dart';

/// Server-authorized reader projection and admin-only authored publication.
class InvestmentNotesEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<String> list(
    Session session, {
    String? corpCode,
    int offset = 0,
  }) async => _guard(
    () async => jsonEncode(
      await InvestmentNotes.list(session, corpCode: corpCode, offset: offset),
    ),
  );

  Future<String> detail(Session session, int articleId) async => _guard(
    () async => jsonEncode(await InvestmentNotes.detail(session, articleId)),
  );

  Future<String> importDraft(
    Session session,
    String payload, {
    int? articleId,
  }) async => _guard(
    () async => jsonEncode(
      await InvestmentNotes.importDraft(session, payload, articleId: articleId),
    ),
  );

  Future<String> preview(Session session, int articleId) async => _guard(
    () async => jsonEncode(await InvestmentNotes.preview(session, articleId)),
  );

  Future<void> publish(
    Session session,
    int articleId,
    String approvedDigest,
  ) async {
    try {
      await InvestmentNotes.publish(session, articleId, approvedDigest);
    } on FormatException catch (e) {
      throw IngestException(message: e.message);
    }
  }

  Future<String> _guard(Future<String> Function() action) async {
    try {
      return await action();
    } on FormatException catch (e) {
      throw IngestException(message: e.message);
    }
  }
}
