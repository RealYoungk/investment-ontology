import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ingest/company_master_sync.dart';
import '../ingest/ksic_revision.dart';
import '../market/market_caps.dart';

/// 상장사 조회.
class CompanyEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const _listed = {Market.kospi, Market.kosdaq, Market.konex};

  /// 시장·대분류별 상장사 수와 최근 수집 작업.
  Future<Overview> overview(Session session) async {
    final byMarket = <FacetCount>[];
    for (final m in _listed) {
      byMarket.add(
        FacetCount(
          code: m.name,
          name: _marketName(m),
          count: await Company.db.count(
            session,
            where: (t) => t.market.equals(m),
          ),
        ),
      );
    }
    final lastJob = await IngestJob.db.findFirstRow(
      session,
      where: (t) => t.kind.equals(CompanyMasterSync.kind),
      orderBy: (t) => t.startedAt.desc(),
    );
    final lastFull = await CompanyMasterSync.lastFullRefresh(session);
    final revision = await KsicRevision.current(session);
    return Overview(
      totalListed: byMarket.fold(0, (sum, f) => sum + f.count),
      byMarket: byMarket,
      bySection: await _facet(
        session,
        column: 'sectionCode',
        revision: revision.revision,
      ),
      lastJob: lastJob,
      lastFullRefreshAt: lastFull?.finishedAt,
      nextFullRefreshAt: CompanyMasterSync.nextFullRefreshAt(lastFull),
      industryRevision: revision,
    );
  }

  /// 대분류 안의 중분류별 상장사 수.
  Future<List<FacetCount>> divisions(
    Session session,
    String sectionCode, {
    Market? market,
  }) async => _facet(
    session,
    column: 'divisionCode',
    sectionCode: sectionCode,
    market: market,
    revision: (await KsicRevision.current(session)).revision,
  );

  Future<CompanyPage> list(
    Session session, {
    String? query,
    Market? market,
    String? sectionCode,
    String? divisionCode,
    CompanySort? sort,
    int? offset,
    int? limit,
  }) async {
    final order = sort ?? CompanySort.name;
    offset = (offset ?? 0).clamp(0, 1 << 31);
    limit = (limit ?? 50).clamp(1, 200);
    Expression where(CompanyTable t) {
      Expression e = market != null
          ? t.market.equals(market)
          : t.market.inSet(_listed);
      if (sectionCode != null) e = e & t.sectionCode.equals(sectionCode);
      if (divisionCode != null) e = e & t.divisionCode.equals(divisionCode);
      final q = query?.trim();
      if (q != null && q.isNotEmpty) {
        final like = '%${_escapeLike(q)}%';
        e =
            e &
            (t.name.ilike(like) |
                t.nameEng.ilike(like) |
                t.stockCode.like('${_escapeLike(q)}%') |
                t.ceoName.ilike(like));
      }
      return e;
    }

    final total = await Company.db.count(session, where: where);
    final List<Company> rows;
    final Map<int, BigInt> caps;
    if (order == CompanySort.marketCap) {
      // 시가총액은 시세 테이블에 있어, 조건에 맞는 기업 전체의 시총을 구해 정렬한 뒤 자른다.
      final all = await Company.db.find(session, where: where);
      caps = (await MarketCaps.latest(session, {
        for (final c in all) c.id!,
      })).caps;
      all.sort((a, b) {
        final ca = caps[a.id], cb = caps[b.id];
        if (ca == null && cb == null) return a.name.compareTo(b.name);
        if (ca == null) return 1;
        if (cb == null) return -1;
        return cb.compareTo(ca);
      });
      rows = all.skip(offset).take(limit).toList();
    } else {
      rows = await Company.db.find(
        session,
        where: where,
        orderByList: (t) => switch (order) {
          CompanySort.name => [t.name.asc()],
          CompanySort.stockCode => [t.stockCode.asc()],
          CompanySort.establishedDate => [
            t.establishedDate.asc(),
            t.name.asc(),
          ],
          CompanySort.marketCap => [t.name.asc()],
        },
        offset: offset,
        limit: limit,
      );
      caps = (await MarketCaps.latest(session, {
        for (final c in rows) c.id!,
      })).caps;
    }

    final names = await _industryNames(
      session,
      (await KsicRevision.current(session)).revision,
      {
        for (final c in rows) ...[?c.industryCode, ?c.sectionCode],
      },
    );
    return CompanyPage(
      total: total,
      items: [
        for (final c in rows)
          CompanyListItem(
            corpCode: c.corpCode,
            name: c.name,
            stockCode: c.stockCode,
            market: c.market,
            industryCode: c.industryCode,
            industryName: names[c.industryCode],
            sectionCode: c.sectionCode,
            sectionName: names[c.sectionCode],
            ceoName: c.ceoName,
            fiscalMonth: c.fiscalMonth,
            establishedDate: c.establishedDate,
            marketCap: caps[c.id],
          ),
      ],
    );
  }

  Future<CompanyDetail?> detail(Session session, String corpCode) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return null;

    final path = <Industry>[];
    final code = company.industryCode;
    if (code != null) {
      final codes = [
        ?company.sectionCode,
        for (var len = 2; len <= code.length; len++) code.substring(0, len),
      ];
      final revision = (await KsicRevision.current(session)).revision;
      final found = {
        for (final i in await Industry.db.find(
          session,
          where: (t) =>
              t.revision.equals(revision) & t.code.inSet(codes.toSet()),
        ))
          i.code: i,
      };
      path.addAll([for (final c in codes) ?found[c]]);
    }

    final sourceId = company.profileSourceId;
    return CompanyDetail(
      company: company,
      industryPath: path,
      profileSource: sourceId == null
          ? null
          : await Source.db.findById(session, sourceId),
      changes: await CompanyChange.db.find(
        session,
        where: (t) => t.companyId.equals(company.id!),
        orderByList: (t) => [t.changedAt.desc(), t.field.asc()],
        limit: 50,
      ),
    );
  }

  Future<List<FacetCount>> _facet(
    Session session, {
    required String column,
    required String revision,
    String? sectionCode,
    Market? market,
  }) async {
    final markets = market != null ? [market] : _listed;
    final params = <String, dynamic>{
      for (final (i, m) in markets.indexed) 'm$i': m.name,
      'section': ?sectionCode,
    };
    final result = await session.db.unsafeQuery(
      'SELECT "$column" AS code, count(*)::int AS n FROM company '
      'WHERE "market" IN (${[for (var i = 0; i < markets.length; i++) '@m$i'].join(', ')}) '
      '${sectionCode != null ? 'AND "sectionCode" = @section ' : ''}'
      'AND "$column" IS NOT NULL '
      'GROUP BY 1 ORDER BY n DESC',
      parameters: QueryParameters.named(params),
    );
    final counts = [
      for (final row in result)
        (
          code: row.toColumnMap()['code'] as String,
          n: row.toColumnMap()['n'] as int,
        ),
    ];
    final names = await _industryNames(session, revision, {
      for (final c in counts) c.code,
    });
    return [
      for (final c in counts)
        FacetCount(code: c.code, name: names[c.code] ?? c.code, count: c.n),
    ];
  }

  Future<Map<String, String>> _industryNames(
    Session session,
    String revision,
    Set<String> codes,
  ) async {
    if (codes.isEmpty) return {};
    final rows = await Industry.db.find(
      session,
      where: (t) => t.revision.equals(revision) & t.code.inSet(codes),
    );
    return {for (final i in rows) i.code: i.name};
  }

  static String _escapeLike(String s) => s.replaceAllMapped(
    RegExp(r'[\\%_]'),
    (m) => '\\${m[0]}',
  );

  static String _marketName(Market m) => switch (m) {
    Market.kospi => '유가증권',
    Market.kosdaq => '코스닥',
    Market.konex => '코넥스',
    Market.other => '기타',
  };
}
