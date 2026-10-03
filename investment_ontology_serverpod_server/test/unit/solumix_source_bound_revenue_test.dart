import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/filing_series_current_eight_source.dart';

import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/solumix_own_revenue_scope.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    SolumixOwnRevenueScope.receipt,
    FsDiv.separate,
  )!;
  Company c() => company(e);
  FinancialReport r() => FinancialReport(
    id: 1,
    companyId: 1,
    rceptNo: e.receipt,
    bsnsYear: 2021,
    reportCode: FinancialReportCode.annual,
    fsDiv: FsDiv.separate,
    reportName: '사업보고서 (2021.12)',
    factCount: 8,
    invalidAmountCount: 0,
    sourceId: 1,
    fetchedAt: DateTime.utc(2026),
  );
  Source s() => Source(
    id: 1,
    kind: SourceKind.dartReport,
    reference: e.receipt,
    title: SolumixOwnRevenueScope.sourceTitle(r().reportName),
    url: SolumixOwnRevenueScope.url,
    retrievedAt: DateTime.utc(2026),
  );
  FinancialFact f() => FinancialFact(
    id: 1,
    reportId: 1,
    companyId: 1,
    bsnsYear: 2021,
    reportCode: FinancialReportCode.annual,
    fsDiv: FsDiv.separate,
    statement: FinancialStatementKind.comprehensiveIncome,
    accountName: SolumixOwnRevenueScope.label,
    amount: SolumixOwnRevenueScope.amount,
    periodName: '2021-01-01~2021-12-31',
    currency: 'KRW',
    sourceId: 1,
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
    expect(line.key, 'revenue');
    expect(line.amount, SolumixOwnRevenueScope.amount);
    expect(line.accountName, SolumixOwnRevenueScope.label);
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
    'factSource',
    'factOwner',
    'factReport',
    'factYear',
    'factBasis',
    'factAmount',
    'factLabel',
    'genericRevenueLabel',
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
          source.reference = '20220329001198';
        case 'url':
          source.url = '${SolumixOwnRevenueScope.url} ';
        case 'kind':
          source.kind = SourceKind.manual;
        case 'corp':
          co.corpCode = '00000000';
        case 'companyName':
          co.name = '주식회사 로보쓰리';
        case 'companyOwner':
          co.id = 2;
        case 'reportReceipt':
          report.rceptNo = '20220329001198';
        case 'reportYear':
          report.bsnsYear = 2022;
        case 'reportBasis':
          report.fsDiv = FsDiv.consolidated;
        case 'reportCode':
          report.reportCode = FinancialReportCode.halfYear;
        case 'reportName':
          report.reportName = '사업보고서 (2022.12)';
        case 'reportSource':
          report.sourceId = 2;
        case 'factSource':
          fact.sourceId = 2;
        case 'factOwner':
          fact.companyId = 2;
        case 'factReport':
          fact.reportId = 2;
        case 'factYear':
          fact.bsnsYear = 2022;
        case 'factBasis':
          fact.fsDiv = FsDiv.consolidated;
        case 'factAmount':
          fact.amount = BigInt.from(90552277);
        case 'factLabel':
          fact.accountName = '제품매출액';
        case 'genericRevenueLabel':
          fact.accountName = '매출액';
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
  test('actual own cache current8, six numericzero, FXdash unknown and explicit negative investment outflow magnitude', () async {
    final result = await VerifiedAnnualSourceCache().verifyRegistered(
      filing(e),
      company(e),
      e.basis,
    );
    final rows = result.numeric!.rows;
    expect(rows.map((x) => x['thstrm_amount']), [
      '7196246873',
      '487642114',
      '6708604759',
      '90552276',
      '-1462706911',
      '-1469436487',
      '-847433956',
      '173072000',
    ]);
    for (final row in rows) {
      final p = row['html_provenance'] as Map;
      expect(
        (p['supportingPeriodEvidence']['currentEquationWitnesses'] as List),
        hasLength(6),
      );
      expect(p['printedMissingTermScope']['numericValue'], isNull);
      expect(p['printedMissingTermScope']['storedAsZero'], false);
      expect(
        p['printedMissingTermScope']['fullyNumericEquationVerified'],
        false,
      );
      expect(p['fullStatementCollected'], false);
    }
    expect(rows.last['html_provenance']['cashDirection'], 'outflow');
    expect(
      SolumixOwnRevenueScope.storedScope(
        rows: rows,
        receipt: e.receipt,
        corp: e.corpCode,
        companyName: e.companyName,
        consolidated: false,
        source: result.numeric!.statementSource,
        digest: result.numeric!.sourceDigest,
        reportName: r().reportName,
      ),
      isNotNull,
    );
  });
  for (final file in [
    'shell.html',
    'cover.html',
    'ofs.html',
    'manifest.json',
  ]) {
    test('actual cache rejects $file drift', () async {
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final bytes = await File(p).readAsBytes();
          return p.endsWith('/$file') ? [...bytes, 32] : bytes;
        },
      );
      expect(
        () => cache.verifyRegistered(filing(e), company(e), e.basis),
        throwsA(isA<FormatException>()),
      );
    });
  }
  test(
    'actual parser rejects wrong basis and current year with exact bytes',
    () {
      final manifest = jsonDecode(
        File('${e.assetDirectory}/manifest.json').readAsStringSync(),
      ) as Map;
      final sources = manifest['sources'] as List;
      for (final wrongBasis in [true, false]) {
        expect(
          () => FilingSeriesCurrentEightSource.parse(
            receipt: e.receipt,
            corpCode: e.corpCode,
            companyName: e.companyName,
            consolidated: wrongBasis,
            start: wrongBasis ? e.periodStart : DateTime.utc(2020),
            end: e.periodEnd,
            raw: {
              for (final s in sources)
                s['label']: File('${e.assetDirectory}/${s['file']}')
                    .readAsStringSync(),
            },
            uris: {for (final s in sources) s['label']: Uri.parse(s['url'])},
          ),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );
  test('stored proof rejects amount, ID, full verification and FX-zero laundering', () async {
    final result = await VerifiedAnnualSourceCache().verifyRegistered(
      filing(e),
      company(e),
      e.basis,
    );
    for (final bad in ['amount', 'id', 'full', 'fxZero', 'equationClaim']) {
      final rows = (jsonDecode(jsonEncode(result.numeric!.rows)) as List)
          .cast<Map<String, dynamic>>();
      switch (bad) {
        case 'amount':
          rows[3]['thstrm_amount'] = '90552277';
        case 'id':
          rows[3]['account_id'] = 'ifrs-full_Revenue';
        case 'full':
          rows[3]['html_provenance']['fullStatementCollected'] = true;
        case 'fxZero':
          rows[3]['html_provenance']['printedMissingTermScope']['numericValue'] =
              '0';
        case 'equationClaim':
          rows[3]['html_provenance']['supportingPeriodEvidence']['currentEquationWitnesses']
              .add(
                rows[3]['html_provenance']['supportingPeriodEvidence']['currentEquationWitnesses'][0],
              );
      }
      expect(
        SolumixOwnRevenueScope.storedScope(
          rows: rows,
          receipt: e.receipt,
          corp: e.corpCode,
          companyName: e.companyName,
          consolidated: false,
          source: result.numeric!.statementSource,
          digest: result.numeric!.sourceDigest,
          reportName: r().reportName,
        ),
        isNull,
      );
    }
  });
  test('SQL uses complete finite Source title and all owner pins; no JSON cast or generic product alias', () {
    final sql = FinancialAccounts.resolvedIdSql('f');
    expect(sql, contains('FROM financial_report r JOIN company c'));
    expect(sql, contains('JOIN source s'));
    expect(sql, contains('s.title='));
    expect(sql, contains("c.\"corpCode\"='01118643'"));
    expect(sql, contains("r.\"rceptNo\"='20220329001197'"));
    expect(sql, contains('count(*)'));
    expect(sql, isNot(contains('::json')));
    expect(
      FinancialAccounts.fallbackNames['revenue'],
      isNot(contains('제품매출액')),
    );
  });
}
