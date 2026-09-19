import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disclosure_values.dart';

/// 주요정보의 이름을 기업·인물에 잇고, 그래프 탐색용 관계 색인([OntologyRelation])을 만든다.
///
/// DB만으로 다시 계산할 수 있다 (호출 없음). 각 기업의 가장 최근 사업보고서를 기준으로 한다.
///
/// 인물 연결 규칙:
/// - 임원은 (이름, 출생년월)로 같은 사람을 찾는다 (수집할 때 잇는다).
/// - 주주 이름이 같은 보고서의 임원 한 명과 같으면 그 사람 (확정).
/// - 지분으로 이어진 기업 묶음의 두 곳 이상 주주 명단에 같은 이름이 특수관계인으로 나오면 같은
///   사람으로 본다 (추정). 사람이 끊은 것([PersonLinkRejection])은 묶지 않는다.
class DisclosureLinks {
  DisclosureLinks(this.session);

  final Session session;

  static const listedMarkets = {Market.kospi, Market.kosdaq, Market.konex};

  /// 이보다 큰 기업 묶음은 인물 추정에 쓰지 않는다 (묶음이 커질수록 동명이인 위험이 크다).
  static const maxClusterSize = 80;

  /// 묶음을 만드는 출자: 경영참여 목적이고 지분율이 이 이상.
  static const clusterInvestmentRatio = 15.0;

  /// 주주 관계 문구 가운데 오너 일가·특수관계인을 뜻하는 것.
  static final _relatedParty = RegExp(
    r'최대주주|특수관계|친인척|본인|배우자|자녀|형제|부모|혈족|인척|가족',
  );

  /// 사람 이름으로 볼 수 있는 표기 (한글 2~5자).
  static final _personName = RegExp(r'^[가-힣]{2,5}$');

  static const _chunk = 1000;

  /// 정규화한 이름 → 상장사 id. 이름이 같은 상장사가 둘 이상이면 넣지 않는다.
  static Map<String, int> companiesByName(Iterable<Company> companies) {
    final ids = <String, Set<int>>{};
    for (final c in companies) {
      for (final name in {c.name, ?c.stockName}) {
        final key = DisclosureValues.companyName(name);
        if (key.isNotEmpty) (ids[key] ??= {}).add(c.id!);
      }
    }
    return {
      for (final e in ids.entries)
        if (e.value.length == 1) e.key: e.value.single,
    };
  }

  static String executivePersonKey(String name, int year, int month) =>
      'exec:$name:$year-${month.toString().padLeft(2, '0')}';

  static Future<int> findOrCreatePerson(Session session, Person person) async {
    final found = await Person.db.findFirstRow(
      session,
      where: (t) => t.personKey.equals(person.personKey),
    );
    if (found != null) return found.id!;
    try {
      return (await Person.db.insertRow(session, person)).id!;
    } on DatabaseUniqueViolationException {
      final again = await Person.db.findFirstRow(
        session,
        where: (t) => t.personKey.equals(person.personKey),
      );
      return again!.id!;
    }
  }

  /// 기업마다 항목별 가장 최근(대체되지 않은) 사업보고서.
  Future<Map<DartSection, Map<int, DisclosureReport>>> currentReports(
    Set<DartSection> sections,
  ) async {
    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.supersededById.equals(null) &
          t.reportCode.equals(FinancialReportCode.annual) &
          t.section.inSet(sections),
    );
    final out = {for (final s in sections) s: <int, DisclosureReport>{}};
    for (final r in reports) {
      final byCompany = out[r.section]!;
      final prev = byCompany[r.companyId];
      if (prev == null || r.bsnsYear > prev.bsnsYear) {
        byCompany[r.companyId] = r;
      }
    }
    return out;
  }

  Future<List<T>> _findByReports<T>(
    Set<int> reportIds,
    Future<List<T>> Function(Set<int> ids) find,
  ) async {
    final ids = reportIds.toList();
    final out = <T>[];
    for (var i = 0; i < ids.length; i += _chunk) {
      out.addAll(
        await find(ids.sublist(i, (i + _chunk).clamp(0, ids.length)).toSet()),
      );
    }
    return out;
  }

  /// 인물 연결과 관계 색인을 다시 만든다.
  Future<({int relations, int estimatedLinks})> rebuild() async {
    final current = await currentReports({
      DartSection.largestShareholders,
      DartSection.executives,
      DartSection.investments,
    });
    final shareholderReports = current[DartSection.largestShareholders]!;
    final executiveReports = current[DartSection.executives]!;
    final investmentReports = current[DartSection.investments]!;

    final shareholders = await _findByReports(
      {for (final r in shareholderReports.values) r.id!},
      (ids) => ShareholderEntry.db.find(
        session,
        where: (t) => t.reportId.inSet(ids),
        orderBy: (t) => t.id,
      ),
    );
    final executives = await _findByReports(
      {for (final r in executiveReports.values) r.id!},
      (ids) => ExecutiveEntry.db.find(
        session,
        where: (t) => t.reportId.inSet(ids),
        orderBy: (t) => t.id,
      ),
    );
    final investments = await _findByReports(
      {for (final r in investmentReports.values) r.id!},
      (ids) => InvestmentEntry.db.find(
        session,
        where: (t) => t.reportId.inSet(ids),
        orderBy: (t) => t.id,
      ),
    );
    final companies = {
      for (final c in await Company.db.find(session)) c.id!: c,
    };

    final links = await _personLinks(shareholders, executives, investments);
    final updates = <ShareholderEntry>[];
    for (final s in shareholders) {
      if (s.isTotal || s.holderCompanyId != null) continue;
      final link = links.links[s.id!];
      if (s.holderPersonId != link?.personId ||
          s.holderLinkBasis != link?.basis) {
        updates.add(
          s.copyWith(
            holderPersonId: link?.personId,
            holderLinkBasis: link?.basis,
          ),
        );
      }
    }
    // copyWith(null)은 값을 지우므로, 연결이 없어진 행은 따로 지운다.
    final cleared = [
      for (final u in updates)
        if (links.links[u.id!] == null)
          ShareholderEntry(
            id: u.id,
            reportId: u.reportId,
            companyId: u.companyId,
            bsnsYear: u.bsnsYear,
            ord: u.ord,
            holderName: u.holderName,
            relationText: u.relationText,
            stockKind: u.stockKind,
            sharesBegin: u.sharesBegin,
            ratioBegin: u.ratioBegin,
            sharesEnd: u.sharesEnd,
            ratioEnd: u.ratioEnd,
            remark: u.remark,
            isTotal: u.isTotal,
            holderCompanyId: u.holderCompanyId,
          )
        else
          u,
    ];
    for (var i = 0; i < cleared.length; i += _chunk) {
      await ShareholderEntry.db.update(
        session,
        cleared.sublist(i, (i + _chunk).clamp(0, cleared.length)),
      );
    }
    final linked = {for (final s in shareholders) s.id!: s};
    for (final u in cleared) {
      linked[u.id!] = u;
    }

    final relations = <OntologyRelation>[
      ..._shareholderRelations(linked.values, shareholderReports, companies),
      for (final e in executives)
        if (executiveReports[e.companyId] case final report?)
          OntologyRelation(
            predicate: RelationPredicate.executiveOf,
            subjectPersonId: e.personId,
            subjectName: e.name,
            objectCompanyId: e.companyId,
            objectName: companies[e.companyId]?.name ?? '',
            asOf: report.settlementDate,
            bsnsYear: report.bsnsYear,
            sourceId: report.sourceId,
            factKind: RelationFactKind.executiveEntry,
            factId: e.id!,
            extractedBy: RelationOrigin.api,
            status: RelationStatus.verified,
          ),
      for (final i in investments)
        if (!i.isTotal && investmentReports[i.companyId] != null)
          OntologyRelation(
            predicate: RelationPredicate.investsIn,
            subjectCompanyId: i.companyId,
            subjectName: companies[i.companyId]?.name ?? '',
            objectCompanyId: i.investeeCompanyId,
            objectName: i.investeeName,
            asOf: investmentReports[i.companyId]!.settlementDate,
            bsnsYear: investmentReports[i.companyId]!.bsnsYear,
            weight: i.ratioEnd,
            sourceId: investmentReports[i.companyId]!.sourceId,
            factKind: RelationFactKind.investmentEntry,
            factId: i.id!,
            extractedBy: RelationOrigin.api,
            status: RelationStatus.verified,
          ),
    ];

    await session.db.transaction((tx) async {
      await OntologyRelation.db.deleteWhere(
        session,
        where: (t) => t.extractedBy.equals(RelationOrigin.api),
        transaction: tx,
      );
      for (var i = 0; i < relations.length; i += _chunk) {
        await OntologyRelation.db.insert(
          session,
          relations.sublist(i, (i + _chunk).clamp(0, relations.length)),
          transaction: tx,
        );
      }
    });

    // 더 이상 어느 주주 행도 가리키지 않는 추정 인물은 지운다.
    await session.db.unsafeExecute(
      'DELETE FROM "person" WHERE "estimated" = TRUE AND "id" NOT IN '
      '(SELECT "holderPersonId" FROM "shareholder_entry" '
      'WHERE "holderPersonId" IS NOT NULL)',
    );
    return (relations: relations.length, estimatedLinks: links.estimated);
  }

  /// 한 기업의 한 주주(기업·인물·이름)를 관계 하나로 묶는다. 지분율은 보통주 합.
  Iterable<OntologyRelation> _shareholderRelations(
    Iterable<ShareholderEntry> rows,
    Map<int, DisclosureReport> reports,
    Map<int, Company> companies,
  ) sync* {
    final groups = <String, List<ShareholderEntry>>{};
    for (final s in rows) {
      if (s.isTotal) continue;
      final holder = s.holderCompanyId != null
          ? 'c${s.holderCompanyId}'
          : s.holderPersonId != null
          ? 'p${s.holderPersonId}'
          : 'n${DisclosureValues.personName(s.holderName)}';
      (groups['${s.companyId}|$holder'] ??= []).add(s);
    }
    for (final g in groups.values) {
      final first = g.first;
      final report = reports[first.companyId];
      if (report == null) continue;
      final common = [
        for (final s in g)
          if (isCommonStock(s.stockKind) && s.ratioEnd != null) s.ratioEnd!,
      ];
      final estimated =
          first.holderLinkBasis == DisclosureLinkBasis.ownershipCluster;
      yield OntologyRelation(
        predicate: RelationPredicate.shareholderOf,
        subjectCompanyId: first.holderCompanyId,
        subjectPersonId: first.holderPersonId,
        subjectName: first.holderCompanyId != null
            ? companies[first.holderCompanyId]?.name ?? first.holderName
            : first.holderName,
        objectCompanyId: first.companyId,
        objectName: companies[first.companyId]?.name ?? '',
        asOf: report.settlementDate,
        bsnsYear: report.bsnsYear,
        weight: common.isEmpty ? null : common.fold<double>(0, (a, b) => a + b),
        sourceId: report.sourceId,
        factKind: RelationFactKind.shareholderEntry,
        factId: first.id!,
        extractedBy: RelationOrigin.api,
        status: estimated ? RelationStatus.draft : RelationStatus.verified,
        subjectBasis: first.holderLinkBasis,
      );
    }
  }

  /// 보통주로 볼 표기 (보통주, 의결권 있는 주식). 표기가 없으면 보통주로 본다.
  static bool isCommonStock(String? kind) {
    if (kind == null) return true;
    final k = kind.replaceAll(' ', '');
    return k.contains('보통') || (k.contains('의결권') && !k.contains('없'));
  }

  /// 주주 행 id → 인물 연결.
  Future<
    ({
      Map<int, ({int personId, DisclosureLinkBasis basis})> links,
      int estimated,
    })
  >
  _personLinks(
    List<ShareholderEntry> shareholders,
    List<ExecutiveEntry> executives,
    List<InvestmentEntry> investments,
  ) async {
    final links = <int, ({int personId, DisclosureLinkBasis basis})>{};

    // 1. 같은 보고서(같은 기업·사업연도)의 임원 한 명과 같은 이름.
    final execByCompany = <int, Map<String, Set<int>>>{};
    final execYear = <int, int>{};
    for (final e in executives) {
      if (e.personId == null) continue;
      final byName = execByCompany[e.companyId] ??= {};
      (byName[DisclosureValues.personName(e.name)] ??= {}).add(e.personId!);
      execYear[e.companyId] = e.bsnsYear;
    }
    final candidates = <ShareholderEntry>[];
    for (final s in shareholders) {
      if (s.isTotal || s.holderCompanyId != null) continue;
      final name = DisclosureValues.personName(s.holderName);
      final same = execYear[s.companyId] == s.bsnsYear
          ? (execByCompany[s.companyId]?[name])
          : null;
      if (same != null && same.length == 1) {
        links[s.id!] = (
          personId: same.single,
          basis: DisclosureLinkBasis.executiveSameReport,
        );
      } else {
        candidates.add(s);
      }
    }

    // 2. 지분으로 이어진 기업 묶음.
    final parent = <int, int>{};
    int find(int x) {
      var r = parent[x] ??= x;
      while (r != parent[r]) {
        r = parent[r]!;
      }
      parent[x] = r;
      return r;
    }

    void union(int a, int b) {
      final ra = find(a), rb = find(b);
      if (ra != rb) parent[ra] = rb;
    }

    for (final s in shareholders) {
      if (!s.isTotal && s.holderCompanyId != null) {
        union(s.companyId, s.holderCompanyId!);
      }
    }
    for (final i in investments) {
      if (!i.isTotal &&
          i.investeeCompanyId != null &&
          (i.purpose?.contains('경영') ?? false) &&
          (i.ratioEnd ?? 0) >= clusterInvestmentRatio) {
        union(i.companyId, i.investeeCompanyId!);
      }
    }
    final size = <int, int>{};
    for (final x in parent.keys.toList()) {
      size[find(x)] = (size[find(x)] ?? 0) + 1;
    }

    final rejected = {
      for (final r in await PersonLinkRejection.db.find(session))
        '${r.companyId}|${r.name}',
    };
    final groups = <String, List<ShareholderEntry>>{};
    for (final s in candidates) {
      final name = DisclosureValues.personName(s.holderName);
      if (!_personName.hasMatch(name)) continue;
      if (!_relatedParty.hasMatch(s.relationText ?? '')) continue;
      if (rejected.contains('${s.companyId}|$name')) continue;
      if (!parent.containsKey(s.companyId)) continue;
      final root = find(s.companyId);
      if ((size[root] ?? 0) > maxClusterSize) continue;
      (groups['$root|$name'] ??= []).add(s);
    }

    final companies = {
      for (final c in await Company.db.find(session)) c.id!: c.corpCode,
    };
    var estimated = 0;
    for (final g in groups.values) {
      final companyIds = {for (final s in g) s.companyId};
      if (companyIds.length < 2) continue;
      final name = DisclosureValues.personName(g.first.holderName);
      // 묶음 안 임원 가운데 같은 이름이 한 사람뿐이면 그 사람 (출생년월이 있는 인물).
      final execPersons = {
        for (final id in companyIds) ...?execByCompany[id]?[name],
      };
      final int personId;
      if (execPersons.length == 1) {
        personId = execPersons.single;
      } else {
        final anchor = ([
          for (final id in companyIds) companies[id] ?? '$id',
        ]..sort()).first;
        personId = await findOrCreatePerson(
          session,
          Person(
            name: name,
            personKey: 'cluster:$name:$anchor',
            estimated: true,
          ),
        );
      }
      for (final s in g) {
        links[s.id!] = (
          personId: personId,
          basis: DisclosureLinkBasis.ownershipCluster,
        );
        estimated++;
      }
    }

    return (links: links, estimated: estimated);
  }
}
