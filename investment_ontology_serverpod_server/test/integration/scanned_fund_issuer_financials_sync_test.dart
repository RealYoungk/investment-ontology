import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exact own fund normal stored numerical contract', (
    builder,
    endpoints,
  ) {
    for (final yearEnd in ['2021-12-31', '2022-12-31']) {
      const corp = '00435297';
      final year = yearEnd.substring(0, 4);
      const sourceRoot = 'https://www.mkif.com';
      final pdfFixture = 'scanned_fund/$year.pdf';
      for (final mode in [
        'valid',
        'missingText',
        'alteredText',
        'alteredImage',
        'cancelled',
      ]) {
        test(
          '$corp/$year infrastructure fund normal worker $mode preserves source and regular ledger',
          () async {
            final session = builder.build();
            addTearDown(session.close);
            final docs =
                IssuerDocumentsCollector.manifest(
                      File(
                        'assets/issuer_documents/verified_fund_documents.json',
                      ).readAsStringSync(),
                    )
                    .where(
                      (d) =>
                          d['metadata']['corpCode'] == corp &&
                          d['metadata']['periodEnd'] == yearEnd,
                    )
                    .toList();
            final m = docs.single['metadata'] as Map;
            await Company.db.insertRow(
              session,
              Company(
                corpCode: corp,
                name: '맥쿼리한국인프라투융자회사',
                market: Market.kospi,
              ),
            );
            final cache = await Directory.systemTemp.createTemp(
              'fund-normal-db-',
            );
            addTearDown(() => cache.delete(recursive: true));
            final text = File(
              '${cache.path}/${m['sha256']}.scanned-ocr.json',
            );
            final bytes = File(
              'test/fixtures/issuer_documents/scanned_fund/$year.scanned-ocr.json',
            ).readAsBytesSync();
            if (mode != 'missingText') {
              await text.writeAsBytes(
                mode == 'alteredText'
                    ? (List<int>.from(bytes)..[10] = bytes[10] ^ 1)
                    : bytes,
              );
            }
            for (var page = 8; page <= 13; page++) {
              final name = page.toString().padLeft(2, '0');
              await File(
                '${cache.path}/${m['sha256']}.p$name.png',
              ).writeAsBytes(
                File(
                  'test/fixtures/issuer_documents/scanned_fund/$year-$name.png',
                ).readAsBytesSync(),
              );
            }
            if (mode == 'alteredImage') {
              await File('${cache.path}/${m['sha256']}.p08.png')
                  .writeAsBytes([1, 2, 3]);
            }
            var gets = 0;
            final client = MockClient((r) async {
              gets++;
              return http.Response.bytes(
                File('test/fixtures/issuer_documents/$pdfFixture')
                    .readAsBytesSync(),
                200,
                request: r,
              );
            });
            addTearDown(client.close);
            final collector = IssuerDocumentsCollector(
                  cache: cache,
                  client: client,
                  delay: (_) async {},
                ),
                manifest = jsonEncode({'schemaVersion': 1, 'documents': docs});
            Future<IssuerDocumentsResult> collect() =>
                IssuerDocumentsSync.collectAndStore(
                  session,
                  manifestText: manifest,
                  collector: collector,
                  cancelled: () async => mode == 'cancelled',
                );
            final result = await collect();
            if (mode == 'cancelled') {
              expect(result.cancelled, true);
              expect(gets, 0);
              expect(await ResearchSnapshot.db.count(session), 0);
              expect(await Source.db.count(session), 0);
            } else if (mode != 'valid') {
              expect(result.financialFailedCompanies, 1);
              expect(result.hasFailure, true);
              expect(await ResearchSnapshot.db.count(session), 1);
              expect(await Source.db.count(session), 1);
              expect(
                await IssuerDocumentsSync.hasPending(
                  session,
                  cache: cache,
                  manifestText: manifest,
                ),
                true,
              );
              await text.writeAsBytes(bytes);
              if (mode == 'alteredImage') {
                await File('${cache.path}/${m['sha256']}.p08.png').writeAsBytes(
                  File(
                    'test/fixtures/issuer_documents/scanned_fund/$year-08.png',
                  ).readAsBytesSync(),
                );
              }
              final recovered = await collect();
              expect(recovered.financialFailedCompanies, 0);
              expect(recovered.financialPeriodGroups, 1);
              expect(await ResearchSnapshot.db.count(session), 2);
              expect(gets, 1);
            } else {
              expect(result.hasFailure, false);
              expect(result.financialPeriodGroups, 1);
              expect(result.financialQuarantinedPeriodGroups, 0);
              expect(await ResearchSnapshot.db.count(session), 2);
              final data = jsonDecode(
                await endpoints.research.data(
                  builder.asAnonymous,
                  corp,
                  'issuerFinancials',
                ),
              ) as Map;
              expect(data['state'], 'ready');
              expect(data['provider'], 'verified-primary-pdf-text-rule');
              expect(data['source']['kind'], 'officialFile');
              expect(data['source']['url'], sourceRoot);
              final row = (data['rows'] as List).single;
              expect(
                row['categorySchema'],
                'printedScannedFundCategories',
              );
              expect(row['periodKind'], 'ownTwelveMonthFiscalYear');
              expect(row['basis'], 'singleFundEntity');
              expect(row['accounts'].length, 8);
              await expectLater(
                endpoints.research.importFeed(
                  builder.asAdmin,
                  corp,
                  'issuerFinancials',
                  jsonEncode(data['rows']),
                  'verified-primary-html-rule',
                  sourceRoot,
                  IssuerFinancialsSync.sourceReference(corp),
                ),
                throwsA(isA<IngestException>()),
              );
              final originals = (await ResearchSnapshot.db.find(session))
                  .map((r) => jsonEncode(r.toJson()))
                  .toList();
              final sources = (await Source.db.find(session))
                  .map((r) => jsonEncode(r.toJson()))
                  .toList();
              await collect();
              expect(gets, 1);
              expect(
                (await ResearchSnapshot.db.find(session))
                    .map((r) => jsonEncode(r.toJson()))
                    .toList(),
                originals,
              );
              expect(
                (await Source.db.find(session))
                    .map((r) => jsonEncode(r.toJson()))
                    .toList(),
                sources,
              );
              expect(
                await IssuerDocumentsSync.hasPending(
                  session,
                  cache: cache,
                  manifestText: manifest,
                ),
                false,
              );
            }
            expect(await FinancialReport.db.count(session), 0);
            expect(await FinancialFact.db.count(session), 0);
            expect(await DartFiling.db.count(session), 0);
            expect(await ApiCallUsage.db.count(session), 0);
            expect(await BusinessDocument.db.count(session), 0);
          },
        );
      }
    }
  });
}
