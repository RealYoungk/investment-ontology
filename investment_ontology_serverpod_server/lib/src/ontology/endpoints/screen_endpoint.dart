import 'dart:io' show stderr;

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/disclosure_links.dart';
import '../cache/single_flight.dart';
import '../financial/financial_basis.dart';
import '../peers/peer_catalog.dart';

/// 재무·시세로 기업을 거르는 스크리닝.
///
/// 지표(PER·PBR·ROE·영업이익률)는 저장하지 않는다. 최근 12개월(TTM) 원천 값과 최근
/// 시가총액으로 계산하고, 계산에 쓴 값도 같이 돌려준다. 기업 화면의 지표와 같은 기준이다.
///
/// 조건 검색은 전체 캐시를 사용하고, 기업 비교는 선택 기업만 SQL에서 계산한다.
class ScreenEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// 사전 처리된 최신 공시 제품군으로 선정한 비교 후보.
  Future<PeerCandidates> peerCandidates(
    Session session,
    String corpCode, {
    String? focusKey,
  }) => PeerProfiles.candidates(session, corpCode, focusKey: focusKey);

  /// 상장사의 자산총계가 이보다 작을 수는 없다. 이보다 작으면 재무제표를 원이 아닌
  /// 단위(천원 등)로 낸 것이라, 시가총액과 섞는 지표(PER·PBR·수익률)를 계산하지 않는다.
  static final _minAssets = BigInt.from(100000000);

  /// 지난 계산을 버린다 (테스트에서 쓴다).
  static void clearCache() {
    _cacheKey = null;
    _cache = null;
    _baseDate = null;
  }

  /// 데이터가 바뀐 뒤 첫 요청에 지난 계산을 먼저 주고 뒤에서 다시 계산할지.
  /// 전 상장사 계산이 10초쯤 걸려, 하루 한 번 누군가는 그만큼 기다리게 된다.
  /// 테스트는 바로 새 값을 보려고 끈다.
  static bool serveStaleWhileRefreshing = true;

  static String? _cacheKey;
  static List<ScreenRow>? _cache;
  static DateTime? _baseDate;

  /// 뒤에서 도는 다시 계산 (한 번에 하나만).
  static Future<void>? _refreshing;

  static final _coldCalculation = SingleFlight<List<ScreenRow>>();

  /// 뒤에서 도는 계산이 끝날 때까지 (테스트에서 쓴다).
  static Future<void> awaitRefresh() => _refreshing ?? Future.value();

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
    double? dividendPayoutMax,
    int? dividendYearsMin,
    BigInt? volumeMin,
    double? volumeRatioMin,
    double? return3mMin,
    double? return12mMin,
    double? bandPositionMin,
    BigInt? marketCapMin,

    /// 하루 평균 거래대금(원)이 이보다 적은 기업은 뺀다 — 사고팔기 어려운 종목.
    BigInt? avgTradingValueMin,
    ScreenSort? sort,
    bool? ascending,
    int? offset,
    int? limit,
  }) async {
    for (final value in [dividendPayoutMax, volumeRatioMin, bandPositionMin]) {
      if (value != null && (!value.isFinite || value < 0)) {
        throw ArgumentError('조건은 유한한 0 이상의 숫자여야 합니다.');
      }
    }
    for (final value in [return3mMin, return12mMin]) {
      if (value != null && (!value.isFinite || value < -100)) {
        throw ArgumentError('등락률은 -100 이상이어야 합니다.');
      }
    }
    if ((bandPositionMin != null && bandPositionMin > 100) ||
        (dividendYearsMin != null &&
            (dividendYearsMin < 0 || dividendYearsMin > 3)) ||
        (volumeMin != null && volumeMin < BigInt.zero) ||
        (marketCapMin != null && marketCapMin < BigInt.zero)) {
      throw ArgumentError('조건 범위를 확인해 주세요. 배당 연수는 최대 3년입니다.');
    }
    final codes = corpCodes?.toSet();
    final List<ScreenRow> all;
    DateTime? baseDate;
    if (codes == null) {
      all = await _universe(session);
      baseDate = _baseDate;
    } else {
      final companies = codes.isEmpty
          ? <Company>[]
          : await Company.db.find(
              session,
              where: (t) => t.corpCode.inSet(codes),
            );
      final ids = [for (final company in companies) company.id!];
      all = ids.isEmpty
          ? <ScreenRow>[]
          : await _compute(session, '', companyIds: ids);
      baseDate = (await MarketSnapshotDay.db.findFirstRow(
        session,
        where: (t) => t.rowCount > 0,
        orderBy: (t) => t.baseDate.desc(),
      ))?.baseDate;
    }
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
                  (dividendPayoutMax == null ||
                      (r.dividendPayout != null &&
                          r.dividendPayout! <= dividendPayoutMax)) &&
                  (dividendYearsMin == null ||
                      (r.dividendYears != null &&
                          r.dividendYears! >= dividendYearsMin)) &&
                  (volumeMin == null ||
                      (r.volume != null && r.volume! >= volumeMin)) &&
                  (volumeRatioMin == null ||
                      (r.volumeRatio != null &&
                          r.volumeRatio! >= volumeRatioMin)) &&
                  (return3mMin == null ||
                      (r.return3m != null && r.return3m! >= return3mMin)) &&
                  (return12mMin == null ||
                      (r.return12m != null && r.return12m! >= return12mMin)) &&
                  (bandPositionMin == null ||
                      (r.bandPosition != null &&
                          r.bandPosition! >= bandPositionMin)) &&
                  (marketCapMin == null || r.marketCap >= marketCapMin) &&
                  (avgTradingValueMin == null ||
                      (r.avgTradingValue != null &&
                          r.avgTradingValue! >= avgTradingValueMin))))
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
      ScreenSort.return3m => r.return3m,
      ScreenSort.return12m => r.return12m,
      // 낮을수록 (52주 최저에 가까울수록) 앞으로.
      ScreenSort.bandPosition =>
        r.bandPosition == null ? null : -r.bandPosition!,
      ScreenSort.avgTradingValue => r.avgTradingValue?.toDouble(),
      ScreenSort.dividendPayout => r.dividendPayout,
      ScreenSort.dividendYears => r.dividendYears?.toDouble(),
      ScreenSort.volume => r.volume?.toDouble(),
      ScreenSort.volumeRatio => r.volumeRatio,
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
      baseDate: baseDate,
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
          if (r.fsDiv == me.fsDiv &&
              code(byId[r.company.id] ?? company) == mine)
            r,
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
      fsDiv: me.fsDiv,
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
    final key = await _versionKey(session);
    if (key == _cacheKey && _cache != null) return _cache!;
    if (serveStaleWhileRefreshing && _cache != null) {
      // 지난 계산을 바로 주고, 새 계산은 따로 연 세션에서 한 번만 돌린다.
      _refreshing ??= _refresh(session.serverpod, key).whenComplete(
        () => _refreshing = null,
      );
      return _cache!;
    }
    return _coldCalculation.run(() => _compute(session, key));
  }

  /// 재무·시세·배당·기업 정보 중 하나라도 바뀌면 달라지는 값.
  static Future<String> _versionKey(Session session) async {
    final version = await session.db.unsafeQuery('''
      SELECT (SELECT max(id) FROM financial_fact),
             (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0),
             (SELECT count(*) FROM company),
             (SELECT max(id) FROM company_change),
             (SELECT max(id) FROM dividend_entry),
             (SELECT count(*) FROM dividend_entry),
             (SELECT max(id) FROM disclosure_report WHERE section = 'dividend')
    ''');
    return version.first.join('|');
  }

  /// 뒤에서 도는 계산 대신 쓸 함수 (테스트에서 실패·재시도를 확인할 때 쓴다).
  static Future<void> Function(Session session, String key)? refreshOverride;

  /// 뒤에서 다시 계산한다. 실패해도 던지지 않는다 — 지난 계산을 계속 주고,
  /// `_refreshing`이 풀려 다음 요청이 다시 시도한다.
  static Future<void> _refresh(Serverpod serverpod, String key) async {
    Session? session;
    try {
      session = await serverpod.createSession(enableLogging: false);
      final compute = refreshOverride;
      if (compute != null) {
        await compute(session, key);
      } else {
        await ScreenEndpoint()._compute(session, key);
      }
    } catch (e, st) {
      await _logRefreshFailure(serverpod, e, st);
    } finally {
      try {
        await session?.close();
      } catch (e, st) {
        await _logRefreshFailure(serverpod, e, st);
      }
    }
  }

  /// 계산 세션은 로그를 끈 채 열려 `log`가 아무것도 남기지 않으니, 로그를 켠 세션을 따로 연다.
  static Future<void> _logRefreshFailure(
    Serverpod serverpod,
    Object error,
    StackTrace stackTrace,
  ) async {
    const message = '스크리너 다시 계산 실패 (지난 계산을 계속 준다)';
    try {
      final session = await serverpod.createSession();
      try {
        session.log(
          message,
          level: LogLevel.error,
          exception: error,
          stackTrace: stackTrace,
        );
      } finally {
        await session.close();
      }
    } catch (_) {
      stderr.writeln('$message: $error\n$stackTrace');
    }
  }

  /// 전 상장사의 지표를 계산해 캐시에 넣는다.
  Future<List<ScreenRow>> _compute(
    Session session,
    String key, {
    List<int>? companyIds,
  }) async {
    // IDs originate from the ORM lookup, never from interpolated request text.
    String selected(String alias) => companyIds == null
        ? ''
        : 'AND $alias."companyId" IN (${companyIds.join(',')})';
    final markets = DisclosureLinks.listedMarkets
        .map((m) => "'${m.name}'")
        .join(', ');
    final rows = await session.db.unsafeQuery('''
      WITH ${FinancialBasis.ctes(companyIds: companyIds)}, cap AS (
        -- 시가총액이 없는 종목(거래정지 등)은 빼고 합한다. 한 종목도 없으면 그 기업은
        -- 스크리너에 나오지 않는다 (값을 매길 수 없으므로).
        SELECT s."companyId" AS id, sum(m."marketCap"::numeric) AS cap
        FROM market_snapshot m
        JOIN security s ON s.id = m."securityId"
        WHERE m."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND s."companyId" IS NOT NULL AND m."marketCap" IS NOT NULL
          ${selected('s')}
        GROUP BY 1
      ), rep AS (
        -- 대표 종목: 가장 최근 기준일 시가총액이 큰 것 (주가 추이 화면과 같은 규칙).
        SELECT DISTINCT ON (s."companyId") s."companyId" AS id, m."securityId" AS sid
        FROM market_snapshot m
        JOIN security s ON s.id = m."securityId"
        WHERE m."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND s."companyId" IS NOT NULL AND m."marketCap" IS NOT NULL
          ${selected('s')}
        ORDER BY s."companyId", m."marketCap"::numeric DESC
      ), px_now AS (
        SELECT r.id, m."closePrice"::numeric AS v, m."listedShares"::numeric AS sh
        FROM rep r JOIN market_snapshot m ON m."securityId" = r.sid
        WHERE m."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
      ), px_3m AS (
        -- 3개월 전 거래일이 휴장일 수 있어 그 이전 마지막 거래일을 쓴다.
        SELECT DISTINCT ON (r.id) r.id, m."closePrice"::numeric AS v,
               m."listedShares"::numeric AS sh
        FROM rep r JOIN market_snapshot m ON m."securityId" = r.sid
        WHERE m."baseDate" <= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0) - interval '3 months'
          AND m."baseDate" >= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0) - interval '3 months' - interval '7 days'
        ORDER BY r.id, m."baseDate" DESC
      ), px_12m AS (
        SELECT DISTINCT ON (r.id) r.id, m."closePrice"::numeric AS v,
               m."listedShares"::numeric AS sh
        FROM rep r JOIN market_snapshot m ON m."securityId" = r.sid
        WHERE m."baseDate" <= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0) - interval '12 months'
          AND m."baseDate" >= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0) - interval '12 months' - interval '7 days'
        ORDER BY r.id, m."baseDate" DESC
      ), liq AS (
        -- 최근 한 달 하루 평균 거래대금. 사고팔 수 있는 크기를 보는 값이다.
        SELECT r.id, avg(m."tradingValue"::numeric) AS v
        FROM rep r JOIN market_snapshot m ON m."securityId" = r.sid
        WHERE m."baseDate" > (
            SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0
          ) - interval '30 days'
          AND m."baseDate" <= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND m."tradingValue" IS NOT NULL
        GROUP BY r.id
      ), band AS (
        -- 액면분할·병합이 있으면 종가를 이어 붙일 수 없다. 상장주식수의 최대·최소도
        -- 같이 가져와, 크게 바뀐 기업은 값을 내지 않는다.
        SELECT r.id, max(m."closePrice"::numeric) AS hi, min(m."closePrice"::numeric) AS lo,
               max(m."listedShares"::numeric) AS sh_hi, min(m."listedShares"::numeric) AS sh_lo
        FROM rep r JOIN market_snapshot m ON m."securityId" = r.sid
        WHERE m."baseDate" > (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0) - interval '12 months'
          AND m."baseDate" <= (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
          AND m."closePrice" IS NOT NULL
        GROUP BY r.id
      ), vol AS (
        -- Exactly the preceding 20 observed trading sessions, excluding today.
        -- Null/negative volumes, incomplete windows and share-count changes invalidate the ratio.
        SELECT r.id, n.volume::numeric AS volume,
          CASE WHEN n.volume::numeric >= 0 AND h.valid = 20 AND h.avg_volume > 0
                 AND n."listedShares"::numeric > 0 AND h.valid_shares = 20
                 AND greatest(h.sh_hi, n."listedShares"::numeric)
                   / least(h.sh_lo, n."listedShares"::numeric) <= 1.3
            THEN n.volume::numeric / h.avg_volume END AS ratio
        FROM rep r JOIN market_snapshot n ON n."securityId" = r.sid
          AND n."baseDate" = (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
        LEFT JOIN LATERAL (
          SELECT count(*) FILTER (WHERE v.volume::numeric >= 0) AS valid,
                 avg(v.volume::numeric) AS avg_volume,
                 count(*) FILTER (WHERE v."listedShares"::numeric > 0) AS valid_shares,
                 min(v."listedShares"::numeric) AS sh_lo,
                 max(v."listedShares"::numeric) AS sh_hi
          FROM (SELECT m.volume, m."listedShares" FROM market_snapshot m
                WHERE m."securityId" = r.sid AND m."baseDate" < n."baseDate"
                  AND m."baseDate" IN (
                    SELECT md."baseDate" FROM market_snapshot_day md
                    WHERE md."rowCount" > 0 AND md."baseDate" < n."baseDate"
                    ORDER BY md."baseDate" DESC LIMIT 20)
                ORDER BY m."baseDate" DESC LIMIT 20) v
        ) h ON true
      ), dividend_report AS (
        -- Select the newest annual disclosure FIRST. Never fall back to an older
        -- positive dividend merely because the latest report is null or zero.
        SELECT DISTINCT ON (dr."companyId") dr.id, dr."companyId", dr."bsnsYear"
        FROM disclosure_report dr
        WHERE dr.section = 'dividend' AND dr."reportCode" = 'annual'
          AND dr."supersededById" IS NULL
          ${selected('dr')}
        ORDER BY dr."companyId", dr."bsnsYear" DESC, dr."rceptNo" DESC
      ), div AS (
        SELECT dr."companyId" AS id, dr."bsnsYear" AS year,
          max(d.current) FILTER (WHERE d.item = '현금배당금총액(백만원)') * 1000000 AS total,
          max(d.prior) FILTER (WHERE d.item = '현금배당금총액(백만원)') AS prior,
          max(d."beforePrior") FILTER (WHERE d.item = '현금배당금총액(백만원)') AS before_prior,
          coalesce(
            max(d.current) FILTER (WHERE d.item = '(연결)현금배당성향(%)'),
            max(d.current) FILTER (WHERE d.item = '현금배당성향(%)')) AS payout
        FROM dividend_report dr LEFT JOIN dividend_entry d ON d."reportId" = dr.id
        GROUP BY dr."companyId", dr."bsnsYear"
      ), metrics AS (
        SELECT c.id, c."corpCode", c.name, c.market, l.y, l.fs, l.code, l.reason, cap.cap, bc.currency AS reporting_currency,
          max(t.v) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue,
          max(t.v) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op,
          coalesce(max(t.v) FILTER (WHERE l.fs='consolidated' AND t.acc='ifrs-full_ProfitLossAttributableToOwnersOfParent'),
            max(t.v) FILTER (WHERE t.acc='ifrs-full_ProfitLoss')) AS ni,
          coalesce(max(b.v) FILTER (WHERE l.fs='consolidated' AND b.acc='ifrs-full_EquityAttributableToOwnersOfParent'),
            max(b.v) FILTER (WHERE b.acc='ifrs-full_Equity')) AS eq,
          CASE WHEN l.fs='consolidated'
            AND max(t.v) FILTER (WHERE t.acc='ifrs-full_ProfitLossAttributableToOwnersOfParent') IS NOT NULL
            AND max(b.v) FILTER (WHERE b.acc='ifrs-full_EquityAttributableToOwnersOfParent') IS NOT NULL
            THEN max(t.v) FILTER (WHERE t.acc='ifrs-full_ProfitLossAttributableToOwnersOfParent')
            ELSE max(t.v) FILTER (WHERE t.acc='ifrs-full_ProfitLoss') END AS roe_ni,
          CASE WHEN l.fs='consolidated'
            AND max(t.v) FILTER (WHERE t.acc='ifrs-full_ProfitLossAttributableToOwnersOfParent') IS NOT NULL
            AND max(b.v) FILTER (WHERE b.acc='ifrs-full_EquityAttributableToOwnersOfParent') IS NOT NULL
            THEN max(b.v) FILTER (WHERE b.acc='ifrs-full_EquityAttributableToOwnersOfParent')
            ELSE max(b.v) FILTER (WHERE b.acc='ifrs-full_Equity') END AS roe_eq,
          max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Equity') AS total_eq,
          max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Liabilities') AS liab,
          max(b.v) FILTER (WHERE b.acc = 'ifrs-full_Assets') AS assets,
          -- 취득액을 음수로 적는 회사가 있어 절댓값으로 뺀다 (기업 화면과 같은 규칙).
          max(t.v) FILTER (WHERE t.acc = 'ifrs-full_CashFlowsFromUsedInOperatingActivities')
            - abs(max(t.v) FILTER (WHERE t.acc = 'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities')) AS fcf,
          max(dv.total) AS dividend,
          max(t.now_cum) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue_now,
          max(t.ago_cum) FILTER (WHERE t.acc = 'ifrs-full_Revenue') AS revenue_ago,
          max(t.now_cum) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op_now,
          max(t.ago_cum) FILTER (WHERE t.acc = 'dart_OperatingIncomeLoss') AS op_ago,
          max(pn.v) AS px, max(p3.v) AS px3, max(p12.v) AS px12,
          max(bd.hi) AS hi52, max(bd.lo) AS lo52,
          max(pn.sh) AS sh, max(p3.sh) AS sh3, max(p12.sh) AS sh12,
          max(bd.sh_hi) AS sh_hi, max(bd.sh_lo) AS sh_lo,
          max(lq.v) AS liq,
          max(vl.volume) AS volume, max(vl.ratio) AS volume_ratio,
          max(dv.year) AS div_year, max(dv.payout) AS payout,
          max(dv.prior) AS div_prior, max(dv.before_prior) AS div_before_prior
        FROM company c
        JOIN latest l ON l.id = c.id
        JOIN cap ON cap.id = c.id
        LEFT JOIN basis_currency bc ON bc.id=c.id AND bc.fs=l.fs
        LEFT JOIN ttm t ON t.id = c.id AND t.fs = l.fs
        LEFT JOIN bs b ON b.id = c.id AND b.fs = l.fs
        LEFT JOIN div dv ON dv.id = c.id
        LEFT JOIN px_now pn ON pn.id = c.id
        LEFT JOIN px_3m p3 ON p3.id = c.id
        LEFT JOIN px_12m p12 ON p12.id = c.id
        LEFT JOIN band bd ON bd.id = c.id
        LEFT JOIN liq lq ON lq.id = c.id
        LEFT JOIN vol vl ON vl.id = c.id
        WHERE c.market IN ($markets)
        GROUP BY c.id, c."corpCode", c.name, c.market, l.y, l.fs, l.code, l.reason, cap.cap, bc.currency
      )
      SELECT id, "corpCode", name, market, y, cap, revenue, op, ni, eq,
             total_eq, liab, fcf, dividend,
             revenue_now, revenue_ago, op_now, op_ago, assets,
             px, px3, px12, hi52, lo52, sh, sh3, sh12, sh_hi, sh_lo, liq, volume, volume_ratio, div_year, payout, div_prior, div_before_prior, fs, code, reason, roe_ni, roe_eq, reporting_currency
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

    /// 재무제표가 원 단위임을 확인했는가. 천원으로 적는 회사가 있어 시가총액과
    /// 섞는 지표는 자산총계로 단위를 확인한 뒤에만 낸다 (모르면 내지 않는다).
    bool wonScale(Object? assets) {
      final v = big(assets);
      return v != null && v >= _minAssets;
    }

    int? whole(Object? v) => v == null ? null : double.parse('$v').round();

    /// 상장주식수가 이보다 달라졌으면 종가를 이어 붙이지 않는다 (액면분할·병합,
    /// 큰 유상증자). 조정 주가를 만들 근거가 없으므로 틀린 값을 내느니 비운다.
    const shareTolerance = 0.3;

    bool sameShares(Object? a, Object? b) {
      final x = a == null ? null : double.parse('$a');
      final y = b == null ? null : double.parse('$b');
      if (x == null || y == null || x <= 0 || y <= 0) return false;
      return (x / y - 1).abs() <= shareTolerance;
    }

    /// 지금 값이 [then]보다 몇 % 오르내렸는가. 주식수가 크게 바뀌었으면 비운다.
    double? change(
      Object? now,
      Object? then,
      Object? sharesNow,
      Object? sharesThen,
    ) {
      if (!sameShares(sharesNow, sharesThen)) return null;
      final a = now == null ? null : double.parse('$now');
      final b = then == null ? null : double.parse('$then');
      if (a == null || b == null || b <= 0) return null;
      return 100 * (a - b) / b;
    }

    /// 52주 최저(0)~최고(100) 사이에서 지금 종가의 자리.
    double? position(Object? now, Object? hi, Object? lo) {
      final v = now == null ? null : double.parse('$now');
      final h = hi == null ? null : double.parse('$hi');
      final l = lo == null ? null : double.parse('$lo');
      if (v == null || h == null || l == null || h <= l) return null;
      return 100 * (v - l) / (h - l);
    }

    /// 전년 같은 기간 대비 증감률(%). 작년이 적자(0 이하)면 계산하지 않는다.
    double? growth(Object? now, Object? ago) {
      final a = now == null ? null : double.parse('$now');
      final b = ago == null ? null : double.parse('$ago');
      if (a == null || b == null || b <= 0) return null;
      return 100 * (a - b) / b;
    }

    Map<String, String> notes(List<dynamic> r) {
      final out = <String, String>{};
      void ratioNote(
        String key,
        int top,
        int bottom,
        String nonPositive, {
        bool scale = false,
      }) {
        if (scale && r[41] != null && r[41] != 'KRW') {
          out[key] = '${r[41]} 표시 재무 · 원화 환산 필요';
        } else if (scale && !wonScale(r[18])) {
          out[key] = r[18] == null ? '자산총계 누락 · 금액 단위 확인 불가' : '재무 금액 단위 확인 필요';
        } else if (r[top] == null || r[bottom] == null) {
          out[key] = '계산에 필요한 재무 자료 부족';
        } else if (double.parse('${r[bottom]}') <= 0) {
          out[key] = nonPositive;
        }
      }

      ratioNote('per', 5, 8, '순이익 0 이하 · PER 계산 불가', scale: true);
      ratioNote('pbr', 5, 9, '자본 0 이하 · PBR 계산 불가', scale: true);
      ratioNote('roe', 39, 40, '자본 0 이하 · ROE 계산 불가');
      ratioNote('operatingMargin', 7, 6, '매출액 0 이하');
      ratioNote('debtRatio', 11, 10, '자본 0 이하 · 부채비율 계산 불가');
      ratioNote('fcfYield', 12, 5, '시가총액 0 이하', scale: true);
      ratioNote('revenueGrowth', 14, 15, '전년 매출액 0 이하');
      ratioNote('operatingIncomeGrowth', 16, 17, '전년 영업이익 0 이하');
      return out;
    }

    final universe = [
      for (final r in rows)
        // 시가총액을 모르는 기업은 스크리너에 올리지 않는다 (SQL에서 걸러지지만
        // 한 번 더 막는다 — 값 없이 올리면 정렬이 무너진다).
        if (big(r[5]) != null)
          ScreenRow(
            company: CompanyRef(
              id: r[0] as int,
              corpCode: r[1] as String,
              name: r[2] as String,
              market: r[3] == null ? null : Market.values.byName('${r[3]}'),
            ),
            bsnsYear: r[4] as int,
            metricNotes: notes(r.toList()),
            fsDiv: FsDiv.values.byName(r[36] as String),
            reportCode: FinancialReportCode.values.byName(r[37] as String),
            basisReason: r[38] as String,
            marketCap: big(r[5])!,
            revenue: r[41] == 'KRW' ? big(r[6]) : null,
            operatingIncome: r[41] == 'KRW' ? big(r[7]) : null,
            netIncome: r[41] == 'KRW' ? big(r[8]) : null,
            equity: r[41] == 'KRW' ? big(r[9]) : null,
            totalEquity: r[41] == 'KRW' ? big(r[10]) : null,
            liabilities: r[41] == 'KRW' ? big(r[11]) : null,
            freeCashFlow: r[41] == 'KRW' ? big(r[12]) : null,
            dividendTotal: big(r[13]),
            // 시가총액(원)과 섞는 지표는 재무제표가 원인 것을 확인했을 때만.
            // 자산총계를 모르면 단위를 확인할 수 없으므로 내지 않는다.
            per: r[41] == 'KRW' && wonScale(r[18]) ? divide(r[5], r[8]) : null,
            pbr: r[41] == 'KRW' && wonScale(r[18]) ? divide(r[5], r[9]) : null,
            roe: r[41] == 'MIXED' ? null : divide(r[39], r[40], scale: 100),
            operatingMargin: r[41] == 'MIXED'
                ? null
                : divide(r[7], r[6], scale: 100),
            debtRatio: r[41] == 'MIXED'
                ? null
                : divide(r[11], r[10], scale: 100),
            fcfYield: r[41] == 'KRW' && wonScale(r[18])
                ? divide(r[12], r[5], scale: 100)
                : null,
            dividendYield: wonScale(r[18])
                ? divide(r[13], r[5], scale: 100)
                : null,
            revenueGrowth: r[41] == 'MIXED' ? null : growth(r[14], r[15]),
            operatingIncomeGrowth: r[41] == 'MIXED'
                ? null
                : growth(r[16], r[17]),
            // 주가는 거래소 시세라 단위 문제가 없다.
            closePrice: whole(r[19]),
            return3m: change(r[19], r[20], r[24], r[25]),
            return12m: change(r[19], r[21], r[24], r[26]),
            high52w: r[21] != null && sameShares(r[27], r[28])
                ? whole(r[22])
                : null,
            low52w: r[21] != null && sameShares(r[27], r[28])
                ? whole(r[23])
                : null,
            bandPosition: r[21] != null && sameShares(r[27], r[28])
                ? position(r[19], r[22], r[23])
                : null,
            avgTradingValue: big(r[29]),
            volume: big(r[30]) != null && big(r[30])! >= BigInt.zero
                ? big(r[30])
                : null,
            volumeRatio: r[31] == null ? null : double.parse('${r[31]}'),
            dividendYear: whole(r[32]),
            dividendPayout: r[33] != null && double.parse('${r[33]}') >= 0
                ? double.parse('${r[33]}')
                : null,
            dividendYears: r[13] == null
                ? null
                : double.parse('${r[13]}') <= 0
                ? 0
                : r[34] == null || double.parse('${r[34]}') <= 0
                ? 1
                : r[35] == null || double.parse('${r[35]}') <= 0
                ? 2
                : 3,
          ),
    ];
    if (companyIds == null) {
      _cacheKey = key;
      _cache = universe;
      _baseDate = day?.baseDate;
    }
    return universe;
  }
}
