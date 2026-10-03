import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/scanned_fund_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/scanned_fund_financials.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_financials.dart';

void main() {
  final independent = jsonDecode(
    File(
      'test/fixtures/issuer_documents/scanned_fund/independent-current-proof.json',
    ).readAsStringSync(),
  ) as List;
  List<int> bytes(Map p) => File(
    'test/fixtures/issuer_documents/scanned_fund/${p['metadata']['periodEnd'].substring(0, 4)}.scanned-ocr.json',
  ).readAsBytesSync();
  for (final p in ScannedFundProfiles.rows) {
    test(
      '${p['metadata']['periodEnd']} exact dual OCR current cells and equations',
      () {
        final row = ScannedFundFinancials.parse(p['metadata'], bytes(p));
        final proof = independent.singleWhere(
          (r) => r['metadata']['sha256'] == row['sha256'],
        );
        expect(row['accounts'].length, 8);
        for (var i = 0; i < 8; i++) {
          final a = row['accounts'][i], b = proof['observations'][i];
          expect(a['amountInteger'], b['amountInteger']);
          expect(a['ocrText'], b['ko']['text']);
          expect(a['independentOcrText'], b['en']['text']);
          expect(a['ocrRowIndex'], b['koRowIndex']);
          expect(a['independentOcrRowIndex'], b['enRowIndex']);
          expect(a['pageOrdinal'], b['pageOrdinal']);
          expect(
            a['amountScope'],
            i < 3 ? 'stockAtPeriodEnd' : 'ownFiscalDuration',
          );
          expect(a['cashDirection'], i >= 6 ? 'outflow' : null);
        }
        expect(row['validation']['checks'].length, proof['checks'].length);
        expect(
          row['validation']['fullyNumericEquationCount'],
          row['periodEnd'] == '2021-12-31' ? 33 : 32,
        );
        expect(
          row['validation']['missingWitnessSubtotalCount'],
          row['periodEnd'] == '2021-12-31' ? 2 : 1,
        );
        expect(
          (row['validation']['checks'] as List).every(
            (c) => c['difference'] == '0',
          ),
          true,
        );
        expect(row['fullStatementCollected'], false);
        expect(row['notesDecodedOrVerified'], false);
        expect(IssuerFinancialsFeed.validate([row]).length, 1);
      },
    );
    test(
      '${p['metadata']['periodEnd']} corrupted source and stored coordinate/digit/sign claims fail closed',
      () {
        final raw = bytes(p);
        final changed = List<int>.from(raw)..[10] = raw[10] ^ 1;
        expect(
          () => ScannedFundFinancials.parse(p['metadata'], changed),
          throwsFormatException,
        );
        final row = ScannedFundFinancials.parse(p['metadata'], raw);
        for (final edit in [
          {'sha256': 'fake'},
          {'corpCode': '00600013'},
          {'basis': 'CFS'},
          {'periodKind': 'halfYear'},
          {'acceptedSeparatorGrammar': 'loose'},
          {'numericState': 'complete'},
          {'rawOcrRewritten': true},
          {'regularReportCode': '11011'},
          {'fullStatementCollected': true},
        ]) {
          final r = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
          r.addAll(edit);
          expect(
            () => IssuerFinancialsFeed.validate([r]),
            throwsFormatException,
          );
        }
        final scaled = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
        for (final c in (scaled['validation']['cells'] as Map).values) {
          final n = ScannedFundFinancials.integer(c['ko']['text']);
          if (n == null) continue;
          final next = n * BigInt.two;
          final text = next.isNegative
              ? '(${(-next).toString()})'
              : next.toString();
          c['ko']['text'] = text;
          c['en']['text'] = text;
          c['amountInteger'] = next.toString();
        }
        for (final a in scaled['accounts']) {
          final c = scaled['validation']['cells'][a['cellKey']];
          a['ocrText'] = c['ko']['text'];
          a['independentOcrText'] = c['en']['text'];
          a['amountInteger'] = c['amountInteger'];
        }
        expect(
          () => IssuerFinancialsFeed.validate([scaled]),
          throwsFormatException,
        );
        for (final change in ['digits', 'bbox', 'group', 'sign']) {
          final r = jsonDecode(jsonEncode(row)) as Map<String, dynamic>,
              c = r['validation']['cells']['assets'];
          if (change == 'digits') {
            c['en']['text'] = '9,999,999';
          } else if (change == 'bbox') {
            c['ko']['x'] = .01;
          } else if (change == 'group') {
            c['ko']['text'] = '53.50g,690,772';
          } else {
            c['ko']['text'] = '-${c['ko']['text']}';
          }
          expect(
            () => IssuerFinancialsFeed.validate([r]),
            throwsFormatException,
          );
        }
      },
    );
  }
  test(
    'source-local separator grammar never guesses digits or missing separators',
    () {
      expect(
        ScannedFundFinancials.integer('289.212,494.110'),
        ScannedFundFinancials.integer('289,212,494,110'),
      );
      expect(
        ScannedFundFinancials.integer('(199.420,165,106)'),
        BigInt.parse('-199420165106'),
      );
      expect(ScannedFundFinancials.integer('-'), isNull);
      for (final invalid in [
        '53.50g,690,772',
        '84.576,897348',
        '84.57,897,348',
        '(-123,456)',
        '1.23',
        '1 234',
      ]) {
        expect(
          () => ScannedFundFinancials.integer(invalid),
          throwsFormatException,
        );
      }
    },
  );
  test('all five MKIF own years stay source-bound and cannot mix KBIF or duplicate', () {
    final scans = ScannedFundProfiles.rows
        .map((p) => ScannedFundFinancials.parse(p['metadata'], bytes(p)))
        .toList();
    final current = InfrastructureFundProfiles.rows
        .take(3)
        .map(
          (p) => InfrastructureFundFinancials.parseRaw(
            p['metadata'],
            File(
              'test/fixtures/issuer_documents/infrastructure_fund/${p['metadata']['corpCode']}-${p['metadata']['periodEnd']}.raw.txt',
            ).readAsBytesSync(),
          ),
        )
        .toList();
    expect(IssuerFinancialsFeed.validate([...scans, ...current]).length, 5);
    expect(
      () => IssuerFinancialsFeed.validate([scans.first, scans.first]),
      throwsFormatException,
    );
    final kb = InfrastructureFundProfiles.rows.last;
    final other = InfrastructureFundFinancials.parseRaw(
      kb['metadata'],
      File(
        'test/fixtures/issuer_documents/infrastructure_fund/${kb['metadata']['corpCode']}-${kb['metadata']['periodEnd']}.raw.txt',
      ).readAsBytesSync(),
    );
    expect(
      () => IssuerFinancialsFeed.validate([scans.first, other]),
      throwsFormatException,
    );
  });
  for (final p in ScannedFundProfiles.rows) {
    test(
      '${p['metadata']['periodEnd']} private source PDF/sidecar/page-image guard',
      () async {
        final m = p['metadata'] as Map,
            year = (m['periodEnd'] as String).substring(0, 4);
        final cache = await Directory.systemTemp.createTemp(
          'scanned-fund-pure-',
        );
        addTearDown(() => cache.delete(recursive: true));
        await File('${cache.path}/${m['sha256']}.pdf').writeAsBytes(
          File('test/fixtures/issuer_documents/scanned_fund/$year.pdf')
              .readAsBytesSync(),
        );
        await File('${cache.path}/${m['sha256']}.scanned-ocr.json')
            .writeAsBytes(bytes(p));
        final docs = <Map<String, dynamic>>[
          {'metadata': m, 'proof': <String, dynamic>{}},
        ];
        await expectLater(
          IssuerFinancialsSync.rows(cache, docs),
          throwsA(isA<FileSystemException>()),
        );
        for (var page = 8; page <= 13; page++) {
          final name = page.toString().padLeft(2, '0');
          await File('${cache.path}/${m['sha256']}.p$name.png').writeAsBytes(
            File('test/fixtures/issuer_documents/scanned_fund/$year-$name.png')
                .readAsBytesSync(),
          );
        }
        expect(
          (await IssuerFinancialsSync.rows(
            cache,
            docs,
          )).single['accounts'].length,
          8,
        );
        await File('${cache.path}/${m['sha256']}.p08.png')
            .writeAsBytes([1, 2, 3]);
        await expectLater(
          IssuerFinancialsSync.rows(cache, docs),
          throwsFormatException,
        );
      },
    );
  }
}
