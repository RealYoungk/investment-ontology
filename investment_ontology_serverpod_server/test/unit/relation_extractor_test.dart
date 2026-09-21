import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ai/relation_extractor.dart';
import 'package:test/test.dart';

void main() {
  const source = '''## 3. 원재료 및 생산설비
주요 원재료 | 매입처
양극재 | 에코프로비엠, 엘앤에프
## 4. 매출 및 수주상황
당사의 주요 매출처는 현대자동차와 Tesla 입니다.''';

  final doc = BusinessDocument(
    id: 7,
    reportId: 1,
    companyId: 10,
    bsnsYear: 2025,
    rceptNo: '20260310000001',
    title: 'II. 사업의 내용',
    text: source,
    charCount: source.length,
  );
  final company = Company(id: 10, corpCode: '00000010', name: '(주)배터리');

  test('모델 답에서 JSON을 꺼내고 형식이 틀린 항목은 버린다', () {
    final parsed = RelationExtractor.parse('''설명입니다.
{"relations":[
 {"type":"supplier","name":"에코프로비엠","evidence":"양극재 | 에코프로비엠, 엘앤에프","confidence":0.9},
 {"type":"unknown","name":"x","evidence":"y"},
 {"type":"customer","name":"","evidence":"z"}
]}''');
    expect(parsed, hasLength(1));
    expect(parsed.single.confidence, 0.9);
    expect(RelationExtractor.parse('JSON 아님'), isEmpty);
  });

  test('근거 인용이 원문에 그대로 있고 이름이 인용 안에 있어야 한다', () {
    ExtractedRelation r(String name, String evidence) =>
        (type: 'customer', name: name, evidence: evidence, confidence: null);
    expect(
      RelationExtractor.grounded(
        r('현대자동차', '주요 매출처는 현대자동차와 Tesla 입니다.'),
        source,
      ),
      isTrue,
    );
    // 공백 차이는 무시한다.
    expect(
      RelationExtractor.grounded(r('Tesla', '현대자동차와  Tesla입니다'), source),
      isTrue,
    );
    // 원문에 없는 인용(지어낸 것)은 버린다.
    expect(
      RelationExtractor.grounded(r('기아', '주요 매출처는 기아입니다.'), source),
      isFalse,
    );
    // 인용에 이름이 없으면 버린다.
    expect(
      RelationExtractor.grounded(r('기아', '주요 매출처는 현대자동차와'), source),
      isFalse,
    );
  });

  test('공급사 → 이 회사, 이 회사 → 고객사로 방향을 맞추고 상장사와 잇는다', () {
    final result = RelationExtractor.toRelations(
      [
        (
          type: 'supplier',
          name: '에코프로비엠',
          evidence: '양극재 | 에코프로비엠, 엘앤에프',
          confidence: 0.9,
        ),
        (
          type: 'customer',
          name: '현대자동차',
          evidence: '당사의 주요 매출처는 현대자동차와 Tesla 입니다.',
          confidence: 0.8,
        ),
        (
          type: 'customer',
          name: '현대자동차',
          evidence: '주요 매출처는 현대자동차와',
          confidence: 0.5,
        ),
        (
          type: 'competitor',
          name: 'LG에너지솔루션',
          evidence: '경쟁사는 LG에너지솔루션',
          confidence: 0.5,
        ),
      ],
      document: doc,
      company: company,
      sourceId: 3,
      model: 'm',
      companiesByName: {'에코프로비엠': 20, '현대자동차': 30},
      companyNames: {20: '(주)에코프로비엠', 30: '현대자동차(주)'},
    );
    // 중복 1건, 원문에 없는 경쟁사 1건을 버린다.
    expect(result.dropped, 2);
    final supplier = result.relations.first;
    expect(supplier.predicate, RelationPredicate.suppliesTo);
    expect((supplier.subjectCompanyId, supplier.objectCompanyId), (20, 10));
    expect(supplier.subjectName, '(주)에코프로비엠');
    final customer = result.relations.last;
    expect((customer.subjectCompanyId, customer.objectCompanyId), (10, 30));
    expect(customer.status, RelationStatus.draft);
    expect(customer.extractedBy, RelationOrigin.ai);
    expect(customer.evidence, contains('현대자동차'));
  });

  test('관계를 찾을 만한 절을 먼저 보낸다', () {
    final text = '## 7. 기타 참고사항\n기타\n## 2. 주요 제품 및 서비스\n제품';
    final excerpt = RelationExtractor.excerpt(text);
    expect(excerpt.indexOf('주요 제품'), lessThan(excerpt.indexOf('기타 참고사항')));
  });
}
