import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ai/ai_extraction_service.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ai/anthropic_client.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given AI 관계 추출', (sessionBuilder, endpoints) {
    late Session session;
    late BusinessDocument doc;
    late int batteryId, cathodeId;
    var answer = '';
    var requests = 0;

    AnthropicClient client() => AnthropicClient(
      'key',
      model: 'claude-test',
      httpClient: MockClient((req) async {
        requests++;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(req.headers['x-api-key'], 'key');
        expect(body['model'], 'claude-test');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': answer},
              ],
            }),
          ),
          200,
        );
      }),
    );

    setUp(() async {
      session = sessionBuilder.build();
      requests = 0;
      batteryId = (await Company.db.insertRow(
        session,
        Company(corpCode: '00000001', name: '(주)배터리', market: Market.kospi),
      )).id!;
      cathodeId = (await Company.db.insertRow(
        session,
        Company(corpCode: '00000002', name: '(주)양극재', market: Market.kosdaq),
      )).id!;
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 't',
          retrievedAt: DateTime.now(),
        ),
      );
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: batteryId,
          section: DartSection.businessContent,
          rceptNo: '20260310000001',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now(),
        ),
      );
      const text =
          '## 3. 원재료 및 생산설비\n주요 원재료는 양극재이며 (주)양극재에서 매입합니다.\n'
          '## 4. 매출 및 수주상황\n주요 매출처는 Tesla입니다.';
      doc = await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: report.id!,
          companyId: batteryId,
          bsnsYear: 2025,
          rceptNo: '20260310000001',
          title: 'II. 사업의 내용',
          text: text,
          charCount: text.length,
        ),
      );
      answer = jsonEncode({
        'relations': [
          {
            'type': 'supplier',
            'name': '(주)양극재',
            'evidence': '양극재이며 (주)양극재에서 매입합니다.',
            'confidence': 0.9,
          },
          {
            'type': 'customer',
            'name': 'Tesla',
            'evidence': '주요 매출처는 Tesla입니다.',
            'confidence': 0.8,
          },
          {
            'type': 'customer',
            'name': 'BMW',
            'evidence': '주요 매출처는 BMW입니다.',
            'confidence': 0.7,
          },
        ],
      });
    });

    test('근거가 원문에 있는 후보만 draft로 저장하고, 검수 결정은 다시 추출해도 유지한다', () async {
      final run = await AiExtractionService(session, client()).extract(doc);
      expect(run.succeeded, isTrue);
      expect((run.relationCount, run.droppedCount), (2, 1));

      var page = await endpoints.review.list(sessionBuilder);
      expect(page.draftCount, 2);
      final supplier = page.items.firstWhere(
        (i) => i.relation.subjectCompanyId == cathodeId,
      );
      expect(supplier.subjectCorpCode, '00000002');
      expect(supplier.companyCorpCode, '00000001');
      expect(supplier.relation.objectCompanyId, batteryId);

      await endpoints.review.decide(
        sessionBuilder,
        supplier.relation.id!,
        true,
      );
      final tesla = page.items.firstWhere(
        (i) => i.relation.objectName == 'Tesla',
      );
      await endpoints.review.decide(sessionBuilder, tesla.relation.id!, false);

      // 다시 추출해도 승인·거절한 관계는 새 draft로 만들지 않는다.
      final again = await AiExtractionService(session, client()).extract(doc);
      expect(again.relationCount, 0);
      page = await endpoints.review.list(sessionBuilder);
      expect(
        (page.draftCount, page.verifiedCount, page.rejectedCount),
        (0, 1, 1),
      );
      // 기업 화면에는 거절한 것을 빼고 보여 준다.
      final mine = await endpoints.review.forCompany(
        sessionBuilder,
        '00000001',
      );
      expect(
        [for (final i in mine) i.relation.status],
        [RelationStatus.verified],
      );
      expect(requests, 2);
    });

    test('모델 호출이 실패하면 실패로 기록하고 관계는 만들지 않는다', () async {
      final failing = AnthropicClient(
        'key',
        model: 'claude-test',
        httpClient: MockClient((_) async => http.Response('overloaded', 529)),
      );
      final run = await AiExtractionService(session, failing).extract(doc);
      expect(run.succeeded, isFalse);
      expect(run.error, contains('529'));
      expect(await OntologyRelation.db.count(session), 0);
    });

    test('키가 없으면 추출 요청을 거절하고 상태에 알린다', () async {
      final status = await endpoints.ai.status(sessionBuilder);
      expect(status.documentCompanies, 1);
      if (!status.keyConfigured) {
        await expectLater(
          endpoints.ai.extractCompany(sessionBuilder, '00000001'),
          throwsA(isA<IngestException>()),
        );
      }
    });
  });
}
