import '../support/financial_html_test_clock.dart';

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in [
    '20230314001271',
    '20230309000572',
    '20230323001133',
  ]) {
    final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
    Future<dynamic> verify(
      DartFiling f, {
      bool tamper = false,
      FsDiv basis = FsDiv.separate,
      bool onlySeparateSources = false,
    }) => VerifiedAnnualSourceCache(
      readAsset: (path) async {
        if (onlySeparateSources &&
            !path.startsWith('${entry.assetDirectory}/')) {
          throw const FormatException('Opposite-basis source is unavailable');
        }
        final bytes = File(path).readAsBytesSync();
        return tamper && path.endsWith('ofs.html') ? [...bytes, 32] : bytes;
      },
    ).verifyRegistered(f, company(entry), basis);
    test(
      '$receipt ordinary public fetch defaults to mandatory revenue',
      () async {
        final manifest = jsonDecode(
          File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        final sources = manifest['sources'] as List;
        final client = MockClient((request) async {
          final source = sources.singleWhere(
            (s) => s['url'] == request.url.toString(),
          );
          return http.Response.bytes(
            File('${entry.assetDirectory}/${source['file']}').readAsBytesSync(),
            200,
            request: request,
          );
        });
        await expectLater(
          fastFinancialHtmlFetcher(client).fetchAnnual(
            receipt,
            reportName: filing(entry).reportName,
            corpCode: entry.corpCode,
            companyName: entry.companyName,
            bsnsYear: entry.year,
            periodEnd: DateTime.utc(entry.year, 12, 31),
            consolidated: false,
          ),
          throwsFormatException,
        );
      },
    );
    test(
      '$receipt immutable six direct accounts preserve absent revenue',
      () async {
        final f = filing(entry), before = filing(entry).toJson();
        final r = await verify(f);
        expect(r.numeric.rows.length, 6);
        expect(
          r.numeric.rows.every((dynamic row) => row['account_id'] == null),
          isTrue,
        );
        expect(
          r.numeric.rows.every(
            (dynamic row) =>
                row['html_provenance']['partialCoreProof']['missingAccount'] ==
                'revenue',
          ),
          isTrue,
        );
        expect(f.toJson(), before);
      },
    );
    for (final bad in ['corp', 'year', 'quarter', 'receipt']) {
      test('$receipt rejects wrong $bad', () async {
        final f = filing(entry);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = 2021;
          case 'quarter':
            f.reportCode = FinancialReportCode.halfYear;
          case 'receipt':
            f.rceptNo = '20230314001272';
        }
        expect(() => verify(f), throwsA(isA<FormatException>()));
      });
    }
    test(
      '$receipt immutable source SHA rejects tamper',
      () => expect(
        () => verify(filing(entry), tamper: true),
        throwsA(isA<FormatException>()),
      ),
    );
    test(
      '$receipt never reuses OFS for CFS when only OFS sources exist',
      () => expect(
        () => verify(
          filing(entry),
          basis: FsDiv.consolidated,
          onlySeparateSources: true,
        ),
        throwsA(isA<FormatException>()),
      ),
    );
  }
}
