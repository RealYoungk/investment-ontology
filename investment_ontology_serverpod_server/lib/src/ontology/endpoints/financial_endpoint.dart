import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../financial/financial_accounts.dart';
import '../ingest/financial_facts_sync.dart';

/// 기업 재무·시세 조회. 파생 지표는 계산하지 않고 원천 값만 돌려준다.
class FinancialEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const _reportOrder = {
    FinancialReportCode.q1: 0,
    FinancialReportCode.halfYear: 1,
    FinancialReportCode.q3: 2,
    FinancialReportCode.annual: 3,
  };

  /// 기업의 기간별 핵심 계정과 최근 시가총액.
  ///
  /// [fsDiv]가 없으면 연결재무제표가 있으면 연결, 없으면 별도를 쓴다.
  Future<CompanyFinancials?> summary(
    Session session,
    String corpCode, {
    FsDiv? fsDiv,
  }) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return null;

    final reports = await FinancialReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) & t.supersededById.equals(null),
    );
    final available = {for (final r in reports) r.fsDiv};
    final chosen = (fsDiv != null && available.contains(fsDiv))
        ? fsDiv
        : available.contains(FsDiv.consolidated)
        ? FsDiv.consolidated
        : available.contains(FsDiv.separate)
        ? FsDiv.separate
        : null;
    final selected = [
      for (final r in reports)
        if (r.fsDiv == chosen) r,
    ]..sort(_byPeriod);

    final ids = {for (final r in selected) r.id!};
    final facts = ids.isEmpty
        ? const <FinancialFact>[]
        : await FinancialFact.db.find(
            session,
            where: (t) =>
                t.reportId.inSet(ids) &
                t.accountId.inSet(FinancialAccounts.accountIds),
          );
    final factsByReport = <int, List<FinancialFact>>{};
    for (final f in facts) {
      (factsByReport[f.reportId] ??= []).add(f);
    }

    final supersededCounts = <int, int>{};
    for (final r in await FinancialReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.supersededById.notEquals(null) &
          t.fsDiv.equals(chosen ?? FsDiv.consolidated),
    )) {
      final key = Object.hash(r.bsnsYear, r.reportCode);
      supersededCounts[key] = (supersededCounts[key] ?? 0) + 1;
    }

    final periods = [
      for (final r in selected)
        FinancialPeriod(
          bsnsYear: r.bsnsYear,
          reportCode: r.reportCode,
          reportId: r.id!,
          rceptNo: r.rceptNo,
          reportName: r.reportName,
          receivedDate: r.receivedDate,
          periodName: _periodName(factsByReport[r.id] ?? const []),
          supersededCount:
              supersededCounts[Object.hash(r.bsnsYear, r.reportCode)] ?? 0,
          lines: FinancialAccounts.pick(factsByReport[r.id] ?? const []),
        ),
    ];

    final filingCount = await DartFiling.db.count(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    final pending = await DartFiling.db.count(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.reportCode.notEquals(null) &
          t.attempts.between(0, FinancialFactsSync.maxAttempts - 1) &
          (t.consolidatedStatus.equals(FilingFetchStatus.pending) |
              t.separateStatus.equals(FilingFetchStatus.pending) |
              t.consolidatedStatus.equals(FilingFetchStatus.failed) |
              t.separateStatus.equals(FilingFetchStatus.failed)),
    );

    return CompanyFinancials(
      corpCode: corpCode,
      fsDiv: chosen,
      availableFsDivs: [
        for (final d in FsDiv.values)
          if (available.contains(d)) d,
      ],
      periods: periods,
      market: await _marketCap(session, company.id!),
      filingCount: filingCount,
      pendingFilingCount: pending,
    );
  }

  /// 재무 보고서 원문 표와 같은 기간의 정정 이력.
  Future<FinancialReportDetail?> report(Session session, int reportId) async {
    final report = await FinancialReport.db.findById(session, reportId);
    if (report == null) return null;
    return FinancialReportDetail(
      report: report,
      source: await Source.db.findById(session, report.sourceId),
      facts: await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(reportId),
        orderByList: (t) => [t.statement.asc(), t.ord.asc(), t.id.asc()],
      ),
      history: await FinancialReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(report.companyId) &
            t.bsnsYear.equals(report.bsnsYear) &
            t.reportCode.equals(report.reportCode) &
            t.fsDiv.equals(report.fsDiv),
        orderBy: (t) => t.rceptNo,
      ),
    );
  }

  static int _byPeriod(FinancialReport a, FinancialReport b) {
    final byYear = a.bsnsYear.compareTo(b.bsnsYear);
    if (byYear != 0) return byYear;
    return _reportOrder[a.reportCode]!.compareTo(_reportOrder[b.reportCode]!);
  }

  static String? _periodName(List<FinancialFact> facts) {
    for (final f in facts) {
      if (f.statement != FinancialStatementKind.balanceSheet &&
          f.periodName != null) {
        return f.periodName;
      }
    }
    return facts.firstOrNull?.periodName;
  }

  /// 기업 발행 종목의 가장 최근 기준일 시세.
  static Future<CompanyMarketCap?> _marketCap(
    Session session,
    int companyId,
  ) async {
    final securities = await Security.db.find(
      session,
      where: (t) => t.companyId.equals(companyId),
    );
    if (securities.isEmpty) return null;
    final byId = {for (final s in securities) s.id!: s};
    final latest = await MarketSnapshot.db.findFirstRow(
      session,
      where: (t) => t.securityId.inSet(byId.keys.toSet()),
      orderBy: (t) => t.baseDate.desc(),
    );
    if (latest == null) return null;
    final snapshots = await MarketSnapshot.db.find(
      session,
      where: (t) =>
          t.securityId.inSet(byId.keys.toSet()) &
          t.baseDate.equals(latest.baseDate),
      orderBy: (t) => t.securityId,
    );
    BigInt? total = BigInt.zero;
    for (final s in snapshots) {
      final cap = s.marketCap;
      total = (total == null || cap == null) ? null : total + cap;
    }
    return CompanyMarketCap(
      baseDate: latest.baseDate,
      marketCap: total,
      securities: [
        for (final s in snapshots)
          SecurityQuote(
            securityId: s.securityId,
            shortCode: byId[s.securityId]!.shortCode,
            name: byId[s.securityId]!.name,
            closePrice: s.closePrice,
            listedShares: s.listedShares,
            marketCap: s.marketCap,
            volume: s.volume,
          ),
      ],
      source: await Source.db.findById(session, latest.sourceId),
    );
  }
}
