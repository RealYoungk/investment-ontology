import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../market/market_caps.dart';
import '../dart/dart_sections.dart';
import '../dart/dart_values.dart';
import '../disclosure/business_text.dart';
import '../disclosure/disclosure_values.dart';

/// 정기보고서 주요정보 조회: 항목 목록 · 원문 표 · 주주환원.
class DisclosureEndpoint extends Endpoint {
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
    final report =
        reports.where((r) => r.bsnsYear == bsnsYear).firstOrNull ??
        reports.first;
    final rows = await DisclosureRow.db.find(
      session,
      where: (t) => t.reportId.equals(report.id!),
      orderBy: (t) => t.ord,
    );
    final decoded = [
      for (final r in rows) (r, jsonDecode(r.rowJson) as Map<String, dynamic>),
    ];
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
    final reports = await _reports(
      session,
      company.id!,
      section: DartSection.businessContent,
    );
    if (reports.isEmpty) return null;
    final report =
        reports.where((r) => r.bsnsYear == bsnsYear).firstOrNull ??
        reports.first;
    final doc = await BusinessDocument.db.findFirstRow(
      session,
      where: (t) => t.reportId.equals(report.id!),
    );
    if (doc == null) return null;
    return BusinessContent(
      bsnsYear: doc.bsnsYear,
      rceptNo: doc.rceptNo,
      title: doc.title,
      sections: [
        for (final s in BusinessText.sections(doc.text))
          BusinessSection(title: s.title, text: s.text),
      ],
      charCount: doc.charCount,
      years: [for (final r in reports) r.bsnsYear],
      source: await Source.db.findById(session, report.sourceId),
    );
  }

  /// 배당(사업보고서마다 당기·전기·전전기) · 가장 최근 자기주식 · 주식 총수.
  Future<ShareholderReturn?> shareholderReturn(
    Session session,
    String corpCode,
  ) async {
    final company = await _company(session, corpCode);
    if (company == null) return null;
    final companyId = company.id!;
    final reports = await _reports(session, companyId);
    DisclosureReport? latest(DartSection s) =>
        reports.where((r) => r.section == s).firstOrNull;

    final dividendReports = {
      for (final r in reports)
        if (r.section == DartSection.dividend) r.id!,
    };
    final dividends = dividendReports.isEmpty
        ? <DividendEntry>[]
        : await DividendEntry.db.find(
            session,
            where: (t) => t.reportId.inSet(dividendReports),
            orderByList: (t) => [t.bsnsYear.desc(), t.ord.asc()],
          );
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
                  treasury: DisclosureValues.integer(f['tesstk_co']),
                  outstanding: DisclosureValues.integer(f['distb_stock_co']),
                );
              }(),
          ];
    final sourceIds = {
      for (final r in reports)
        if (r.section == DartSection.dividend ||
            r.id == treasuryReport?.id ||
            r.id == totalReport?.id)
          r.sourceId,
    };
    return ShareholderReturn(
      corpCode: corpCode,
      dividends: dividends,
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
  }) => DisclosureReport.db.find(
    session,
    where: (t) {
      Expression e =
          t.companyId.equals(companyId) &
          t.supersededById.equals(null) &
          t.reportCode.equals(FinancialReportCode.annual);
      if (section != null) e = e & t.section.equals(section);
      return e;
    },
    orderByList: (t) => [t.bsnsYear.desc()],
  );

  /// 기업의 '본문에서 뽑은 값' 가운데 승인된 것 (수주잔고·가동률·점유율 등).
  ///
  /// 가장 최근 사업연도만. 화면은 이 값을 출처·근거와 함께 보여 준다.
  Future<List<DocumentFact>> facts(Session session, String corpCode) async {
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
      orderByList: (t) => [t.bsnsYear.desc(), t.kind.asc(), t.id.asc()],
    );
    if (all.isEmpty) return all;
    final year = all.first.bsnsYear;
    return [
      for (final f in all)
        if (f.bsnsYear == year) f,
    ];
  }

  /// 승인된 값 전부 (연도별 흐름을 보려고). 오래된 해부터.
  ///
  /// 같은 항목이 해마다 있으면 화면이 막대 차트로 그린다 — 표만 있으면 흐름이 안 보인다.
  Future<List<DocumentFact>> factTrends(
    Session session,
    String corpCode,
  ) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return const [];
    return DocumentFact.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.status.equals(RelationStatus.verified),
      orderByList: (t) => [t.bsnsYear.asc(), t.kind.asc(), t.id.asc()],
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
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.receivedDate.notEquals(null) & t.companyId.notEquals(null),
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
          if (market == null || c.market == market)
            FilingFeedItem(
              company: CompanyRef(
                id: c.id!,
                corpCode: c.corpCode,
                name: c.name,
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
