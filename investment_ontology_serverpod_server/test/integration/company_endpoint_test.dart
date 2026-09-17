import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_revision.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 상장사 데이터', (sessionBuilder, endpoints) {
    setUp(() async {
      final session = sessionBuilder.build();
      await KsicSeeder.seed(session);
      await KsicRevision.invalidate(session);
      Company company(
        String corpCode,
        String name,
        String stockCode,
        Market market,
        String industryCode,
      ) {
        final cls = KsicSeeder.classify(industryCode);
        return Company(
          corpCode: corpCode,
          name: name,
          stockCode: stockCode,
          market: market,
          industryCode: industryCode,
          sectionCode: cls.section,
          divisionCode: cls.division,
        );
      }

      await Company.db.insert(session, [
        company('00126380', '삼성전자', '005930', Market.kospi, '264'),
        company('00164779', 'SK하이닉스', '000660', Market.kospi, '261'),
        company('00258801', '카카오', '035720', Market.kospi, '631'),
        company('00000100', '에코프로비엠', '247540', Market.kosdaq, '282'),
        company('00000200', '상폐기업', '999999', Market.other, '264'),
      ]);
    });

    test('overview는 상장 시장만 센다', () async {
      final overview = await endpoints.company.overview(sessionBuilder);

      expect(overview.totalListed, 4);
      expect(
        {for (final f in overview.byMarket) f.code: f.count},
        {'kospi': 3, 'kosdaq': 1, 'konex': 0},
      );
      final manufacturing = overview.bySection.firstWhere((f) => f.code == 'C');
      expect(manufacturing.name, '제조업');
      expect(manufacturing.count, 3);
    });

    test('list는 이름·종목코드로 검색하고 업종명을 붙인다', () async {
      final byName = await endpoints.company.list(sessionBuilder, query: '삼성');
      expect(byName.total, 1);
      expect(byName.items.single.industryName, '통신 및 방송 장비 제조업');
      expect(byName.items.single.sectionName, '제조업');

      final byCode = await endpoints.company.list(
        sessionBuilder,
        query: '0006',
      );
      expect(byCode.items.single.name, 'SK하이닉스');
    });

    test('list 필터: 시장, 대분류, 중분류', () async {
      final kosdaq = await endpoints.company.list(
        sessionBuilder,
        market: Market.kosdaq,
      );
      expect(kosdaq.items.map((c) => c.name), ['에코프로비엠']);

      final semis = await endpoints.company.list(
        sessionBuilder,
        sectionCode: 'C',
        divisionCode: '26',
      );
      expect(semis.total, 2);
    });

    test('LIKE 특수문자는 와일드카드로 해석하지 않는다', () async {
      final page = await endpoints.company.list(sessionBuilder, query: '%');
      expect(page.total, 0);
    });

    test('divisions는 대분류 안의 중분류별 수를 준다', () async {
      final divisions = await endpoints.company.divisions(sessionBuilder, 'C');
      expect({for (final d in divisions) d.code: d.count}, {'26': 2, '28': 1});
    });

    test('근거 코드가 없으면 최신 차수(11차) 이름을 쓴다', () async {
      final overview = await endpoints.company.overview(sessionBuilder);
      expect(overview.industryRevision!.revision, 'KSIC 11');
      expect(overview.industryRevision!.confirmed, isFalse);
    });

    test('10차에만 있는 코드가 쓰이면 10차 이름으로 보여준다', () async {
      final session = sessionBuilder.build();
      await Company.db.insertRow(
        session,
        Company(
          corpCode: '00000300',
          name: '시계회사',
          market: Market.kosdaq,
          industryCode: '274',
          sectionCode: 'C',
          divisionCode: '27',
        ),
      );
      await KsicRevision.invalidate(session);

      final overview = await endpoints.company.overview(sessionBuilder);
      expect(overview.industryRevision!.revision, 'KSIC 10');
      expect(overview.industryRevision!.evidenceCodes, ['274']);
      final page = await endpoints.company.list(sessionBuilder, query: '삼성');
      expect(page.items.single.industryName, '통신 및 방송장비 제조업');
    });

    test('detail은 KSIC 경로를 대분류부터 준다', () async {
      final detail = await endpoints.company.detail(sessionBuilder, '00126380');
      expect(detail!.industryPath.map((i) => i.code), ['C', '26', '264']);
      expect(await endpoints.company.detail(sessionBuilder, 'nope'), isNull);
    });
  });
}
