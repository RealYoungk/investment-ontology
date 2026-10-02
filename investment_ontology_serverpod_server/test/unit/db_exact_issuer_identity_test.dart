import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/db_exact_issuer_identity.dart';

void main() {
  test(
    'immutable cache returns own standalone eight printed accounts',
    () async {
      final f = DartFiling(
        id: 1,
        companyId: 1,
        rceptNo: '20220316001241',
        corpCode: '00115694',
        bsnsYear: 2021,
        reportCode: FinancialReportCode.annual,
        reportName: '사업보고서 (2021.12)',
        consolidatedStatus: FilingFetchStatus.failed,
        separateStatus: FilingFetchStatus.failed,
        attempts: 3,
        lastError: 'api-noData-annual-public:attempt=3; verification failed',
        discoveredAt: DateTime.utc(2026),
      );
      final c = Company(
        id: 1,
        corpCode: '00115694',
        name: 'DB증권(주)',
        stockCode: '016610',
        market: Market.kospi,
        fiscalMonth: 12,
      );
      final before = f.toJson();
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        f,
        c,
        FsDiv.separate,
      );
      expect(result.numeric!.rows.length, 8);
      expect(result.numeric!.sourceReceipt, f.rceptNo);
      expect(
        result.numeric!.rows.singleWhere(
          (r) => r['account_nm'] == '영업수익',
        )['thstrm_amount'],
        '1278947330226',
      );
      expect(
        (result.numeric!.rows.first['html_provenance']
            as Map)['exactIssuerIdentity']['globalAlias'],
        false,
      );
      expect(f.toJson(), before);
    },
  );
  final raw = {
    for (final label in DbExactIssuerIdentity.hashes.keys)
      label: File(
        'assets/financial_source_cache/20220316001241-ofs-exact-issuer/$label.html',
      ).readAsStringSync(),
  };
  Map<String, dynamic> verify({
    String receipt = '20220316001241',
    String corp = '00115694',
    String name = 'DB증권(주)',
    bool cfs = false,
    DateTime? start,
    Map<String, String>? documents,
  }) => DbExactIssuerIdentity.verify(
    documents ?? raw,
    receipt: receipt,
    corp: corp,
    currentName: name,
    consolidated: cfs,
    start: start ?? DateTime.utc(2021),
    end: DateTime.utc(2021, 12, 31),
  );
  test('same own filing self declaration binds exact historical cover', () {
    expect(verify()['selfDeclaredName'], '디비금융투자 주식회사');
  });
  test('other receipt including stored FY22 is not an alias', () {
    expect(() => verify(receipt: '20230321001219'), throwsFormatException);
  });
  test('other corporation rejects', () {
    expect(() => verify(corp: '00115695'), throwsFormatException);
  });
  test('other master name rejects', () {
    expect(() => verify(name: '디비금융투자'), throwsFormatException);
  });
  test('connected ambiguous basis not admitted', () {
    expect(() => verify(cfs: true), throwsFormatException);
  });
  test('wrong annual period rejects', () {
    expect(() => verify(start: DateTime.utc(2022)), throwsFormatException);
  });
  for (final label in raw.keys) {
    test('$label mutation rejects independently', () {
      expect(
        () => verify(documents: {...raw, label: '${raw[label]} altered'}),
        throwsFormatException,
      );
    });
  }
}
