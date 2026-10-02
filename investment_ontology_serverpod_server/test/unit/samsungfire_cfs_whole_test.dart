import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  for (final receipt in ['20220310001159', '20230309000772']) {
    final e = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.consolidated)!;
    final manifest = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    );
    final cover = File('${e.assetDirectory}/cover.html').readAsStringSync();
    final body = File('${e.assetDirectory}/cfs.html').readAsStringSync();
    final coverUri = Uri.parse(
      (manifest['sources'] as List).singleWhere(
        (s) => s['label'] == 'cover',
      )['url'],
    );
    final bodyUri = Uri.parse(
      (manifest['sources'] as List).singleWhere(
        (s) => s['label'] == 'cfs',
      )['url'],
    );
    List<Map<String, dynamic>> parse({
      String? html,
      String? corp,
      String? rcept,
      Uri? source,
      int? year,
      bool cfs = true,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover,
      statementHtml: html ?? body,
      coverSource: coverUri,
      statementSource: source ?? bodyUri,
      receipt: rcept ?? receipt,
      corpCode: corp ?? e.corpCode,
      companyName: e.companyName,
      periodStart: DateTime.utc(year ?? e.year),
      periodEnd: DateTime.utc(year ?? e.year, 12, 31),
      consolidated: cfs,
    );
    test('$receipt actual whole CFS with independent NCI hierarchy', () {
      final rows = parse();
      final expected = jsonDecode(
        File('${e.assetDirectory}/expected-rows.json').readAsStringSync(),
      );
      expect(
        rows.map((r) => [r['account_nm'], r['thstrm_amount']]).toList(),
        expected,
      );
      expect(rows, hasLength(8));
      final p = rows.first['html_provenance']['wholeCoreProof'];
      expect(
        p['wholeCfsHierarchy'],
        'own-parent-components5-nci6-whole-total7',
      );
      expect(p['wholeCE']['wholeColumn'], 7);
      expect(p['wholeCE']['wholeProfit'], rows[5]['thstrm_amount']);
      expect(p['wholeCE']['closingEquity'], rows[2]['thstrm_amount']);
      expect(rows[5]['account_nm'], startsWith('X. 연결당기순이익'));
      expect(
        rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
        true,
      );
      final f = FinancialFact(
        id: 1,
        reportId: 1,
        companyId: 1,
        bsnsYear: e.year,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.consolidated,
        statement: FinancialStatementKind.comprehensiveIncome,
        accountName: rows[5]['account_nm'],
        amount: BigInt.parse(rows[5]['thstrm_amount']),
        sourceId: 1,
      );
      expect(FinancialAccounts.pick([f]).single.key, 'netIncome');
      expect(FinancialAccounts.pick([f]).single.amount, f.amount);
    });
    for (final change in [
      'corp',
      'receipt',
      'basis',
      'year',
      'coordinates',
      'whole-header',
      'parent-components',
      'currency',
      'profit-cell',
      'current-dates',
      'annotation-extra',
    ]) {
      test('$receipt immutable CFS rejects $change', () {
        expect(
          () => switch (change) {
            'corp' => parse(corp: '00139215'),
            'receipt' => parse(rcept: '20220310001158'),
            'basis' => parse(cfs: false),
            'year' => parse(year: e.year - 1),
            'coordinates' => parse(
              source: bodyUri.replace(
                queryParameters: {
                  ...bodyUri.queryParameters,
                  'dcmNo': '99999999',
                },
              ),
            ),
            'whole-header' => parse(
              html: body.replaceAll('총 &nbsp; 계', '지배기업 합계'),
            ),
            'parent-components' => parse(
              html: body.replaceAll('비지배지분', '지배기업 소유주지분'),
            ),
            'currency' => parse(html: body.replaceAll('단위: 원', '단위: 천원')),
            'profit-cell' => parse(
              html: body.replaceAll(
                e.year == 2021 ? '1,124,710,311,207' : '1,283,702,016,384',
                '1,283,702,016,385',
              ),
            ),
            'current-dates' => parse(
              html: body.replaceAll(
                '${e.year}년 12월 31일(당기말)',
                '${e.year}년 12월 30일(당기말)',
              ),
            ),
            _ => parse(html: body.replaceAll('비상위험준비금 반영후', '참고 비상위험준비금 반영후')),
          },
          throwsFormatException,
        );
      });
    }
  }
}
