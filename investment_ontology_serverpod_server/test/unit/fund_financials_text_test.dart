import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/fund_financial_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/fund_financials_text.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';

void main() {
  final independent = jsonDecode(
    File(
      'test/fixtures/issuer_documents/fund_text/independent-current-proof.json',
    ).readAsStringSync(),
  ) as List;
  List<int> bytes(Map p) => File(
    'test/fixtures/issuer_documents/fund_text/${p['metadata']['periodEnd']}.txt',
  ).readAsBytesSync();
  for (final p in FundFinancialProfiles.rows) {
    final m = p['metadata'] as Map, end = m['periodEnd'];
    test('$end exact full text current fund cells and all six checks', () {
      final row = FundFinancialsText.parseText(m, bytes(p));
      final expected =
          independent.singleWhere((r) => r['periodEnd'] == end) as Map;
      final accounts = row['numericState'] == 'pendingCashScope'
          ? row['quarantinedAccounts']
          : row['accounts'];
      expect(accounts.length, 7);
      for (var i = 0; i < 7; i++) {
        for (final k in [
          'metric',
          'statement',
          'accountLabel',
          'printedAmount',
          'amountInteger',
          'comparativePrintedAmount',
          'pageOrdinal',
          'lineOrdinal',
          'rawLine',
          'periodStart',
          'periodEnd',
          'amountScope',
          'cashDirection',
        ]) {
          expect(accounts[i][k], expected['observations'][i][k], reason: k);
        }
      }
      for (final k in [
        'balanceDifference',
        'cashRollDifference',
        'cashActivityDifference',
        'equityCloseDifference',
        'equityMovementDifference',
        'wholeProfitDifference',
        'currentBSCashMinusCF',
        'comparativeBSCashMinusCF',
        'currentBSCashAndDepositsMinusCF',
        'comparativeBSCashAndDepositsMinusCF',
        'notesCashDefinitionQuote',
        'notesCashDefinitionContradiction',
      ]) {
        expect(row['validation'][k], expected['validation'][k], reason: k);
      }
      expect(row['numericState'], expected['numericState']);
      expect(row['fullStatementCollected'], false);
      expect(row['regularReportCode'], null);
      expect(row['xbrlAccountId'], null);
      expect(IssuerFinancialsFeed.validate([row]), [row]);
    });
    test(
      '$end altered text and wrong company/period/unit/state fail closed',
      () {
        final original = FundFinancialsText.parseText(m, bytes(p));
        final changed = bytes(p)..[10] = 32;
        expect(
          () => FundFinancialsText.parseText(m, changed),
          throwsFormatException,
        );
        for (final edit in [
          {'corpCode': '00435297'},
          {'sha256': 'invented'},
          {'periodEnd': '2026-12-31'},
          {'currency': 'USD'},
          {'basis': 'CFS'},
          {'numericState': 'complete'},
          {'regularReportCode': '11011'},
          {'periodKind': 'halfYear'},
          {'categorySchema': 'industrial'},
        ]) {
          final row = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
          row.addAll(edit);
          expect(
            () => IssuerFinancialsFeed.validate([row]),
            throwsFormatException,
          );
        }
        final metadata = Map<String, dynamic>.from(m)
          ..['periodStart'] = '2026-04-01';
        expect(
          () => FundFinancialsText.parseText(metadata, bytes(p)),
          throwsFormatException,
        );
        expect(
          () => FundFinancialsText.verifyPdf(m, utf8.encode('%PDF-unreviewed')),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'normal cache reader requires original PDF and exact private complete text',
    () async {
      final p = FundFinancialProfiles.rows.last, m = p['metadata'] as Map;
      final cache = await Directory.systemTemp.createTemp(
        'fund-pure-private-cache-',
      );
      addTearDown(() => cache.delete(recursive: true));
      final pdf = File('${cache.path}/${m['sha256']}.pdf'),
          text = File('${cache.path}/${m['sha256']}.fund.txt');
      final original = File(
        'test/fixtures/issuer_documents/mapps-2026-half.pdf',
      ).readAsBytesSync();
      await pdf.writeAsBytes(original);
      await text.writeAsBytes(bytes(p));
      FundFinancialsText.verifyPdf(m, original);
      final documents = [
        {'metadata': m, 'proof': <String, dynamic>{}},
      ];
      expect(
        (await IssuerFinancialsSync.rows(
          cache,
          documents,
        )).single['accounts'].length,
        7,
      );
      await text.delete();
      await expectLater(
        IssuerFinancialsSync.rows(cache, documents),
        throwsA(isA<FileSystemException>()),
      );
      await text.writeAsBytes(bytes(p));
      await pdf.writeAsBytes(List<int>.from(original)..[10] = 32);
      await expectLater(
        IssuerFinancialsSync.rows(cache, documents),
        throwsFormatException,
      );
    },
  );
  test('stored proof rejects coordinated literal changes despite claimed zero checks', () {
    final p = FundFinancialProfiles.rows.last;
    final original = FundFinancialsText.parseText(p['metadata'], bytes(p));
    for (final index in [0, 4, 5]) {
      final row = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      final account = row['accounts'][index];
      account['rawLine'] = (account['rawLine'] as String).replaceFirst(
        account['printedAmount'],
        '1',
      );
      account['printedAmount'] = '1';
      account['amountInteger'] = '1';
      expect(() => IssuerFinancialsFeed.validate([row]), throwsFormatException);
    }
    final row = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    row['validation']['currentBSCashMinusCF'] = '99';
    expect(() => IssuerFinancialsFeed.validate([row]), throwsFormatException);
  });
  test('six documents stay separate and missing/double signs are rejected', () {
    final rows = FundFinancialProfiles.rows
        .map((p) => FundFinancialsText.parseText(p['metadata'], bytes(p)))
        .toList();
    expect(IssuerFinancialsFeed.validate(rows).length, 6);
    expect(
      rows.where((r) => r['numericState'] == 'pendingCashScope').length,
      2,
    );
    expect(rows.expand((r) => r['accounts'] as List).length, 28);
    expect(rows.expand((r) => r['quarantinedAccounts'] as List).length, 14);
    expect(rows.last['periodKind'], 'ownSixMonthFiscalYear');
    expect(FundFinancialsText.integer('-'), null);
    expect(() => FundFinancialsText.integer('(-1)'), throwsFormatException);
    expect(
      () => IssuerFinancialsFeed.validate([...rows, rows.first]),
      throwsFormatException,
    );
  });
}
