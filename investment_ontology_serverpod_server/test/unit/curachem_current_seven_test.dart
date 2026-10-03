import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20250305000164',
    FsDiv.separate,
  )!;
  test('own exact current seven preserves absent whole PPE total', () async {
    final r = await VerifiedAnnualSourceCache().verifyRegistered(
      filing(e),
      company(e),
      e.basis,
    );
    expect(r.absence, isNull);
    expect(r.numeric!.rows.map((r) => r['thstrm_amount']).toList(), [
      '15425583523',
      '8124107688',
      '7301475835',
      '5356867177',
      '-406123410',
      '-266546846',
      '-487952845',
    ]);
    final facts = [
      for (var i = 0; i < r.numeric!.rows.length; i++)
        FinancialFact(
          id: i + 1,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          statement: switch (r.numeric!.rows[i]['sj_div']) {
            'BS' => FinancialStatementKind.balanceSheet,
            'IS' => FinancialStatementKind.incomeStatement,
            _ => FinancialStatementKind.cashFlow,
          },
          accountName: r.numeric!.rows[i]['account_nm'] as String,
          amount: BigInt.parse(r.numeric!.rows[i]['thstrm_amount'] as String),
          sourceId: 1,
        ),
    ];
    final lines = FinancialAccounts.pick(facts);
    expect(lines.map((l) => l.key).toSet(), {
      'assets',
      'liabilities',
      'equity',
      'revenue',
      'operatingIncome',
      'netIncome',
      'operatingCashFlow',
    });
    expect(lines.any((l) => l.key == 'capex'), false);
    expect(r.numeric!.rows.every((r) => r['account_id'] == null), true);
    for (final row in r.numeric!.rows) {
      final p = row['html_provenance'] as Map;
      expect(p['partialCore7'], true);
      expect(p['column'], 3);
      expect(p['currentHeader'], '2024연도(제16기)');
      expect(p['fullStatementCollected'], false);
      expect(p['allStatementRowsVerified'], false);
      expect(p['detailHierarchyComplete'], false);
      expect(p['notesVerified'], false);
      expect(p['notesReadScopeComplete'], false);
      expect(p['uncollectedOptionalAccounts'], ['capex']);
      expect(
        (p['missingAccountReasons'] as Map)['capex'],
        contains('not the total'),
      );
    }
  });
  for (final mutation in ['shell', 'cover', 'ofs', 'corp', 'year', 'basis']) {
    test('exact original rejects $mutation', () async {
      final f = filing(e);
      if (mutation == 'corp') f.corpCode = '00000000';
      if (mutation == 'year') f.bsnsYear = 2023;
      final cache = VerifiedAnnualSourceCache(
        readAsset: (path) async {
          final b = await File(path).readAsBytes();
          return path.endsWith('/$mutation.html') ? [...b, 32] : b;
        },
      );
      await expectLater(
        cache.verifyRegistered(
          f,
          company(e),
          mutation == 'basis' ? FsDiv.consolidated : e.basis,
        ),
        throwsFormatException,
      );
    });
  }
}
