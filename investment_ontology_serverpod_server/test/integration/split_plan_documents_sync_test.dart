import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/split_plan_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/split_plan_documents.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Delegated split source normal persistence', (
    builder,
    endpoints,
  ) {
    for (final mode in ['valid', 'corruptFirst', 'wrongSource', 'cancelled']) {
      test('compiled split2 $mode preserves actor, source, replay and no regular periods', () async {
        final session = builder.build();
        addTearDown(session.close);
        for (final row in SplitPlanDocuments.rows) {
          for (final parent in [false, true]) {
            final code =
                row[parent ? 'filingActorCorpCode' : 'corpCode'] as String;
            final source = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartApi,
                title: "DART company master test-only Source",
                url:
                    'https://opendart.fss.or.kr/api/company.json?corp_code=$code',
                reference: mode == 'wrongSource' && code == '02038566'
                    ? 'wrong'
                    : code,
                retrievedAt: DateTime.utc(2026, 9, 17),
              ),
            );
            await Company.db.insertRow(
              session,
              Company(
                corpCode: code,
                name:
                    row[parent ? 'filingActorPrintedName' : 'targetPrintedName']
                        as String,
                establishedDate: parent
                    ? null
                    : DateTime.parse(row['actualEstablishedDate'] as String),
                profileSourceId: source.id,
              ),
            );
          }
        }
        final cache = await Directory.systemTemp.createTemp(
          'split-own-contract-',
        );
        addTearDown(() => cache.delete(recursive: true));
        var gets = 0;
        final collector = IssuerDocumentsCollector(
          cache: cache,
          delay: (_) async {},
          client: MockClient((request) async {
            gets++;
            final row = SplitPlanDocuments.rows.singleWhere(
              (r) => r['officialUrl'] == request.url.toString(),
            );
            final bytes = gzip.decode(
              File(
                'test/fixtures/issuer_documents/split/${row['corpCode']}.html.gz',
              ).readAsBytesSync(),
            );
            if (mode == 'corruptFirst' && row['corpCode'] == '02038566') {
              bytes[100] ^= 1;
            }
            return http.Response.bytes(bytes, 200, request: request);
          }),
        );
        addTearDown(collector.client.close);
        final result = await SplitPlanDocumentsSync.collect(
          session,
          collector,
          () async => mode == 'cancelled',
        );
        expect(result.cancelled, mode == 'cancelled');
        expect(
          result.stored,
          mode == 'cancelled'
              ? 0
              : (mode == 'corruptFirst' || mode == 'wrongSource')
              ? 1
              : 2,
        );
        expect(
          result.failed,
          (mode == 'corruptFirst' || mode == 'wrongSource') ? 1 : 0,
        );
        if (mode == 'valid') {
          final before = (await ResearchSnapshot.db.find(session))
              .map((r) => jsonEncode(r.toJson()))
              .toList();
          for (final row in SplitPlanDocuments.rows) {
            final value = jsonDecode(
              await endpoints.research.data(
                builder.asAnonymous,
                row['corpCode'] as String,
                SplitPlanDocuments.kind,
              ),
            );
            expect(value['state'], 'ready');
            expect(value['rows'], [row]);
            expect(value['source']['kind'], 'officialFile');
            expect((value['rows'] as List).single['financialValues'], isNull);
            expect(
              () => endpoints.research.importFeed(
                builder.asAdmin,
                row['corpCode'] as String,
                SplitPlanDocuments.kind,
                jsonEncode([row]),
                SplitPlanDocuments.provider,
                'https://kind.krx.co.kr',
                SplitPlanDocuments.reference,
              ),
              throwsA(isA<IngestException>()),
            );
          }
          expect(await SplitPlanDocumentsSync.pending(session, cache), false);
          await SplitPlanDocumentsSync.collect(
            session,
            collector,
            () async => false,
          );
          expect(gets, 2);
          expect(
            (await ResearchSnapshot.db.find(session))
                .map((r) => jsonEncode(r.toJson()))
                .toList(),
            before,
          );
          final current = await ResearchSnapshot.db.findFirstRow(
            session,
            where: (t) => t.kind.equals(SplitPlanDocuments.kind),
          );
          final source = await Source.db.findById(session, current!.sourceId);
          await Source.db.updateRow(
            session,
            source!.copyWith(kind: SourceKind.dartApi),
          );
          expect(await SplitPlanDocumentsSync.pending(session, cache), true);
          await SplitPlanDocumentsSync.collect(
            session,
            collector,
            () async => false,
          );
          expect(await SplitPlanDocumentsSync.pending(session, cache), false);
          expect(gets, 2);
          await File(
            '${cache.path}/${SplitPlanDocuments.rows.first['sha256']}.html',
          ).delete();
          expect(await SplitPlanDocumentsSync.pending(session, cache), true);
        }
        expect(await FinancialReport.db.count(session), 0);
        expect(await FinancialFact.db.count(session), 0);
        expect(await DartFiling.db.count(session), 0);
        expect(await ApiCallUsage.db.count(session), 0);
        expect(await BusinessDocument.db.count(session), 0);
      });
    }
  });
}
