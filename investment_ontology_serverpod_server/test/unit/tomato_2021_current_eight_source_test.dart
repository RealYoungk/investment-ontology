import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/tomato_2021_current_eight_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

void main() {
  const dir =
      'assets/financial_source_cache/20220329000107-cfs-tomato-current-eight';
  final p = Tomato2021CurrentEightSource.profile;
  final uris = <String, Uri>{
    for (final s in p['sources'] as List)
      s['label'] as String: Uri.parse(s['url'] as String),
  };
  final raw = <String, String>{
    for (final s in p['sources'] as List)
      s['label'] as String: File('$dir/${s['file']}').readAsStringSync(),
  };
  List<Map<String, dynamic>> parse({
    Map<String, String>? input,
    Map<String, Uri>? links,
    String receipt = '20220329000107',
    String corp = '01436479',
    bool cfs = true,
    DateTime? from,
    DateTime? to,
  }) => Tomato2021CurrentEightSource.parse(
    raw: input ?? raw,
    uris: links ?? uris,
    receipt: receipt,
    corp: corp,
    start: from ?? DateTime.utc(2021),
    end: to ?? DateTime.utc(2021, 12, 31),
    consolidated: cfs,
  );
  test(
    'own current8 sourcebound, wholeNI distinct, partial scopes preserved',
    () {
      final rows = parse();
      expect(rows.map((r) => r['thstrm_amount']), [
        '11540049550',
        '8755743896',
        '2784305654',
        '22856123584',
        '1493134849',
        '1285575825',
        '1628812748',
        '24903518',
      ]);
      expect(
        rows.every((r) => r['account_id'] == null && r['ord'] is String),
        true,
      );
      expect(rows[5]['thstrm_amount'], isNot('1290553743'));
      expect(rows.last['html_provenance']['currentCell'], '(24,903,518)');
      expect(rows.last['html_provenance']['cashDirection'], 'outflow');
      expect(
        rows.every(
          (r) =>
              r['html_provenance']['fullStatementCollected'] == false &&
              r['html_provenance']['source'] == uris['cfs'].toString(),
        ),
        true,
      );
      expect((p['checks'] as List).length, 36);
      expect(p['scopeProof']['fullyNumericEquationCount'], lessThan(36));
      expect(p['scopeProof']['missingTermNotZero'], true);
      expect(p['scopeProof']['notesDecodedOrVerified'], false);
      expect(
        VerifiedAnnualSourceRegistry.find('20220329000107', FsDiv.consolidated),
        isNotNull,
      );
      expect(
        VerifiedAnnualSourceRegistry.find('20220329000107', FsDiv.separate),
        isNull,
      );
    },
  );
  test(
    'compiled source profile exactly matches package',
    () => expect(p, jsonDecode(File('$dir/profile.json').readAsStringSync())),
  );
  test('normal financial summary recognizes eight finite original labels', () {
    final facts = [
      for (final r in parse())
        FinancialFact(
          id: 1,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2021,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.consolidated,
          statement: r['sj_div'] == 'BS'
              ? FinancialStatementKind.balanceSheet
              : r['sj_div'] == 'CF'
              ? FinancialStatementKind.cashFlow
              : FinancialStatementKind.comprehensiveIncome,
          accountName: r['account_nm'] as String,
          amount: BigInt.parse(r['thstrm_amount'] as String),
          sourceId: 1,
        ),
    ];
    expect(
      FinancialAccounts.pick(facts).map((l) => l.key),
      unorderedEquals([
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
        'capex',
      ]),
    );
  });
  for (final label in ['shell', 'cover', 'cfs']) {
    test(
      '$label wrong URI rejects',
      () => expect(
        () => parse(
          links: {...uris, label: Uri.parse('https://dart.fss.or.kr/')},
        ),
        throwsFormatException,
      ),
    );
    test(
      '$label altered bytes reject',
      () => expect(
        () => parse(input: {...raw, label: '${raw[label]} '}),
        throwsFormatException,
      ),
    );
  }
  test(
    'wrong receipt rejects',
    () => expect(() => parse(receipt: '20220329000108'), throwsFormatException),
  );
  test(
    'wrong issuer rejects',
    () => expect(() => parse(corp: '01436478'), throwsFormatException),
  );
  test(
    'OFS remains unapproved',
    () => expect(() => parse(cfs: false), throwsFormatException),
  );
  test(
    'wrong start rejects',
    () => expect(() => parse(from: DateTime.utc(2020)), throwsFormatException),
  );
  test(
    'wrong end rejects',
    () => expect(
      () => parse(to: DateTime.utc(2021, 12, 30)),
      throwsFormatException,
    ),
  );
  test(
    'invalid grouped monetary original rejects',
    () => expect(
      () => parse(
        input: {
          ...raw,
          'cfs': raw['cfs']!.replaceFirst('24,903,518', '24,9,3,518'),
        },
      ),
      throwsFormatException,
    ),
  );
  test(
    'missing raw cannot use cached values',
    () => expect(
      () => parse(input: {'shell': raw['shell']!, 'cover': raw['cover']!}),
      throwsFormatException,
    ),
  );
}
