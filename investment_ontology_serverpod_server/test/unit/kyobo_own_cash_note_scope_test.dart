import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/located_own_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final basis in FsDiv.values) {
    final e = VerifiedAnnualSourceRegistry.find('20230314000692', basis)!;
    test(
      '${basis.name} exact own current8 and bounded note precision',
      () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) => File(p).readAsBytes(),
        );
        final source = (await cache.verifyRegistered(
          filing(e),
          company(e),
          basis,
        )).numeric!;
        final rows = source.rows;
        expect(rows.length, 8);
        expect(rows.map((r) => r['account_id']), everyElement(isNull));
        expect(
          rows.map((r) => r['thstrm_amount']).toList(),
          basis == FsDiv.consolidated
              ? [
                  '13417260497201',
                  '11855462300592',
                  '1561798196609',
                  '4065850269135',
                  '51650690828',
                  '43289135655',
                  '-929113661308',
                  '-12814286680',
                ]
              : [
                  '12149139534066',
                  '10584274049147',
                  '1564865484919',
                  '4036211804575',
                  '90025670393',
                  '44599774443',
                  '70701089899',
                  '-12814286680',
                ],
        );
        final m = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        expect((m['checks'] as List).length, 8);
        expect(
          (m['checks'] as List).map((c) => c['residual']),
          everyElement(0),
        );
        expect(
          (m['checks'] as List).map((c) => c['fullyNumeric']),
          everyElement(true),
        );
        expect((m['supportingNoteChecks'] as List).map((c) => c['residual']), [
          0,
          0,
        ]);
        final p = rows.first['html_provenance'] as Map;
        expect(
          p['crossPrecisionLiteralRemainders'],
          basis == FsDiv.consolidated
              ? [-101, 363, -50, -447]
              : [-154, 310, -297, 306],
        );
        for (final flag in [
          'notesVerified',
          'fullStatementCollected',
          'detailEnrichmentApproved',
          'crossPrecisionEqualityClaim',
          'roundingCauseInferred',
        ]) {
          expect(p[flag], false);
        }
        Map<String, dynamic>? scope(
          List<Map<String, dynamic>> r, {
          String? corp,
        }) => LocatedOwnCurrentSource.storedScope(
          rows: r,
          receipt: e.receipt,
          corp: corp ?? e.corpCode,
          companyName: e.companyName,
          consolidated: basis == FsDiv.consolidated,
          source: source.statementSource,
          digest: source.sourceDigest,
        );
        expect(scope(rows), isNotNull);
        expect(scope(rows, corp: '00000000'), isNull);
        for (final field in [
          'amount',
          'label',
          'statement',
          'coordinate',
          'noteSHA',
          'remainders',
          'whole',
          'rounding',
          'equality',
        ]) {
          final bad = (jsonDecode(jsonEncode(rows)) as List)
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          final v = bad.first['html_provenance'] as Map;
          switch (field) {
            case 'amount':
              bad.first['thstrm_amount'] = '1';
            case 'label':
              bad.first['account_nm'] = '외국회사자산';
            case 'statement':
              bad.first['sj_div'] = 'CIS';
            case 'coordinate':
              v['currentColumn'] = 2;
            case 'noteSHA':
              v['supportingNoteSha256'] = '0' * 64;
            case 'remainders':
              v['crossPrecisionLiteralRemainders'] = [0, 0, 0, 0];
            case 'whole':
              v['fullStatementCollected'] = true;
            case 'rounding':
              v['roundingCauseInferred'] = true;
            case 'equality':
              v['crossPrecisionEqualityClaim'] = true;
          }
          expect(scope(bad), isNull, reason: field);
        }
        await expectLater(
          cache.verifyRegistered(
            filing(e),
            company(e).copyWith(corpCode: '00000000'),
            basis,
          ),
          throwsFormatException,
        );
      },
    );
  }
}
