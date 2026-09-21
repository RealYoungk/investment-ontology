import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 기업 시가총액 = 기업에 연결된 종목(보통주·우선주 등) 시가총액의 합, 가장 최근 기준일.
abstract final class MarketCaps {
  /// [companyIds]의 가장 최근 기준일 시가총액. 시세가 없으면 빈 지도와 null 기준일.
  static Future<({DateTime? baseDate, Map<int, BigInt> caps})> latest(
    Session session,
    Set<int> companyIds,
  ) async {
    final day = await MarketSnapshotDay.db.findFirstRow(
      session,
      where: (t) => t.rowCount > 0,
      orderBy: (t) => t.baseDate.desc(),
    );
    if (day == null || companyIds.isEmpty) {
      return (baseDate: day?.baseDate, caps: <int, BigInt>{});
    }
    final securities = await Security.db.find(
      session,
      where: (t) => t.companyId.inSet(companyIds),
    );
    final companyOf = {for (final s in securities) s.id!: s.companyId!};
    final snaps = companyOf.isEmpty
        ? const <MarketSnapshot>[]
        : await MarketSnapshot.db.find(
            session,
            where: (t) =>
                t.baseDate.equals(day.baseDate) &
                t.securityId.inSet(companyOf.keys.toSet()),
          );
    final caps = <int, BigInt>{};
    for (final s in snaps) {
      final cap = s.marketCap;
      final company = companyOf[s.securityId];
      if (cap == null || company == null) continue;
      caps[company] = (caps[company] ?? BigInt.zero) + cap;
    }
    return (baseDate: day.baseDate, caps: caps);
  }
}
