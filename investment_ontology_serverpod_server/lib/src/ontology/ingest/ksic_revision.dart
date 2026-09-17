import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// DART 업종코드가 KSIC 몇 차 기준인지 실제 데이터로 판정한다.
///
/// DART는 차수를 밝히지 않는다. 한 차수에만 있는 코드(예: 10차에만 있는 274,
/// 11차에만 있는 109·603·846)가 실제로 쓰였는지를 근거로 삼는다.
/// 차수마다 같은 코드의 뜻이 다를 수 있어(예: 104~108) 판정이 필요하다.
abstract final class KsicRevision {
  static const latest = 'KSIC 11';
  static const _cacheKey = 'ksic_revision_check';

  /// 판정 결과 (수집이 끝나면 [invalidate]로 다시 계산).
  static Future<IndustryRevisionCheck> current(Session session) async {
    final cached = await session.caches.local.get<IndustryRevisionCheck>(
      _cacheKey,
    );
    if (cached != null) return cached;
    final check = await resolve(session);
    await session.caches.local.put(
      _cacheKey,
      check,
      lifetime: const Duration(hours: 1),
    );
    return check;
  }

  static Future<void> invalidate(Session session) =>
      session.caches.local.invalidateKey(_cacheKey);

  static Future<IndustryRevisionCheck> resolve(Session session) async {
    final rows = await session.db.unsafeQuery(
      'SELECT DISTINCT "industryCode" AS code FROM company '
      'WHERE "industryCode" IS NOT NULL',
    );
    final used = {for (final r in rows) r.toColumnMap()['code'] as String};

    final byRevision = <String, Set<String>>{};
    for (final i in await Industry.db.find(session)) {
      (byRevision[i.revision] ??= {}).add(i.code);
    }
    return decide(used, byRevision);
  }

  /// [used]: 기업에 쓰인 업종코드, [byRevision]: 차수별 분류표 코드.
  static IndustryRevisionCheck decide(
    Set<String> used,
    Map<String, Set<String>> byRevision,
  ) {
    if (byRevision.isEmpty) {
      return IndustryRevisionCheck(
        revision: latest,
        distinctCodes: used.length,
        unmatchedCodes: used.toList()..sort(),
        evidenceCodes: const [],
        confirmed: false,
      );
    }
    final candidates = [
      for (final MapEntry(key: revision, value: codes) in byRevision.entries)
        (
          revision: revision,
          unmatched: (used.difference(codes).toList()..sort()),
          evidence:
              (used
                  .where(
                    (c) =>
                        codes.contains(c) &&
                        byRevision.entries.every(
                          (o) => o.key == revision || !o.value.contains(c),
                        ),
                  )
                  .toList()
                ..sort()),
        ),
    ];
    // 없는 코드가 적을수록, 근거 코드가 많을수록, 최신일수록 우선.
    candidates.sort((a, b) {
      final byUnmatched = a.unmatched.length.compareTo(b.unmatched.length);
      if (byUnmatched != 0) return byUnmatched;
      final byEvidence = b.evidence.length.compareTo(a.evidence.length);
      if (byEvidence != 0) return byEvidence;
      return b.revision.compareTo(a.revision);
    });
    final best = candidates.first;
    final others = candidates.skip(1);
    final confirmed =
        best.evidence.isNotEmpty &&
        others.every(
          (o) =>
              o.unmatched.length > best.unmatched.length ||
              o.evidence.length < best.evidence.length,
        );
    return IndustryRevisionCheck(
      revision: best.revision,
      distinctCodes: used.length,
      unmatchedCodes: best.unmatched,
      evidenceCodes: best.evidence,
      confirmed: confirmed,
    );
  }
}
