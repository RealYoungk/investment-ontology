import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/suntech_cf_current_eight_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/suntech_own_cf_scope.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final entry = VerifiedAnnualSourceRegistry.find(
    '20250317000968',
    FsDiv.consolidated,
  )!;
  final profile = SuntechCfCurrentEightSource.profiles[entry.receipt] as Map;
  final manifest = jsonDecode(
    File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
  );
  final raw = <String, String>{
    for (final s in manifest['sources'] as List)
      s['label']: File('${entry.assetDirectory}/${s['file']}')
          .readAsStringSync(),
  };
  final uris = <String, Uri>{
    for (final s in manifest['sources'] as List)
      s['label']: Uri.parse(s['url']),
  };
  List<Map<String, dynamic>> parse({
    String corp = '00963000',
    bool cfs = true,
    int year = 2024,
    Map<String, String>? changed,
  }) => SuntechCfCurrentEightSource.parse(
    raw: changed ?? raw,
    uris: uris,
    receipt: entry.receipt,
    corp: corp,
    start: DateTime.utc(year),
    end: DateTime.utc(year, 12, 31),
    consolidated: cfs,
  );
  final c = company(entry);
  final r = FinancialReport(
    id: 1,
    companyId: 1,
    rceptNo: entry.receipt,
    bsnsYear: 2024,
    reportCode: FinancialReportCode.annual,
    fsDiv: FsDiv.consolidated,
    reportName: '사업보고서 (2024.12)',
    factCount: 8,
    sourceId: 1,
    fetchedAt: DateTime.utc(2026),
  );
  final s = Source(
    id: 1,
    kind: SourceKind.dartReport,
    reference: entry.receipt,
    url: SuntechOwnCfScope.url,
    title: SuntechOwnCfScope.sourceTitle(r.reportName),
    retrievedAt: DateTime.utc(2026),
  );
  List<FinancialFact> facts() => [
    for (final row in parse())
      FinancialFact(
        id: int.parse(row['ord']),
        ord: int.parse(row['ord']),
        companyId: 1,
        reportId: 1,
        sourceId: 1,
        bsnsYear: 2024,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.consolidated,
        statement: row['sj_div'] == 'BS'
            ? FinancialStatementKind.balanceSheet
            : row['sj_div'] == 'IS'
            ? FinancialStatementKind.incomeStatement
            : FinancialStatementKind.cashFlow,
        accountName: row['account_nm'],
        accountId: null,
        amount: BigInt.parse(row['thstrm_amount']),
        currency: 'KRW',
        periodName: row['thstrm_nm'],
      ),
  ];
  test('exact own physical eight: CF NI and PPE preserve original statement/name/amount', () async {
    final actual = (await VerifiedAnnualSourceCache(
      readAsset: (p) async => File(p).readAsBytes(),
    ).verifyRegistered(filing(entry), c, entry.basis)).numeric!;
    expect(actual.sourceDigest, profile['sourceDigest']);
    expect(actual.rows, parse());
    expect(actual.rows.length, 8);
    expect(
      actual.rows,
      jsonDecode(
        File('${entry.assetDirectory}/expected-rows.json').readAsStringSync(),
      ),
    );
    final ni = actual.rows.singleWhere((x) => x['account_nm'] == '1.당기순이익');
    expect(ni['sj_div'], 'CF');
    expect(ni['account_id'], isNull);
    expect(ni['thstrm_amount'], '-1288353219');
    final ppe = actual.rows.singleWhere((x) => x['account_nm'] == '유형자산의증가');
    expect(ppe['sj_div'], 'CF');
    expect(ppe['thstrm_amount'], '93377336');
    expect(ppe['html_provenance']['cashDirection'], 'outflow');
    expect(FinancialAccounts.pick(facts()).map((l) => l.key).toSet(), {
      'assets',
      'liabilities',
      'equity',
      'revenue',
      'operatingIncome',
      'operatingCashFlow',
    });
    final selected = FinancialAccounts.pick(
      facts(),
      company: c,
      report: r,
      source: s,
    );
    expect(selected.length, 8);
    for (final key in SuntechOwnCfScope.keys) {
      final line = selected.singleWhere((l) => l.key == key);
      expect(line.statement, FinancialStatementKind.cashFlow);
      expect(line.accountId, isNull);
      expect(line.accountName, SuntechOwnCfScope.cell(key)['label']);
      expect(line.amount, BigInt.parse(SuntechOwnCfScope.cell(key)['value']));
    }
    expect(
      SuntechOwnCfScope.storedScope(
        rows: actual.rows,
        receipt: entry.receipt,
        corp: c.corpCode,
        companyName: c.name,
        consolidated: true,
        source: actual.statementSource,
        digest: actual.sourceDigest,
        reportName: r.reportName,
      ),
      SuntechOwnCfScope.proof,
    );
    for (final row in actual.rows) {
      final p = row['html_provenance'];
      expect(p['CECurrencyVerified'], false);
      expect(p['CEUnitPrinted'], false);
      expect(p['wholePLNISynthesized'], false);
      expect(p['fullStatementCollected'], false);
      expect(p['notesVerified'], false);
      expect(p['checkedPrintedEquationCount'], 14);
      expect(p['fullyNumericEquationCount'], 11);
    }
  });
  test('owner receipt period basis and every raw source pinned', () {
    expect(() => parse(corp: '00000000'), throwsFormatException);
    expect(() => parse(cfs: false), throwsFormatException);
    expect(() => parse(year: 2023), throwsFormatException);
    for (final key in raw.keys) {
      expect(
        () => parse(changed: {...raw, key: '${raw[key]} '}),
        throwsFormatException,
        reason: key,
      );
    }
  });
  test('source drift and duplicate source-bound candidate never select canonical NI/PPE', () {
    for (final bad in [
      s.copyWith(title: '${s.title} '),
      s.copyWith(reference: 'wrong'),
      s.copyWith(url: 'https://dart.fss.or.kr/wrong'),
      s.copyWith(kind: SourceKind.manual),
    ]) {
      final keys = FinancialAccounts.pick(
        facts(),
        company: c,
        report: r,
        source: bad,
      ).map((l) => l.key).toSet();
      expect(keys.intersection(SuntechOwnCfScope.keys), isEmpty);
    }
    for (final key in SuntechOwnCfScope.keys) {
      final ff = facts(),
          target = ff.singleWhere(
            (f) => f.accountName == SuntechOwnCfScope.cell(key)['label'],
          );
      ff.add(target.copyWith(id: 999));
      expect(
        FinancialAccounts.pick(
          ff,
          company: c,
          report: r,
          source: s,
        ).where((l) => l.key == key),
        isEmpty,
      );
      for (final bad in [
        target.copyWith(amount: BigInt.zero),
        target.copyWith(statement: FinancialStatementKind.incomeStatement),
        target.copyWith(accountId: 'ifrs-full_ProfitLoss'),
        target.copyWith(ord: 1),
        target.copyWith(currency: 'USD'),
        target.copyWith(periodName: '2023-01-01~2023-12-31'),
        target.copyWith(sourceId: 2),
      ]) {
        final changed = facts();
        changed[changed.indexWhere((f) => f.id == target.id)] = bad;
        expect(
          FinancialAccounts.pick(
            changed,
            company: c,
            report: r,
            source: s,
          ).where((l) => l.key == key),
          isEmpty,
        );
      }
    }
  });
  test('existing same-receipt OFS selection remains independent', () {
    final ofr = r.copyWith(fsDiv: FsDiv.separate);
    final of = facts().first.copyWith(
      id: 999,
      fsDiv: FsDiv.separate,
      statement: FinancialStatementKind.incomeStatement,
      accountName: '당기순이익',
      amount: BigInt.from(17),
    );
    expect(
      FinancialAccounts.pick(
        [of],
        company: c,
        report: ofr,
        source: s,
      ).single.key,
      'netIncome',
    );
    expect(
      FinancialAccounts.pick(
        [of],
        company: c,
        report: ofr,
        source: s,
      ).single.amount,
      BigInt.from(17),
    );
    expect(
      SuntechOwnCfScope.boundReportSql('f'),
      contains("bound_report.\"fsDiv\"='consolidated'"),
    );
  });
  test('report and context drift rejected; exact SQL finite predicates preserve source guards', () {
    for (final bad in [
      r.copyWith(rceptNo: '20250317000969'),
      r.copyWith(fsDiv: FsDiv.separate),
      r.copyWith(bsnsYear: 2023),
      r.copyWith(sourceId: 2),
      r.copyWith(factCount: 9),
    ]) {
      expect(SuntechOwnCfScope.validSource(c, bad, s), false);
    }
    expect(
      SuntechOwnCfScope.validSource(c.copyWith(corpCode: '00000000'), r, s),
      false,
    );
    final sql = FinancialAccounts.resolvedIdSql('f');
    expect(sql, contains(SuntechOwnCfScope.sqlCondition('f', 'netIncome')));
    expect(sql, contains(SuntechOwnCfScope.sqlCondition('f', 'capex')));
    expect(sql, isNot(contains(r'\"')));
    expect(
      FinancialBasis.ctes(companyId: 1),
      contains(
        "f.resolved_id='ifrs-full_ProfitLoss' AND f.statement='cashFlow'",
      ),
    );
  });
}
