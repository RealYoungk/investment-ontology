import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_conflict.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/land_trust_own_source_conflicts.dart';

void main() {
  for (final p in LandTrustOwnSourceConflicts.profiles.values) {
    final receipt = p['receipt'] as String,
        basis = (p['basis'] as String).toLowerCase(),
        year = p['year'] as int;
    final cover = File(
          'test/fixtures/financial_html/landtrust-conflicts/$receipt/cover.html',
        ).readAsStringSync(),
        body = File(
          'test/fixtures/financial_html/landtrust-conflicts/$receipt/$basis.html',
        ).readAsStringSync();
    void verify({
      String? corp,
      String? changed,
      DateTime? start,
      bool? consolidated,
    }) => KnownAnnualSourceConflicts.verify(
      receipt: receipt,
      corpCode: corp ?? '00233653',
      consolidated: consolidated ?? (basis == 'cfs'),
      start: start ?? DateTime.utc(year),
      end: DateTime.utc(year, 12, 31),
      coverSource: Uri.parse(p['coverURI']),
      statementSource: Uri.parse(p['sourceURI']),
      coverHtml: cover,
      statementHtml: changed ?? body,
    );
    test(
      '$receipt $basis explicit conflict no numerical writes',
      () => expect(
        () => verify(),
        throwsA(
          isA<KnownAnnualSourceConflict>()
              .having(
                (e) => e.evidence['financialFactsStored'],
                'no facts',
                false,
              )
              .having((e) => e.evidence['noData'], 'not absence', false),
        ),
      ),
    );
    test(
      '$receipt $basis altered body not pinned',
      () => expect(() => verify(changed: '$body '), returnsNormally),
    );
    test(
      '$receipt $basis other issuer not pinned',
      () => expect(() => verify(corp: '00000000'), returnsNormally),
    );
    test(
      '$receipt $basis prior period not pinned',
      () =>
          expect(() => verify(start: DateTime.utc(year - 1)), returnsNormally),
    );
    test(
      '$receipt $basis opposite original URI not pinned',
      () => expect(() => verify(consolidated: basis != 'cfs'), returnsNormally),
    );
  }
}
