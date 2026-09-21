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

    test('밖에서 뽑은 결과도 같은 검증을 거쳐 저장한다 (키 없이)', () async {
      // 구독 세션 등으로 미리 읽고 넣는 길. 화면 요청 중에는 모델을 부르지 않는다.
      final pending = await endpoints.ai.pending(sessionBuilder);
      expect(pending.map((d) => d.corpCode), contains('00000001'));
      final text = await endpoints.ai.documentText(
        sessionBuilder,
        pending.first.documentId,
      );
      expect(text, contains('양극재'));

      final run = await endpoints.ai.submit(
        sessionBuilder,
        pending.first.documentId,
        jsonEncode({
          'relations': [
            {
              'type': 'supplier',
              'name': '(주)양극재',
              'evidence': '양극재이며 (주)양극재에서 매입합니다.',
              'confidence': 0.9,
            },
            {
              'type': 'customer',
              'name': '없는회사',
              'evidence': '원문에 없는 문장입니다.',
              'confidence': 0.9,
            },
          ],
        }),
      );

      expect((run.relationCount, run.droppedCount), (1, 1));
      expect(run.model, 'claude-code');
      final page = await endpoints.review.list(sessionBuilder);
      expect(page.draftCount, 1);
      expect(page.items.single.relation.extractorModel, 'claude-code');
      // 넣은 뒤에는 '아직 읽지 않은 본문'에서 빠진다.
      expect(await endpoints.ai.pending(sessionBuilder), isEmpty);
    });

    test('본문 값(수주잔고 등)도 근거가 원문에 있어야 저장한다', () async {
      final result = await endpoints.ai.submitFacts(
        sessionBuilder,
        doc.id!,
        jsonEncode({
          'facts': [
            {
              'kind': 'orderBacklog',
              'label': '배터리',
              'value': 21292358,
              'unit': '백만원',
              'asOf': '2025-12-31',
              'evidence': '주요 원재료는 양극재이며 (주)양극재에서 매입합니다.',
              'confidence': 0.9,
            },
            {
              'kind': 'utilization',
              'label': '없는 부문',
              'value': 91.6,
              'unit': '%',
              'evidence': '원문에 없는 문장이라 버려야 합니다.',
            },
          ],
        }),
      );
      expect(result, '저장 1건, 버린 것 1건');

      final page = await endpoints.review.facts(sessionBuilder);
      expect(page.draftCount, 1);
      final item = page.items.single;
      expect((item.companyName, item.fact.label), ('(주)배터리', '배터리'));
      expect(item.fact.unit, '백만원');

      await endpoints.review.decideFact(sessionBuilder, item.fact.id!, true);
      final after = await endpoints.review.facts(
        sessionBuilder,
        status: RelationStatus.verified,
      );
      expect(after.verifiedCount, 1);
      expect(after.items.single.fact.reviewedAt, isNotNull);
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
