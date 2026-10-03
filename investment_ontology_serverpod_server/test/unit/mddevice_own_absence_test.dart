import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20240409003743',
    FsDiv.consolidated,
  )!;
  test('MDDevice2022 own CFS none exact legal overview evidence', () async {
    var reads = 0;
    final cache = VerifiedAnnualSourceCache(
      readAsset: (p) async {
        reads++;
        return File(p).readAsBytesSync();
      },
    );
    final result = await cache.verifyRegistered(filing(e), company(e), e.basis);
    final a = result.absence!;
    expect(reads, 5);
    expect(result.numeric, isNull);
    expect(a.sourceReceipt, e.receipt);
    expect(a.corpCode, e.corpCode);
    expect(a.periodStart, DateTime.utc(2022));
    expect(a.periodEnd, DateTime.utc(2022, 12, 31));
    expect(a.issuerProof, isNotNull);
    expect(a.issuerIdentityEvidence, isNotNull);
    expect(a.statementSource.queryParameters['rcpNo'], e.receipt);
    expect(a.coverSource.queryParameters['rcpNo'], e.receipt);
    expect(a.evidence.replaceAll(RegExp(r'\s+'), ''), '"해당사항없습니다."');
  });
  for (final bad in [
    'corp',
    'receipt',
    'year',
    'halfYear',
    'opposite',
    'shell',
    'cover',
    'cfs',
    'overview',
  ]) {
    test('MDDevice2022 own CFS absence rejects $bad', () async {
      final f = filing(e), c = company(e);
      switch (bad) {
        case 'corp':
          f.corpCode = '00000000';
        case 'receipt':
          f.rceptNo = '20240101000000';
        case 'year':
          f.bsnsYear = 2023;
        case 'halfYear':
          f.reportCode = FinancialReportCode.halfYear;
      }
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final b = File(p).readAsBytesSync();
          return p.endsWith('$bad.html') ? [...b, 32] : b;
        },
      );
      expect(
        () => cache.verifyRegistered(
          f,
          c,
          bad == 'opposite' ? FsDiv.separate : e.basis,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  }
}
