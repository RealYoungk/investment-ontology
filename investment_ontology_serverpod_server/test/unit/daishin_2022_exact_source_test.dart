import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/daishin_2022_exact_source.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  const dir = 'assets/financial_source_cache/20230316001545-ofs-daishin';
  final m = jsonDecode(File('$dir/manifest.json').readAsStringSync()) as Map;
  final uris = <String, Uri>{
    for (final s in m['sources'] as List)
      s['label'] as String: Uri.parse(s['url'] as String),
  };
  final raw = <String, String>{
    for (final s in m['sources'] as List)
      s['label'] as String: File('$dir/${s['file']}').readAsStringSync(),
  };
  List<Map<String, dynamic>> parse({
    Map<String, String>? input,
    Map<String, Uri>? links,
    String receipt = '20230316001545',
    String corp = '00110893',
    bool cfs = false,
    DateTime? start,
    DateTime? end,
  }) => Daishin2022ExactSource.parse(
    raw: input ?? raw,
    uris: links ?? uris,
    receipt: receipt,
    corp: corp,
    start: start ?? DateTime.utc(2022),
    end: end ?? DateTime.utc(2022, 12, 31),
    consolidated: cfs,
  );
  test(
    'actual pinned direct eight and cash CE proofs retain labels and source',
    () {
      final rows = parse();
      expect(rows.length, 8);
      expect(rows.map((r) => r['thstrm_amount']), [
        '13561139399000',
        '11511801876000',
        '2049337523000',
        '3107330022000',
        '88877753000',
        '86474236000',
        '382074231000',
        '14288414000',
      ]);
      expect(rows.every((r) => r['account_id'] == null), isTrue);
      expect(rows.last['account_nm'], '9. 유형자산의 취득');
      expect(
        (rows[5]['html_provenance'] as Map)['fullStatementCollected'],
        isFalse,
      );
      expect(rows[5]['account_nm'], contains('대손준비금반영후'));
    },
  );
  for (final label in ['shell', 'cover', 'ofs', 'notes']) {
    test(
      '$label raw mutation rejected',
      () => expect(
        () => parse(input: {...raw, label: '${raw[label]} '}),
        throwsFormatException,
      ),
    );
    test(
      '$label wrong own URI rejected',
      () => expect(
        () => parse(
          links: {...uris, label: Uri.parse('https://dart.fss.or.kr/')},
        ),
        throwsFormatException,
      ),
    );
  }
  test(
    'wrong corporation rejects',
    () => expect(() => parse(corp: '00120181'), throwsFormatException),
  );
  test(
    'wrong receipt rejects',
    () => expect(() => parse(receipt: '20230315000964'), throwsFormatException),
  );
  test(
    'CFS conflict cannot be upgraded',
    () => expect(() => parse(cfs: true), throwsFormatException),
  );
  test(
    'notes unit cannot be borrowed or changed',
    () => expect(
      () => parse(
        input: {...raw, 'notes': raw['notes']!.replaceAll('천원', '백만원')},
      ),
      throwsFormatException,
    ),
  );
  test(
    'note definition or deposit numeric cannot be corrected',
    () => expect(
      () => parse(
        input: {
          ...raw,
          'notes': raw['notes']!.replaceFirst('182,078,250', '182,078,251'),
        },
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong actual end rejects',
    () => expect(
      () => parse(end: DateTime.utc(2022, 12, 30)),
      throwsFormatException,
    ),
  );
  test('eight raw labels resolve exact financial summary keys', () {
    final rows = parse();
    final facts = [
      for (final r in rows)
        FinancialFact(
          id: 1,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
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
  test('exact whole NI annotation rejects parent/detail or modified note', () {
    final row = parse()[5];
    FinancialFact fact(String name) => FinancialFact(
      id: 1,
      reportId: 1,
      companyId: 1,
      bsnsYear: 2022,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.separate,
      statement: FinancialStatementKind.comprehensiveIncome,
      accountName: name,
      amount: BigInt.parse('86474236000'),
      sourceId: 1,
    );
    expect(
      FinancialAccounts.resolvedIdSql('f'),
      contains(FinancialAccounts.normalizedName(row['account_nm'] as String)),
    );
    for (final label in [
      '지배주주${row['account_nm']}',
      '부문${row['account_nm']}',
      (row['account_nm'] as String).replaceAll('87,133', '86,474'),
    ]) {
      expect(FinancialAccounts.pick([fact(label)]), isEmpty);
    }
  });
}
