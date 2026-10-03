import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/samsungsec_2021_own_audit_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final basis in ['cfs', 'ofs']) {
    final cfs = basis == 'cfs';
    final entry = VerifiedAnnualSourceRegistry.find(
      '20220310000784',
      cfs ? FsDiv.consolidated : FsDiv.separate,
    )!;
    final profile = SamsungSec2021OwnAuditSource.profiles[basis] as Map;
    final uris = <String, Uri>{
      for (final source in profile['sources'] as List)
        source['label'] as String: Uri.parse(source['url'] as String),
    };
    final raw = <String, String>{
      for (final source in profile['sources'] as List)
        source['label'] as String: File(
          '${entry.assetDirectory}/${source['file']}',
        ).readAsStringSync(),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? documents,
      Map<String, Uri>? links,
      String corp = '00104856',
      String receipt = '20220310000784',
      DateTime? start,
      DateTime? end,
    }) => SamsungSec2021OwnAuditSource.parse(
      raw: documents ?? raw,
      uris: links ?? uris,
      corp: corp,
      receipt: receipt,
      start: start ?? DateTime.utc(2021),
      end: end ?? DateTime.utc(2021, 12, 31),
      consolidated: cfs,
    );
    test('$basis normal exact package current8 and summary retain physical units', () async {
      var reads = 0;
      final result = await VerifiedAnnualSourceCache(
        readAsset: (p) async {
          reads++;
          return File(p).readAsBytes();
        },
      ).verifyRegistered(filing(entry), company(entry), entry.basis);
      expect(reads, 6);
      expect(result.absence, isNull);
      expect(result.numeric!.sourceReceipt, entry.receipt);
      expect(result.numeric!.correctionReceipt, isNull);
      final rows = result.numeric!.rows;
      expect(
        rows.map((r) => r['thstrm_amount']),
        cfs
            ? [
                '65707486999598',
                '59626558211304',
                '6080928788294',
                '9809518741000',
                '1308683292414',
                '965338208537',
                '-2074931652028',
                '10679117986',
              ]
            : [
                '59641733206965',
                '53716199273175',
                '5925533933790',
                '9665173191000',
                '1288559477610',
                '936741374045',
                '-1775023755295',
                '10451260965',
              ],
      );
      expect(
        rows.every((r) => r['ord'] is String && r['account_id'] == null),
        isTrue,
      );
      expect(rows[3]['html_provenance']['printedPhysicalLabel'], '소계');
      expect(rows[3]['html_provenance']['precisionUnit'], '1000');
      expect(rows[4]['html_provenance']['precisionUnit'], '1');
      expect(
        rows[4]['html_provenance']['sourceDiscrepancies'][0]['convertedDifferenceWon'],
        cfs ? 414 : -390,
      );
      expect(profile['checks'], hasLength(cfs ? 51 : 37));
      expect(
        profile,
        jsonDecode(
          File('${entry.assetDirectory}/current-evidence.json')
              .readAsStringSync(),
        ),
      );
      final facts = [
        for (final r in rows)
          FinancialFact(
            id: 1,
            reportId: 1,
            companyId: 1,
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            fsDiv: entry.basis,
            statement: r['sj_div'] == 'BS'
                ? FinancialStatementKind.balanceSheet
                : r['sj_div'] == 'CF'
                ? FinancialStatementKind.cashFlow
                : FinancialStatementKind.comprehensiveIncome,
            accountName: r['account_nm'] as String,
            accountId: null,
            amount: BigInt.parse(r['thstrm_amount'] as String),
            sourceId: 1,
          ),
      ];
      expect(
        FinancialAccounts.pick(facts).map((l) => l.key),
        containsAll([
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
      expect(
        rows.every(
          (r) =>
              r['html_provenance']['fullStatementCollected'] == false &&
              r['html_provenance']['notesReadScopeComplete'] == false,
        ),
        isTrue,
      );
    });
    for (final filename in [
      'shell.html',
      'cover.html',
      'audit-shell.html',
      'audit-primary.html',
      'main-$basis.html',
    ]) {
      test('$basis adapter rejects altered $filename', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final bytes = await File(p).readAsBytes();
            return p.endsWith('/$filename') ? [...bytes, 32] : bytes;
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(entry), company(entry), entry.basis),
          throwsFormatException,
        );
      });
    }
    for (final mutation in ['unknown-filename', 'unknown-label']) {
      test('$basis manifest $mutation rejected', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final bytes = await File(p).readAsBytes();
            if (!p.endsWith('manifest.json')) return bytes;
            final text = utf8.decode(bytes);
            return utf8.encode(
              mutation == 'unknown-filename'
                  ? text.replaceFirst('audit-primary.html', 'unknown.html')
                  : text.replaceFirst('auditShell', 'unknownLabel'),
            );
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(entry), company(entry), entry.basis),
          throwsFormatException,
        );
      });
    }
    test(
      '$basis rejects opposite basis original and URI',
      () => expect(
        () => parse(
          documents: {
            ...raw,
            basis: File(
              'assets/financial_source_cache/20220310000784-${cfs ? 'ofs' : 'cfs'}-samsungsec-own-audit-current-eight/audit-primary.html',
            ).readAsStringSync(),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      '$basis wrong issuer rejected',
      () => expect(() => parse(corp: '00113191'), throwsFormatException),
    );
    test(
      '$basis wrong receipt rejected',
      () =>
          expect(() => parse(receipt: '20230309000572'), throwsFormatException),
    );
    test(
      '$basis prior year rejected',
      () => expect(
        () => parse(start: DateTime.utc(2020), end: DateTime.utc(2020, 12, 31)),
        throwsFormatException,
      ),
    );
    test(
      '$basis changed own source URI rejected',
      () => expect(
        () => parse(
          links: {...uris, basis: Uri.parse('${uris[basis]}&altered=1')},
        ),
        throwsFormatException,
      ),
    );
    test(
      '$basis missing audit chain rejected',
      () => expect(
        () => parse(documents: {...raw}..remove('auditShell')),
        throwsFormatException,
      ),
    );
    test(
      '$basis own current numeric cell tamper rejected',
      () => expect(
        () => parse(
          documents: {
            ...raw,
            basis: raw[basis]!.replaceFirst(
              cfs ? '965,338,208,537' : '936,741,374,045',
              '1,2,3',
            ),
          },
        ),
        throwsFormatException,
      ),
    );
  }
  test('exact ninth capex fallback preserves CF label and SQL, excludes other statements', () {
    const label = '(9)유형자산의취득';
    final row = FinancialFact(
      id: 1,
      reportId: 1,
      companyId: 1,
      bsnsYear: 2021,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.consolidated,
      statement: FinancialStatementKind.cashFlow,
      accountName: label,
      amount: BigInt.parse('10679117986'),
      sourceId: 1,
    );
    final line = FinancialAccounts.pick([row]).single;
    expect(line.key, 'capex');
    expect(line.accountName, label);
    expect(line.amount, row.amount);
    final sql = FinancialAccounts.resolvedIdSql('f');
    expect(sql, contains("'(9)유형자산의취득'"));
    expect(sql, contains("f.statement IN ('cashFlow')"));
    for (final st in FinancialStatementKind.values) {
      if (st != FinancialStatementKind.cashFlow) {
        expect(FinancialAccounts.pick([row.copyWith(statement: st)]), isEmpty);
      }
    }
    for (final name in ['(10)유형자산의취득', '(9)유형자산의취득 참고', '(9)사용권자산의취득']) {
      expect(
        FinancialAccounts.pick([row.copyWith(accountName: name)]),
        isEmpty,
      );
    }
  });
}
