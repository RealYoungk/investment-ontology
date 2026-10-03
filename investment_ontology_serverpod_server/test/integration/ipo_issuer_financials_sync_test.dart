import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/ipo_issuer_financials_html.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Eight source-bound IPO numerical observations', (
    builder,
    endpoints,
  ) {
    test('normal worker stores 82 current cells separately; raw contract, replay and financial ledger stay intact', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp(
        'ipo-financial-eight-db-',
      );
      addTearDown(() => cache.delete(recursive: true));
      final docs = IssuerDocumentsCollector.manifest(
        File('assets/issuer_documents/verified_dart_documents.json')
            .readAsStringSync(),
      ).where(IpoIssuerFinancialsHtml.supports).toList();
      for (final d in docs) {
        final m = d['metadata'] as Map;
        await Company.db.insertRow(
          session,
          Company(
            corpCode: m['corpCode'],
            name: m['issuerQuote'],
            market: Market.kosdaq,
          ),
        );
      }
      var gets = 0;
      final collector = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((request) async {
          gets++;
          final url = request.url.toString(),
              d = docs.singleWhere(
                (d) =>
                    (d['metadata'] as Map)['officialUrl'] ==
                        request.url.toString() ||
                    (d['proof'] as Map)['shellUrl'] == request.url.toString(),
              );
          final m = d['metadata'] as Map,
              receipt = m['providerReceipt'],
              part = m['officialUrl'] == url ? 'financial' : 'shell';
          return http.Response.bytes(
            File('test/fixtures/issuer_documents/dart/$receipt-$part.html')
                .readAsBytesSync(),
            200,
            request: request,
          );
        }),
      );
      addTearDown(collector.client.close);
      final manifest = jsonEncode({'schemaVersion': 1, 'documents': docs});
      Future<IssuerDocumentsResult> collect() =>
          IssuerDocumentsSync.collectAndStore(
            session,
            manifestText: manifest,
            collector: collector,
            cancelled: () async => false,
          );
      final result = await collect();
      expect(result.storedCompanies, 8);
      expect(result.storedDocuments, 8);
      expect(result.financialPeriodGroups, 11);
      expect(result.financialFailedCompanies, 0);
      expect(result.hasFailure, isFalse);
      expect(gets, 16);
      expect(await ResearchSnapshot.db.count(session), 16);
      var directCells = 0;
      for (final d in docs) {
        final m = d['metadata'] as Map;
        final raw = jsonDecode(
          await endpoints.research.data(
            builder.asAnonymous,
            m['corpCode'],
            'issuerDocuments',
          ),
        ) as Map;
        expect((raw['rows'] as List).single['numericState'], 'notExtracted');
        expect((raw['rows'] as List).single['financialValues'], isNull);
        final data = jsonDecode(
          await endpoints.research.data(
            builder.asAnonymous,
            m['corpCode'],
            'issuerFinancials',
          ),
        ) as Map;
        expect(data['state'], 'ready');
        expect(data['source']['kind'], 'officialFile');
        final rows = data['rows'] as List;
        directCells += rows.expand((r) => r['accounts'] as List).length;
        for (final r in rows) {
          expect(r['numericState'], 'partialCore');
          expect(r['regularReportCode'], isNull);
        }
        await expectLater(
          endpoints.research.importFeed(
            builder.asAdmin,
            m['corpCode'],
            'issuerFinancials',
            jsonEncode(rows),
            'verified-primary-html-rule',
            'https://dart.fss.or.kr',
            'source-bound-partial-current-core;no-api-report-or-xbrl-assertion',
          ),
          throwsA(isA<IngestException>()),
        );
      }
      final counterpartCompany = await Company.db.findFirstRow(
        session,
        where: (t) =>
            t.corpCode.equals((docs[1]['metadata'] as Map)['corpCode']),
      );
      await expectLater(
        IssuerFinancialsSync.store(session, counterpartCompany!, cache, [
          docs.first,
        ], () async => false),
        throwsFormatException,
      );
      expect(await ResearchSnapshot.db.count(session), 16);
      expect(directCells, 82);
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: manifest,
        ),
        isFalse,
      );
      final originals = (await ResearchSnapshot.db.find(session))
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await collect();
      expect(gets, 16);
      expect(
        (await ResearchSnapshot.db.find(session))
            .map((r) => jsonEncode(r.toJson()))
            .toList(),
        originals,
      );
      expect(await FinancialReport.db.count(session), 0);
      expect(await FinancialFact.db.count(session), 0);
      expect(await DartFiling.db.count(session), 0);
      expect(await BusinessDocument.db.count(session), 0);
      expect(await ApiCallUsage.db.count(session), 0);
    });
  });
}
