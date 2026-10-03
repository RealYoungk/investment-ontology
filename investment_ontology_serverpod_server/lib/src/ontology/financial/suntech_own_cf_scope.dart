import 'dart:convert';

import '../../generated/protocol.dart';
import '../dart/suntech_cf_current_eight_source.dart';

/// Only this own consolidated annual CF can supply these canonical lines.
/// Physical statement, raw label, null XBRL ID and raw amount remain unchanged.
abstract final class SuntechOwnCfScope {
  static const receipt = '20250317000968', corp = '00963000', year = 2024;
  static const keys = {'netIncome', 'capex'};
  static const reportNames = ['사업보고서 (2024.12)'];
  static Map<String, dynamic> get profile =>
      SuntechCfCurrentEightSource.profiles[receipt] as Map<String, dynamic>;
  static Map<String, dynamic> cell(String key) =>
      (profile['core'] as List).singleWhere((v) => v['key'] == key)
          as Map<String, dynamic>;
  static String get url =>
      (profile['sources'] as List).singleWhere(
            (s) => s['label'] == 'cfs',
          )['url']
          as String;
  static String get digest => profile['sourceDigest'] as String;
  static Map<String, dynamic> get proof => {
    'action': 'verified-exact-own-consolidated-cf-net-income-and-ppe',
    'receipt': receipt,
    'corpCode': corp,
    'year': year,
    'fsDiv': 'consolidated',
    'source': url,
    'sha256': digest,
    'ruleVersion': SuntechCfCurrentEightSource.rule,
    'coreRows': 8,
    'coreRowProvenance': SuntechCfCurrentEightSource.expectedRows(receipt),
    'netIncomeSourceStatement': 'cashFlow',
    'netIncomeRawLabel': cell('netIncome')['label'],
    'netIncomeAmount': cell('netIncome')['value'],
    'capexRawLabel': cell('capex')['label'],
    'capexAmount': cell('capex')['value'],
    'storedAccountId': null,
    'wholePLNISynthesized': false,
    'CEUnitPrinted': false,
    'CECurrencyVerified': false,
    'allStatementRowsVerified': false,
    'fullStatementCollected': false,
    'notesVerified': false,
  };
  static String sourceTitle(String name) =>
      'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · $name · 연결 · SHA256:$digest · ${jsonEncode(proof)}';
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
    if (receipt != SuntechOwnCfScope.receipt ||
        corp != SuntechOwnCfScope.corp ||
        companyName != '(주)썬테크' ||
        !consolidated ||
        source?.toString() != url ||
        digest != SuntechOwnCfScope.digest ||
        !reportNames.contains(reportName) ||
        jsonEncode(rows) !=
            jsonEncode(SuntechCfCurrentEightSource.expectedRows(receipt))) {
      return null;
    }
    return proof;
  }

  static bool validSource(Company c, FinancialReport r, Source s) =>
      c.id != null &&
      r.id != null &&
      s.id != null &&
      c.corpCode == corp &&
      c.name == '(주)썬테크' &&
      r.companyId == c.id &&
      r.rceptNo == receipt &&
      r.bsnsYear == year &&
      r.reportCode == FinancialReportCode.annual &&
      r.fsDiv == FsDiv.consolidated &&
      r.factCount == 8 &&
      r.supersededById == null &&
      r.sourceId == s.id &&
      s.kind == SourceKind.dartReport &&
      s.reference == receipt &&
      s.url == url &&
      reportNames.contains(r.reportName) &&
      s.title == sourceTitle(r.reportName);
  static bool candidate(
    String key,
    FinancialFact f,
    Company c,
    FinancialReport r,
  ) =>
      keys.contains(key) &&
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == r.sourceId &&
      f.bsnsYear == r.bsnsYear &&
      f.reportCode == r.reportCode &&
      f.fsDiv == r.fsDiv &&
      f.accountId == null &&
      f.accountName == cell(key)['label'] &&
      f.statement == FinancialStatementKind.cashFlow &&
      f.accountDetail == null &&
      f.supersededById == null;
  static bool validFact(
    String key,
    FinancialFact f,
    Company c,
    FinancialReport r,
    Source s,
  ) =>
      candidate(key, f, c, r) &&
      validSource(c, r, s) &&
      f.id != null &&
      f.ord == cell(key)['physicalOrd'] &&
      f.currency == 'KRW' &&
      f.amount == BigInt.parse(cell(key)['value'] as String) &&
      f.cumulativeAmount == null &&
      f.priorAmount == null &&
      f.priorCumulativeAmount == null &&
      f.priorQuarterAmount == null &&
      f.beforePriorAmount == null &&
      f.periodName == '2024-01-01~2024-12-31';
  static const apiUrl =
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250317000968';
  static const apiTitle =
      'DART 전체 재무제표 (fnlttSinglAcntAll) · 사업보고서 (2024.12) · 연결';
  static bool validApiSource(Company c, FinancialReport r, Source s) =>
      c.id != null &&
      c.corpCode == corp &&
      c.name == '(주)썬테크' &&
      r.id != null &&
      r.companyId == c.id &&
      r.rceptNo == receipt &&
      r.bsnsYear == year &&
      r.reportCode == FinancialReportCode.annual &&
      r.fsDiv == FsDiv.consolidated &&
      r.supersededById == null &&
      r.reportName == reportNames.single &&
      r.sourceId == s.id &&
      s.id != null &&
      s.kind == SourceKind.dartReport &&
      s.reference == receipt &&
      s.url == apiUrl &&
      s.title == apiTitle;
  static bool apiFact(FinancialFact f, Company c, FinancialReport r) =>
      f.id != null &&
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == r.sourceId &&
      f.bsnsYear == year &&
      f.reportCode == FinancialReportCode.annual &&
      f.fsDiv == FsDiv.consolidated &&
      f.currency == 'KRW' &&
      f.supersededById == null &&
      f.accountDetail == null;
  static String apiSourceSql(String f) =>
      "EXISTS (SELECT 1 FROM financial_report ar JOIN company ac ON ac.id=ar.\"companyId\" JOIN source ass ON ass.id=ar.\"sourceId\" WHERE ar.id=$f.\"reportId\" AND ac.id=$f.\"companyId\" AND ac.\"corpCode\"='$corp' AND ac.name='(주)썬테크' AND ar.\"rceptNo\"='$receipt' AND ar.\"bsnsYear\"=2024 AND ar.\"reportCode\"='annual' AND ar.\"fsDiv\"='consolidated' AND ar.\"supersededById\" IS NULL AND ar.\"reportName\"=${_q(reportNames.single)} AND ar.\"sourceId\"=$f.\"sourceId\" AND ass.kind='dartReport' AND ass.reference='$receipt' AND ass.url=${_q(apiUrl)} AND ass.title=${_q(apiTitle)} AND $f.currency='KRW')";
  static String _q(String value) => "'${value.replaceAll("'", "''")}'";
  static String boundReportSql(String f) =>
      "NOT (${apiSourceSql(f)}) AND EXISTS (SELECT 1 FROM financial_report bound_report WHERE bound_report.id=$f.\"reportId\" AND bound_report.\"rceptNo\"='$receipt' AND bound_report.\"fsDiv\"='consolidated')";
  static String sqlCondition(String f, String key) {
    if (!keys.contains(key)) throw ArgumentError.value(key);
    final e = cell(key), label = _q(cell(key)['label'] as String);
    return '''$f."accountId" IS NULL AND $f."accountName"=$label AND $f.statement='cashFlow' AND $f.amount::numeric=${e['value']} AND $f.currency='KRW' AND $f."accountDetail" IS NULL AND $f."supersededById" IS NULL AND $f."bsnsYear"=2024 AND $f."reportCode"='annual' AND $f."fsDiv"='consolidated' AND $f.ord=${e['physicalOrd']} AND $f."cumulativeAmount" IS NULL AND $f."priorAmount" IS NULL AND $f."priorCumulativeAmount" IS NULL AND $f."priorQuarterAmount" IS NULL AND $f."beforePriorAmount" IS NULL AND $f."periodName"='2024-01-01~2024-12-31'
    AND EXISTS (SELECT 1 FROM financial_report r JOIN company c ON c.id=r."companyId" JOIN source s ON s.id=r."sourceId" WHERE r.id=$f."reportId" AND c.id=$f."companyId" AND c."corpCode"='$corp' AND c.name='(주)썬테크' AND r."rceptNo"='$receipt' AND r."bsnsYear"=2024 AND r."reportCode"='annual' AND r."fsDiv"='consolidated' AND r."factCount"=8 AND r."supersededById" IS NULL AND r."sourceId"=$f."sourceId" AND s.kind='dartReport' AND s.reference='$receipt' AND s.url=${_q(url)} AND r."reportName"=${_q(reportNames.single)} AND s.title=${_q(sourceTitle(reportNames.single))}
    AND (SELECT count(*) FROM financial_fact d WHERE d."reportId"=r.id AND d."sourceId"=s.id AND d."companyId"=c.id AND d."bsnsYear"=r."bsnsYear" AND d."reportCode"=r."reportCode" AND d."fsDiv"=r."fsDiv" AND d."accountId" IS NULL AND d."accountName"=$label AND d.statement='cashFlow' AND d."accountDetail" IS NULL AND d."supersededById" IS NULL)=1)''';
  }
}
