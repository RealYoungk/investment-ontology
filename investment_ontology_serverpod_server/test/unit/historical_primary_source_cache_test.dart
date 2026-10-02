import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final cases = jsonDecode(
    File('test/fixtures/financial_html/primary-historical-issuer/cases.json')
        .readAsStringSync(),
  ) as List;
  for (final proof in cases.take(2)) {
    final e = VerifiedAnnualSourceRegistry.find(
      proof['receipt'],
      FsDiv.separate,
    )!;
    test(
      '${e.receipt} capped whole7 cache needs only three original documents',
      () async {
        final reads = <String>[];
        final f = filing(e), before = f.toJson();
        final result = await VerifiedAnnualSourceCache(
          readAsset: (p) async {
            reads.add(p);
            return File(p).readAsBytes();
          },
        ).verifyRegistered(f, company(e), FsDiv.separate);
        expect(reads.map((p) => p.split('/').last), [
          'manifest.json',
          'shell.html',
          'cover.html',
          'ofs.html',
        ]);
        expect(f.toJson(), before);
        expect(result.absence, isNull);
        final rows = result.numeric!.rows;
        expect(rows, hasLength(7));
        expect(
          rows.map((r) => [r['account_nm'], r['thstrm_amount']]).toList(),
          proof['expectedRows'],
        );
        expect(rows.every((r) => r['account_id'] == null), true);
        expect(result.numeric!.primaryIssuerProof, isNotNull);
        for (final row in rows) {
          final identity = row['html_provenance']['primaryHistoricalIssuer'];
          expect(identity['corpCode'], e.corpCode);
          expect(identity['receipt'], e.receipt);
          expect(identity['currentMasterName'], e.companyName);
          expect(identity['primaryTitleQuotes'], hasLength(4));
          expect(identity['statementSource'], proof['urls']['ofs']);
        }
      },
    );
    for (final label in [
      'manifest.json',
      'shell.html',
      'cover.html',
      'ofs.html',
    ]) {
      test('${e.receipt} $label tamper rejects without network', () async {
        await expectLater(
          VerifiedAnnualSourceCache(
            readAsset: (p) async {
              final b = await File(p).readAsBytes();
              return p.endsWith(label) ? [...b, 32] : b;
            },
          ).verifyRegistered(filing(e), company(e), FsDiv.separate),
          throwsFormatException,
        );
      });
    }
    test('${e.receipt} wrong identity or completed status cannot replay', () {
      for (final f in [
        filing(e).copyWith(corpCode: '99999999'),
        filing(e).copyWith(bsnsYear: e.year - 1),
        filing(e).copyWith(reportCode: FinancialReportCode.halfYear),
        filing(e).copyWith(reportName: '사업보고서 (${e.year}.06)'),
        filing(e).copyWith(separateStatus: FilingFetchStatus.stored),
        filing(e).copyWith(separateStatus: FilingFetchStatus.noData),
        filing(e).copyWith(lastError: 'api-noData-annual-public:attempt=2;'),
        filing(e).copyWith(lastError: 'api-noData-annual-public:attempt=4;'),
      ]) {
        expect(VerifiedAnnualSourceCache.eligibleFor(f, e), false);
      }
      expect(
        VerifiedAnnualSourceRegistry.find(e.receipt, FsDiv.consolidated),
        isNull,
      );
    });
  }
}
