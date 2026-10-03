import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/db_fy22_whole_current_source.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/db_fy22_exact_issuer_identity.dart';

void main() {
  test(
    'immutable cache returns own connected eight printed accounts',
    () async {
      final f = DartFiling(
        id: 1,
        companyId: 1,
        rceptNo: '20230321001219',
        corpCode: '00115694',
        bsnsYear: 2022,
        reportCode: FinancialReportCode.annual,
        reportName: '사업보고서 (2022.12)',
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
        FsDiv.consolidated,
      );
      expect(result.numeric!.rows.length, 8);
      expect(result.numeric!.sourceReceipt, f.rceptNo);
      expect(
        result.numeric!.rows.singleWhere(
          (r) => r['account_nm'] == '영업수익',
        )['thstrm_amount'],
        '1223166577309',
      );
      expect(
        (result.numeric!.rows.first['html_provenance']
            as Map)['exactIssuerIdentity']['globalAlias'],
        false,
      );
      final capex = result.numeric!.rows.singleWhere(
        (r) => r['account_nm'] == '유형자산의 취득',
      );
      expect(capex['thstrm_amount'], '-3687283186');
      expect(capex['html_provenance']['currentCell'], '(3,687,283,186)');
      expect(capex['html_provenance']['printedUnit'], '원');
      expect(f.toJson(), before);
    },
  );
  final raw = {
    for (final label in DbFy22ExactIssuerIdentity.hashes.keys)
      label: File(
        'assets/financial_source_cache/20230321001219-cfs-exact-issuer/$label.html',
      ).readAsStringSync(),
  };
  Map<String, dynamic> verify({
    String receipt = '20230321001219',
    String corp = '00115694',
    String name = 'DB증권(주)',
    bool cfs = true,
    DateTime? start,
    Map<String, String>? documents,
  }) => DbFy22ExactIssuerIdentity.verify(
    documents ?? raw,
    receipt: receipt,
    corp: corp,
    currentName: name,
    consolidated: cfs,
    start: start ?? DateTime.utc(2022),
    end: DateTime.utc(2022, 12, 31),
  );
  test('same own filing self declaration binds exact historical cover', () {
    expect(verify()['selfDeclaredName'], '디비금융투자 주식회사');
  });
  test('other receipt including stored FY22 is not an alias', () {
    expect(() => verify(receipt: '20220316001241'), throwsFormatException);
  });
  test('other corporation rejects', () {
    expect(() => verify(corp: '00115695'), throwsFormatException);
  });
  test('other master name rejects', () {
    expect(() => verify(name: '디비금융투자'), throwsFormatException);
  });
  test('connected ambiguous basis not admitted', () {
    expect(() => verify(cfs: false), throwsFormatException);
  });
  test('wrong annual period rejects', () {
    expect(() => verify(start: DateTime.utc(2021)), throwsFormatException);
  });
  for (final label in raw.keys) {
    test('$label mutation rejects independently', () {
      expect(
        () => verify(documents: {...raw, label: '${raw[label]} altered'}),
        throwsFormatException,
      );
    });
  }
  final profile = DbFy22WholeCurrentSource.profiles.single;
  List<Map<String, dynamic>> parse({
    String? body,
    Uri? uri,
    DateTime? end,
    bool cfs = true,
  }) => DbFy22WholeCurrentSource.parse(
    receipt: '20230321001219',
    corpCode: '00115694',
    companyName: 'DB증권(주)',
    cover: raw['cover']!,
    body: body ?? raw['cfs']!,
    coverSource: Uri.parse(DbFy22ExactIssuerIdentity.urls['cover']!),
    statementSource: uri ?? Uri.parse(DbFy22ExactIssuerIdentity.urls['cfs']!),
    start: DateTime.utc(2022),
    end: end ?? DateTime.utc(2022, 12, 31),
    consolidated: cfs,
  );
  test('independent CE CF BS proof and printed source cells preserved', () {
    final rows = parse();
    expect(rows.length, 8);
    expect(rows.every((r) => r['account_id'] == null), true);
    final evidence = rows.first['html_provenance']['supportingPeriodEvidence'];
    expect(evidence['openingCash'], '544685756338');
    expect(evidence['closingCash'], '625908557652');
    expect(evidence['exchangeCash'], '-612244428');
    expect(evidence['currentProfit'], '10770184612');
    expect(evidence['fullStatementCollected'], false);
    expect(evidence['flowCaptionPrintedStart'], true);
    expect(profile['printedUnitTableIndices'], [2, 5, 8, 12]);
  });
  for (final mutation in {
    'unit': ['(단위 : 원)', '(단위 : 천원)'],
    'current-date': ['2022년 12월 31일', '2023년 12월 31일'],
    'net-income': ['10,770,184,612', '10,770,184,613'],
    'cash': ['625,908,557,652', '625,908,557,653'],
    'capex': ['3,687,283,186', '3,687,283,187'],
  }.entries) {
    test('exact raw ${mutation.key} mutation cannot change proof', () {
      final altered = raw['cfs']!.replaceAll(
        mutation.value[0],
        mutation.value[1],
      );
      expect(altered, isNot(raw['cfs']));
      expect(() => parse(body: altered), throwsFormatException);
    });
  }
  test(
    'wrong source coordinate rejects',
    () => expect(
      () => parse(
        uri: Uri.parse('${DbFy22ExactIssuerIdentity.urls['cfs']!}&x=1'),
      ),
      throwsFormatException,
    ),
  );
  test('wrong year and basis cannot reuse immutable source', () {
    expect(() => parse(end: DateTime.utc(2021, 12, 31)), throwsFormatException);
    expect(() => parse(cfs: false), throwsFormatException);
  });
}
