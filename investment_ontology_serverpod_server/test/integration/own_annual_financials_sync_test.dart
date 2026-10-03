import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/own_annual_financials_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/own_annual_financials_html.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Own annual source-bound primary numerical observations', (
    builder,
    endpoints,
  ) {
    test('normal company worker stores all own20/current156 independently and replays immutably', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp('own-annual20-db-');
      addTearDown(() => cache.delete(recursive: true));
      final all = IssuerDocumentsCollector.manifest(
        await IssuerDocumentsSync.combinedManifestText(),
      );
      final docs = all
          .where(
            (d) =>
                OwnAnnualFinancialsHtml.supportsCorp(d['metadata']['corpCode']),
          )
          .toList();
      expect(docs, hasLength(25));
      final corps = docs
          .map((d) => d['metadata']['corpCode'] as String)
          .toSet();
      for (final corp in corps) {
        await Company.db.insertRow(
          session,
          Company(corpCode: corp, name: corp, market: Market.kosdaq),
        );
      }
      var gets = 0;
      final collector = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((request) async {
          gets++;
          final url = request.url.toString();
          final doc = docs.singleWhere(
            (d) =>
                d['metadata']['officialUrl'] == url ||
                d['proof']['shellUrl'] == url,
          );
          final m = doc['metadata'] as Map;
          final receipt = m['providerReceipt'];
          final shell = doc['proof']['shellUrl'] == url;
          final path = OwnAnnualFinancialsHtml.supports(doc)
              ? '$receipt-own-${shell ? 'shell' : 'statement'}.html'
              : '$receipt-${shell ? 'shell' : 'financial'}.html';
          return http.Response.bytes(
            File('test/fixtures/issuer_documents/dart/$path').readAsBytesSync(),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
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
      final first = await collect();
      expect(first.failedCompanies, 0, reason: first.reasons.join("; "));
      expect(first.financialFailedCompanies, 0);
      expect(first.ownAnnualFailedCompanies, 0);
      expect(first.storedDocuments, 25);
      expect(first.ownAnnualPeriodGroups, 20);
      expect(first.financialPeriodGroups, 8);
      expect(gets, 50);
      var cells = 0;
      for (final corp in corps) {
        final data = jsonDecode(
          await endpoints.research.data(
            builder.asAnonymous,
            corp,
            'issuerAnnualFinancials',
          ),
        ) as Map;
        expect(data['state'], 'ready');
        expect(data['source']['kind'], 'officialFile');
        expect(data['source']['reference'], OwnAnnualFinancialsSync.reference);
        final rows = data['rows'] as List;
        cells += rows.expand((r) => r['accounts'] as List).length;
        for (final row in rows) {
          expect(row['corpCode'], corp);
          expect(row['periodKind'], 'ownAnnual');
          expect(row['observationRole'], 'currentOwn');
          expect(row['regularReportCode'], isNull);
        }
        await expectLater(
          endpoints.research.importFeed(
            builder.asAdmin,
            corp,
            'issuerAnnualFinancials',
            jsonEncode(rows),
            OwnAnnualFinancialsSync.provider,
            'https://dart.fss.or.kr',
            OwnAnnualFinancialsSync.reference,
          ),
          throwsA(isA<IngestException>()),
        );
      }
      expect(cells, 156);
      expect(await ResearchSnapshot.db.count(session), 15);
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: manifest,
        ),
        isFalse,
      );
      final before = (await ResearchSnapshot.db.find(session))
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await collect();
      expect(gets, 50);
      expect(
        (await ResearchSnapshot.db.find(session))
            .map((r) => jsonEncode(r.toJson()))
            .toList(),
        before,
      );
      final other = await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals('01586923'),
      );
      await expectLater(
        OwnAnnualFinancialsSync.store(
          session,
          other!,
          cache,
          docs.where((d) => d['metadata']['corpCode'] == '01564514').toList(),
          () async => false,
        ),
        throwsFormatException,
      );
      final cancelled = await IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: manifest,
        collector: collector,
        cancelled: () async => true,
      );
      expect(cancelled.cancelled, isTrue);
      expect(await ResearchSnapshot.db.count(session), 15);
      expect(gets, 50);
      expect(await FinancialReport.db.count(session), 0);
      expect(await FinancialFact.db.count(session), 0);
      expect(await DartFiling.db.count(session), 0);
      expect(await ApiCallUsage.db.count(session), 0);
      expect(await BusinessDocument.db.count(session), 0);
    });
  });
}
