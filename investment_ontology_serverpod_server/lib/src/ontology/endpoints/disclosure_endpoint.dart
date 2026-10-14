import '../business/business_report_period.dart';
import '../disclosure/financial_business_source_tables.dart';
import '../disclosure/stored_segment_revenue.dart';
import '../disclosure/stored_rnd_facts.dart';
import '../disclosure/stored_segment_number_guard.dart';
import '../disclosure/stored_market_share_projection.dart';
import '../disclosure/recovered_market_share_facts.dart';
import '../financial/financial_basis.dart';
import '../disclosure/scoped_order_fact_projection.dart';
import '../disclosure/order_unreconciled_source_tables.dart';
import '../presentation/company_presentation.dart';

import 'dart:convert';

import '../business/business_profiles.dart';
import '../business/latest_business_report.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/market_caps.dart';
import '../dart/dart_sections.dart';
import '../dart/dart_values.dart';
import '../disclosure/business_text.dart';
import '../disclosure/business_table_insights.dart';
import '../disclosure/investment_facts.dart';
import '../disclosure/interim_rnd_facts.dart';
import '../disclosure/disclosure_values.dart';

/// 정기보고서 주요정보 조회: 항목 목록 · 원문 표 · 주주환원.
class DisclosureEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// 최신 활성 공시에서 미리 추출한 제품·공정 설명.
  Future<BusinessUnderstanding> understanding(
    Session session,
    String corpCode,
  ) => BusinessProfiles.read(session, corpCode);

  /// 기업이 가진 주요정보 항목과 사업연도 (항목 순서는 [DartSections.info]).
  Future<List<DisclosureSectionInfo>> sections(
    Session session,
    String corpCode,
  ) async {
    final company = await _company(session, corpCode);
    if (company == null) return [];
    final years = <DartSection, Set<int>>{};
    for (final r in await _reports(session, company.id!)) {
      (years[r.section] ??= {}).add(r.bsnsYear);
    }
    return [
      for (final e in DartSections.info.entries)
        if (years[e.key] case final ys?)
          DisclosureSectionInfo(
            section: e.key,
            label: e.value.label,
            group: e.value.group,
            years: ys.toList()..sort((a, b) => b.compareTo(a)),
          ),
    ];
  }

  /// 항목 하나의 원문 표 (응답 필드 그대로, 머리글만 한글). [bsnsYear]가 없으면 가장 최근.
  Future<DisclosureTable?> table(
    Session session,
    String corpCode,
    DartSection section, {
    int? bsnsYear,
  }) async {
    final company = await _company(session, corpCode);
    if (company == null) return null;
    final reports = await _reports(session, company.id!, section: section);
    if (reports.isEmpty) return null;
    final report = bsnsYear == null
        ? reports.first
        : reports.where((r) => r.bsnsYear == bsnsYear).firstOrNull;
    if (report == null) return null;
    final rows = await DisclosureRow.db.find(
      session,
      where: (t) => t.reportId.equals(report.id!),
      orderBy: (t) => t.ord,
    );
    final seenRows = <String>{};
    final decoded = <(DisclosureRow, Map<String, dynamic>)>[];
    for (final r in rows) {
      final fields = jsonDecode(r.rowJson) as Map<String, dynamic>;
      final keys = fields.keys.toList()..sort();
      final identity = jsonEncode({for (final k in keys) k: fields[k]});
      if (seenRows.add(identity)) decoded.add((r, fields));
    }
    final fields = <String>[];
    for (final (_, f) in decoded) {
      for (final k in f.keys) {
        if (!DartSections.commonFields.contains(k) && !fields.contains(k)) {
          fields.add(k);
        }
      }
    }
    // 모든 행이 비어 있는 열은 뺀다 (표본에서 금액 열 몇 개가 항상 비어 있었다).
    final used = [
      for (final k in fields)
        if (decoded.any((d) => DartValues.text(d.$2[k]) != null)) k,
    ];
    return DisclosureTable(
      section: section,
      label: DartSections.of(section).label,
      bsnsYear: report.bsnsYear,
      rceptNo: report.rceptNo,
      settlementDate: report.settlementDate,
      headers: [for (final k in used) DartSections.fieldLabel(k)],
      rows: [
        for (final (r, f) in decoded)
          DisclosureTableRow(
            isTotal: r.isTotal,
            cells: [
              for (final k in used)
                DartValues.text(f[k])?.replaceAll(RegExp(r'\s*\n\s*'), ' '),
            ],
          ),
      ],
      emptyRowCount: report.emptyRowCount,
      source: await Source.db.findById(session, report.sourceId),
      years: [for (final r in reports) r.bsnsYear],
    );
  }

  /// 사업보고서 본문 "II. 사업의 내용"을 하위 절로 나눠서. [bsnsYear]가 없으면 가장 최근.
  Future<BusinessContent?> businessContent(
    Session session,
    String corpCode, {
    int? bsnsYear,
  }) async {
    final company = await _company(session, corpCode);
    if (company == null) return null;
    final selector = bsnsYear == null
        ? LatestBusinessReport.sql
        : LatestBusinessReport.sql.replaceFirst(
            ') p ORDER BY',
            ') p WHERE p."bsnsYear"=@year ORDER BY',
          );
    final rows = await session.db.unsafeQuery(
      'SELECT latest."documentId", latest."reportName", latest."rceptNo" FROM ($selector) latest WHERE latest."companyId"=@id',
      parameters: QueryParameters.named({
        'id': company.id!,
        'year': ?bsnsYear,
      }),
    );
    var id = rows.firstOrNull?.first as int?;
    final latestReportName = rows.firstOrNull?[1] as String?;
    var isFallback = false;
    if (id == null && bsnsYear == null && rows.isNotEmpty) {
      final available = await session.db.unsafeQuery(
        '''SELECT d.id FROM business_document d
          JOIN disclosure_report r ON r.id=d."reportId"
            AND r."companyId"=d."companyId" AND r."rceptNo"=d."rceptNo"
          WHERE d."companyId"=@id AND r.section='businessContent'
            AND r."supersededById" IS NULL
          ORDER BY coalesce(r."settlementDate", make_date(r."bsnsYear"::int, CASE r."reportCode" WHEN 'annual' THEN 12 WHEN 'q3' THEN 9 WHEN 'halfYear' THEN 6 ELSE 3 END, 1)) DESC, CASE r."reportCode"
            WHEN 'annual' THEN 4 WHEN 'q3' THEN 3 WHEN 'halfYear' THEN 2 ELSE 1 END DESC,
            r."rceptNo" DESC LIMIT 1''',
        parameters: QueryParameters.named({'id': company.id!}),
      );
      id = available.firstOrNull?.first as int?;
      isFallback = id != null;
    }
    final doc = id == null
        ? null
        : await BusinessDocument.db.findById(session, id);
    final report = doc == null
        ? null
        : await DisclosureReport.db.findById(session, doc.reportId);
    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.section.equals(DartSection.businessContent) &
          t.supersededById.equals(null),
      orderByList: (t) => [t.bsnsYear.desc(), t.rceptNo.desc()],
    );
    if (doc == null || report == null) return null;
    final reportPeriod = businessReportPeriod(report, doc.bsnsYear);
    final financialTables = FinancialBusinessSourceTables.parse(
      doc.text,
      reportPeriod,
      industryCode: company.industryCode,
    );
    return BusinessContent(
      bsnsYear: doc.bsnsYear,
      rceptNo: doc.rceptNo,
      title: isFallback
          ? '이전 저장 보고서 · 최신 ${latestReportName ?? '정기보고서'} 본문 수집 대기'
          : rows.firstOrNull?[2] != doc.rceptNo
          ? '첨부정정의 동일 보고기간 원본문 · ${doc.rceptNo}'
          : doc.title,
      sections: [
        for (final s in BusinessText.sections(doc.text))
          BusinessSection(title: s.title, text: s.text),
      ],
      charCount: doc.charCount,
      years: {for (final r in reports) r.bsnsYear}.toList(),
      source: await Source.db.findById(session, report.sourceId),
      tableInsights: [
        ...financialTables,
        ...OrderUnreconciledSourceTables.parse(doc.text, reportPeriod),
        ...BusinessTableInsights.parse(
          doc.text,
          reportPeriod: reportPeriod,
        ).where((table) {
          if (table.topic != 'complexRevenueSource' || table.rows.isEmpty) {
            return true;
          }
          final rawRows = table.rows
              .map((row) => row.cells.join('|').replaceAll(RegExp(r'\s+'), ''))
              .toSet();
          return !financialTables.any((financial) {
            final financialLines = financial.evidence
                .split('\n')
                .map((line) => line.replaceAll(RegExp(r'\s+'), ''))
                .toSet();
            return rawRows.every(financialLines.contains);
          });
        }),
      ],
    );
  }

  /// 연간 배당(사업보고서마다 당기·전기·전전기) · 가장 최근 자기주식 · 주식 총수.
  Future<ShareholderReturn?> shareholderReturn(
    Session session,
    String corpCode, {
    int? bsnsYear,
  }) async {
    final company = await _company(session, corpCode);
    if (company == null) return null;
    final companyId = company.id!;
    final reports = await _reports(session, companyId, includeInterim: true);
    int reportRank(FinancialReportCode code) => switch (code) {
      FinancialReportCode.annual => 4,
      FinancialReportCode.q3 => 3,
      FinancialReportCode.halfYear => 2,
      FinancialReportCode.q1 => 1,
    };
    reports.sort((a, b) {
      final year = b.bsnsYear.compareTo(a.bsnsYear);
      if (year != 0) return year;
      final period = reportRank(b.reportCode)
          .compareTo(reportRank(a.reportCode));
      return period != 0 ? period : b.rceptNo.compareTo(a.rceptNo);
    });
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.companyId.equals(companyId) &
          t.bsnsYear.notEquals(null) &
          t.reportCode.notEquals(null),
      orderByList: (t) => [t.bsnsYear.desc(), t.rceptNo.desc()],
    );
    int rank(FinancialReportCode code) => switch (code) {
      FinancialReportCode.annual => 4,
      FinancialReportCode.q3 => 3,
      FinancialReportCode.halfYear => 2,
      FinancialReportCode.q1 => 1,
    };
    filings.sort((a, b) {
      final year = b.bsnsYear!.compareTo(a.bsnsYear!);
      if (year != 0) return year;
      final period = rank(b.reportCode!).compareTo(rank(a.reportCode!));
      return period != 0 ? period : b.rceptNo.compareTo(a.rceptNo);
    });
    final expected = filings.firstOrNull;
    String periodName(DisclosureReport r) =>
        '${r.bsnsYear}년 ${switch (r.reportCode) {
          FinancialReportCode.annual => '연간',
          FinancialReportCode.q1 => '1분기',
          FinancialReportCode.halfYear => '상반기',
          FinancialReportCode.q3 => '3분기 누적',
        }}';
    DisclosureReport? latest(DartSection s) => reports
        .where(
          (r) => r.section == s && (bsnsYear == null || r.bsnsYear == bsnsYear),
        )
        .firstOrNull;

    final dividendReports = {
      for (final r in reports)
        if (r.section == DartSection.dividend &&
            r.reportCode == FinancialReportCode.annual)
          r.id!,
    };
    final dividends = dividendReports.isEmpty
        ? <DividendEntry>[]
        : await DividendEntry.db.find(
            session,
            where: (t) => t.reportId.inSet(dividendReports),
            orderByList: (t) => [t.bsnsYear.desc(), t.ord.asc()],
          );
    final interimReport = reports
        .where(
          (r) =>
              r.section == DartSection.dividend &&
              r.reportCode != FinancialReportCode.annual,
        )
        .firstOrNull;
    // Keep a stale interim out of the latest report slot.
    final currentInterim =
        interimReport != null &&
            (expected == null ||
                (interimReport.bsnsYear == expected.bsnsYear &&
                    interimReport.reportCode == expected.reportCode))
        ? interimReport
        : null;
    final interimDividends = currentInterim == null
        ? <DividendEntry>[]
        : await DividendEntry.db.find(
            session,
            where: (t) => t.reportId.equals(currentInterim.id!),
            orderBy: (t) => t.ord,
          );
    // Ord is source order, not business identity. Preserve different periods,
    // stock classes and numbers; collapse only exact repeated observations.
    for (final entries in [dividends, interimDividends]) {
      final seen = <String>{};
      entries.removeWhere(
        (e) => !seen.add(
          jsonEncode([
            e.reportId,
            e.item,
            e.unit,
            e.stockKind,
            e.current,
            e.prior,
            e.beforePrior,
          ]),
        ),
      );
    }
    final treasuryReport = latest(DartSection.treasuryStock);
    final treasury = treasuryReport == null
        ? <TreasuryStockEntry>[]
        : await TreasuryStockEntry.db.find(
            session,
            where: (t) => t.reportId.equals(treasuryReport.id!),
            orderBy: (t) => t.ord,
          );
    final totalReport = latest(DartSection.stockTotal);
    final totals = totalReport == null
        ? <StockTotalRow>[]
        : [
            for (final r in await DisclosureRow.db.find(
              session,
              where: (t) => t.reportId.equals(totalReport.id!),
              orderBy: (t) => t.ord,
            ))
              () {
                final f = jsonDecode(r.rowJson) as Map<String, dynamic>;
                return StockTotalRow(
                  kind: DisclosureValues.displayName(f['se']),
                  issued: DisclosureValues.integer(f['istc_totqy']),
                  authorized: DisclosureValues.integer(f['isu_stock_totqy']),
                  treasury: DisclosureValues.integer(f['tesstk_co']),
                  outstanding: DisclosureValues.integer(f['distb_stock_co']),
                );
              }(),
          ];
    final ledger = expected == null
        ? <DartFilingSection>[]
        : await DartFilingSection.db.find(
            session,
            where: (t) => t.filingId.equals(expected.id!),
          );
    String statusFor(DartSection section, DisclosureReport? actual) {
      if (expected == null) return actual == null ? 'pending' : 'stored';
      if (actual != null &&
          actual.bsnsYear == expected.bsnsYear &&
          actual.reportCode == expected.reportCode) {
        return 'stored';
      }
      return ledger
              .where((l) => l.section == section)
              .firstOrNull
              ?.status
              .name ??
          'pending';
    }

    final sourceIds = {
      for (final r in reports)
        if (dividendReports.contains(r.id) ||
            r.id == currentInterim?.id ||
            r.id == treasuryReport?.id ||
            r.id == totalReport?.id)
          r.sourceId,
    };
    return ShareholderReturn(
      corpCode: corpCode,
      dividends: dividends,
      interimDividends: interimDividends,
      latestDividendStatus: statusFor(DartSection.dividend, currentInterim),
      latestTreasuryStatus: statusFor(
        DartSection.treasuryStock,
        treasuryReport,
      ),
      latestStockTotalStatus: statusFor(DartSection.stockTotal, totalReport),
      interimReportName: currentInterim == null
          ? null
          : periodName(currentInterim),
      treasuryReportName: treasuryReport == null
          ? null
          : periodName(treasuryReport),
      stockTotalReportName: totalReport == null
          ? null
          : periodName(totalReport),
      latestReportName: expected?.reportName,
      latestYear: expected?.bsnsYear,
      annualEndYear: expected == null
          ? null
          : expected.bsnsYear! -
                (expected.reportCode == FinancialReportCode.annual ? 0 : 1),
      availableYears: {
        for (final r in reports) r.bsnsYear,
        if (expected?.bsnsYear != null) expected!.bsnsYear!,
      }.toList()..sort(),
      treasuryYear: treasuryReport?.bsnsYear,
      treasury: treasury,
      stockTotalYear: totalReport?.bsnsYear,
      stockTotals: [
        for (final t in totals)
          if (t.kind.isNotEmpty) t,
      ],
      sources: sourceIds.isEmpty
          ? []
          : await Source.db.find(
              session,
              where: (t) => t.id.inSet(sourceIds),
              orderByList: (t) => [t.id.desc()],
            ),
    );
  }

  static Future<Company?> _company(Session session, String corpCode) =>
      Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals(corpCode),
      );

  /// 대체되지 않은 사업보고서 항목, 최근 사업연도부터.
  static Future<List<DisclosureReport>> _reports(
    Session session,
    int companyId, {
    DartSection? section,
    bool includeInterim = false,
  }) => DisclosureReport.db.find(
    session,
    where: (t) {
      Expression e =
          t.companyId.equals(companyId) & t.supersededById.equals(null);
      if (!includeInterim) {
        e = e & t.reportCode.equals(FinancialReportCode.annual);
      }
      if (section != null) e = e & t.section.equals(section);
      return e;
    },
    orderByList: (t) => [
      t.bsnsYear.desc(),
      t.settlementDate.desc(),
      t.rceptNo.desc(),
    ],
  );

  /// 기업의 '본문에서 뽑은 값' 가운데 승인된 것 (수주잔고·가동률·점유율 등).
  ///
  /// 가장 최근 사업연도만. 화면은 이 값을 출처·근거와 함께 보여 준다.
  Future<List<DocumentFact>> facts(Session session, String corpCode) async {
    final all = await factTrends(session, corpCode);
    if (all.isEmpty) return all;
    final year = all.map((f) => f.bsnsYear).reduce((a, b) => a > b ? a : b);
    return [
      for (final fact in all)
        if (fact.bsnsYear == year) fact,
    ];
  }

  /// 승인된 값 전부 (연도별 흐름을 보려고). 오래된 해부터.
  ///
  static Future<List<SegmentFinancialRevenueReference>>
  _segmentRevenueReferences(
    Session session,
    BusinessDocument doc,
    DisclosureReport report,
  ) async {
    final eligible = FinancialBasis.eligibleReportsCte.replaceFirst(
      'WHERE CASE WHEN',
      'WHERE r."companyId"=${doc.companyId} AND CASE WHEN',
    );
    final rows = await session.db.unsafeQuery(
      'WITH $eligible SELECT r."companyId",r."bsnsYear",r."reportCode",r."fsDiv",r."rceptNo", '
      'CASE WHEN r."reportCode"=\'annual\' THEN f.amount ELSE coalesce(f."cumulativeAmount",f.amount) END '
      'FROM eligible_reports r JOIN financial_fact f ON f."reportId"=r.id '
      'WHERE r."rceptNo"=@receipt AND r."bsnsYear"=@year AND r."reportCode"=@period '
      'AND r."supersededById" IS NULL AND f."supersededById" IS NULL '
      'AND f."companyId"=r."companyId" AND f."sourceId"=r."sourceId" '
      'AND f."bsnsYear"=r."bsnsYear" AND f."reportCode"=r."reportCode" AND f."fsDiv"=r."fsDiv" '
      'AND f."accountId"=\'ifrs-full_Revenue\' AND f."accountDetail" IS NULL '
      'AND f.statement IN (\'incomeStatement\',\'comprehensiveIncome\') '
      'AND coalesce(f.currency,\'KRW\')=\'KRW\'',
      parameters: QueryParameters.named({
        'receipt': doc.rceptNo,
        'year': doc.bsnsYear,
        'period': report.reportCode.name,
      }),
    );
    return [
      for (final row in rows)
        if (BigInt.tryParse('${row[5]}') case final value?)
          (
            companyId: row[0] as int,
            bsnsYear: row[1] as int,
            reportCode: FinancialReportCode.values.byName('${row[2]}'),
            fsDiv: FsDiv.values.byName('${row[3]}'),
            rceptNo: row[4] as String,
            revenueWon: value,
          ),
    ];
  }

  /// 같은 항목이 해마다 있으면 화면이 막대 차트로 그린다 — 표만 있으면 흐름이 안 보인다.
  Future<List<BusinessFactPeriod>> factPeriods(
    Session session,
    String corpCode,
  ) async {
    final company = await _company(session, corpCode);
    if (company == null) return [];
    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.section.equals(DartSection.businessContent) &
          t.supersededById.equals(null),
    );
    final byId = {for (final r in reports) r.id!: r};
    final documents = await BusinessDocument.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    return [
      for (final doc in documents)
        if (byId[doc.reportId] case final report?)
          if (report.settlementDate != null ||
              report.reportCode == FinancialReportCode.annual)
            BusinessFactPeriod(
              documentId: doc.id!,
              bsnsYear: doc.bsnsYear,
              reportCode: report.reportCode,
              periodEnd:
                  report.settlementDate ??
                  DateTime.utc(
                    doc.bsnsYear,
                    (company.fiscalMonth ?? 12) + 1,
                    0,
                  ),
            ),
    ];
  }

  Future<List<DocumentFact>> factTrends(
    Session session,
    String corpCode,
  ) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return const [];
    final all = await DocumentFact.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.status.equals(RelationStatus.verified),
      orderByList: (t) => [t.bsnsYear.asc(), t.kind.asc(), t.id.asc()],
    );
    final reports = await DisclosureReport.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.section.equals(DartSection.businessContent),
    );
    final active = {
      for (final r in reports)
        if (r.supersededById == null) r.id!,
    };
    final documents = await BusinessDocument.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    final byDocument = {
      for (final d in documents)
        if (active.contains(d.reportId)) d.id!: d,
    };
    final activeReports = {
      for (final report in reports)
        if (report.supersededById == null) report.id!: report,
    };
    final valid = <DocumentFact>[];
    for (final doc in byDocument.values) {
      final stored = all
          .where(
            (fact) =>
                fact.documentId == doc.id &&
                fact.companyId == doc.companyId &&
                fact.bsnsYear == doc.bsnsYear &&
                fact.sourceId == activeReports[doc.reportId]?.sourceId &&
                !(fact.kind == DocumentFactKind.segmentRevenue &&
                    fact.extractedBy == RelationOrigin.api &&
                    RegExp(r'^(?:단순합계|합계\(연결조정(?:전|후)\))$')
                        .hasMatch(fact.label.replaceAll(' ', ''))),
          )
          .toList();
      final orderChecked = ScopedOrderFactProjection.revalidate(
        stored,
        doc.text,
        companyName: company.name,
      );
      valid.addAll(
        stored.any((fact) => fact.kind == DocumentFactKind.marketShare)
            ? StoredMarketShareProjection.project(
                orderChecked,
                doc,
                owner: company.name,
                industryCode: company.industryCode,
              )
            : orderChecked,
      );
    }
    for (final doc in byDocument.values) {
      final report = activeReports[doc.reportId];
      if (report == null) continue;
      valid.addAll(
        RecoveredMarketShareFacts.project(
          doc,
          report,
          valid,
          owner: company.name,
          industryCode: company.industryCode,
        ),
      );
      final candidates = valid
          .where(
            (fact) =>
                fact.documentId == doc.id &&
                StoredSegmentNumberGuard.isCandidate(fact),
          )
          .toList();
      if (candidates.isNotEmpty) {
        final references = await _segmentRevenueReferences(
          session,
          doc,
          report,
        );
        valid.removeWhere(
          (fact) =>
              fact.documentId == doc.id &&
              !StoredSegmentNumberGuard.assess(
                fact,
                doc,
                report,
                financialRevenues: references,
              ).keep,
        );
      }
      if (report.reportCode == FinancialReportCode.annual) {
        valid.removeWhere(
          (fact) => StoredRndFacts.isLegacyRuleFact(fact, doc.id!),
        );
        valid.addAll(await StoredRndFacts.read(session, doc, report));
      }
      for (final projected in StoredSegmentRevenue.project(doc, report)) {
        if (!valid.any(
          (f) =>
              f.documentId == doc.id &&
              f.kind == projected.kind &&
              f.label == projected.label &&
              f.unit == projected.unit &&
              f.asOf == projected.asOf,
        )) {
          valid.add(projected);
        }
      }
    }
    // 같은 항목·같은 해의 값이 여러 보고서에 있으면(표가 당기·전기·전전기를 나란히 적고,
    // 회사는 재작성한다) 그 해의 보고서 값을 쓴다 — 없으면 가장 가까운 해의 보고서.
    final best = <String, DocumentFact>{};
    for (final f in valid) {
      final year = f.asOf?.year ?? f.bsnsYear;
      final key =
          '${f.kind.name}|${f.label}|${f.unit}|${(f.asOf ?? DateTime.utc(year, 12, 31)).toIso8601String()}';
      final prev = best[key];
      if (prev == null) {
        best[key] = f;
        continue;
      }
      final d = (f.bsnsYear - year).abs(), pd = (prev.bsnsYear - year).abs();
      if (d < pd ||
          d == pd &&
              (f.bsnsYear > prev.bsnsYear ||
                  f.bsnsYear == prev.bsnsYear &&
                      byDocument[f.documentId]!.rceptNo.compareTo(
                            byDocument[prev.documentId]!.rceptNo,
                          ) >
                          0)) {
        best[key] = f;
      }
    }
    // Interim R&D is validated from stored source without DB mutations.
    final interim = <DocumentFact>[];
    final newest = byDocument.values.toList()
      ..sort((a, b) => b.rceptNo.compareTo(a.rceptNo));
    if (newest.isNotEmpty) {
      final doc = newest.first;
      final report = activeReports[doc.reportId];
      if (report != null && report.reportCode != FinancialReportCode.annual) {
        final projected = await InterimRndFacts.read(session, doc, report);
        interim.addAll(
          projected.where(
            (f) => !best.values.any(
              (existing) =>
                  existing.kind == f.kind &&
                  existing.label == f.label &&
                  existing.unit == f.unit &&
                  existing.asOf == f.asOf,
            ),
          ),
        );
      }
    }
    return [
      for (final f in best.values)
        if (!InvestmentFacts.redundantRoundedTotal(f, valid)) f,
      ...interim,
    ];
  }

  /// 이 기업의 최근 공시 (종류 가리지 않음). 계약·증자·주요사항 등.
  Future<List<DartDisclosure>> recentOf(
    Session session,
    String corpCode, {
    int? limit,
  }) async {
    final company = await _company(session, corpCode);
    if (company == null) return const [];
    return DartDisclosure.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!),
      orderByList: (t) => [t.receivedDate.desc(), t.rceptNo.desc()],
      limit: (limit ?? 12).clamp(1, 50),
    );
  }

  /// "사업의 내용"을 읽기 좋게 녹인 절들 (없으면 빈 목록). [bsnsYear]가 없으면 가장 최근 해.
  Future<List<BusinessDigestSection>> digest(
    Session session,
    String corpCode, {
    int? bsnsYear,
  }) async {
    final company = await _company(session, corpCode);
    if (company == null) return const [];
    final year =
        bsnsYear ??
        (await BusinessDigestSection.db.findFirstRow(
          session,
          where: (t) => t.companyId.equals(company.id!),
          orderBy: (t) => t.bsnsYear.desc(),
        ))?.bsnsYear;
    if (year == null) return const [];
    return BusinessDigestSection.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!) & t.bsnsYear.equals(year),
      orderBy: (t) => t.ord,
    );
  }

  /// 최근 올라온 정기보고서. 새 공시를 눈에 띄게 보여 주는 용도다.
  ///
  /// 사업·반기·분기보고서만 다룬다 (수집 대상이 그것뿐이다). 정정 공시도 그대로 보인다.
  Future<List<FilingFeedItem>> recentFilings(
    Session session, {
    Market? market,
    int? limit,
  }) async {
    // 시장으로 거를 때는 먼저 그 시장의 기업을 추려 조회한다 — 전체에서 앞 몇 건을
    // 가져와 뒤에서 거르면, 공시가 적은 시장(코넥스)은 늘 빈 목록이 된다.
    Set<int>? onlyIds;
    if (market != null) {
      onlyIds = {
        for (final c in await Company.db.find(
          session,
          where: (t) => t.market.equals(market),
        ))
          c.id!,
      };
      if (onlyIds.isEmpty) return const [];
    }
    final filings = await DartFiling.db.find(
      session,
      where: (t) {
        final base =
            t.receivedDate.notEquals(null) & t.companyId.notEquals(null);
        return onlyIds == null ? base : base & t.companyId.inSet(onlyIds);
      },
      orderByList: (t) => [t.receivedDate.desc(), t.rceptNo.desc()],
      limit: (limit ?? 30).clamp(1, 200),
    );
    if (filings.isEmpty) return const [];
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final f in filings) f.companyId!}),
      ))
        c.id!: c,
    };
    final caps = await MarketCaps.latest(session, companies.keys.toSet());
    return [
      for (final f in filings)
        if (companies[f.companyId] case final c?)
          FilingFeedItem(
            company: CompanyRef(
              id: c.id!,
              corpCode: c.corpCode,
              name: c.displayName,
              market: c.market,
            ),
            rceptNo: f.rceptNo,
            reportName: f.reportName,
            receivedDate: f.receivedDate,
            bsnsYear: f.bsnsYear,
            financialStored:
                f.consolidatedStatus == FilingFetchStatus.stored ||
                f.separateStatus == FilingFetchStatus.stored,
            marketCap: caps.caps[c.id],
          ),
    ];
  }
}
