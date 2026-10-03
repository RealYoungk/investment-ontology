import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/hanwha_own_net_income_scope.dart';

import 'verified_annual_source_registry_test.dart' show company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    HanwhaOwnNetIncomeScope.receipt,
    FsDiv.separate,
  )!;
  Company c() => company(e);
  FinancialReport r() => FinancialReport(
    id: 1,
    companyId: 1,
    rceptNo: e.receipt,
    bsnsYear: 2022,
    reportCode: FinancialReportCode.annual,
    fsDiv: FsDiv.separate,
    reportName: '사업보고서 (2022.12)',
    factCount: 8,
    invalidAmountCount: 0,
    sourceId: 1,
    fetchedAt: DateTime.utc(2026),
  );
  Source s() => Source(
    id: 1,
    kind: SourceKind.dartReport,
    reference: e.receipt,
    title: HanwhaOwnNetIncomeScope.sourceTitle(r().reportName),
    url: HanwhaOwnNetIncomeScope.url,
    retrievedAt: DateTime.utc(2026),
  );
  FinancialFact f() => FinancialFact(
    id: 1,
    reportId: 1,
    companyId: 1,
    bsnsYear: 2022,
    reportCode: FinancialReportCode.annual,
    fsDiv: FsDiv.separate,
    statement: FinancialStatementKind.comprehensiveIncome,
    accountName: HanwhaOwnNetIncomeScope.label,
    amount: HanwhaOwnNetIncomeScope.amount,
    periodName: '2022-01-01~2022-12-31',
    currency: 'KRW',
    sourceId: 1,
    ord: 72,
  );
  test('literal productRevenue default remains unavailable; exact complete Source allows original fact only', () {
    final fact = f(), before = fact.toJson();
    expect(FinancialAccounts.pick([fact]), isEmpty);
    final line = FinancialAccounts.pick(
      [fact],
      company: c(),
      report: r(),
      source: s(),
    ).single;
    expect(line.key, 'netIncome');
    expect(line.amount, HanwhaOwnNetIncomeScope.amount);
    expect(line.accountName, HanwhaOwnNetIncomeScope.label);
    expect(line.accountId, isNull);
    expect(fact.toJson(), before);
    expect(
      FinancialAccounts.pick(
        [fact, fact.copyWith(id: 2)],
        company: c(),
        report: r(),
        source: s(),
      ),
      isEmpty,
    );
  });
  for (final field in [
    'sourceTitle',
    'sourceId',
    'reference',
    'url',
    'kind',
    'corp',
    'companyName',
    'companyOwner',
    'reportReceipt',
    'reportYear',
    'reportBasis',
    'reportCode',
    'reportName',
    'reportSource',
    'reportFactCount',
    'ord',
    'factSource',
    'factOwner',
    'factReport',
    'factYear',
    'factBasis',
    'factAmount',
    'factLabel',
    'genericNILabel',
    'currency',
    'statement',
    'detail',
    'superseded',
    'priorAmount',
    'periodName',
    'beforePriorAmount',
    'priorQuarterAmount',
  ]) {
    test('rejects exact $field drift without global alias', () {
      final co = c(), report = r(), source = s(), fact = f();
      switch (field) {
        case 'sourceTitle':
          source.title += ' ';
        case 'sourceId':
          source.id = 2;
        case 'reference':
          source.reference = '20230314000605';
        case 'url':
          source.url = '${HanwhaOwnNetIncomeScope.url} ';
        case 'kind':
          source.kind = SourceKind.manual;
        case 'corp':
          co.corpCode = '00000000';
        case 'companyName':
          co.name = '주식회사 로보쓰리';
        case 'companyOwner':
          co.id = 2;
        case 'reportReceipt':
          report.rceptNo = '20230314000605';
        case 'reportYear':
          report.bsnsYear = 2023;
        case 'reportBasis':
          report.fsDiv = FsDiv.consolidated;
        case 'reportCode':
          report.reportCode = FinancialReportCode.halfYear;
        case 'reportName':
          report.reportName = '사업보고서 (2023.12)';
        case 'reportFactCount':
          report.factCount = 7;
        case 'ord':
          fact.ord = 999;
        case 'reportSource':
          report.sourceId = 2;
        case 'factSource':
          fact.sourceId = 2;
        case 'factOwner':
          fact.companyId = 2;
        case 'factReport':
          fact.reportId = 2;
        case 'factYear':
          fact.bsnsYear = 2023;
        case 'factBasis':
          fact.fsDiv = FsDiv.consolidated;
        case 'factAmount':
          fact.amount = BigInt.from(90552277);
        case 'factLabel':
          fact.accountName = '제품매출액';
        case 'genericNILabel':
          fact.accountName = '당기순이익';
        case 'currency':
          fact.currency = 'USD';
        case 'statement':
          fact.statement = FinancialStatementKind.cashFlow;
        case 'detail':
          fact.accountDetail = 'segment';
        case 'superseded':
          fact.supersededById = 2;
        case 'periodName':
          fact.periodName = '2020-01-01~2020-12-31';
        case 'beforePriorAmount':
          fact.beforePriorAmount = BigInt.one;
        case 'priorQuarterAmount':
          fact.priorQuarterAmount = BigInt.one;
        case 'priorAmount':
          fact.priorAmount = BigInt.one;
      }
      expect(
        FinancialAccounts.pick(
          [fact],
          company: co,
          report: report,
          source: source,
        ),
        isEmpty,
      );
    });
  }
  test('standard exact API typed-ID report keeps default, HTML cannot forge typed ID', () {
    final fact = f().copyWith(
      accountId: 'ifrs-full_ProfitLoss',
      accountName: 'API own net profit',
      amount: BigInt.from(123),
    );
    final api = s().copyWith(
      title: 'DART 전체 재무제표 (fnlttSinglAcntAll) · ${r().reportName} · 별도',
      url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${e.receipt}',
    );
    expect(
      FinancialAccounts.pick(
        [fact],
        company: c(),
        report: r(),
        source: api,
      ).single.amount,
      BigInt.from(123),
    );
    expect(
      FinancialAccounts.pick([fact], company: c(), report: r(), source: s()),
      isEmpty,
    );
  });
  test('canonical persisted proof refuses missing CE, source precision and scope laundering', () {
    Map<String, dynamic>? scope(List<Map<String, dynamic>> rows) =>
        HanwhaOwnNetIncomeScope.storedScope(
          rows: rows,
          receipt: e.receipt,
          corp: e.corpCode,
          companyName: e.companyName,
          consolidated: false,
          source: Uri.parse(HanwhaOwnNetIncomeScope.url),
          digest: HanwhaOwnNetIncomeScope.digest,
          reportName: r().reportName,
        );
    expect(scope(HanwhaOwnNetIncomeScope.expectedRows), isNotNull);
    for (final field in [
      'amount',
      'statement',
      'sourceSHA',
      'coordinate',
      'unit',
      'CEzero',
      'remainder',
      'whole',
      'notes',
    ]) {
      final bad = (jsonDecode(
        jsonEncode(HanwhaOwnNetIncomeScope.expectedRows),
      ) as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      final v = bad.first['html_provenance'] as Map;
      switch (field) {
        case 'amount':
          bad[5]['thstrm_amount'] = '0';
        case 'statement':
          bad[5]['sj_div'] = 'CF';
        case 'sourceSHA':
          v['sourceSha256'] = '0' * 64;
        case 'coordinate':
          v['currentColumn'] = 2;
        case 'unit':
          v['unit'] = '천원';
        case 'CEzero':
          v['ceRollFullyNumericVerified'] = true;
        case 'remainder':
          v['crossPrecisionLiteralRemainders'] = [0, 0, 0, 0];
        case 'whole':
          v['fullStatementCollected'] = true;
        case 'notes':
          v['notesVerified'] = true;
      }
      expect(scope(bad), isNull, reason: field);
    }
  });
  test('SQL shares exact owner, full title, current label/ord and canonical proof without JSON casts', () {
    final sql = HanwhaOwnNetIncomeScope.sqlCondition('f');
    expect(
      sql,
      contains(
        HanwhaOwnNetIncomeScope.sourceTitle(r().reportName)
            .replaceAll("'", "''"),
      ),
    );
    expect(sql, contains('f.ord=${f().ord}'));
    expect(sql, contains('f.amount::numeric=-23530284903'));
    expect(sql, contains('r."factCount"=8'));
    expect(sql, contains('count(*)'));
    expect(sql, contains('00148610'));
    expect(sql, contains('f."accountId" IS NULL'));
    expect(sql, isNot(contains('::json')));
  });
}
