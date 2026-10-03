import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_financials.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';

void main() {
  final proof = jsonDecode(
    File(
      'test/fixtures/issuer_documents/infrastructure_fund/independent-current-proof.json',
    ).readAsStringSync(),
  ) as List;
  List<int> bytes(Map p) => File(
    'test/fixtures/issuer_documents/infrastructure_fund/${p['metadata']['corpCode']}-${p['metadata']['periodEnd']}.raw.txt',
  ).readAsBytesSync();
  for (final p in InfrastructureFundProfiles.rows) {
    final m = p['metadata'] as Map,
        label = '${m['corpCode']}/${m['periodEnd']}';
    test(
      '$label actual eight printed cells and full bound current hierarchy',
      () {
        final row = InfrastructureFundFinancials.parseRaw(m, bytes(p));
        final expected = proof.singleWhere(
          (x) => x['metadata']['sha256'] == m['sha256'],
        );
        expect(row['accounts'].length, 8);
        for (var i = 0; i < 8; i++) {
          for (final key in [
            'metric',
            'accountLabel',
            'printedAmount',
            'comparativePrintedAmount',
            'amountInteger',
            'statement',
            'pageOrdinal',
            'lineOrdinal',
            'rawLine',
            'rawGlyphLine',
            'tokenCount',
            'currentTokenIndex',
            'comparativeTokenIndex',
            'cashDirection',
            'amountScope',
          ]) {
            expect(
              row['accounts'][i][key],
              expected['observations'][i][key],
              reason: key,
            );
          }
        }
        expect(row['validation']['checks'].length, expected['checks'].length);
        expect(
          (row['validation']['checks'] as List).every(
            (c) => c['difference'] == '0',
          ),
          true,
        );
        expect(row['validation']['equityMovementDifference'], '0');
        expect(row['validation']['equityCloseDifference'], '0');
        expect(row['validation']['wholeProfitDifference'], '0');
        expect(row['notesDecodedOrVerified'], false);
        expect(row['wholeFontMapVerified'], false);
        expect(row['fullStatementCollected'], false);
        expect(IssuerFinancialsFeed.validate([row]), [row]);
      },
    );
    test(
      '$label wrong source, transform, issuer, unit, period, coordinates and signs fail closed',
      () {
        final row = InfrastructureFundFinancials.parseRaw(m, bytes(p));
        expect(
          () => InfrastructureFundFinancials.parseRaw(
            m,
            bytes(p)..[10] = bytes(p)[10] ^ 1,
          ),
          throwsFormatException,
        );
        expect(
          () => InfrastructureFundFinancials.verifyPdf(
            m,
            utf8.encode('%PDF-invented'),
          ),
          throwsFormatException,
        );
        for (final change in [
          {'corpCode': '00600013'},
          {'sha256': 'fake'},
          {'periodStart': '2025-07-01'},
          {'currency': 'USD'},
          {'basis': 'CFS'},
          {'regularReportCode': '11011'},
          {'numericState': 'complete'},
          {'textTransformation': 'guessed'},
          {'wholeFontMapVerified': true},
          {'notesDecodedOrVerified': true},
          {'unapprovedMetric': '123'},
        ]) {
          final r = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
          r.addAll(change);
          expect(
            () => IssuerFinancialsFeed.validate([r]),
            throwsFormatException,
          );
        }
        final forgedHeader =
            jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
        forgedHeader['statementHeaders'][0]['printedHeader'] =
            'Other issuer (단위:원) 2024년';
        expect(
          () => IssuerFinancialsFeed.validate([forgedHeader]),
          throwsFormatException,
        );
        final forgedGlyph = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
        final firstKey = (p['observations'] as List).first['cellKey'];
        forgedGlyph['validation']['cells'][firstKey]['rawGlyphLine'] =
            'different bytes';
        expect(
          () => IssuerFinancialsFeed.validate([forgedGlyph]),
          throwsFormatException,
        );
        final changed = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
        changed['accounts'][7]['amountInteger'] = '-1';
        expect(
          () => IssuerFinancialsFeed.validate([changed]),
          throwsFormatException,
        );
        final c = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
        final key = (p['observations'] as List).first['cellKey'];
        c['validation']['cells'][key]['currentTokenIndex'] = -1;
        expect(() => IssuerFinancialsFeed.validate([c]), throwsFormatException);
      },
    );
  }
  test('mixed counterpart issuers and duplicate documents cannot form one company snapshot', () {
    final rows = InfrastructureFundProfiles.rows
        .map(
          (p) => InfrastructureFundFinancials.parseRaw(p['metadata'], bytes(p)),
        )
        .toList();
    expect(IssuerFinancialsFeed.validate(rows.take(3).toList()).length, 3);
    expect(IssuerFinancialsFeed.validate(rows.skip(3).toList()).length, 2);
    expect(
      () => IssuerFinancialsFeed.validate([rows.first, rows.last]),
      throwsFormatException,
    );
    expect(
      () => IssuerFinancialsFeed.validate([rows.first, rows.first]),
      throwsFormatException,
    );
  });
  for (final spec in [
    ['00435297', '2024-12-31', 'mkif-2024.pdf'],
    ['01880801', '2025-12-31', 'kbif-2025.pdf'],
  ]) {
    test(
      '${spec.first} private original and raw text normal cache guard',
      () async {
        final p = InfrastructureFundProfiles.rows.singleWhere(
          (p) =>
              p['metadata']['corpCode'] == spec[0] &&
              p['metadata']['periodEnd'] == spec[1],
        );
        final m = p['metadata'] as Map;
        final dir = await Directory.systemTemp.createTemp(
          'infrastructure-fund-pure-',
        );
        addTearDown(() => dir.delete(recursive: true));
        final pdf = File('${dir.path}/${m['sha256']}.pdf');
        final raw = File('${dir.path}/${m['sha256']}.infrastructure.raw.txt');
        final docs = <Map<String, dynamic>>[
          {'metadata': m, 'proof': <String, dynamic>{}},
        ];
        await pdf.writeAsBytes(
          File('test/fixtures/issuer_documents/${spec[2]}').readAsBytesSync(),
        );
        await expectLater(
          IssuerFinancialsSync.rows(dir, docs),
          throwsA(isA<FileSystemException>()),
        );
        await raw.writeAsBytes(bytes(p));
        final rows = await IssuerFinancialsSync.rows(dir, docs);
        expect(rows.single['accounts'].length, 8);
        final changed = List<int>.from(bytes(p))..[10] = bytes(p)[10] ^ 1;
        await raw.writeAsBytes(changed);
        await expectLater(
          IssuerFinancialsSync.rows(dir, docs),
          throwsFormatException,
        );
        await raw.writeAsBytes(bytes(p));
        await pdf.writeAsBytes(utf8.encode('%PDF-wrong source'));
        await expectLater(
          IssuerFinancialsSync.rows(dir, docs),
          throwsFormatException,
        );
      },
    );
  }
}
