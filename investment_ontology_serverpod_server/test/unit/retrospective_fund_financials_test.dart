import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/retrospective_fund_contract.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/retrospective_fund_financials.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';

void main() {
  const base = 'test/fixtures/issuer_documents/kbif_retrospective';
  final text = File('$base/corrected-20241115.txt').readAsBytesSync(),
      pdf = File('$base/corrected-20241115.pdf').readAsBytesSync(),
      independent = jsonDecode(
        File('$base/independent-ledger.json').readAsStringSync(),
      ) as Map;
  final doc = <String, dynamic>{
    'metadata': RetrospectiveFundContract.data['metadata'],
    'proof': RetrospectiveFundContract.data['documentProof'],
  };
  test('actual printed fiscal columns independently match source ledger without own-report substitution', () {
    RetrospectiveFundFinancials.verifyPdf(pdf);
    final rows = RetrospectiveFundFinancials.parse(text);
    expect(rows.length, 2);
    for (final r in rows) {
      final col = r['printedColumnOrdinal'] as int;
      for (final a in r['accounts'] as List) {
        final p = (independent['rows']['${a['pageOrdinal']}'] as List)
            .singleWhere((v) => v['line'] == a['lineOrdinal']);
        expect(a['printedAmount'], p['tokens'][col]);
        expect(a['amountInteger'], '${p['values'][col]}');
        expect(a['characterSpan'], hasLength(2));
      }
      expect(r['publishedAt'], '2024-11-15');
      expect(r['standaloneOwnAuditRetrieved'], false);
      expect(r['fullStatementCollected'], false);
      expect(r['wholeDocumentReviewed'], false);
      expect(r['ttmEligible'], false);
      expect(r['regularReportCode'], null);
      expect(r['sourceConflicts'].length, 12);
      expect(r['validation']['checks'].length, 31);
      final checks = r['validation']['checks'] as List;
      expect(checks.every((v) => v['difference'] == '0'), true);
      expect(
        r['validation']['fullyNumericEquationCount'],
        checks
            .where((v) => v['equationScope'] == 'fullyNumericPrintedEquation')
            .length,
      );
      expect(r['validation']['missingWitnessSubtotalCount'], greaterThan(0));
      expect(
        r['periodKind'],
        col == 1 ? 'ownTwelveMonthFiscalYear' : 'ownSixMonthFiscalYear',
      );
    }
    final issues = rows.first['excludedFiscalPeriods'] as List;
    expect(issues.length, 2);
    expect(issues.every((i) => (i['accounts'] as List).isEmpty), true);
    expect(issues.last['failureDifferenceInteger'], '3672767716');
    expect(IssuerFinancialsFeed.validate(rows).length, 2);
  });
  test('source metadata and prospectus acceptance is exact, not a provider/type bypass', () {
    final manifest = jsonEncode({
      'schemaVersion': 1,
      'documents': [doc],
    });
    expect(IssuerDocumentsCollector.manifest(manifest).length, 1);
    expect(IssuerFinancialsSync.supports(doc), true);
    for (final key in [
      'sha256',
      'officialUrl',
      'corpCode',
      'documentType',
      'periodStart',
      'periodEnd',
      'publishedAt',
      'issuerQuote',
      'periodQuote',
    ]) {
      final changed = jsonDecode(manifest) as Map;
      changed['documents'][0]['metadata'][key] = 'invalid';
      expect(
        () => IssuerDocumentsCollector.manifest(jsonEncode(changed)),
        throwsFormatException,
      );
      expect(
        RetrospectiveFundContract.supports(changed['documents'][0]),
        false,
      );
    }
    final changed = jsonDecode(manifest) as Map;
    changed['documents'][0]['metadata']['officialUrl'] =
        'https://kbif.co.kr/upload/2024/11/other.pdf';
    expect(
      () => IssuerDocumentsFeed.validate([changed['documents'][0]['metadata']]),
      throwsFormatException,
    );
    changed['documents'][0] = jsonDecode(jsonEncode(doc));
    changed['documents'][0]['proof']['readScope'] = 'text cover p1';
    expect(
      () => IssuerDocumentsCollector.manifest(jsonEncode(changed)),
      throwsFormatException,
    );
  });
  test('original PDF, full text, stored amounts/coordinate/period/conflict mutations fail closed', () {
    expect(
      () => RetrospectiveFundFinancials.verifyPdf([
        ...pdf.sublist(0, 10),
        0,
        ...pdf.sublist(11),
      ]),
      throwsFormatException,
    );
    expect(
      () => RetrospectiveFundFinancials.parse([
        ...text.sublist(0, 10),
        0,
        ...text.sublist(11),
      ]),
      throwsFormatException,
    );
    final rows = RetrospectiveFundFinancials.parse(text);
    for (final edit in [
      {'corpCode': '00600013'},
      {'basis': 'CFS'},
      {'periodKind': 'halfYear'},
      {'documentType': 'auditReport'},
      {'publishedAt': '2023-12-31'},
      {'standaloneOwnAuditRetrieved': true},
      {'numericState': 'complete'},
      {'fullStatementCollected': true},
      {'regularReportCode': '11011'},
      {'ttmEligible': true},
      {'sourceConflicts': []},
      {'excludedFiscalPeriods': []},
    ]) {
      final changed = jsonDecode(jsonEncode(rows)) as List;
      (changed.first as Map).addAll(edit);
      expect(
        () => IssuerFinancialsFeed.validate(changed),
        throwsFormatException,
      );
    }
    for (final key in [
      'amountInteger',
      'printedAmount',
      'lineOrdinal',
      'pageOrdinal',
      'tokenOrdinal',
      'rawLine',
    ]) {
      final changed = jsonDecode(jsonEncode(rows)) as List;
      changed.first['accounts'][0][key] = key.endsWith('Ordinal') ? 999 : '999';
      expect(
        () => IssuerFinancialsFeed.validate(changed),
        throwsFormatException,
      );
    }
    expect(
      () => IssuerFinancialsFeed.validate([rows.first, rows.first]),
      throwsFormatException,
    );
    final older = jsonDecode(jsonEncode(rows)) as List;
    older.first['periodStart'] = '2021-07-01';
    older.first['periodEnd'] = '2021-12-31';
    expect(() => IssuerFinancialsFeed.validate(older), throwsFormatException);
  });
  test('private cache requires both exact original source files and returns two bounded groups', () async {
    final cache = await Directory.systemTemp.createTemp(
      'kbif-retrospective-pure-',
    );
    addTearDown(() => cache.delete(recursive: true));
    final sha = doc['metadata']['sha256'];
    await File('${cache.path}/$sha.pdf').writeAsBytes(pdf);
    await File('${cache.path}/$sha.retrospective.txt').writeAsBytes(text);
    expect((await IssuerFinancialsSync.rows(cache, [doc])).length, 2);
    await File('${cache.path}/$sha.retrospective.txt')
        .writeAsString('shell only');
    await expectLater(
      IssuerFinancialsSync.rows(cache, [doc]),
      throwsFormatException,
    );
  });
}
