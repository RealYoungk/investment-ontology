import '../dart/isung_cfs_current_seven_source.dart';
import '../financial/solumix_own_revenue_scope.dart';
import '../dart/located_own_current_source.dart';
import '../dart/known_annual_conflict_cache.dart';
import '../dart/isung_current_seven_source.dart';
import '../dart/known_annual_source_not_presented.dart';

import 'dart:convert';

import '../dart/imgt_explicit_revenue_missing.dart';
import '../dart/curachem_current_seven_source.dart';
import '../dart/konasol_current_seven_source.dart';
import '../dart/curachem_restated_current_seven_source.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../financial/financial_accounts.dart';
import '../financial/financial_basis.dart';
import '../financial/financial_source_duration.dart';
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

  /// Same five-annual-years/latest-interim target selection as normal ingestion.
  /// Select final revisions before testing status: an older pending correction
  /// must not appear when the active final revision is already complete.
  /// Failed targets remain outstanding even when automatic retries are blocked.
  static int activePendingFilingCount(Iterable<DartFiling> filings) {
    final rows = filings.toList();
    final ids = FinancialFactsSync.financialScopeIds(rows);
    return rows
        .where(
          (f) =>
              ids.contains(f.id) &&
              (f.consolidatedStatus == FilingFetchStatus.pending ||
                  f.separateStatus == FilingFetchStatus.pending ||
                  f.consolidatedStatus == FilingFetchStatus.failed ||
                  f.separateStatus == FilingFetchStatus.failed),
        )
        .length;
  }

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

    final durations = await FinancialSourceDuration.load(
      session,
      companyIds: [company.id!],
    );
    final shortIds = durations.blockedReportIds;
    final activeIds = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.ctes(companyId: company.id!, blockedAnnualFlowReportIds: shortIds)} SELECT id FROM active_reports',
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
      'WITH ${FinancialBasis.ctes(companyId: company.id!, blockedAnnualFlowReportIds: shortIds)} SELECT fs,reason FROM latest',
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

    final explicitMissingReasons = <int, String>{};
    if ({
      ImgtExplicitRevenueMissing.corp,
      ...ImgtExplicitRevenueMissing.spac.values.map((p) => p.corp),
    }.contains(company.corpCode)) {
      for (final r in selected.where(
        (r) => ImgtExplicitRevenueMissing.supports(company.corpCode, r.rceptNo),
      )) {
        final source = await Source.db.findById(session, r.sourceId);
        final audit = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${r.rceptNo}:${r.fsDiv.name}',
          ),
        );
        if (source == null || audit == null) continue;
        final reportFacts = factsByReport[r.id] ?? const <FinancialFact>[];
        for (final line in FinancialAccounts.pick(reportFacts)) {
          final reason = ImgtExplicitRevenueMissing.reason(
            company: company.corpCode,
            report: r,
            source: source,
            audit: audit,
            facts: reportFacts,
            line: line,
          );
          if (reason != null) explicitMissingReasons[line.factId] = reason;
        }
      }
    }
    final supersededCounts = <int, int>{};
    final correctionCounts = await session.db.unsafeQuery(
      'WITH ${FinancialBasis.ctes(companyId: company.id!, blockedAnnualFlowReportIds: shortIds)} '
      'SELECT a.id,count(h.id) FROM active_reports a '
      'JOIN eligible_reports h ON h."companyId"=a."companyId" '
      'AND h."fsDiv"=a."fsDiv" AND h."bsnsYear"=a."bsnsYear" '
      'AND h."reportCode"=a."reportCode" AND h.actual_period=a.actual_period '
      'AND h."supersededById" IS NOT NULL GROUP BY a.id',
    );
    for (final row in correctionCounts) {
      supersededCounts[row[0] as int] = row[1] as int;
    }

    final exactRevenueSources = <int, Source>{};
    if (company.corpCode == SolumixOwnRevenueScope.corp) {
      for (final r in selected.where(
        (r) => r.rceptNo == SolumixOwnRevenueScope.receipt,
      )) {
        final source = await Source.db.findById(session, r.sourceId);
        if (source != null &&
            SolumixOwnRevenueScope.validSource(company, r, source)) {
          exactRevenueSources[r.id!] = source;
        }
      }
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
          periodName:
              durations.ranges[r.id]?.label ??
              (shortIds.contains(r.id) ? '원문 보고기간 확인 필요' : null) ??
              _periodName(factsByReport[r.id] ?? const []),
          supersededCount: supersededCounts[r.id] ?? 0,
          lines: [
            for (final line in FinancialAccounts.pick(
              factsByReport[r.id] ?? const [],
              company: company,
              report: r,
              source: exactRevenueSources[r.id],
            ))
              if (shortIds.contains(r.id) &&
                  line.statement != FinancialStatementKind.balanceSheet)
                FinancialLine(
                  key: line.key,
                  factId: line.factId,
                  statement: line.statement,
                  accountId: line.accountId,
                  accountName: line.accountName,
                  currency: line.currency,
                  unavailableReason:
                      '${durations.ranges[r.id]?.label ?? '원문 보고기간 확인 필요'} · 12개월 계산 입력을 제공하지 않습니다. 원문 보고서를 열어 공시 금액을 확인하세요.',
                  priorSameUnavailableReason:
                      '${durations.ranges[r.id]?.label ?? '원문 보고기간 확인 필요'} · 보고기간이 확인된 12개월 계산 입력이 아닙니다.',
                )
              else
                (line
                  ..unavailableReason =
                      explicitMissingReasons[line.factId] ??
                      line.unavailableReason),
          ],
        ),
    ];

    final filingCount = await DartFiling.db.count(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    final companyFilings = company.stockCode == null
        ? <DartFiling>[]
        : await DartFiling.db.find(
            session,
            where: (t) => t.companyId.equals(company.id!),
          );
    final pending = activePendingFilingCount(companyFilings);

    final active = FinancialFactsSync.financialScopeIds(companyFilings);
    final availabilitySources = <Source>[];
    for (final f in companyFilings.where(
      (f) =>
          active.contains(f.id) &&
          (f.rceptNo == KnownAnnualSourcesNotPresented.receipt ||
              KnownAnnualConflictCache.profiles.any(
                (p) => p['receipt'] == f.rceptNo,
              )),
    )) {
      for (final div in FsDiv.values) {
        final isNotPresented = KnownAnnualNotPresentedCache.eligible(
          f,
          company,
          div,
        );
        final isConflict =
            KnownAnnualConflictCache.profile(
              f,
              company,
              div,
              requireExhausted: false,
            ) !=
            null;
        if (!isNotPresented && !isConflict) continue;
        final source = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            '${isNotPresented ? 'financial-source-not-presented' : 'financial-source-conflict'}:${f.rceptNo}:${div.name}',
          ),
        );
        if (source != null &&
            (isNotPresented
                ? KnownAnnualSourcesNotPresented.validFailureSource(
                    source,
                    f,
                    company,
                    div,
                  )
                : KnownAnnualConflictCache.validFailureSource(
                    source,
                    f,
                    company,
                    div,
                  ))) {
          availabilitySources.add(source);
        }
      }
    }

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
      statementAvailabilitySources: availabilitySources,
    );
  }

  static bool validPartialScopeSource(
    Source source,
    FinancialReport report,
    String corpCode,
  ) {
    if (report.fsDiv == FsDiv.consolidated &&
        IsungCfsCurrentSevenSource.profiles.containsKey(report.rceptNo)) {
      final profile =
          IsungCfsCurrentSevenSource.profiles[report.rceptNo] as Map;
      final body = (profile['sources'] as List).singleWhere(
        (s) => s['label'] == 'cfs',
      );
      if (corpCode != '01365384' ||
          report.bsnsYear != profile['year'] ||
          report.fsDiv != FsDiv.consolidated ||
          report.reportCode != FinancialReportCode.annual ||
          source.kind != SourceKind.dartReport ||
          source.url != body['url'] ||
          source.reference !=
              'financial-api-noData-source:${report.rceptNo}:consolidated') {
        return false;
      }
      try {
        final v = jsonDecode(source.title);
        final expected = IsungCfsCurrentSevenSource.sourceAuditRows(
          report.rceptNo,
        );
        return v is Map &&
            v['action'] == 'verified-keyless-annual-source-after-api-noData' &&
            v['targetReceipt'] == report.rceptNo &&
            v['sourceReceipt'] == report.rceptNo &&
            v['format'] == 'html' &&
            v['corpCode'] == corpCode &&
            v['fsDiv'] == 'consolidated' &&
            v['reportName'] == report.reportName &&
            v['coreRows'] == 7 &&
            v['sha256'] == profile['sourceDigest'] &&
            jsonEncode(v['coreRowProvenance']) == jsonEncode(expected);
      } on FormatException {
        return false;
      } on TypeError {
        return false;
      }
    }
    if (LocatedOwnCurrentSource.recordedPartialScope(
      source,
      report,
      corpCode,
    )) {
      return true;
    }
    if (IsungCurrentSevenSource.profiles.containsKey(report.rceptNo)) {
      final profile = IsungCurrentSevenSource.profiles[report.rceptNo] as Map;
      final body = (profile['sources'] as List).singleWhere(
        (s) => s['label'] == 'ofs',
      );
      if (corpCode != '01365384' ||
          report.bsnsYear != profile['year'] ||
          report.fsDiv != FsDiv.separate ||
          report.reportCode != FinancialReportCode.annual ||
          source.kind != SourceKind.dartReport ||
          source.url != body['url'] ||
          source.reference !=
              'financial-api-noData-source:${report.rceptNo}:separate') {
        return false;
      }
      try {
        final v = jsonDecode(source.title);
        final expected = IsungCurrentSevenSource.expectedRows(report.rceptNo);
        return v is Map &&
            v['action'] == 'verified-keyless-annual-source-after-api-noData' &&
            v['targetReceipt'] == report.rceptNo &&
            v['sourceReceipt'] == report.rceptNo &&
            v['format'] == 'html' &&
            v['corpCode'] == corpCode &&
            v['fsDiv'] == 'separate' &&
            v['reportName'] == report.reportName &&
            v['coreRows'] == 7 &&
            jsonEncode(v['coreRowProvenance']) == jsonEncode(expected);
      } on FormatException {
        return false;
      } on TypeError {
        return false;
      }
    }
    final binding = {
      CurachemCurrentSevenSource.receipt: (
        CurachemCurrentSevenSource.corp,
        CurachemCurrentSevenSource.bodyUri,
        CurachemCurrentSevenSource.bodySha,
        "8c39bff6456acf946f58632df188cf597d85e5abae4d0a3c3d9d32abf08856a5",
      ),
      KonasolCurrentSevenSource.receipt: (
        KonasolCurrentSevenSource.corp,
        KonasolCurrentSevenSource.bodyUri,
        KonasolCurrentSevenSource.bodySha,
        "ab9301d36cc45c833ffcff0750b4361d8a560e67f847ab09a4d8a811199d05ff",
      ),
      CurachemRestatedCurrentSevenSource.receipt: (
        CurachemRestatedCurrentSevenSource.corp,
        CurachemRestatedCurrentSevenSource.bodyUri,
        CurachemRestatedCurrentSevenSource.bodySha,
        'ab29e1b04ffce6c1604728768cb52cfa01259187b2cb3d93407eb8ca1615d4a7',
      ),
      '20221027000409': (
        '01020269',
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=20221027000409&dcmNo=8850347&eleId=21&offset=183582&length=68022&dtd=dart3.xsd',
        '09e57bf14a980f2209851a223e5f8e007fc654463055efc76d620637dc4126b9',
        'd2abe487a65ac53fb3ad604cad7cd30666df2cb301ee50aebc53b38ad0acf8e9',
      ),
    }[report.rceptNo];
    final talos = report.rceptNo == '20221027000409';
    final year = talos
        ? 2021
        : report.rceptNo == CurachemRestatedCurrentSevenSource.receipt
        ? 2023
        : 2024;
    if (binding == null ||
        corpCode != binding.$1 ||
        report.bsnsYear != year ||
        report.fsDiv != FsDiv.separate ||
        report.reportCode != FinancialReportCode.annual ||
        source.url != binding.$2 ||
        source.kind != SourceKind.dartReport ||
        source.reference !=
            'financial-api-noData-source:${report.rceptNo}:${report.fsDiv.name}') {
      return false;
    }
    try {
      final value = jsonDecode(source.title);
      if (value is! Map ||
          value['action'] !=
              'verified-keyless-annual-source-after-api-noData' ||
          value['targetReceipt'] != report.rceptNo ||
          value['sourceReceipt'] != report.rceptNo ||
          value['format'] != 'html' ||
          value['corpCode'] != corpCode ||
          value['fsDiv'] != report.fsDiv.name ||
          value['reportName'] != report.reportName) {
        return false;
      }
      final rows = value['coreRowProvenance'];
      if (rows is! List ||
          rows.isEmpty ||
          value['coreRows'] != rows.length ||
          rows.length != 7 ||
          value['sha256'] != binding.$4) {
        return false;
      }
      final coordinates =
          report.rceptNo == CurachemRestatedCurrentSevenSource.receipt
          ? [(0, 34), (0, 47), (0, 58), (1, 1), (1, 22), (1, 37), (3, 1)]
          : report.rceptNo == CurachemCurrentSevenSource.receipt
          ? [(0, 31), (0, 43), (0, 54), (1, 1), (1, 22), (1, 37), (3, 1)]
          : [(1, 70), (1, 92), (1, 107), (3, 2), (3, 46), (3, 72), (7, 2)];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is! Map) {
          return false;
        }
        final proof = row['html_provenance'];
        if (proof is! Map ||
            (talos ? proof['printedAmount'] : proof['currentCell'])
                is! String ||
            row['thstrm_amount'] is! String) {
          return false;
        }
        final token =
            ((talos ? proof['printedAmount'] : proof['currentCell']) as String)
                .replaceAll(',', '')
                .replaceAll(RegExp(r'\s'), '');
        final signed = token.startsWith('(') && token.endsWith(')')
            ? '-${token.substring(1, token.length - 1)}'
            : token;
        if (BigInt.tryParse(signed) == null ||
            BigInt.tryParse(signed)! * BigInt.from(talos ? 1000 : 1) !=
                BigInt.tryParse(row['thstrm_amount'] as String)) {
          return false;
        }

        if (proof['partialCore7'] != true ||
            proof['fullStatementCollected'] != false ||
            proof['allStatementRowsVerified'] != false ||
            proof['notesReadScopeComplete'] != false ||
            (!talos &&
                (proof['tableIndex'] != coordinates[i].$1 ||
                    proof['rowIndex'] != coordinates[i].$2)) ||
            (talos &&
                proof['htmlTrIndex'] != [45, 63, 76, 81, 115, 129, 148][i]) ||
            (talos ? proof['currentColumn'] : proof['column']) !=
                (report.rceptNo == KonasolCurrentSevenSource.receipt ? 1 : 3) ||
            (talos ? proof['unit'] : proof['printedUnit']) !=
                (talos ? '천원' : '원') ||
            (talos ? proof['unitMultiplier'] : proof['multiplier']) !=
                (talos ? '1000' : '1') ||
            proof['printedLabel'] != row['account_nm'] ||
            proof['missingAccountReasons'] is! Map ||
            (proof['missingAccountReasons'] as Map)['capex'] !=
                (talos
                    ? 'Printed PPE acquisition row is zero but machine/equipment detail is nonzero; no unambiguous whole acquisition total collected.'
                    : report.rceptNo != KonasolCurrentSevenSource.receipt
                    ? 'No printed whole PPE acquisition total; research-equipment component is not the total.'
                    : 'No printed whole PPE acquisition total; printed acquisition components are not the total.') ||
            proof['detailHierarchyComplete'] != false ||
            proof['notesVerified'] != false ||
            proof['source'] != source.url ||
            proof['sourceSha256'] != binding.$3 ||
            proof['basis'] !=
                (report.fsDiv == FsDiv.separate ? 'OFS' : 'CFS') ||
            proof['periodStart'] != '$year-01-01' ||
            proof['periodEnd'] != '$year-12-31') {
          return false;
        }
      }
      return true;
    } on FormatException {
      return false;
    }
  }

  /// 재무 보고서 원문 표와 같은 기간의 정정 이력.
  Future<FinancialReportDetail?> report(Session session, int reportId) async {
    final report = await FinancialReport.db.findById(session, reportId);
    if (report == null) return null;
    final facts = await FinancialFact.db.find(
      session,
      where: (t) => t.reportId.equals(reportId),
      orderByList: (t) => [t.statement.asc(), t.ord.asc(), t.id.asc()],
    );
    final sourceIds = {
      report.sourceId,
      for (final fact in facts) fact.sourceId,
    };
    final partialScopeSource = await Source.db.findFirstRow(
      session,
      where: (t) => t.reference.equals(
        'financial-api-noData-source:${report.rceptNo}:${report.fsDiv.name}',
      ),
    );
    if (partialScopeSource != null) {
      final company = await Company.db.findById(session, report.companyId);
      if (company != null &&
          validPartialScopeSource(
            partialScopeSource,
            report,
            company.corpCode,
          )) {
        sourceIds.add(partialScopeSource.id!);
      }
    }
    final sources = await Source.db.find(
      session,
      where: (t) => t.id.inSet(sourceIds),
      orderBy: (t) => t.id,
    );
    return FinancialReportDetail(
      report: report,
      source: sources.where((s) => s.id == report.sourceId).firstOrNull,
      sources: sources,
      facts: facts,
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
    final aActual = RegExp(r'\(([0-9]{4}\.[0-9]{2})\)$')
        .firstMatch(a.reportName)
        ?.group(1);
    final bActual = RegExp(r'\(([0-9]{4}\.[0-9]{2})\)$')
        .firstMatch(b.reportName)
        ?.group(1);
    if (aActual != null && bActual != null) {
      final actual = aActual.compareTo(bActual);
      if (actual != 0) return actual;
    }
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
