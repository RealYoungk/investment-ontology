import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/ls_kiwoom_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

const expected = <String, List<String>>{
  '20220324000600:consolidated': [
    '45301100676390',
    '40999237946334',
    '4301862730056',
    '5866189220774',
    '1208885819778',
    '910172830315',
    '-3528473618059',
    '-15526716807',
  ],
  '20230316001115:consolidated': [
    '6169919669399',
    '5250382412000',
    '919537257399',
    '1348600743673',
    '41776774836',
    '29709033982',
    '-44210626065',
  ],
  '20230316001115:separate': [
    '6163539030726',
    '5243911359473',
    '919627671253',
    '1348050976024',
    '41611282378',
    '29623112906',
    '-44361755686',
  ],
  '20220317000673:consolidated': [
    '6931932578875',
    '6003552338083',
    '928380240792',
    '1544545436005',
    '225778127755',
    '160829586520',
    '-171229176384',
  ],
  '20220317000673:separate': [
    '6921167983689',
    '5992611407967',
    '928556575722',
    '1540762440279',
    '225446321920',
    '160676957829',
    '-170171725867',
  ],
};
void main() {
  for (final e in VerifiedAnnualSourceRegistry.entries.where(
    (e) => LsKiwoomCurrentSource.supports(e.ruleVersion),
  )) {
    final key = '${e.receipt}:${e.basis.name}';
    final m = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    ) as Map;
    final raw = <String, String>{
      for (final s in m['sources'] as List)
        s['label'] as String: File('${e.assetDirectory}/${s['file']}')
            .readAsStringSync(),
    };
    final uris = <String, Uri>{
      for (final s in m['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? body,
      Map<String, Uri>? urls,
      String? corp,
      String? receipt,
      String? name,
      int? year,
      bool? cfs,
    }) => LsKiwoomCurrentSource.parse(
      raw: body ?? raw,
      uris: urls ?? uris,
      corp: corp ?? e.corpCode,
      receipt: receipt ?? e.receipt,
      companyName: name ?? e.companyName,
      start: DateTime.utc(year ?? e.year),
      end: DateTime.utc(year ?? e.year, 12, 31),
      consolidated: cfs ?? (e.basis == FsDiv.consolidated),
    );
    test(
      '$key exact own current cells and separate source precisions',
      () async {
        var reads = 0;
        final r = await VerifiedAnnualSourceCache(
          readAsset: (p) async {
            reads++;
            return File(p).readAsBytes();
          },
        ).verifyRegistered(filing(e), company(e), e.basis);
        expect(reads, e.corpCode == '00296290' ? 5 : 6);
        expect(r.absence, isNull);
        final rows = r.numeric!.rows;
        expect(rows.map((r) => r['thstrm_amount']), expected[key]);
        expect(
          rows.map((r) => r['account_nm']),
          parse().map((r) => r['account_nm']),
        );
        final scope = LsKiwoomCurrentSource.storedScope(
          rows: rows,
          receipt: e.receipt,
          corp: e.corpCode,
          companyName: e.companyName,
          consolidated: e.basis == FsDiv.consolidated,
          source: uris[e.statementLabel],
          digest:
              (rows.first['html_provenance'] as Map)['sourceSha256'] as String,
        );
        expect(scope?['coreRows'], rows.length);
        expect(
          LsKiwoomCurrentSource.storedScope(
            rows: rows,
            receipt: e.receipt,
            corp: '00000000',
            companyName: e.companyName,
            consolidated: e.basis == FsDiv.consolidated,
            source: uris[e.statementLabel],
            digest:
                (rows.first['html_provenance'] as Map)['sourceSha256']
                    as String,
          ),
          isNull,
        );
        final facts = [
          for (final row in rows)
            FinancialFact(
              id: rows.indexOf(row) + 1,
              reportId: 1,
              companyId: 1,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              fsDiv: e.basis,
              statement: row['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : row['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.incomeStatement,
              accountName: row['account_nm'] as String,
              amount: BigInt.parse(row['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        final keys = {
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
          if (e.corpCode == '00296290') 'capex',
        };
        expect(FinancialAccounts.pick(facts).map((r) => r.key).toSet(), keys);
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['unit'], '원');
          expect(p['unitMultiplier'], '1');
          expect(p['basis'], e.basis == FsDiv.consolidated ? 'CFS' : 'OFS');
          expect(p['wholeNetIncomeExact'], true);
          expect(p['sameUnitCurrentMainEquationsExact'], true);
          expect(p['fullStatementVerified'], false);
          expect(p['notesVerified'], false);
          expect(p['numericCellCorrection'], false);
          expect(p['genericRoundingTolerance'], false);
          expect(p['priorNumericPeriodsCollected'], false);
          expect(row.containsKey('frmtrm_amount'), false);
          final n = p['cashScopeEvidence'] as Map;
          expect(n['printedUnit'], '천원');
          expect(n['crossPrecisionEqualityClaim'], false);
          expect(n['roundingCauseClaim'], false);
          expect(n['allNotesVerified'], false);
          expect(
            n['cashDetailResidual'],
            e.corpCode == '00296290' ? '-1' : '0',
          );
          expect(p['sourceScopeNotice'], contains('주석'));
          expect(
            p['uncollectedOptionalAccounts'],
            e.corpCode == '00296290' ? isEmpty : ['capex'],
          );
        }
      },
    );
    test('$key every source and binding cannot be transplanted', () {
      expect(() => parse(corp: '00000000'), throwsFormatException);
      expect(() => parse(receipt: '19990101000000'), throwsFormatException);
      expect(() => parse(name: '이베스트투자증권(주)'), throwsFormatException);
      expect(() => parse(year: e.year - 1), throwsFormatException);
      // LS has a valid independent opposite source. Changing only the requested
      // basis with the original bytes must reject, not assert that no source exists.
      expect(
        () => parse(cfs: e.basis != FsDiv.consolidated),
        throwsFormatException,
      );
      for (final k in raw.keys) {
        expect(
          () => parse(body: {...raw, k: '${raw[k]} '}),
          throwsFormatException,
        );
        expect(
          () => parse(urls: {...uris, k: Uri.parse('${uris[k]}&changed=1')}),
          throwsFormatException,
        );
        expect(() => parse(body: {...raw}..remove(k)), throwsFormatException);
      }
      expect(
        () => parse(body: {...raw, 'extra': 'unrelated'}),
        throwsFormatException,
      );
    });
    test(
      '$key manifest and note corruption fail before emitting numeric result',
      () async {
        for (final suffix in [
          'manifest.json',
          'notes.html',
          '${e.statementLabel}.html',
        ]) {
          final cache = VerifiedAnnualSourceCache(
            readAsset: (p) async {
              final b = await File(p).readAsBytes();
              return p.endsWith(suffix) ? [...b, 32] : b;
            },
          );
          await expectLater(
            cache.verifyRegistered(filing(e), company(e), e.basis),
            throwsFormatException,
          );
        }
      },
    );
  }
}
