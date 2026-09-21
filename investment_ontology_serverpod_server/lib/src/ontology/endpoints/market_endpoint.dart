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
