import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

const novmetaValues = <String, String>{
  'assets': '8348217667',
  'liabilities': '8810811187',
  'equity': '-462593520',
  'revenue': '74484000',
  'operatingIncome': '-6900304702',
  'netIncome': '-7516838106',
  'operatingCashFlow': '-4521510709',
  'capex': '-57441932',
};
void main() {
  final entry = VerifiedAnnualSourceRegistry.find(
    '20220318000715',
    FsDiv.consolidated,
  )!;
  Future<dynamic> verify(
    DartFiling f, {
    Company? owner,
    FsDiv basis = FsDiv.consolidated,
    String? tamper,
  }) => VerifiedAnnualSourceCache(
    readAsset: (path) async {
      final raw = File(path).readAsBytesSync();
      return path.endsWith(
            tamper == 'manifest' ? 'manifest.json' : '$tamper.html',
          )
          ? [...raw, 32]
          : raw;
    },
  ).verifyRegistered(f, owner ?? company(entry), basis);
  test('Novmeta2021 CFS direct whole8 and independent whole CE preserve raw source', () async {
    final before = filing(entry).toJson();
    final r = await verify(filing(entry));
    final rows = r.numeric.rows as List<Map<String, dynamic>>;
    expect(rows, hasLength(8));
    expect(rows.every((x) => x['account_id'] == null), true);
    final converted = FinancialRows.toFacts(
      rows,
      reportId: 1,
      companyId: 1,
      bsnsYear: 2021,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.consolidated,
      sourceId: 1,
    );
    for (var i = 0; i < converted.facts.length; i++) {
      converted.facts[i].id = i + 1;
    }
    final lines = FinancialAccounts.pick(converted.facts);
    for (final e in novmetaValues.entries) {
      expect(
        lines.singleWhere((l) => l.key == e.key).amount,
        BigInt.parse(e.value),
      );
    }
    expect(rows.map((r) => r['account_nm']).toList(), [
      '자산 총계',
      '부채 총계',
      '자본 총계',
      '매출액',
      '영업손실',
      '당기순손실',
      '영업활동으로부터의 순현금유출',
      '유형자산의 취득',
    ]);
    final body = File('${entry.assetDirectory}/cfs.html').readAsStringSync();
    // Direct current CE whole column, not the parent/NCI cells beside it.
    final compact = body
        .replaceAll(RegExp(r'<[^>]*>|\s+'), '')
        .replaceAll('&nbsp;', '');
    expect(
      compact,
      contains(
        '당기순손실--(7,057,722,395)--(7,057,722,395)(459,115,711)(7,516,838,106)',
      ),
    );
    expect(
      compact,
      contains(
        '2021년12월31일(당기말)4,481,433,50031,931,495,695(52,316,840,564)(223,916,510)12,071,833,853(4,055,994,026)3,593,400,506(462,593,520)',
      ),
    );
    expect(
      BigInt.parse(novmetaValues['assets']!),
      BigInt.parse(novmetaValues['liabilities']!) +
          BigInt.parse(novmetaValues['equity']!),
    );
    expect(
      r.numeric.statementSource.toString(),
      contains('rcpNo=20220318000715&dcmNo=8477481&eleId=19'),
    );
    expect(r.numeric.periodStart, DateTime.utc(2021));
    expect(r.numeric.periodEnd, DateTime.utc(2021, 12, 31));
    expect(
      r.numeric.sourceDigest,
      sha256
          .convert(
            utf8.encode('${r.numeric.coverHtml}\n${r.numeric.statementHtml}'),
          )
          .toString(),
    );
    expect(filing(entry).toJson(), before);
  });
  for (final label in ['shell', 'cover', 'cfs', 'manifest']) {
    test(
      'Novmeta2021 rejects immutable $label tamper',
      () => expect(
        () => verify(filing(entry), tamper: label),
        throwsFormatException,
      ),
    );
  }
  for (final bad in [
    'corp',
    'year',
    'quarter',
    'receipt',
    'period',
    'current-name',
  ]) {
    test('Novmeta2021 rejects wrong $bad', () async {
      final f = filing(entry);
      Company? c;
      switch (bad) {
        case 'corp':
          f.corpCode = '00000000';
        case 'year':
          f.bsnsYear = 2022;
        case 'quarter':
          f.reportCode = FinancialReportCode.halfYear;
        case 'receipt':
          f.rceptNo = '20220318000716';
        case 'period':
          f.reportName = '사업보고서 (2021.06)';
        case 'current-name':
          c = company(entry).copyWith(name: '다른법인');
      }
      await expectLater(verify(f, owner: c), throwsFormatException);
    });
  }
  test(
    'Novmeta2021 CFS never substitutes unavailable OFS',
    () => expect(
      () => verify(filing(entry), basis: FsDiv.separate),
      throwsFormatException,
    ),
  );
}
