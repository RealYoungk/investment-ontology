import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/disclosure_links.dart';

/// 재무·시세로 기업을 거르는 스크리닝.
///
/// 지표(PER·PBR·ROE·영업이익률)는 저장하지 않는다. 조회할 때 가장 최근 연결
/// 사업보고서의 원천 값과 최근 시가총액으로 계산하고, 계산에 쓴 값도 같이 돌려준다.
class ScreenEndpoint extends Endpoint {
  /// 계정 하나가 없을 때 대신 쓰는 계정까지 포함한 XBRL ID.
  static const _accounts = [
    'ifrs-full_Revenue',
    'dart_OperatingIncomeLoss',
    'ifrs-full_ProfitLossAttributableToOwnersOfParent',
    'ifrs-full_ProfitLoss',
    'ifrs-full_EquityAttributableToOwnersOfParent',
    'ifrs-full_Equity',
  ];

  /// 조건에 맞는 기업. 값이 없는 기업(적자·자본잠식 등)은 그 지표 조건이 있으면 빠진다.
  Future<ScreenPage> list(
    Session session, {
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
    final markets = market == null
        ? DisclosureLinks.listedMarkets.map((m) => m.name).toList()
        : [market.name];
    // 계정·시장 목록은 코드 안의 고정값이다. 파라미터로 넘기면 계획이 나빠져 3배 느리다.
    final accountList = _accounts.map((a) => "'$a'").join(', ');
    final marketList = markets.map((m) => "'$m'").join(', ');
    final having = <String>[
      if (perMax != null) 'per IS NOT NULL AND per <= @perMax',
      if (pbrMax != null) 'pbr IS NOT NULL AND pbr <= @pbrMax',
      if (roeMin != null) 'roe IS NOT NULL AND roe >= @roeMin',
      if (operatingMarginMin != null)
        'margin IS NOT NULL AND margin >= @marginMin',
      if (marketCapMin != null) 'cap >= @capMin',
    ];
    final order = switch (sort ?? ScreenSort.marketCap) {
      ScreenSort.marketCap => 'cap',
      ScreenSort.per => 'per',
      ScreenSort.pbr => 'pbr',
      ScreenSort.roe => 'roe',
      ScreenSort.operatingMargin => 'margin',
    };
    // 정렬 기준이 없는 기업은 언제나 뒤로 보낸다.
    final direction = (ascending ?? false)
        ? 'ASC NULLS LAST'
        : 'DESC NULLS LAST';

    final sql =
        '''
      WITH cap AS (
        SELECT s."companyId" AS id, sum(m."marketCap"::numeric) AS cap
        FROM market_snapshot m
        JOIN security s ON s.id = m."securityId"
        WHERE m."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND s."companyId" IS NOT NULL
        GROUP BY s."companyId"
      ), latest AS (
        -- 최신 연도는 보고서 장부에서 찾는다 (사실 테이블을 훑으면 1초 넘게 걸린다).
        SELECT "companyId" AS id, max("bsnsYear") AS y
        FROM financial_report
        WHERE "reportCode" = 'annual' AND "fsDiv" = 'consolidated'
        GROUP BY "companyId"
      ), pivot AS (
        SELECT f."companyId" AS id,
          max(f.amount::numeric) FILTER (WHERE f."accountId" = 'ifrs-full_Revenue') AS revenue,
          max(f.amount::numeric) FILTER (WHERE f."accountId" = 'dart_OperatingIncomeLoss') AS op,
          coalesce(
            max(f.amount::numeric) FILTER (WHERE f."accountId" = 'ifrs-full_ProfitLossAttributableToOwnersOfParent'),
            max(f.amount::numeric) FILTER (WHERE f."accountId" = 'ifrs-full_ProfitLoss')) AS ni,
          coalesce(
            max(f.amount::numeric) FILTER (WHERE f."accountId" = 'ifrs-full_EquityAttributableToOwnersOfParent'),
            max(f.amount::numeric) FILTER (WHERE f."accountId" = 'ifrs-full_Equity')) AS eq
        FROM financial_fact f
        JOIN latest l ON l.id = f."companyId" AND l.y = f."bsnsYear"
        WHERE f."reportCode" = 'annual' AND f."fsDiv" = 'consolidated'
          AND f."supersededById" IS NULL
          AND f."accountId" IN ($accountList)
        GROUP BY f."companyId"
      ), metrics AS (
        SELECT c.id, c."corpCode", c.name, c.market, l.y, cap.cap,
          p.revenue, p.op, p.ni, p.eq,
          CASE WHEN p.ni > 0 THEN cap.cap / p.ni END AS per,
          CASE WHEN p.eq > 0 THEN cap.cap / p.eq END AS pbr,
          CASE WHEN p.eq > 0 THEN 100.0 * p.ni / p.eq END AS roe,
          CASE WHEN p.revenue > 0 THEN 100.0 * p.op / p.revenue END AS margin
        FROM company c
        JOIN pivot p ON p.id = c.id
        JOIN latest l ON l.id = c.id
        JOIN cap ON cap.id = c.id
        WHERE c.market IN ($marketList)
          ${sectionCode == null ? '' : 'AND c."sectionCode" = @sectionCode'}
      )
      SELECT id, "corpCode", name, market, y, cap, revenue, op, ni, eq,
             per, pbr, roe, margin, count(*) OVER () AS total,
             (SELECT count(*) FROM metrics) AS universe
      FROM metrics
      ${having.isEmpty ? '' : 'WHERE ${having.join(' AND ')}'}
      ORDER BY $order $direction, cap DESC NULLS LAST
      LIMIT @limit OFFSET @offset
    ''';

    final parameters = <String, dynamic>{
      'limit': (limit ?? 50).clamp(1, 200),
      'offset': offset ?? 0,
    };
    if (sectionCode != null) parameters['sectionCode'] = sectionCode;
    if (perMax != null) parameters['perMax'] = perMax;
    if (pbrMax != null) parameters['pbrMax'] = pbrMax;
    if (roeMin != null) parameters['roeMin'] = roeMin;
    if (operatingMarginMin != null) {
      parameters['marginMin'] = operatingMarginMin;
    }
    if (marketCapMin != null) parameters['capMin'] = marketCapMin.toString();

    final rows = await session.db.unsafeQuery(
      sql,
      parameters: QueryParameters.named(parameters),
    );

    final day = await MarketSnapshotDay.db.findFirstRow(
      session,
      where: (t) => t.rowCount > 0,
      orderBy: (t) => t.baseDate.desc(),
    );
    BigInt? big(Object? v) =>
        v == null ? null : BigInt.parse('$v'.split('.').first);
    double? num_(Object? v) => v == null ? null : double.parse('$v');
    return ScreenPage(
      items: [
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
            per: num_(r[10]),
            pbr: num_(r[11]),
            roe: num_(r[12]),
            operatingMargin: num_(r[13]),
          ),
      ],
      total: rows.isEmpty ? 0 : (rows.first[14] as int),
      baseDate: day?.baseDate,
      universe: rows.isEmpty ? 0 : (rows.first[15] as int),
    );
  }
}
