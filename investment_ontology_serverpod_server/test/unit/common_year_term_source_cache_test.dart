import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final entry = VerifiedAnnualSourceRegistry.find(
    '20250321001653',
    FsDiv.separate,
  )!;
  Future<dynamic> verify(
    DartFiling f, {
    FsDiv basis = FsDiv.separate,
    bool tamper = false,
  }) async => VerifiedAnnualSourceCache(
    readAsset: (path) async {
      final bytes = File(path).readAsBytesSync();
      return tamper && path.endsWith('ofs.html') ? [...bytes, 32] : bytes;
    },
  ).verifyRegistered(f, company(entry), basis);
  test('exact actual package source seven values and CE whole proof', () async {
    final f = filing(entry);
    final before = f.toJson();
    final r = await verify(f);
    expect(r!.numeric!.rows.take(7).map((r) => r['thstrm_amount']).toList(), [
      '46061578422',
      '31944885315',
      '14116693107',
      '20980394946',
      '-3323843419',
      '-3287506222',
      '4300195369',
    ]);
    expect(f.toJson(), before);
    expect(
      r.numeric!.statementSource.toString(),
      contains('dcmNo=10449285&eleId=21&offset=715884&length=49841'),
    );
    expect(
      r.numeric!.rows.every(
        (r) =>
            (r['html_provenance']
                as Map)['supportingWholeEquityEvidence']['wholeProfit'] ==
            '-3287506222',
      ),
      isTrue,
    );
  });
  for (final bad in ['corp', 'year', 'quarter', 'receipt']) {
    test('exact source eligibility rejects $bad', () async {
      final f = filing(entry);
      switch (bad) {
        case 'corp':
          f.corpCode = '00000000';
        case 'year':
          f.bsnsYear = 2023;
        case 'quarter':
          f.reportCode = FinancialReportCode.halfYear;
        case 'receipt':
          f.rceptNo = '20250321001654';
      }
      expect(() => verify(f), throwsA(isA<FormatException>()));
    });
  }
  test('opposite basis selects its independently approved source', () async {
    final opposite = VerifiedAnnualSourceRegistry.find(
      entry.receipt,
      FsDiv.consolidated,
    )!;
    final result = await verify(filing(entry), basis: FsDiv.consolidated);
    expect(result!.numeric, isNotNull);
    expect(opposite.manifestDigest, isNot(entry.manifestDigest));
    expect(
      result.numeric!.statementSource.toString(),
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001653&dcmNo=10449285&eleId=19&offset=299229&length=58169&dtd=dart4.xsd',
    );
    final separate = await verify(filing(entry));
    expect(
      result.numeric!.statementSource,
      isNot(separate!.numeric!.statementSource),
    );
    expect(
      result.numeric!.rows.every(
        (row) => (row['html_provenance'] as Map)['basis'] == 'CFS',
      ),
      isTrue,
    );
  });
  test(
    'immutable raw source tamper rejected',
    () => expect(
      () => verify(filing(entry), tamper: true),
      throwsA(isA<FormatException>()),
    ),
  );
}
