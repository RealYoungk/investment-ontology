import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ingest/ksic_revision.dart';

/// 시세 조회.
class MarketEndpoint extends Endpoint {
  static const _listed = {Market.kospi, Market.kosdaq, Market.konex};

  /// 업종 코드가 없는 기업의 묶음 코드.
  static const unclassifiedCode = '-';

  /// 첫 화면에서 대분류마다 이름을 적어 보여 줄 기업 수. 나머지는 '그 외'로 묶인다.
  static const _topCompanies = 40;

  /// 가장 최근 기준일의 업종별 시가총액.
  ///
  /// 기업 시가총액은 기업에 연결된 종목(보통주·우선주 등) 시가총액의 합이다.
  /// [sectionCode]가 없으면 대분류 → 그 안 시가총액 상위 기업, 있으면 그 대분류의
  /// 중분류 → 기업으로 묶는다. 화면에 다 그릴 수 없어 대분류마다 [_topCompanies]개까지만 보낸다.
  Future<MarketCapTreemap> industryTreemap(
    Session session, {
    String? sectionCode,
    Market? market,
  }) async {
    final revision = (await KsicRevision.current(session)).revision;
    final latestDay = await MarketSnapshotDay.db.findFirstRow(
      session,
      where: (t) => t.rowCount > 0,
      orderBy: (t) => t.baseDate.desc(),
    );
    String? sectionName;
    if (sectionCode != null) {
      sectionName = (await Industry.db.findFirstRow(
        session,
        where: (t) => t.revision.equals(revision) & t.code.equals(sectionCode),
      ))?.name;
    }
    if (latestDay == null) {
      return MarketCapTreemap(
        sectionCode: sectionCode,
        sectionName: sectionName,
        market: market,
        total: BigInt.zero,
        nodes: const [],
        unlinkedSecurityCount: 0,
        unlinkedMarketCap: BigInt.zero,
        industryRevision: revision,
      );
    }

    final snapshots = await MarketSnapshot.db.find(
      session,
      where: (t) => t.baseDate.equals(latestDay.baseDate),
    );
    final securities = {
      for (final s in await Security.db.find(session)) s.id!: s,
    };
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) =>
            market != null ? t.market.equals(market) : t.market.inSet(_listed),
      ))
        c.id!: c,
    };

    final capByCompany = <int, BigInt>{};
    var unlinkedCount = 0;
    var unlinkedCap = BigInt.zero;
    for (final snap in snapshots) {
      final cap = snap.marketCap;
      if (cap == null) continue;
      final security = securities[snap.securityId];
      final companyId = security?.companyId;
      if (companyId == null) {
        if (market == null || security?.market == market) {
          unlinkedCount++;
          unlinkedCap += cap;
        }
        continue;
      }
      if (!companies.containsKey(companyId)) continue;
      capByCompany[companyId] = (capByCompany[companyId] ?? BigInt.zero) + cap;
    }

    // 묶음 키: (상위 코드, 하위 코드).
    final groups = <String, Map<String, List<(Company, BigInt)>>>{};
    capByCompany.forEach((id, cap) {
      final c = companies[id]!;
      final section = c.sectionCode ?? unclassifiedCode;
      if (sectionCode != null && section != sectionCode) return;
      final division = c.divisionCode ?? unclassifiedCode;
      final outer = sectionCode == null ? section : division;
      final inner = sectionCode == null ? division : c.corpCode;
      ((groups[outer] ??= {})[inner] ??= []).add((c, cap));
    });

    final codes = {
      for (final e in groups.entries) ...[e.key, ...e.value.keys],
    }..remove(unclassifiedCode);
    final names = {
      for (final i in await Industry.db.find(
        session,
        where: (t) => t.revision.equals(revision) & t.code.inSet(codes),
      ))
        i.code: i.name,
    };
    String nameOf(String code) =>
        code == unclassifiedCode ? '업종 미분류' : names[code] ?? code;

    BigInt sum(Iterable<BigInt> caps) =>
        caps.fold(BigInt.zero, (a, b) => a + b);
    int byCap(MarketCapNode a, MarketCapNode b) =>
        b.marketCap.compareTo(a.marketCap);

    final nodes = [
      for (final outer in groups.entries)
        MarketCapNode(
          code: outer.key,
          name: nameOf(outer.key),
          marketCap: sum([
            for (final list in outer.value.values)
              for (final (_, cap) in list) cap,
          ]),
          companyCount: outer.value.values.fold(0, (n, l) => n + l.length),
          children:
              sectionCode == null
                    ? _topOf(outer.value)
                    : [
                        for (final inner in outer.value.entries)
                          for (final (company, cap) in inner.value)
                            _companyNode(company, cap),
                      ]
                ..sort(byCap),
        ),
    ]..sort(byCap);

    return MarketCapTreemap(
      baseDate: latestDay.baseDate,
      source: latestDay.sourceId == null
          ? null
          : await Source.db.findById(session, latestDay.sourceId!),
      sectionCode: sectionCode,
      sectionName: sectionName,
      market: market,
      total: sum([for (final n in nodes) n.marketCap]),
      nodes: nodes,
      unlinkedSecurityCount: unlinkedCount,
      unlinkedMarketCap: unlinkedCap,
      industryRevision: revision,
    );
  }

  /// 시장 전체 시가총액의 추이 ([days] 달력일).
  ///
  /// 그 기준일에 시세가 있는 종목의 시가총액 합이다. 상장·폐지로 종목 수가 달라지므로
  /// 지수가 아니라 "그날 시장에 얼마가 있었는가"로 읽는다. 종목 수도 함께 준다.
  Future<List<MarketCapPoint>> capHistory(
    Session session, {
    Market? market,
    int days = 365,
  }) async {
    final filter = market == null ? '' : "AND c.market = '${market.name}'";
    final window = days.clamp(30, 3660);
    final rows = await session.db.unsafeQuery('''
      SELECT m."baseDate", sum(m."marketCap"::numeric) AS cap, count(*) AS n
      FROM market_snapshot m
      JOIN security s ON s.id = m."securityId"
      LEFT JOIN company c ON c.id = s."companyId"
      WHERE m."marketCap" IS NOT NULL
        AND m."baseDate" > (
          SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0
        ) - interval '$window days'
        $filter
      GROUP BY 1
      ORDER BY 1
    ''');
    final all = [
      for (final r in rows)
        MarketCapPoint(
          date: r[0] as DateTime,
          marketCap: BigInt.parse('${r[1]}'.split('.').first),
          securityCount: int.parse('${r[2]}'),
        ),
    ];
    if (all.length <= _pricePoints) return all;
    // 마지막 거래일이 반드시 남게 뒤에서부터 고른다.
    final stride = (all.length / _pricePoints).ceil();
    return [for (var i = all.length - 1; i >= 0; i -= stride) all[i]].reversed
        .toList();
  }

  /// 상장주식수가 이보다 달라졌으면 종가를 이어 붙이지 않는다 (스크리너와 같은 규칙).
  static const shareTolerance = 0.3;

  /// 화면에 그릴 점 수의 목표. 거래일이 이보다 많으면 일정 간격으로 골라 보낸다.
  static const _pricePoints = 260;

  /// 기업 대표 종목의 종가 추이 ([days] 거래일 아닌 달력일 기준).
  ///
  /// 기업에 종목이 여럿이면(보통주·우선주) 가장 최근 시가총액이 큰 쪽을 대표로 쓴다.
  /// 5년치는 1,200일이 넘으므로 [_pricePoints]개 안팎으로 솎아 보낸다 — 마지막 점은
  /// 늘 최근 거래일이다.
  Future<PriceHistory?> priceHistory(
    Session session,
    String corpCode, {
    int days = 365,
  }) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return null;
    final securities = await Security.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    if (securities.isEmpty) return null;

    final latestDay = await MarketSnapshotDay.db.findFirstRow(
      session,
      where: (t) => t.rowCount > 0,
      orderBy: (t) => t.baseDate.desc(),
    );
    if (latestDay == null) return null;

    // 대표 종목: 가장 최근 기준일 시가총액이 큰 쪽.
    final latest = await MarketSnapshot.db.find(
      session,
      where: (t) =>
          t.securityId.inSet({for (final s in securities) s.id!}) &
          t.baseDate.equals(latestDay.baseDate),
    );
    latest.sort(
      (a, b) =>
          (b.marketCap ?? BigInt.zero).compareTo(a.marketCap ?? BigInt.zero),
    );
    final securityId = latest.isEmpty
        ? securities.first.id!
        : latest.first.securityId;
    final security = securities.firstWhere((s) => s.id == securityId);

    final from = latestDay.baseDate.subtract(
      Duration(days: days.clamp(30, 3660)),
    );
    final rows = await MarketSnapshot.db.find(
      session,
      where: (t) => t.securityId.equals(securityId) & (t.baseDate >= from),
      orderBy: (t) => t.baseDate,
    );
    final closes = [
      for (final r in rows)
        if (r.closePrice != null) (r.baseDate, r.closePrice!.toInt()),
    ];
    if (closes.isEmpty) return null;
    final stride = (closes.length / _pricePoints).ceil().clamp(1, 60);
    // 뒤에서부터 골라 마지막 거래일이 반드시 남게 한다.
    final picked = [
      for (var i = closes.length - 1; i >= 0; i -= stride) closes[i],
    ].reversed;
    // 52주 고저. 액면분할·병합이 있으면 종가를 이어 붙일 수 없어 비운다.
    final yearAgo = latestDay.baseDate.subtract(const Duration(days: 365));
    final year = [
      for (final r in rows)
        if (r.baseDate.isAfter(yearAgo) && r.closePrice != null) r,
    ];
    int? high, low;
    double? band;
    if (year.isNotEmpty) {
      final shares = [for (final r in year) ?r.listedShares];
      final okShares =
          shares.length == year.length &&
          shares.every(
            (s) =>
                s > BigInt.zero &&
                (s.toDouble() / shares.last.toDouble() - 1).abs() <=
                    shareTolerance,
          );
      if (okShares) {
        final closes = [for (final r in year) r.closePrice!.toInt()];
        high = closes.reduce((a, b) => a > b ? a : b);
        low = closes.reduce((a, b) => a < b ? a : b);
        final now = closes.last;
        band = high > low ? 100 * (now - low) / (high - low) : null;
      }
    }

    return PriceHistory(
      securityName: security.name,
      shortCode: security.shortCode,
      stride: stride,
      points: [
        for (final (date, close) in picked)
          PricePoint(date: date, close: close),
      ],
      high52w: high,
      low52w: low,
      bandPosition: band,
    );
  }

  static MarketCapNode _companyNode(Company company, BigInt cap) =>
      MarketCapNode(
        code: company.corpCode,
        name: company.name,
        marketCap: cap,
        companyCount: 1,
        market: company.market,
        children: const [],
      );

  /// 대분류 안 기업을 시가총액 순으로 [_topCompanies]개까지.
  static List<MarketCapNode> _topOf(
    Map<String, List<(Company, BigInt)>> byDivision,
  ) {
    final all = [
      for (final list in byDivision.values)
        for (final (company, cap) in list) _companyNode(company, cap),
    ]..sort((a, b) => b.marketCap.compareTo(a.marketCap));
    return all.length <= _topCompanies ? all : all.sublist(0, _topCompanies);
  }
}
