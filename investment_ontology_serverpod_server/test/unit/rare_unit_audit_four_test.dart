import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

const rareAuditCore = <String, List<String>>{
  '20220315001280': [
    '279970504121',
    '52503883749',
    '227466620372',
    '98907904571',
    '77586406127',
    '65900657046',
    '20225533021',
  ],
  '20230315001270': [
    '317116709762',
    '52095398765',
    '265021310997',
    '71062149684',
    '46379304790',
    '41386370894',
    '11238243854',
  ],
  '20240320001438': [
    '12035780767',
    '8581007122',
    '3454773645',
    '25425046136',
    '1058112330',
    '-489424042',
    '1003215225',
  ],
  '20250317000968': [
    '11489071405',
    '9210486059',
    '2278585346',
    '15496735181',
    '-811594236',
    '-1288353219',
    '-921809673',
  ],
};
void main() {
  for (final r in rareAuditCore.keys) {
    final e = VerifiedAnnualSourceRegistry.find(r, FsDiv.separate)!;
    test('$r actual audited whole7 source remains actual receipt', () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        FsDiv.separate,
      );
      final source = result.numeric!;
      expect(result.absence, isNull);
      expect(
        source.rows.take(7).map((r) => r['thstrm_amount']),
        rareAuditCore[r],
      );
      expect(
        source.sourceReceipt,
        r == '20250317000968' ? '20250317000704' : r,
      );
      expect(
        source.statementSource.queryParameters['rcpNo'],
        source.sourceReceipt,
      );
      expect(
        source.rows.every(
          (row) =>
              row['account_id'] == null &&
              (row['html_provenance'] as Map)['source'] ==
                  source.statementSource.toString(),
        ),
        true,
      );
    });
    for (final file in [
      'shell',
      'cover',
      'auditShell',
      'ofs',
      if (r == '20250317000968') 'originalShell',
    ]) {
      test('$r pinned $file changed rejects before inferred unit', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final b = await File(path).readAsBytes();
            return path == '${e.assetDirectory}/$file.html' ? [...b, 32] : b;
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(e), company(e), FsDiv.separate),
          throwsFormatException,
        );
      });
    }
    test(
      '$r parser rejects contradictory company, basis, period, unit and source',
      () {
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        );
        Uri uri(String label) => Uri.parse(
          (manifest['sources'] as List).singleWhere(
            (x) => x['label'] == label,
          )['url'],
        );
        final cover = File('${e.assetDirectory}/cover.html').readAsStringSync();
        final body = File('${e.assetDirectory}/ofs.html').readAsStringSync();
        List<Map<String, dynamic>> parse({
          String? corp,
          bool? basis,
          DateTime? end,
          String? raw,
          Uri? source,
        }) => PublicFinancialHtml.parseStandardAnnual(
          coverHtml: cover,
          statementHtml: raw ?? body,
          coverSource: uri('cover'),
          statementSource: source ?? uri('ofs'),
          receipt: r == '20250317000968' ? '20250317000704' : r,
          corpCode: corp ?? e.corpCode,
          companyName: e.companyName,
          periodStart: DateTime.utc(e.year),
          periodEnd: end ?? DateTime.utc(e.year, 12, 31),
          consolidated: basis ?? false,
        );
        for (final f in [
          () => parse(corp: '00000000'),
          () => parse(basis: true),
          () => parse(end: DateTime.utc(e.year - 1, 12, 31)),
          () => parse(raw: body.replaceAll('단위 : 원', '단위 : USD')),
          () => parse(
            source: uri('ofs').replace(
              queryParameters: {...uri('ofs').queryParameters, 'dcmNo': '1'},
            ),
          ),
        ]) {
          expect(f, throwsFormatException);
        }
      },
    );
    test('$r other basis and company not eligible', () {
      expect(
        VerifiedAnnualSourceCache.eligibleFor(
          filing(e).copyWith(corpCode: '00000000'),
          e,
        ),
        false,
      );
      expect(VerifiedAnnualSourceRegistry.find(r, FsDiv.consolidated), isNull);
    });
  }
  test('literal double Roman dot whole operating label only', () {
    expect(FinancialAccounts.normalizedName('III.. 영업이익'), '영업이익');
    expect(FinancialAccounts.normalizedName('III.. 영업비용'), isNot('영업이익'));
    expect(
      FinancialAccounts.resolvedIdSql('f'),
      contains("= 'III..영업이익'"),
    );
  });
}
