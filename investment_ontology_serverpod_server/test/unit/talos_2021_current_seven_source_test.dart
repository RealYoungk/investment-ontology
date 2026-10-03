import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/talos_2021_current_seven_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20221027000409',
    FsDiv.separate,
  )!;
  test(
    'own 2021 exact rightmost current seven preserve residuals and missing PPE',
    () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      expect(result.absence, isNull);
      final rows = result.numeric!.rows;
      expect(rows, hasLength(7));
      expect(rows.map((r) => r['thstrm_amount']), [
        '12715300000',
        '7922322000',
        '4792978000',
        '8552935000',
        '630513000',
        '268403000',
        '1284415000',
      ]);
      expect(
        rows.every(
          (r) =>
              (r['html_provenance'] as Map)['fullStatementCollected'] == false,
        ),
        isTrue,
      );
      expect(rows.first['html_provenance']['partialCore7'], true);
      expect(rows.first['html_provenance']['uncollectedOptionalAccounts'], [
        'capex',
      ]);
      expect(
        rows.first['html_provenance']['printedThousandWonResiduals']['CE opening+current-profit+revaluation-closing'],
        '1',
      );
      expect(rows.first['html_provenance']['currentColumn'], 3);
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
        () => Talos2021CurrentSevenSource.parse(
          raw: raw,
          uris: uris,
          receipt: mutation == 'receipt' ? '20230718000182' : e.receipt,
          corp: mutation == 'corp' ? '00000000' : e.corpCode,
          start: DateTime.utc(mutation == 'year' ? 2022 : 2021),
          end: DateTime.utc(2021, 12, 31),
          consolidated: mutation == 'basis',
        ),
        throwsFormatException,
      );
    });
  }
}
