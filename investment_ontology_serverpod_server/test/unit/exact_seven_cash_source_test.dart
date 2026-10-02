import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

const exactSevenValues = <String, Map<String, String>>{
  '20230323001437': {
    'assets': '24129727023',
    'liabilities': '24570272946',
    'equity': '-440545923',
    'revenue': '29945358559',
    'operatingIncome': '387897142',
    'netIncome': '-654850680',
    'operatingCashFlow': '1886295687',
  },
  '20230315000894': {
    'assets': '1502891064305',
    'liabilities': '1043504162865',
    'equity': '459386901440',
    'revenue': '1117144964059',
    'operatingIncome': '37196834948',
    'netIncome': '24033307547',
    'operatingCashFlow': '-150348093',
  },
};
void main() {
  for (final receipt in exactSevenValues.keys) {
    final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
    Future<dynamic> verify({
      DartFiling? target,
      Company? owner,
      String? tamper,
      FsDiv basis = FsDiv.separate,
    }) => VerifiedAnnualSourceCache(
      readAsset: (path) async {
        final bytes = File(path).readAsBytesSync();
        return tamper != null && path.endsWith(tamper) ? [...bytes, 32] : bytes;
      },
    ).verifyRegistered(target ?? filing(entry), owner ?? company(entry), basis);
    test(
      '$receipt own OFS direct seven / CE current-prior / CF cash witnesses',
      () async {
        final result = await verify();
        final rows = result.numeric.rows as List<Map<String, dynamic>>;
        expect(rows, hasLength(7));
        expect(rows.every((r) => r['account_id'] == null), true);
        final facts = FinancialRows.toFacts(
          rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: 1,
        ).facts;
        for (var i = 0; i < facts.length; i++) {
          facts[i].id = i + 1;
        }
        final lines = FinancialAccounts.pick(facts);
        expect(lines, hasLength(7));
        for (final e in exactSevenValues[receipt]!.entries) {
          expect(
            lines.singleWhere((l) => l.key == e.key).amount,
            BigInt.parse(e.value),
          );
        }
        expect(lines.any((l) => l.key == 'capex'), false);
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['fullStatementCollected'], false);
          expect(p['printedUnit'], '원');
          expect(p['periodStart'], '2022-01-01');
          expect(p['periodEnd'], '2022-12-31');
          expect(p['uncollectedOptionalAccounts'], ['capex']);
          expect(p['exactSevenCash']['wholeCeWitnesses'], hasLength(2));
          expect(p['exactSevenCash']['cashCurrentPriorChecked'], true);
        }
        expect(result.numeric.periodStart, DateTime.utc(2022));
        expect(result.numeric.periodEnd, DateTime.utc(2022, 12, 31));
      },
    );
    for (final part in [
      'shell.html',
      'cover.html',
      'ofs.html',
      'manifest.json',
    ]) {
      test(
        '$receipt raw $part SHA tamper rejected',
        () => expect(() => verify(tamper: part), throwsFormatException),
      );
    }
    for (final bad in [
      'corp',
      'year',
      'kind',
      'period',
      'receipt',
      'name',
      'basis',
    ]) {
      test('$receipt wrong $bad rejected', () async {
        final f = filing(entry);
        Company? c;
        var basis = FsDiv.separate;
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = 2023;
          case 'kind':
            f.reportCode = FinancialReportCode.halfYear;
          case 'period':
            f.reportName = '사업보고서 (2022.06)';
          case 'receipt':
            f.rceptNo = '20230323001438';
          case 'name':
            c = company(entry).copyWith(name: '다른회사');
          case 'basis':
            basis = FsDiv.consolidated;
        }
        await expectLater(
          verify(target: f, owner: c, basis: basis),
          throwsFormatException,
        );
      });
    }
    test(
      '$receipt unit/period/NI/CE-only/current amount mutations rejected',
      () async {
        final r = await verify(), n = r.numeric;
        for (final mutated in [
          n.statementHtml.replaceFirst('(단위', '(외화단위'),
          n.statementHtml.replaceFirst('2022년', '2023년'),
          n.statementHtml.replaceFirst('당기순', '지배기업당기순'),
          n.statementHtml.replaceFirst('총', '비지배총'),
          n.statementHtml.replaceFirst(
            receipt == '20230323001437' ? '654,850,680' : '24,033,307,547',
            '654,850,681',
          ),
          '${n.statementHtml}<table><tr><td>duplicate</td></tr></table>',
        ]) {
          expect(mutated, isNot(n.statementHtml));
          expect(
            () => PublicFinancialHtml.parseStandardAnnual(
              coverHtml: n.coverHtml,
              statementHtml: mutated,
              coverSource: n.coverSource,
              statementSource: n.statementSource,
              receipt: receipt,
              corpCode: entry.corpCode,
              companyName: entry.companyName,
              periodStart: DateTime.utc(2022),
              periodEnd: DateTime.utc(2022, 12, 31),
              consolidated: false,
            ),
            throwsFormatException,
          );
        }
      },
    );
  }
  test(
    'only exact unclosed printed Hanyang NI label maps; no grammar loosening',
    () {
      const label = FinancialAccounts.exactHanyangPrintedProfit;
      expect(FinancialAccounts.normalizedName('Ⅷ.$label'), '당기순이익');
      for (final bad in [
        label.replaceFirst('25,894', '25,895'),
        '$label:자회사',
        label.replaceFirst('전기', '부문전기'),
        label.replaceFirst('당기순이익', '지배기업당기순이익'),
      ]) {
        expect(FinancialAccounts.normalizedName(bad), isNot('당기순이익'));
      }
      expect(FinancialAccounts.resolvedIdSql('f'), contains(label));
    },
  );
}
