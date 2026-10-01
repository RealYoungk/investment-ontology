import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../financial/financial_accounts.dart';
import '../financial/financial_basis.dart';
import '../ingest/financial_facts_sync.dart';

/// 기업 재무·시세 조회. 파생 지표는 계산하지 않고 원천 값만 돌려준다.
class FinancialEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static const _reportOrder = {
    FinancialReportCode.q1: 0,
    FinancialReportCode.halfYear: 1,
    FinancialReportCode.q3: 2,
    FinancialReportCode.annual: 3,
  };

  /// 기업의 기간별 핵심 계정과 최근 시가총액.
  ///
  /// [fsDiv]가 없으면 최신 기간과 계산 가능성을 공통 규칙으로 판단한다.
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

    final activeIds = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT id FROM active_reports',
    );
    final reportIds = {for (final row in activeIds) row[0] as int};
    final reports = reportIds.isEmpty
        ? <FinancialReport>[]
        : await FinancialReport.db.find(
            session,
            where: (t) => t.id.inSet(reportIds),
          );
    final available = {for (final r in reports) r.fsDiv};
    final selection = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT fs,reason FROM latest',
    );
    // Explicit requests never silently return another basis.
    final chosen =
        fsDiv ??
        (selection.isEmpty
            ? null
            : FsDiv.values.byName('${selection.first[0]}'));
    final reason = fsDiv != null
        ? 'manual'
        : selection.isEmpty
        ? 'no_financials'
        : '${selection.first[1]}';
    // Same canonical report per period as the shared selection SQL.
    final canonical = <(int, FinancialReportCode), FinancialReport>{};
    for (final report in reports.where((r) => r.fsDiv == chosen)) {
      final key = (report.bsnsYear, report.reportCode);
      final old = canonical[key];
      if (old == null ||
          report.rceptNo.compareTo(old.rceptNo) > 0 ||
          report.rceptNo == old.rceptNo && report.id! > old.id!) {
        canonical[key] = report;
      }
    }
    final selected = canonical.values.toList()..sort(_byPeriod);

    final ids = {for (final r in selected) r.id!};
    final facts = ids.isEmpty
        ? const <FinancialFact>[]
        : await FinancialFact.db.find(
            session,
            where: (t) =>
                t.reportId.inSet(ids) &
                (t.accountId.inSet(FinancialAccounts.accountIds) |
                    t.accountId.equals(null)) &
                t.supersededById.equals(null),
            orderBy: (t) => t.id,
          );
    final factsByReport = <int, List<FinancialFact>>{};
    final reportById = {for (final r in selected) r.id!: r};
    for (final f in facts) {
      final report = reportById[f.reportId]!;
      if (f.sourceId != report.sourceId ||
          f.companyId != report.companyId ||
          f.bsnsYear != report.bsnsYear ||
          f.reportCode != report.reportCode ||
          f.fsDiv != report.fsDiv) {
        continue;
      }
      (factsByReport[f.reportId] ??= []).add(f);
    }

    final supersededCounts = <int, int>{};
    final correctionCounts = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.ctes(companyId: company.id!)} '
      'SELECT a.id,count(h.id) FROM active_reports a '
      'JOIN eligible_reports h ON h."companyId"=a."companyId" '
      'AND h."fsDiv"=a."fsDiv" AND h."bsnsYear"=a."bsnsYear" '
      'AND h."reportCode"=a."reportCode" AND h.actual_period=a.actual_period '
      'AND h."supersededById" IS NOT NULL GROUP BY a.id',
    );
    for (final row in correctionCounts) {
      supersededCounts[row[0] as int] = row[1] as int;
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
          supersededCount: supersededCounts[r.id] ?? 0,
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
      basisReason: reason,
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
      history: await _history(session, report),
    );
  }

  static Future<List<FinancialReport>> _history(
    Session session,
    FinancialReport report,
  ) async {
    final ids = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.eligibleReportsCte} '
      'SELECT h.id FROM eligible_reports current_report '
      'JOIN eligible_reports h ON h."companyId"=current_report."companyId" '
      'AND h."bsnsYear"=current_report."bsnsYear" '
      'AND h."reportCode"=current_report."reportCode" '
      'AND h."fsDiv"=current_report."fsDiv" '
      'AND h.actual_period=current_report.actual_period '
      'WHERE current_report.id=\$1',
      parameters: QueryParameters.positional([report.id]),
    );
    if (ids.isEmpty) return [];
    return FinancialReport.db.find(
      session,
      where: (t) => t.id.inSet(<int>{for (final row in ids) row[0] as int}),
      orderBy: (t) => t.rceptNo,
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
