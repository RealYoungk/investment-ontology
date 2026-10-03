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
    for (final mode in ['valid', 'missingText', 'alteredText', 'cancelled']) {
      test(
        'own2026 fund normal worker $mode preserves source and regular ledger',
        () async {
          final session = builder.build();
          addTearDown(session.close);
          final docs =
              IssuerDocumentsCollector.manifest(
                    File('assets/issuer_documents/verified_fund_documents.json')
                        .readAsStringSync(),
                  )
                  .where(
                    (d) =>
                        d['metadata']['corpCode'] == '00600013' &&
                        d['metadata']['periodEnd'] == '2026-06-30',
                  )
                  .toList();
          final m = docs.single['metadata'] as Map;
          await Company.db.insertRow(
            session,
            Company(
              corpCode: '00600013',
              name: '미래에셋맵스리얼티',
              market: Market.kospi,
            ),
          );
          final cache = await Directory.systemTemp.createTemp(
            'fund-normal-db-',
          );
          addTearDown(() => cache.delete(recursive: true));
          final text = File('${cache.path}/${m['sha256']}.fund.txt');
          final bytes = File(
            'test/fixtures/issuer_documents/fund_text/2026-06-30.txt',
          ).readAsBytesSync();
          if (mode != 'missingText') {
            await text.writeAsBytes(
              mode == 'alteredText'
                  ? (List<int>.from(bytes)..[10] = 32)
                  : bytes,
            );
          }
          var gets = 0;
          final client = MockClient((r) async {
            gets++;
            return http.Response.bytes(
              File('test/fixtures/issuer_documents/mapps-2026-half.pdf')
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
                '00600013',
                'issuerFinancials',
              ),
            ) as Map;
            expect(data['state'], 'ready');
            expect(data['provider'], 'verified-primary-pdf-text-rule');
            expect(data['source']['kind'], 'officialFile');
            expect(data['source']['url'], 'https://re1.miraeasset.com');
            final row = (data['rows'] as List).single;
            expect(row['categorySchema'], 'printedFundCategories');
            expect(row['periodKind'], 'ownSixMonthFiscalYear');
            expect(row['basis'], 'singleFundEntity');
            expect(row['accounts'].length, 7);
            await expectLater(
              endpoints.research.importFeed(
                builder.asAdmin,
                '00600013',
                'issuerFinancials',
                jsonEncode(data['rows']),
                'verified-primary-html-rule',
                'https://re1.miraeasset.com',
                IssuerFinancialsSync.sourceReference('00600013'),
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
  });
}
