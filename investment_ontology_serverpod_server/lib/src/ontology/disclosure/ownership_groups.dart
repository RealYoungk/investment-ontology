import '../presentation/company_presentation.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/market_caps.dart';
import 'disclosure_links.dart';

/// 지분으로 이어진 상장사 묶음 ([CompanyGroup]). 각 기업의 가장 최근 사업보고서 기준.
///
/// DB만으로 계산한다 (호출 없음). 묶는 규칙은 [DisclosureLinks.ownershipClusters]와 같다.
class OwnershipGroups {
  OwnershipGroups(this.session);

  final Session session;

  static const _chunk = 1000;

  static String? _cacheKey;
  static List<CompanyGroup>? _cache;

  /// 두 곳 이상으로 이루어진 묶음 전부. 시가총액 합이 큰 순서.
  ///
  /// 주요정보·인물 연결·시세가 바뀌지 않았으면 지난 계산을 그대로 쓴다.
  Future<List<CompanyGroup>> all() async {
    final key = await _dataVersion();
    if (key == _cacheKey && _cache != null) return _cache!;
    final groups = await _compute();
    _cacheKey = key;
    _cache = groups;
    return groups;
  }

  Future<String> _dataVersion() async {
    final rows = await session.db.unsafeQuery('''
      SELECT (SELECT max(id) FROM disclosure_report),
             (SELECT count(*) FROM disclosure_report WHERE "supersededById" IS NOT NULL),
             (SELECT max(id) FROM ontology_relation),
             (SELECT count(*) FROM ontology_relation),
             (SELECT max("baseDate") FROM market_snapshot_day WHERE "rowCount" > 0)
    ''');
    return rows.first.join('|');
  }

  Future<List<CompanyGroup>> _compute() async {
    final (shareholders, investments) = await _currentEntries();
    final root = DisclosureLinks.ownershipClusters(shareholders, investments);
    final members = <int, List<int>>{};
    for (final e in root.entries) {
      (members[e.value] ??= []).add(e.key);
    }
    members.removeWhere((_, ids) => ids.length < 2);
    if (members.isEmpty) return const [];

    final companyIds = {for (final ids in members.values) ...ids};
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) => t.id.inSet(companyIds),
      ))
        c.id!: c,
    };
    final caps = await MarketCaps.latest(session, companyIds);

    final personIds = {
      for (final s in shareholders)
        if (!s.isTotal && s.holderPersonId != null) s.holderPersonId!,
    };
    final persons = personIds.isEmpty
        ? <int, Person>{}
        : {
            for (final p in await Person.db.find(
              session,
              where: (t) => t.id.inSet(personIds),
            ))
              p.id!: p,
          };

    final groups = <CompanyGroup>[];
    for (final e in members.entries) {
      final ids = e.value.toSet();
      final refs = [
        for (final id in ids)
          if (companies[id] case final c?)
            GroupMember(
              company: CompanyRef(
                id: id,
                corpCode: c.corpCode,
                name: c.displayName,
                market: c.market,
              ),
              marketCap: caps.caps[id],
            ),
      ]..sort(_byCapDesc);
      if (refs.length < 2) continue;

      final rawEdges = <GroupEdge>[
        for (final s in shareholders)
          if (DisclosureLinks.clusterShareholder(s) &&
              ids.contains(s.companyId))
            GroupEdge(
              fromCompanyId: s.holderCompanyId!,
              toCompanyId: s.companyId,
              predicate: RelationPredicate.shareholderOf,
              ratio: s.ratioEnd,
              bsnsYear: s.bsnsYear,
            ),
        for (final i in investments)
          if (DisclosureLinks.clusterInvestment(i) && ids.contains(i.companyId))
            GroupEdge(
              fromCompanyId: i.companyId,
              toCompanyId: i.investeeCompanyId!,
              predicate: RelationPredicate.investsIn,
              ratio: i.ratioEnd,
              bsnsYear: i.bsnsYear,
            ),
      ];
      // 같은 두 기업 사이 행이 주식 종류·계정별로 여럿이면 지분율이 가장 큰 것 하나만 남긴다.
      final byPair = <String, GroupEdge>{};
      for (final e in rawEdges) {
        if (e.fromCompanyId == e.toCompanyId) continue;
        final key = '${e.fromCompanyId}|${e.toCompanyId}|${e.predicate.name}';
        final prev = byPair[key];
        if (prev == null || (e.ratio ?? 0) > (prev.ratio ?? 0)) byPair[key] = e;
      }
      final edges = byPair.values.toList();

      final personCompanies = <int, Set<int>>{};
      for (final s in shareholders) {
        if (!s.isTotal &&
            s.holderPersonId != null &&
            ids.contains(s.companyId)) {
          (personCompanies[s.holderPersonId!] ??= {}).add(s.companyId);
        }
      }
      final shared = [
        for (final p in personCompanies.entries)
          if (p.value.length >= 2 && persons[p.key] != null)
            GroupPerson(
              personId: p.key,
              name: persons[p.key]!.name,
              estimated: persons[p.key]!.estimated,
              birthYear: persons[p.key]!.birthYear,
              companyCount: p.value.length,
            ),
      ]..sort((a, b) => b.companyCount.compareTo(a.companyCount));

      final capped = [for (final m in refs) ?m.marketCap];
      groups.add(
        CompanyGroup(
          anchor: refs.first.company,
          members: refs,
          edges: edges,
          totalMarketCap: capped.isEmpty
              ? null
              : capped.reduce((a, b) => a + b),
          baseDate: caps.baseDate,
          sharedPersons: shared,
        ),
      );
    }
    groups.sort(
      (a, b) => (b.totalMarketCap ?? BigInt.zero).compareTo(
        a.totalMarketCap ?? BigInt.zero,
      ),
    );
    return groups;
  }

  static int _byCapDesc(GroupMember a, GroupMember b) {
    final c = (b.marketCap ?? BigInt.from(-1)).compareTo(
      a.marketCap ?? BigInt.from(-1),
    );
    return c != 0 ? c : a.company.name.compareTo(b.company.name);
  }

  Future<(List<ShareholderEntry>, List<InvestmentEntry>)>
  _currentEntries() async {
    final current = await DisclosureLinks(session).currentReports({
      DartSection.largestShareholders,
      DartSection.investments,
    });
    final shareholderReports = [
      for (final r in current[DartSection.largestShareholders]!.values) r.id!,
    ];
    final investmentReports = [
      for (final r in current[DartSection.investments]!.values) r.id!,
    ];
    final shareholders = <ShareholderEntry>[];
    for (var i = 0; i < shareholderReports.length; i += _chunk) {
      final ids = shareholderReports
          .sublist(i, (i + _chunk).clamp(0, shareholderReports.length))
          .toSet();
      shareholders.addAll(
        await ShareholderEntry.db.find(
          session,
          where: (t) => t.reportId.inSet(ids),
        ),
      );
    }
    final investments = <InvestmentEntry>[];
    for (var i = 0; i < investmentReports.length; i += _chunk) {
      final ids = investmentReports
          .sublist(i, (i + _chunk).clamp(0, investmentReports.length))
          .toSet();
      investments.addAll(
        await InvestmentEntry.db.find(
          session,
          where: (t) => t.reportId.inSet(ids),
        ),
      );
    }
    return (shareholders, investments);
  }
}
