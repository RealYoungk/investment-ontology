import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_market_share_projection.dart';

DocumentFact fact(
  String row,
  double value, {
  RelationOrigin origin = RelationOrigin.api,
}) => DocumentFact(
  documentId: 1,
  companyId: 2,
  bsnsYear: 2021,
  kind: DocumentFactKind.marketShare,
  label: '제품',
  value: value,
  unit: '%',
  asOf: DateTime.utc(2020, 12, 31),
  evidence: row,
  extractedBy: origin,
  extractorModel: '표 규칙',
  status: RelationStatus.verified,
  createdAt: DateTime.utc(2021),
);
BusinessDocument doc(String text) => BusinessDocument(
  id: 1,
  reportId: 3,
  companyId: 2,
  bsnsYear: 2021,
  rceptNo: '20220321000000',
  title: '사업의 내용',
  text: text,
  charCount: text.length,
);
void main() {
  test(
    'actual Dongkuk own multi-product footnote preserves verified plate rows',
    () {
      for (final id in [538, 7672]) {
        final text = File(
          'test/fixtures/business_operating_source/market_share_own_$id.txt',
        ).readAsStringSync();
        final row = text
            .split('\n')
            .firstWhere((l) => l.startsWith('후판(수입제외)'));
        expect(
          StoredMarketShareProjection.explicitOwnProductEvidence(text),
          contains(row),
        );
        expect(
          StoredMarketShareProjection.project(
            [fact(row, 12)],
            doc(text),
            owner: '동국제강',
          ),
          hasLength(1),
        );
      }
    },
  );

  test('direct holding declaration is source scoped, investee and from-holding statements are not', () {
    expect(
      StoredMarketShareProjection.declaresHolding('당사는 지주회사로서 경영활동을 조율합니다.'),
      isTrue,
    );
    expect(
      StoredMarketShareProjection.declaresHolding('회사는 순수 지주회사입니다.'),
      isTrue,
    );
    for (final text in [
      '당사는 지주회사로부터 배당을 받습니다.',
      '당사는 지주회사인 A사의 자회사입니다.',
      '피투자회사가 지주회사로 전환하였습니다.',
      '당사는 자회사가 지주회사로 전환하는 데 투자하였습니다.',
    ]) {
      expect(StoredMarketShareProjection.declaresHolding(text), isFalse);
    }
  });

  test('normal bare two-digit year header survives and collision recovers only missing own row', () {
    final document = doc("""시장점유율
(단위:%)
구분 | 25 | 24 | 23
당사 | 44 | 43 | 42
""").copyWith(bsnsYear: 2025);
    final report = DisclosureReport(
      id: 3,
      companyId: 2,
      section: DartSection.businessContent,
      rceptNo: document.rceptNo,
      bsnsYear: 2025,
      reportCode: FinancialReportCode.annual,
      settlementDate: DateTime.utc(2025, 12, 31),
      rowCount: 1,
      sourceId: 4,
      fetchedAt: DateTime.utc(2022),
    );
    final recovered = StoredMarketShareProjection.recover(
      document,
      report,
      [],
      owner: '대주이엔티',
    );
    expect(recovered.map((f) => f.value), [44, 43, 42]);
    expect(
      StoredMarketShareProjection.recover(
        document,
        report,
        recovered,
        owner: '대주이엔티',
      ),
      isEmpty,
    );
    expect(
      StoredMarketShareProjection.recover(
        document,
        report.copyWith(companyId: 7),
        [],
        owner: '대주이엔티',
      ),
      isEmpty,
    );
    expect(
      StoredMarketShareProjection.recover(
        document,
        report,
        [],
        owner: '지주회사',
        holding: true,
      ),
      isEmpty,
    );
  });

  test('actual source multi-company rows cannot terminate a table as false short-year headers', () {
    for (final id in [11143, 15365]) {
      final text = File(
        'test/fixtures/business_operating_source/market_share_$id.txt',
      ).readAsStringSync();
      final row = text.split('\n').firstWhere((l) => l.startsWith('현대엘리베이터 |'));
      final values = row
          .split('|')
          .skip(1)
          .map((v) => double.parse(v.trim()))
          .toList();
      for (final value in values) {
        expect(
          StoredMarketShareProjection.project(
            [fact(row, value)],
            doc(text),
            owner: '대주이엔티',
          ),
          isEmpty,
        );
      }
    }
  });

  test('real Daeju competitor multi-row market table is excluded', () {
    const text = '''[시장점유율]
(단위:%)
구 분 | 2019년 | 2020년
현대엘리베이터 | 43.3 | 39
오티스엘리베이터 | 13.9 | 16
기타 | 20.2 | 21
합 계 | 100 | 100
''';
    expect(
      StoredMarketShareProjection.project(
        [fact('현대엘리베이터 | 43.3 | 39', 39)],
        doc(text),
        owner: '대주이엔티',
      ),
      isEmpty,
    );
  });
  test('singleton product remains accepted and holding scope never becomes parent fact', () {
    const text = '''시장점유율
구분 | 2019년 | 2020년
TV | 30.1% | 28.3%
''';
    final values = [fact('TV | 30.1% | 28.3%', 28.3)];
    expect(
      StoredMarketShareProjection.project(values, doc(text), owner: '제조회사'),
      hasLength(1),
    );
    expect(
      StoredMarketShareProjection.project(
        values,
        doc(text),
        owner: '지주회사',
        industryCode: '64992',
      ),
      isEmpty,
    );
  });
  test('unsupported prose and independent reviewed evidence are preserved', () {
    final values = [
      fact('회사의 점유율은 3%이다.', 3),
      fact('경쟁회사 | 2% | 3%', 3, origin: RelationOrigin.ai),
    ];
    expect(
      StoredMarketShareProjection.project(values, doc('다른 본문'), owner: '당사'),
      hasLength(2),
    );
  });
}
