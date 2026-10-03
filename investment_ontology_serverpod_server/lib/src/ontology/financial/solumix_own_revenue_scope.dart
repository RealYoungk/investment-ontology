import 'dart:convert';

import '../../generated/protocol.dart';
import '../dart/filing_series_current_eight_source.dart';

/// Exact own printed product revenue is the whole primary revenue only here.
/// No stored name/ID rewriting and no global product-revenue alias.
abstract final class SolumixOwnRevenueScope {
  static const receipt = '20220329001197';
  static const corp = '01118643';
  static const year = 2021;
  static const label = 'I.제품매출액';
  static final amount = BigInt.from(90552276);
  static Map<String, dynamic> get profile => FilingSeriesCurrentEightSource
      .profiles
      .singleWhere((p) => p['receipt'] == receipt);
  static String get url =>
      (profile['sources'] as List).singleWhere(
            (s) => s['label'] == 'ofs',
          )['url']
          as String;
  static String get digest => profile['compoundDigest'] as String;
  static const reportNames = ['사업보고서 (2021.12)', '[기재정정]사업보고서 (2021.12)'];
  static Map<String, dynamic> get proof => {
    'action': 'verified-exact-filing-series-whole-product-revenue',
    'receipt': receipt,
    'corpCode': corp,
    'year': year,
    'fsDiv': 'separate',
    'source': url,
    'sha256': digest,
    'ruleVersion': FilingSeriesCurrentEightSource.rule,
    'coreRows': 8,
    'coreRowProvenance': FilingSeriesCurrentEightSource.expectedRows(profile),
    'wholeRevenueLabel': label,
    'wholeRevenueAmount': amount.toString(),
    'fullyNumericMainEquationCount': 6,
    'printedFxDashIsNumericZero': false,
    'fullStatementCollected': false,
    'notesVerified': false,
  };
  static String sourceTitle(String reportName) =>
      'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · $reportName · 별도 · SHA256:$digest · ${jsonEncode(proof)}';

  static Map<String, dynamic>? storedScope({
    required List<Map<String, dynamic>> rows,
    required String receipt,
    required String corp,
    required String companyName,
    required bool consolidated,
    required Uri? source,
    required String? digest,
    required String reportName,
  }) {
    if (receipt != SolumixOwnRevenueScope.receipt ||
        corp != SolumixOwnRevenueScope.corp ||
        companyName != profile['name'] ||
        consolidated ||
        source?.toString() != url ||
        digest != SolumixOwnRevenueScope.digest ||
        !reportNames.contains(reportName) ||
        jsonEncode(rows) !=
            jsonEncode(FilingSeriesCurrentEightSource.expectedRows(profile))) {
      return null;
    }
    return proof;
  }

  static bool validSource(Company c, FinancialReport r, Source s) =>
      c.id != null &&
      r.id != null &&
      s.id != null &&
      c.corpCode == corp &&
      c.name == profile['name'] &&
      r.companyId == c.id &&
      r.rceptNo == receipt &&
      r.bsnsYear == year &&
      r.reportCode == FinancialReportCode.annual &&
      r.fsDiv == FsDiv.separate &&
      r.supersededById == null &&
      r.sourceId == s.id &&
      s.kind == SourceKind.dartReport &&
      s.reference == receipt &&
      s.url == url &&
      reportNames.contains(r.reportName) &&
      s.title == sourceTitle(r.reportName);
  static bool candidate(FinancialFact f, Company c, FinancialReport r) =>
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == r.sourceId &&
      f.bsnsYear == r.bsnsYear &&
      f.reportCode == r.reportCode &&
      f.fsDiv == r.fsDiv &&
      f.accountId == null &&
      f.accountName == label &&
      f.statement == FinancialStatementKind.comprehensiveIncome &&
      f.accountDetail == null &&
      f.supersededById == null;

  static bool validFact(
    FinancialFact f,
    Company c,
    FinancialReport r,
    Source s,
  ) =>
      validSource(c, r, s) &&
      f.id != null &&
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == s.id &&
      f.bsnsYear == year &&
      f.reportCode == FinancialReportCode.annual &&
      f.fsDiv == FsDiv.separate &&
      f.statement == FinancialStatementKind.comprehensiveIncome &&
      f.accountId == null &&
      f.accountDetail == null &&
      f.supersededById == null &&
      f.currency == 'KRW' &&
      f.accountName == label &&
      f.amount == amount &&
      f.cumulativeAmount == null &&
      f.priorAmount == null &&
      f.priorCumulativeAmount == null &&
      f.priorQuarterAmount == null &&
      f.beforePriorAmount == null &&
      f.periodName == '2021-01-01~2021-12-31';

  static String _quote(String s) => "'${s.replaceAll("'", "''")}'";

  /// Shares all stable Source title/owner pins with the public read selector.
  static String sqlCondition(String f) {
    final names = reportNames.map(_quote).join(',');
    final titles = reportNames
        .map(
          (n) =>
              "(r.\"reportName\"=${_quote(n)} AND s.title=${_quote(sourceTitle(n))})",
        )
        .join(' OR ');
    return '''$f."accountId" IS NULL AND $f."accountName"=${_quote(label)} AND $f.statement='comprehensiveIncome' AND $f.amount::numeric=90552276 AND $f.currency='KRW' AND $f."accountDetail" IS NULL AND $f."supersededById" IS NULL AND $f."bsnsYear"=2021 AND $f."reportCode"='annual' AND $f."fsDiv"='separate' AND $f."cumulativeAmount" IS NULL AND $f."priorAmount" IS NULL AND $f."priorCumulativeAmount" IS NULL AND $f."priorQuarterAmount" IS NULL AND $f."beforePriorAmount" IS NULL AND $f."periodName"='2021-01-01~2021-12-31'
      AND EXISTS (SELECT 1 FROM financial_report r JOIN company c ON c.id=r."companyId" JOIN source s ON s.id=r."sourceId" WHERE r.id=$f."reportId" AND c.id=$f."companyId" AND c."corpCode"=${_quote(corp)} AND c.name=${_quote(profile['name'] as String)} AND r."rceptNo"=${_quote(receipt)} AND r."bsnsYear"=2021 AND r."reportCode"='annual' AND r."fsDiv"='separate' AND r."supersededById" IS NULL AND r."sourceId"=$f."sourceId" AND s.kind='dartReport' AND s.reference=${_quote(receipt)} AND s.url=${_quote(url)} AND r."reportName" IN ($names) AND ($titles)
        AND (SELECT count(*) FROM financial_fact d WHERE d."reportId"=r.id AND d."sourceId"=s.id AND d."companyId"=c.id AND d."bsnsYear"=r."bsnsYear" AND d."reportCode"=r."reportCode" AND d."fsDiv"=r."fsDiv" AND d."accountId" IS NULL AND d."accountName"=${_quote(label)} AND d.statement='comprehensiveIncome' AND d."accountDetail" IS NULL AND d."supersededById" IS NULL)=1)''';
  }
}
