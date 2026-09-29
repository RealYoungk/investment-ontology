import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'peer_rules.dart';

abstract final class PeerProfiles {
  static const latestSql = '''
    SELECT DISTINCT ON (d."companyId") d.id, d."companyId"
    FROM business_document d JOIN disclosure_report r ON r.id=d."reportId"
    JOIN company c ON c.id=d."companyId"
    WHERE r."supersededById" IS NULL AND c.market IN ('kospi','kosdaq','konex')
      AND (c."industryCode" IS NULL OR c."industryCode" <> '64992')
    ORDER BY d."companyId", d."bsnsYear" DESC, d."rceptNo" DESC, d.id DESC
  ''';

  static Future<void> store(Session session, BusinessDocument doc) async {
    final signals = PeerRules.parse(doc.text);
    await session.db.transaction((tx) async {
      // Serialize replays of the same document, including ingestion/startup races.
      await session.db.unsafeQuery(
        'SELECT id FROM business_document WHERE id=@id FOR UPDATE',
        parameters: QueryParameters.named({'id': doc.id!}),
        transaction: tx,
      );
      final old = await PeerProfile.db.findFirstRow(
        session,
        where: (t) => t.documentId.equals(doc.id!),
        transaction: tx,
      );
      final profile = PeerProfile(
        id: old?.id,
        documentId: doc.id!,
        ruleVersion: PeerRules.version,
        signals: signals,
        computedAt: DateTime.now().toUtc(),
      );
      if (old == null) {
        await PeerProfile.db.insertRow(session, profile, transaction: tx);
      } else {
        await PeerProfile.db.updateRow(session, profile, transaction: tx);
      }
    });
  }

  /// Stored source only; no network/AI. Empty profiles are also recorded.
  static Future<int> backfill(Session session) async {
    final rows = await session.db.unsafeQuery('''
      SELECT latest.id FROM ($latestSql) latest
      LEFT JOIN peer_profile p ON p."documentId"=latest.id
      WHERE p.id IS NULL OR p."ruleVersion" <> @version
    ''', parameters: QueryParameters.named({'version': PeerRules.version}));
    var count = 0;
    for (final row in rows) {
      final doc = await BusinessDocument.db.findById(session, row[0] as int);
      if (doc != null) {
        await store(session, doc);
        count++;
      }
    }
    return count;
  }

  static Future<PeerCandidates> candidates(
    Session session,
    String corpCode, {
    String? focusKey,
  }) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw ArgumentError('기업 코드 형식 오류');
    }
    final rows = await session.db.unsafeQuery(
      '''
      SELECT c."corpCode", c.name, d."bsnsYear", d."rceptNo", p.signals,
             p."computedAt", p."ruleVersion", c."industryCode"
      FROM ($latestSql) latest
      JOIN business_document d ON d.id=latest.id
      JOIN company c ON c.id=latest."companyId"
      LEFT JOIN peer_profile p ON p."documentId"=d.id
      WHERE d."bsnsYear" >= @oldest
    ''',
      parameters: QueryParameters.named({'oldest': DateTime.now().year - 2}),
    );
    List<PeerSignal> signals(dynamic raw) => (raw as List)
        .map((v) => PeerSignal.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    final anchor = rows.where((r) => r[0] == corpCode).firstOrNull;
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    final ready = anchor != null && anchor[6] == PeerRules.version;
    final own = ready ? signals(anchor[4]) : <PeerSignal>[];
    final focuses = PeerRules.focuses(own);
    final focus =
        focuses.where((s) => s.key == focusKey).firstOrNull ??
        focuses.firstOrNull;
    final ranked = <(int, PeerCandidate)>[];
    if (own.isNotEmpty) {
      for (final r in rows) {
        if (r[0] == corpCode || r[6] != PeerRules.version) continue;
        final candidate = signals(r[4]);
        if (focus == null || !candidate.any((s) => s.key == focus.key)) {
          continue;
        }
        final match = PeerRules.match(
          own,
          candidate,
          anchorIndustry: anchor![7] as String?,
          candidateIndustry: r[7] as String?,
        );
        if (match == null) continue;
        ranked.add((
          match.score,
          PeerCandidate(
            corpCode: r[0] as String,
            name: r[1] as String,
            tier: match.tier,
            reasons: match.reasons,
            differences: match.differences,
            signals: candidate,
            bsnsYear: r[2] as int,
            rceptNo: r[3] as String,
          ),
        ));
      }
    }
    ranked.sort((a, b) {
      final score = b.$1.compareTo(a.$1);
      return score != 0 ? score : a.$2.corpCode.compareTo(b.$2.corpCode);
    });
    return PeerCandidates(
      status: anchor == null
          ? 'no_document'
          : !ready
          ? 'pending'
          : own.isEmpty
          ? 'unsupported'
          : ranked.isEmpty
          ? 'empty'
          : 'ready',
      anchorName: company?.name ?? corpCode,
      signals: own,
      bsnsYear: anchor?[2] as int?,
      rceptNo: anchor?[3] as String?,
      computedAt: ready ? anchor[5] as DateTime : null,
      ruleVersion: PeerRules.version,
      items: ranked.take(5).map((r) => r.$2).toList(),
    );
  }
}
