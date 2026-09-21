import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/disclosure_links.dart';

/// 재무·시세로 기업을 거르는 스크리닝.
///
/// 지표(PER·PBR·ROE·영업이익률)는 저장하지 않는다. 최근 12개월(TTM) 원천 값과 최근
/// 시가총액으로 계산하고, 계산에 쓴 값도 같이 돌려준다. 기업 화면의 지표와 같은 기준이다.
///
/// 전 상장사를 한 번 계산해 두고(데이터가 바뀌면 다시), 거르기·정렬은 메모리에서 한다.
class ScreenEndpoint extends Endpoint {
  static const _income = [
    'ifrs-full_Revenue',
    'dart_OperatingIncomeLoss',
    'ifrs-full_ProfitLossAttributableToOwnersOfParent',
    'ifrs-full_ProfitLoss',
  ];
  static const _balance = [
    'ifrs-full_EquityAttributableToOwnersOfParent',
    'ifrs-full_Equity',
  ];

  static String? _cacheKey;
  static List<ScreenRow>? _cache;
  static DateTime? _baseDate;

  /// 조건에 맞는 기업. 값이 없는 기업(적자·자본잠식 등)은 그 지표 조건이 있으면 빠진다.
  Future<ScreenPage> list(
    Session session, {

    /// 이 기업들만 (비교 화면). 주면 다른 조건은 무시한다.
    List<String>? corpCodes,
    Market? market,
    String? sectionCode,
    double? perMax,
    double? pbrMax,
    double? roeMin,
    double? operatingMarginMin,
    BigInt? marketCapMin,
    ScreenSort? sort,
    bool? ascending,
    int? offset,
    int? limit,
  }) async {
    final all = await _universe(session);
    final codes = corpCodes?.toSet();
    var rows = [
      for (final r in all)
        if (codes == null || codes.contains(r.company.corpCode))
          if (codes != null ||
              ((market == null || r.company.market == market) &&
                  (perMax == null || (r.per != null && r.per! <= perMax)) &&
                  (pbrMax == null || (r.pbr != null && r.pbr! <= pbrMax)) &&
                  (roeMin == null || (r.roe != null && r.roe! >= roeMin)) &&
                  (operatingMarginMin == null ||
                      (r.operatingMargin != null &&
                          r.operatingMargin! >= operatingMarginMin)) &&
                  (marketCapMin == null || r.marketCap >= marketCapMin)))
            r,
    ];
    if (sectionCode != null && codes == null) {
      final ids = {
        for (final c in await Company.db.find(
          session,
          where: (t) => t.sectionCode.equals(sectionCode),
        ))
          c.id!,
      };
      rows = [
        for (final r in rows)
          if (ids.contains(r.company.id)) r,
      ];
    }

    double? key(ScreenRow r) => switch (sort ?? ScreenSort.marketCap) {
      ScreenSort.marketCap => r.marketCap.toDouble(),
      ScreenSort.per => r.per,
      ScreenSort.pbr => r.pbr,
      ScreenSort.roe => r.roe,
      ScreenSort.operatingMargin => r.operatingMargin,
    };
    final asc = ascending ?? false;
    rows.sort((a, b) {
      final x = key(a), y = key(b);
      // 값이 없는 기업은 어느 방향이든 뒤로 보낸다.
      if (x == null || y == null) {
        return x == null && y == null
            ? b.marketCap.compareTo(a.marketCap)
            : (x == null ? 1 : -1);
      }
      final c = asc ? x.compareTo(y) : y.compareTo(x);
      return c != 0 ? c : b.marketCap.compareTo(a.marketCap);
    });

    final from = (offset ?? 0).clamp(0, rows.length);
    final to = (from + (limit ?? 50).clamp(1, 500)).clamp(from, rows.length);
    return ScreenPage(
      items: rows.sublist(from, to),
      total: rows.length,
      baseDate: _baseDate,
      universe: all.length,
    );
  }

  /// 전 상장사의 지표. 재무·시세가 바뀌지 않았으면 지난 계산을 그대로 쓴다.
  Future<List<ScreenRow>> _universe(Session session) async {
    final version = await session.db.unsafeQuery('''
      SELECT (SELECT max(id) FROM financial_fact),
             (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0),
             (SELECT count(*) FROM company)
    ''');
    final key = version.first.join('|');
    if (key == _cacheKey && _cache != null) return _cache!;

    final markets = DisclosureLinks.listedMarkets
        .map((m) => "'${m.name}'")
        .join(', ');
    final income = _income.map((a) => "'$a'").join(', ');
    final balance = _balance.map((a) => "'$a'").join(', ');
    final rows = await session.db.unsafeQuery('''
      WITH rank_code AS (
        SELECT * FROM (VALUES ('q1',1),('halfYear',2),('q3',3),('annual',4)) AS t(code, rk)
      ), latest AS (
        -- 기업마다 가장 최근 연결 보고서 (분기·반기 포함).
        SELECT DISTINCT ON (r."companyId")
               r."companyId" AS id, r."bsnsYear" AS y, r."reportCode" AS code
        FROM financial_report r JOIN rank_code rc ON rc.code = r."reportCode"
        WHERE r."fsDiv" = 'consolidated'
        ORDER BY r."companyId", r."bsnsYear" DESC, rc.rk DESC
      ), inc AS (
        SELECT f."companyId" AS id, f."accountId" AS acc, f."bsnsYear" AS y,
               f."reportCode" AS code, f.amount::numeric AS amt,
               f."cumulativeAmount"::numeric AS cum,
               f."priorCumulativeAmount"::numeric AS prior
        FROM financial_fact f
        WHERE f."fsDiv" = 'consolidated' AND f."supersededById" IS NULL
          AND f.statement IN ('incomeStatement','comprehensiveIncome')
          AND f."accountId" IN ($income)
      ), cur AS (
        SELECT i.id, i.acc, l.code, max(i.amt) AS amt, max(i.cum) AS cum,
               max(i.prior) AS prior
        FROM inc i JOIN latest l ON l.id = i.id AND l.y = i.y AND l.code = i.code
        GROUP BY 1, 2, 3
      ), prev AS (
        SELECT i.id, i.acc, max(i.amt) AS amt
        FROM inc i JOIN latest l ON l.id = i.id AND i.y = l.y - 1
        WHERE i.code = 'annual'
        GROUP BY 1, 2
      ), ttm AS (
        -- 최근 보고서가 사업보고서면 그 값, 아니면 전년 연간 + 올해 누적 − 전년 같은 기간 누적.
        SELECT c.id, c.acc,
               CASE WHEN c.code = 'annual' THEN c.amt
                    ELSE p.amt + c.cum - c.prior END AS v
        FROM cur c LEFT JOIN prev p ON p.id = c.id AND p.acc = c.acc
      ), bs AS (
        SELECT f."companyId" AS id, f."accountId" AS acc, max(f.amount::numeric) AS v
        FROM financial_fact f
        JOIN latest l ON l.id = f."companyId" AND l.y = f."bsnsYear" AND l.code = f."reportCode"
        WHERE f."fsDiv" = 'consolidated' AND f."supersededById" IS NULL
          AND f.statement = 'balanceSheet' AND f."accountId" IN ($balance)
        GROUP BY 1, 2
      ), cap AS (
        SELECT s."companyId" AS id, sum(m."marketCap"::numeric) AS cap
        FROM market_snapshot m
        JOIN security s ON s.id = m."securityId"
        WHERE m."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND s."companyId" IS NOT NULL
        GROUP BY 1
      ), metrics AS (
        SELECT c.id, c."corpCode", c.name, c.market, l.y, cap.cap,
          max(t.v) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue,
          max(t.v) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op,
          coalesce(
            max(t.v) FILTER (WHERE t.acc = 'ifrs-full_ProfitLossAttributableToOwnersOfParent'),
            max(t.v) FILTER (WHERE t.acc = 'ifrs-full_ProfitLoss')) AS ni,
          coalesce(
            max(b.v) FILTER (WHERE b.acc = 'ifrs-full_EquityAttributableToOwnersOfParent'),
            max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Equity')) AS eq
        FROM company c
        JOIN latest l ON l.id = c.id
        JOIN cap ON cap.id = c.id
        LEFT JOIN ttm t ON t.id = c.id
        LEFT JOIN bs b ON b.id = c.id
        WHERE c.market IN ($markets)
        GROUP BY c.id, c."corpCode", c.name, c.market, l.y, cap.cap
      )
      SELECT id, "corpCode", name, market, y, cap, revenue, op, ni, eq
      FROM metrics
    ''');

    final day = await MarketSnapshotDay.db.findFirstRow(
      session,
      where: (t) => t.rowCount > 0,
      orderBy: (t) => t.baseDate.desc(),
    );
    BigInt? big(Object? v) =>
        v == null ? null : BigInt.parse('$v'.split('.').first);
    double? divide(Object? top, Object? bottom, {double scale = 1}) {
      final a = top == null ? null : double.parse('$top');
      final b = bottom == null ? null : double.parse('$bottom');
      if (a == null || b == null || b <= 0) return null;
      return scale * a / b;
    }

    final universe = [
      for (final r in rows)
        ScreenRow(
          company: CompanyRef(
            id: r[0] as int,
            corpCode: r[1] as String,
            name: r[2] as String,
            market: r[3] == null ? null : Market.values.byName('${r[3]}'),
          ),
          bsnsYear: r[4] as int,
          marketCap: big(r[5])!,
          revenue: big(r[6]),
          operatingIncome: big(r[7]),
          netIncome: big(r[8]),
          equity: big(r[9]),
          per: divide(r[5], r[8]),
          pbr: divide(r[5], r[9]),
          roe: divide(r[8], r[9], scale: 100),
          operatingMargin: divide(r[7], r[6], scale: 100),
        ),
    ];
    _cacheKey = key;
    _cache = universe;
    _baseDate = day?.baseDate;
    return universe;
  }
}
