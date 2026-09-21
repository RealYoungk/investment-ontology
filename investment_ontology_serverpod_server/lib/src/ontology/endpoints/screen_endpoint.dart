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
  /// 최근 12개월(TTM)로 더하는 계정 — 손익계산서와 현금흐름표.
  static const _flow = [
    'ifrs-full_Revenue',
    'dart_OperatingIncomeLoss',
    'ifrs-full_ProfitLossAttributableToOwnersOfParent',
    'ifrs-full_ProfitLoss',
    'ifrs-full_CashFlowsFromUsedInOperatingActivities',
    'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities',
  ];

  /// 최근 보고서 기말 값을 쓰는 계정 — 재무상태표.
  static const _balance = [
    'ifrs-full_EquityAttributableToOwnersOfParent',
    'ifrs-full_Equity',
    'ifrs-full_Liabilities',
  ];

  /// 지난 계산을 버린다 (테스트에서 쓴다).
  static void clearCache() {
    _cacheKey = null;
    _cache = null;
    _baseDate = null;
  }

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
    double? revenueGrowthMin,
    double? operatingIncomeGrowthMin,
    double? debtRatioMax,
    double? dividendYieldMin,
    double? fcfYieldMin,
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
                  (revenueGrowthMin == null ||
                      (r.revenueGrowth != null &&
                          r.revenueGrowth! >= revenueGrowthMin)) &&
                  (operatingIncomeGrowthMin == null ||
                      (r.operatingIncomeGrowth != null &&
                          r.operatingIncomeGrowth! >=
                              operatingIncomeGrowthMin)) &&
                  (debtRatioMax == null ||
                      (r.debtRatio != null && r.debtRatio! <= debtRatioMax)) &&
                  (dividendYieldMin == null ||
                      (r.dividendYield != null &&
                          r.dividendYield! >= dividendYieldMin)) &&
                  (fcfYieldMin == null ||
                      (r.fcfYield != null && r.fcfYield! >= fcfYieldMin)) &&
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
      // 부채비율은 낮을수록 좋으니 기본 정렬(내림차순)에서 낮은 쪽이 앞에 오게 뒤집는다.
      ScreenSort.debtRatio => r.debtRatio == null ? null : -r.debtRatio!,
      ScreenSort.fcfYield => r.fcfYield,
      ScreenSort.dividendYield => r.dividendYield,
      ScreenSort.revenueGrowth => r.revenueGrowth,
      ScreenSort.operatingIncomeGrowth => r.operatingIncomeGrowth,
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

  /// 같은 업종 기업들과의 비교. 업종은 값이 있는 기업이 다섯 곳은 되도록
  /// 세분류 → 중분류 → 대분류 순으로 넓혀 잡는다.
  Future<PeerComparison?> peers(Session session, String corpCode) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company?.id == null) return null;
    final all = await _universe(session);
    final me = all.where((r) => r.company.corpCode == corpCode).firstOrNull;
    if (me == null) return null;

    final companies = await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
    );
    final byId = {for (final c in companies) c.id!: c};

    // 좁은 업종부터 본다. 기업 수가 너무 적으면 중앙값이 뜻이 없다.
    const minPeers = 5;
    List<ScreenRow> inGroup(String? Function(Company) code) {
      final mine = code(company!);
      if (mine == null || mine.isEmpty) return const [];
      return [
        for (final r in all)
          if (code(byId[r.company.id] ?? company) == mine) r,
      ];
    }

    var code = company!.industryCode;
    var group = inGroup((c) => c.industryCode);
    if (group.length < minPeers) {
      code = company.divisionCode;
      group = inGroup((c) => c.divisionCode);
    }
    if (group.length < minPeers) {
      code = company.sectionCode;
      group = inGroup((c) => c.sectionCode);
    }
    if (group.length < minPeers || code == null) return null;

    final industry = await Industry.db.findFirstRow(
      session,
      where: (t) => t.code.equals(code!),
    );

    PeerMetric metric(
      String key,
      String label,
      double? Function(ScreenRow) pick, {
      bool lowerIsBetter = false,
    }) {
      final values = [for (final r in group) ?pick(r)]..sort();
      final mine = pick(me);
      final median = values.isEmpty
          ? null
          : values.length.isOdd
          ? values[values.length ~/ 2]
          : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2;
      int? rank;
      if (mine != null && values.isNotEmpty) {
        rank =
            1 + values.where((v) => lowerIsBetter ? v < mine : v > mine).length;
      }
      return PeerMetric(
        key: key,
        label: label,
        value: mine,
        median: median,
        rank: rank,
        ranked: values.isEmpty ? null : values.length,
        lowerIsBetter: lowerIsBetter,
      );
    }

    return PeerComparison(
      code: code,
      label: industry?.name ?? code,
      peerCount: group.length,
      metrics: [
        metric('per', 'PER', (r) => r.per, lowerIsBetter: true),
        metric('pbr', 'PBR', (r) => r.pbr, lowerIsBetter: true),
        metric('roe', 'ROE', (r) => r.roe),
        metric('operatingMargin', '영업이익률', (r) => r.operatingMargin),
        metric('revenueGrowth', '매출 성장률', (r) => r.revenueGrowth),
        metric('debtRatio', '부채비율', (r) => r.debtRatio, lowerIsBetter: true),
        metric('dividendYield', '배당수익률', (r) => r.dividendYield),
        metric('fcfYield', 'FCF 수익률', (r) => r.fcfYield),
      ],
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
    final flow = _flow.map((a) => "'$a'").join(', ');
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
        -- 누적 값: 사업보고서·1분기와 현금흐름표는 amount가 곧 누적이다
        -- (현금흐름표에는 3개월 값이 따로 없다). 기업 화면과 같은 규칙.
        SELECT f."companyId" AS id, f."accountId" AS acc, f."bsnsYear" AS y,
               f."reportCode" AS code, f.amount::numeric AS amt,
               CASE WHEN f."reportCode" IN ('annual','q1')
                      OR f.statement = 'cashFlow'
                    THEN coalesce(f."cumulativeAmount"::numeric, f.amount::numeric)
                    ELSE f."cumulativeAmount"::numeric END AS cum
        FROM financial_fact f
        WHERE f."fsDiv" = 'consolidated' AND f."supersededById" IS NULL
          AND f.statement IN ('incomeStatement','comprehensiveIncome','cashFlow')
          AND f."accountId" IN ($flow)
      ), cur AS (
        SELECT i.id, i.acc, l.code, max(i.amt) AS amt, max(i.cum) AS cum
        FROM inc i JOIN latest l ON l.id = i.id AND l.y = i.y AND l.code = i.code
        GROUP BY 1, 2, 3
      ), prev AS (
        -- 전년 사업보고서(연간)와 전년 같은 기간 누적.
        SELECT i.id, i.acc,
               max(i.amt) FILTER (WHERE i.code = 'annual') AS annual,
               max(i.cum) FILTER (WHERE i.code = l.code) AS same
        FROM inc i JOIN latest l ON l.id = i.id AND i.y = l.y - 1
        GROUP BY i.id, i.acc, l.code
      ), ttm AS (
        -- 최근 보고서가 사업보고서면 그 값, 아니면 전년 연간 + 올해 누적 − 전년 같은 기간 누적.
        -- 성장률은 같은 기간끼리 견준다 (올해 누적 vs 전년 같은 기간 누적).
        SELECT c.id, c.acc,
               CASE WHEN c.code = 'annual' THEN c.amt
                    ELSE p.annual + c.cum - p.same END AS v,
               CASE WHEN c.code = 'annual' THEN c.amt ELSE c.cum END AS now_cum,
               CASE WHEN c.code = 'annual' THEN p.annual ELSE p.same END AS ago_cum
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
      ), div AS (
        -- 최근 사업연도의 현금배당금총액 (백만원 → 원). 단위는 항목 이름에 있으므로
        -- 아는 표기만 받는다 (다른 단위가 나오면 틀린 값을 쓰느니 비워 둔다).
        SELECT DISTINCT ON (d."companyId") d."companyId" AS id,
               d.current * 1000000 AS total
        FROM dividend_entry d
        WHERE d.item = '현금배당금총액(백만원)' AND d.current IS NOT NULL
        ORDER BY d."companyId", d."bsnsYear" DESC
      ), metrics AS (
        SELECT c.id, c."corpCode", c.name, c.market, l.y, cap.cap,
          max(t.v) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue,
          max(t.v) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op,
          coalesce(
            max(t.v) FILTER (WHERE t.acc = 'ifrs-full_ProfitLossAttributableToOwnersOfParent'),
            max(t.v) FILTER (WHERE t.acc = 'ifrs-full_ProfitLoss')) AS ni,
          coalesce(
            max(b.v) FILTER (WHERE b.acc = 'ifrs-full_EquityAttributableToOwnersOfParent'),
            max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Equity')) AS eq,
          max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Equity') AS total_eq,
          max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Liabilities') AS liab,
          -- 취득액을 음수로 적는 회사가 있어 절댓값으로 뺀다 (기업 화면과 같은 규칙).
          max(t.v) FILTER (WHERE t.acc = 'ifrs-full_CashFlowsFromUsedInOperatingActivities')
            - abs(max(t.v) FILTER (WHERE t.acc = 'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities')) AS fcf,
          max(dv.total) AS dividend,
          max(t.now_cum) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue_now,
          max(t.ago_cum) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue_ago,
          max(t.now_cum) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op_now,
          max(t.ago_cum) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op_ago
        FROM company c
        JOIN latest l ON l.id = c.id
        JOIN cap ON cap.id = c.id
        LEFT JOIN ttm t ON t.id = c.id
        LEFT JOIN bs b ON b.id = c.id
        LEFT JOIN div dv ON dv.id = c.id
        WHERE c.market IN ($markets)
        GROUP BY c.id, c."corpCode", c.name, c.market, l.y, cap.cap
      )
      SELECT id, "corpCode", name, market, y, cap, revenue, op, ni, eq,
             total_eq, liab, fcf, dividend,
             revenue_now, revenue_ago, op_now, op_ago
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

    /// 전년 같은 기간 대비 증감률(%). 작년이 적자(0 이하)면 계산하지 않는다.
    double? growth(Object? now, Object? ago) {
      final a = now == null ? null : double.parse('$now');
      final b = ago == null ? null : double.parse('$ago');
      if (a == null || b == null || b <= 0) return null;
      return 100 * (a - b) / b;
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
          totalEquity: big(r[10]),
          liabilities: big(r[11]),
          freeCashFlow: big(r[12]),
          dividendTotal: big(r[13]),
          per: divide(r[5], r[8]),
          pbr: divide(r[5], r[9]),
          roe: divide(r[8], r[9], scale: 100),
          operatingMargin: divide(r[7], r[6], scale: 100),
          debtRatio: divide(r[11], r[10], scale: 100),
          fcfYield: divide(r[12], r[5], scale: 100),
          dividendYield: divide(r[13], r[5], scale: 100),
          revenueGrowth: growth(r[14], r[15]),
          operatingIncomeGrowth: growth(r[16], r[17]),
        ),
    ];
    _cacheKey = key;
    _cache = universe;
    _baseDate = day?.baseDate;
    return universe;
  }
}
