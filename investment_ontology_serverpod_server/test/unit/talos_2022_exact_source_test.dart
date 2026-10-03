import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/talos_2022_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20230718000182',
    FsDiv.separate,
  )!;
  test(
    'own 2022 exact current eight use printed amounts and checked BS PL CE CF',
    () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      expect(result.absence, isNull);
      final rows = result.numeric!.rows;
      expect(rows, hasLength(8));
      expect(rows.map((r) => r['thstrm_amount']), [
        '13096422929',
        '6749016414',
        '6347406515',
        '12856659431',
        '2330213967',
        '885239045',
        '1837532540',
        '217935190',
      ]);
      expect(
        rows.every(
          (r) =>
              (r['html_provenance'] as Map)['fullStatementCollected'] == false,
        ),
        isTrue,
      );
      expect(rows.last['html_provenance']['printedAmount'], '(217,935,190)');
      expect(
        rows.first['html_provenance']['priorOpeningUsage'],
        contains('no prior numeric period'),
      );
    },
  );
  for (final part in ['shell', 'cover', 'ofs']) {
    test(
      'actual source rejects altered $part bytes before numeric mapping',
      () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final b = await File(path).readAsBytes();
            return path.endsWith('/$part.html') ? [...b, 32] : b;
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(e), company(e), e.basis),
          throwsFormatException,
        );
      },
    );
  }
  for (final mutation in ['uri', 'corp', 'year', 'receipt', 'basis']) {
    test('rejects wrong $mutation binding', () {
      final manifest = jsonDecode(
        File('${e.assetDirectory}/manifest.json').readAsStringSync(),
      ) as Map;
      final raw = <String, String>{}, uris = <String, Uri>{};
      for (final s in manifest['sources'] as List) {
        raw[s['label']] = File('${e.assetDirectory}/${s['file']}')
            .readAsStringSync();
        uris[s['label']] = Uri.parse(s['url']);
      }
      if (mutation == 'uri') uris['ofs'] = Uri.parse('${uris['ofs']}&extra=1');
      expect(
        () => Talos2022ExactSource.parse(
          raw: raw,
          uris: uris,
          receipt: mutation == 'receipt' ? '20221027000409' : e.receipt,
          corp: mutation == 'corp' ? '00000000' : e.corpCode,
          start: DateTime.utc(mutation == 'year' ? 2021 : 2022),
          end: DateTime.utc(2022, 12, 31),
          consolidated: mutation == 'basis',
        ),
        throwsFormatException,
      );
    });
  }
}
