import '../presentation/company_presentation.dart';

import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../disclosure/disclosure_values.dart';
import '../governance/ownership_period.dart';
import '../governance/ownership_history.dart';

/// 지배구조 조회: 최대주주 · 임원 · 타법인출자와 인물.
class GovernanceEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static const _sections = {
    DartSection.largestShareholders,
    DartSection.executives,
    DartSection.investments,
  };

  /// 기업의 한 사업연도(없으면 가장 최근) 지배구조.
  Future<CompanyGovernance?> summary(
    Session session,
    String corpCode, {
    int? bsnsYear,
  }) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return null;
    final companyId = company.id!;

    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(companyId) &
          t.supersededById.equals(null) &
          t.section.inSet(_sections),
    );
    // 보고서 접수일이 아니라 대상 기간을 먼저 비교한다. 과거 정정공시가
    // 최신 반기 현황을 덮거나 서로 다른 기간의 항목을 섞지 않도록 한다.
    int periodRank(FinancialReportCode code) => switch (code) {
      FinancialReportCode.q1 => 1,
      FinancialReportCode.halfYear => 2,
      FinancialReportCode.q3 => 3,
      FinancialReportCode.annual => 4,
    };
    reports.sort((a, b) {
      final yearOrder = b.bsnsYear.compareTo(a.bsnsYear);
      if (yearOrder != 0) return yearOrder;
      final periodOrder = periodRank(b.reportCode)
          .compareTo(periodRank(a.reportCode));
      if (periodOrder != 0) return periodOrder;
      return b.rceptNo.compareTo(a.rceptNo);
    });
    final years = {for (final r in reports) r.bsnsYear}.toList()
      ..sort((a, b) => b.compareTo(a));
    final year = bsnsYear != null && years.contains(bsnsYear)
        ? bsnsYear
        : years.firstOrNull;

    final selected = reports.where((r) => r.bsnsYear == year).firstOrNull;
    DisclosureReport? report(DartSection s) => reports
        .where(
          (r) => r.section == s && r.rceptNo == selected?.rceptNo,
        )
        .firstOrNull;
    final shareholderReport = report(DartSection.largestShareholders);
    final executiveReport = report(DartSection.executives);
    final investmentReport = report(DartSection.investments);

    final shareholders = shareholderReport == null
        ? <ShareholderEntry>[]
        : await ShareholderEntry.db.find(
            session,
            where: (t) => t.reportId.equals(shareholderReport.id!),
            orderBy: (t) => t.ord,
          );
    final executives = executiveReport == null
        ? <ExecutiveEntry>[]
        : await ExecutiveEntry.db.find(
            session,
            where: (t) => t.reportId.equals(executiveReport.id!),
            orderBy: (t) => t.ord,
          );
    final investments = investmentReport == null
        ? <InvestmentEntry>[]
        : await InvestmentEntry.db.find(
            session,
            where: (t) => t.reportId.equals(investmentReport.id!),
            orderBy: (t) => t.ord,
          );

    // 다른 기업의 보고서에서 역으로: 이 기업에 출자한 기업, 이 기업이 주주인 기업.
    final investorRelations = await OntologyRelation.db.find(
      session,
      where: (t) =>
          t.objectCompanyId.equals(companyId) &
          t.predicate.equals(RelationPredicate.investsIn) &
          t.subjectCompanyId.notEquals(companyId),
      orderByList: (t) => [t.weight.desc()],
    );
    final holdingRelations = await OntologyRelation.db.find(
      session,
      where: (t) =>
          t.subjectCompanyId.equals(companyId) &
          t.predicate.equals(RelationPredicate.shareholderOf) &
          t.objectCompanyId.notEquals(companyId),
      orderByList: (t) => [t.weight.desc()],
    );

    final companyIds = <int>{
      for (final s in shareholders) ?s.holderCompanyId,
      for (final i in investments) ?i.investeeCompanyId,
      for (final r in investorRelations) ?r.subjectCompanyId,
      for (final r in holdingRelations) ?r.objectCompanyId,
    };
    final companies = await _companyRefs(session, companyIds);
    final corpCodes = {for (final c in companies) c.id: c.corpCode};

    GovernanceLink link(OntologyRelation r, int? otherId) => GovernanceLink(
      predicate: r.predicate,
      companyId: otherId,
      corpCode: otherId == null ? null : corpCodes[otherId],
      name: otherId == r.subjectCompanyId ? r.subjectName : r.objectName,
      weight: r.weight,
      bsnsYear: r.bsnsYear,
      relationId: r.id!,
    );

    final personIds = <int>{
      for (final s in shareholders) ?s.holderPersonId,
      for (final e in executives) ?e.personId,
    };
    final sourceIds = {
      for (final r in [shareholderReport, executiveReport, investmentReport])
        ?r?.sourceId,
    };

    // 소액주주 현황: 그 해 보고서의 '소액주주' 줄 (사람 수와 보유 지분율).
    final minority = await DisclosureReport.db.findFirstRow(
      session,
      where: (t) =>
          t.companyId.equals(companyId) &
          t.section.equals(DartSection.minorityShareholders) &
          t.supersededById.equals(null) &
          t.rceptNo.equals(selected?.rceptNo ?? ''),
      orderBy: (t) => t.bsnsYear.desc(),
    );
    final minorityRow = minority == null
        ? null
        : (await DisclosureRow.db.find(
            session,
            where: (t) => t.reportId.equals(minority.id!),
            orderBy: (t) => t.ord,
          )).firstOrNull;
    final minorityJson = minorityRow == null
        ? null
        : jsonDecode(minorityRow.rowJson) as Map<String, dynamic>;

    return CompanyGovernance(
      minorityHolders: DisclosureValues.integer(
        minorityJson?['shrholdr_co'],
      )?.toInt(),
      minorityRatio: DisclosureValues.decimal(
        minorityJson?['hold_stock_rate'],
      ),
      corpCode: corpCode,
      bsnsYear: year,
      settlementDate: (shareholderReport ?? executiveReport ?? investmentReport)
          ?.settlementDate,
      shareholderPeriodStart: ownershipPeriodStart(
        shareholderReport?.settlementDate,
        reports
            .where(
              (r) =>
                  r.section == DartSection.largestShareholders &&
                  r.reportCode == FinancialReportCode.annual &&
                  shareholderReport != null &&
                  r.bsnsYear < shareholderReport.bsnsYear,
            )
            .map((r) => r.settlementDate)
            .nonNulls,
      ),
      shareholderPeriodEnd: shareholderReport?.settlementDate,
      availableYears: years,
      shareholders: shareholders,
      executives: executives,
      investments: investments,
      investors: [
        for (final r in investorRelations) link(r, r.subjectCompanyId),
      ],
      holdings: [for (final r in holdingRelations) link(r, r.objectCompanyId)],
      companies: companies,
      persons: personIds.isEmpty
          ? []
          : await Person.db.find(
              session,
              where: (t) => t.id.inSet(personIds),
            ),
      sources: sourceIds.isEmpty
          ? []
          : await Source.db.find(session, where: (t) => t.id.inSet(sourceIds)),
    );
  }

  /// 최근 5개 사업연도 말과 그 이후의 최신 분기/반기 최대주주 현황.
  /// 수집되지 않은 기간도 남기며 보고서 발표일로 기간 순서를 뒤집지 않는다.
  Future<List<OwnershipSnapshot>> ownershipHistory(
    Session session,
    String corpCode,
  ) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return [];
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.bsnsYear.notEquals(null) &
          t.reportCode.notEquals(null),
    );
    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.supersededById.equals(null) &
          t.section.inSet({
            DartSection.largestShareholders,
            DartSection.businessContent,
          }),
    );
    final holders = reports
        .where((r) => r.section == DartSection.largestShareholders)
        .toList();
    final selected = selectOwnershipFilings(filings, corpCode);
    final ids = {for (final r in holders) r.id!};
    final rows = ids.isEmpty
        ? <ShareholderEntry>[]
        : await ShareholderEntry.db.find(
            session,
            where: (t) => t.reportId.inSet(ids),
            orderBy: (t) => t.ord,
          );
    final sourceIds = {for (final r in holders) r.sourceId};
    final sources = sourceIds.isEmpty
        ? <Source>[]
        : await Source.db.find(session, where: (t) => t.id.inSet(sourceIds));
    return [
      for (final filing in selected)
        (() {
          // Exact filing only: an uncollected correction must not silently show stale rows.
          final report = holders
              .where((r) => r.rceptNo == filing.rceptNo)
              .firstOrNull;
          final end =
              report?.settlementDate ??
              reports
                  .where((r) => r.rceptNo == filing.rceptNo)
                  .firstOrNull
                  ?.settlementDate;
          final previousAnnualEnds = reports
              .where(
                (r) =>
                    r.reportCode == FinancialReportCode.annual &&
                    r.bsnsYear < filing.bsnsYear!,
              )
              .map((r) => r.settlementDate)
              .nonNulls;
          return OwnershipSnapshot(
            bsnsYear: filing.bsnsYear!,
            reportCode: filing.reportCode!,
            reportName: filing.reportName,
            rceptNo: filing.rceptNo,
            periodStart: ownershipPeriodStart(end, previousAnnualEnds),
            periodEnd: end,
            collected: report != null,
            shareholders: report == null
                ? []
                : rows.where((r) => r.reportId == report.id).toList(),
            source: sources.where((s) => s.id == report?.sourceId).firstOrNull,
          );
        })(),
    ];
  }

  /// 이름으로 인물을 찾는다. 이어진 기업이 많은 순서로 [limit]명.
  Future<List<PersonHit>> searchPersons(
    Session session,
    String query, {
    int? limit,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final rows = await session.db.unsafeQuery(
      'SELECT p.id, p.name, p.estimated, p."birthYear", p."birthMonth", '
      'count(DISTINCT r."objectCompanyId")::int AS n, '
      '(array_agg(DISTINCT c.name))[1:3] AS names '
      'FROM person p '
      'JOIN ontology_relation r ON r."subjectPersonId" = p.id '
      'JOIN company c ON c.id = r."objectCompanyId" '
      'WHERE p.name LIKE @q '
      'GROUP BY p.id ORDER BY n DESC, p.name LIMIT @limit',
      parameters: QueryParameters.named({
        'q': '${q.replaceAll('%', '').replaceAll('_', '')}%',
        'limit': (limit ?? 5).clamp(1, 20),
      }),
    );
    return [
      for (final r in rows)
        PersonHit(
          personId: r[0] as int,
          name: r[1] as String,
          estimated: r[2] as bool,
          birthYear: r[3] as int?,
          birthMonth: r[4] as int?,
          companyCount: r[5] as int,
          companyNames: [for (final n in (r[6] as List? ?? const [])) '$n'],
        ),
    ];
  }

  /// 인물과 그가 주주·임원으로 있는 기업 (각 기업의 가장 최근 사업보고서 기준).
  Future<PersonProfile?> person(Session session, int personId) async {
    final person = await Person.db.findById(session, personId);
    if (person == null) return null;
    final relations = await OntologyRelation.db.find(
      session,
      where: (t) =>
          t.subjectPersonId.equals(personId) &
          t.status.notEquals(RelationStatus.rejected),
    );
    final companies = {
      for (final c in await _companyRefs(session, {
        for (final r in relations) ?r.objectCompanyId,
      }))
        c.id: c,
    };
    final shareholderIds = {
      for (final r in relations)
        if (r.factKind == RelationFactKind.shareholderEntry) r.factId,
    };
    final executiveIds = {
      for (final r in relations)
        if (r.factKind == RelationFactKind.executiveEntry) r.factId,
    };
    final shareholders = {
      for (final s
          in shareholderIds.isEmpty
              ? const <ShareholderEntry>[]
              : await ShareholderEntry.db.find(
                  session,
                  where: (t) => t.id.inSet(shareholderIds),
                ))
        s.id!: s,
    };
    final executives = {
      for (final e
          in executiveIds.isEmpty
              ? const <ExecutiveEntry>[]
              : await ExecutiveEntry.db.find(
                  session,
                  where: (t) => t.id.inSet(executiveIds),
                ))
        e.id!: e,
    };

    final roles = <PersonRole>[
      for (final r in relations)
        if (companies[r.objectCompanyId] case final company?)
          () {
            final s = r.factKind == RelationFactKind.shareholderEntry
                ? shareholders[r.factId]
                : null;
            final e = r.factKind == RelationFactKind.executiveEntry
                ? executives[r.factId]
                : null;
            return PersonRole(
              predicate: r.predicate,
              companyId: company.id,
              corpCode: company.corpCode,
              companyName: company.name,
              bsnsYear: r.bsnsYear,
              weight: r.weight,
              position: e?.position,
              registration: e?.registration,
              detail: s?.relationText ?? e?.duties,
              basis: r.subjectBasis,
              estimated: r.status == RelationStatus.draft,
            );
          }(),
    ]..sort((a, b) => (b.weight ?? -1).compareTo(a.weight ?? -1));
    return PersonProfile(person: person, roles: roles);
  }

  /// 추정 인물 연결을 끊는다: 이 기업의 이 이름은 다시 계산해도 묶지 않는다.
  Future<void> rejectPersonLink(
    Session session,
    String corpCode,
    String holderName,
  ) async {
    OntologyAccess.requireAdmin(session);
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return;
    final name = DisclosureValues.personName(holderName);
    if (name.isEmpty) return;
    await session.db.unsafeExecute(
      'INSERT INTO "person_link_rejection" ("companyId", "name", "createdAt") '
      'VALUES (@company, @name, NOW()) ON CONFLICT DO NOTHING',
      parameters: QueryParameters.named({
        'company': company.id!,
        'name': name,
      }),
    );
    // 다음 전체 계산을 기다리지 않고 이 기업의 추정 연결을 바로 푼다.
    final rows = [
      for (final s in await ShareholderEntry.db.find(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.holderLinkBasis.equals(DisclosureLinkBasis.ownershipCluster),
      ))
        if (DisclosureValues.personName(s.holderName) == name) s,
    ];
    if (rows.isEmpty) return;
    final ids = {for (final s in rows) s.id!};
    await session.db.unsafeExecute(
      'UPDATE "shareholder_entry" SET "holderPersonId" = NULL, '
      '"holderLinkBasis" = NULL WHERE "id" = ANY(@ids)',
      parameters: QueryParameters.named({'ids': ids.toList()}),
    );
    await session.db.unsafeExecute(
      'UPDATE "ontology_relation" SET "subjectPersonId" = NULL, '
      '"subjectBasis" = NULL, "status" = @status '
      'WHERE "factKind" = @kind AND "factId" = ANY(@ids)',
      parameters: QueryParameters.named({
        'status': RelationStatus.verified.name,
        'kind': RelationFactKind.shareholderEntry.name,
        'ids': ids.toList(),
      }),
    );
  }

  static Future<List<CompanyRef>> _companyRefs(
    Session session,
    Set<int> ids,
  ) async => ids.isEmpty
      ? []
      : [
          for (final c in await Company.db.find(
            session,
            where: (t) => t.id.inSet(ids),
          ))
            CompanyRef(
              id: c.id!,
              corpCode: c.corpCode,
              name: c.displayName,
              market: c.market,
            ),
        ];
}
