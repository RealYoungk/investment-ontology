import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/data_go_kr/data_go_kr_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_sync.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 가짜 공공데이터포털. 기준일(YYYYMMDD)별 시세·상장종목 항목.
class FakeDataGoKr {
  final prices = <String, List<Map<String, String>>>{};
  final listed = <String, List<Map<String, String>>>{};
  final priceCalls = <String>[];
  final listedCalls = <String>[];
  String? errorBody;

  DataGoKrClient client() => DataGoKrClient(
    'key',
    httpClient: MockClient((req) async {
      final q = req.url.queryParameters;
      final date = q['basDt']!;
      final isPrice = req.url.path.endsWith('getStockPriceInfo_V2');
      (isPrice ? priceCalls : listedCalls).add(date);
      if (errorBody != null) {
        return http.Response.bytes(utf8.encode(errorBody!), 200);
      }
      final items = (isPrice ? prices : listed)[date] ?? const [];
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'response': {
              'header': {'resultCode': '00', 'resultMsg': 'NORMAL SERVICE.'},
              'body': {
                'numOfRows': 1000,
                'pageNo': int.parse(q['pageNo']!),
                'totalCount': items.length,
                'items': items.isEmpty ? '' : {'item': items},
              },
            },
          }),
        ),
        200,
      );
    }),
  );
}

Map<String, String> price(
  String isin,
  String code,
  String name, {
  String market = 'KOSPI',
  String close = '71000',
  String cap = '423850000000000',
}) => {
  'srtnCd': code,
  'isinCd': isin,
  'itmsNm': name,
  'mrktCtg': market,
  'clpr': close,
  'vs': '-500',
  'mkp': '71500',
  'hipr': '72000',
  'lopr': '70500',
  'trqu': '12345678',
  'trPrc': '876543210000',
  'lstgStCnt': '5969782550',
  'mrktTotAmt': cap,
};

void main() {
  withServerpod('Given MarketSnapshotSync', (sessionBuilder, endpoints) {
    late Session session;
    late FakeDataGoKr api;
    // 2026-09-17(목) 12:00 KST
    final now = DateTime.utc(2026, 9, 17, 3);
    final resumes = <DateTime>[];

    Future<IngestJob> runSync({int dailyBudget = 9000}) async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: MarketSnapshotSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await MarketSnapshotSync(
        session,
        api.client(),
        job.id!,
        dailyBudget: dailyBudget,
        backfillFrom: DateTime.utc(2026, 9, 16),
        callInterval: Duration.zero,
        clock: () => now,
        scheduleResume: (at) async => resumes.add(at),
      ).run();
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    setUp(() async {
      session = sessionBuilder.build();
      api = FakeDataGoKr();
      resumes.clear();
      await Company.db.insertRow(
        session,
        Company(
          corpCode: '00126380',
          name: '삼성전자',
          market: Market.kospi,
          jurirNo: '1301110006246',
        ),
      );
    });

    test('기준일 시세와 종목을 저장하고, 상장종목 정보로 기업에 잇는다', () async {
      // 9/16부터 어제(9/16)까지 하루만 대상.
      api.prices['20260916'] = [
        price('KR7005930003', '005930', '삼성전자'),
        price('KR7005931001', '005935', '삼성전자우', cap: '40000000000000'),
      ];
      api.listed['20260916'] = [
        {
          'srtnCd': 'A005930',
          'isinCd': 'KR7005930003',
          'itmsNm': '삼성전자',
          'mrktCtg': 'KOSPI',
          'crno': '1301110006246',
          'corpNm': '삼성전자(주)',
        },
        {
          'srtnCd': 'A005935',
          'isinCd': 'KR7005931001',
          'itmsNm': '삼성전자우',
          'mrktCtg': 'KOSPI',
          'crno': '1301110006246',
          'corpNm': '삼성전자(주)',
        },
      ];

      final job = await runSync();

      expect(job.status, IngestStatus.succeeded, reason: job.message);
      expect(api.priceCalls, ['20260916']);
      final securities = await Security.db.find(
        session,
        orderBy: (t) => t.shortCode,
      );
      expect(securities.map((s) => s.shortCode), ['005930', '005935']);
      final company = (await Company.db.find(session)).single;
      expect(securities.every((s) => s.companyId == company.id), isTrue);
      expect(securities.first.crno, '1301110006246');
      expect(securities.first.market, Market.kospi);

      final snapshot = (await MarketSnapshot.db.find(
        session,
        where: (t) => t.securityId.equals(securities.first.id!),
      )).single;
      expect(snapshot.baseDate, DateTime.utc(2026, 9, 16));
      expect(snapshot.closePrice, BigInt.from(71000));
      expect(snapshot.change, BigInt.from(-500));
      expect(snapshot.marketCap, BigInt.parse('423850000000000'));
      expect(snapshot.listedShares, BigInt.parse('5969782550'));
      final source = (await Source.db.findById(session, snapshot.sourceId))!;
      expect(source.kind, SourceKind.dataGoKrApi);
      expect(source.url, isNot(contains('serviceKey')));
      expect(
        (await MarketSnapshotDay.db.find(session)).single.rowCount,
        2,
      );
    });

    test('상장종목정보에 없는 우선주는 ISIN 발행체 코드로, 외국 기업은 DART 종목코드로 잇는다', () async {
      final foreign = await Company.db.insertRow(
        session,
        Company(
          corpCode: '01160512',
          name: '헝셩그룹',
          market: Market.kosdaq,
          stockCode: '900270',
        ),
      );
      api.prices['20260916'] = [
        price('KR7005930003', '005930', '삼성전자'),
        price('KR7005931001', '005935', '삼성전자우', cap: '40000000000000'),
        price(
          'HK0000214814',
          '900270',
          '헝셩그룹',
          market: 'KOSDAQ',
          cap: '31119196640',
        ),
        // 발행체 코드가 연결된 종목과 겹치지 않는 우선주는 잇지 않는다.
        price('KR7999991009', '999995', '모르는우', cap: '1000'),
      ];
      api.listed['20260916'] = [
        {
          'srtnCd': 'A005930',
          'isinCd': 'KR7005930003',
          'itmsNm': '삼성전자',
          'mrktCtg': 'KOSPI',
          'crno': '1301110006246',
          'corpNm': '삼성전자(주)',
        },
        {
          'srtnCd': 'A900270',
          'isinCd': 'HK0000214814',
          'itmsNm': '헝셩그룹',
          'mrktCtg': 'KOSDAQ',
          'crno': '0000000000000',
          'corpNm': '헝셩그룹유한회사',
        },
      ];

      await runSync();

      final samsung = (await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals('00126380'),
      ))!;
      final byCode = {
        for (final s in await Security.db.find(session)) s.shortCode: s,
      };
      expect(byCode['005930']!.linkBasis, SecurityLinkBasis.crno);
      expect(byCode['005935']!.companyId, samsung.id);
      expect(byCode['005935']!.linkBasis, SecurityLinkBasis.isinIssuer);
      expect(byCode['900270']!.crno, isNull, reason: '0뿐인 법인등록번호는 없는 값');
      expect(byCode['900270']!.companyId, foreign.id);
      expect(byCode['900270']!.linkBasis, SecurityLinkBasis.dartStockCode);
      expect(byCode['999995']!.companyId, isNull);
    });

    test('주말은 건너뛰고, 휴장일은 기록하되 게시 전일 수 있는 최근 빈 날은 다시 본다', () async {
      Future<void> run() async {
        final job = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: MarketSnapshotSync.kind,
            status: IngestStatus.running,
            startedAt: DateTime.now().toUtc(),
          ),
        );
        await MarketSnapshotSync(
          session,
          api.client(),
          job.id!,
          backfillFrom: DateTime.utc(2026, 9, 10),
          callInterval: Duration.zero,
          clock: () => now,
        ).run();
      }

      api.prices['20260915'] = [price('KR7005930003', '005930', '삼성전자')];

      await run();

      expect(api.priceCalls, [
        '20260916',
        '20260915',
        '20260914',
        '20260911',
        '20260910',
      ]);
      final days = {
        for (final d in await MarketSnapshotDay.db.find(session))
          d.baseDate.day: d.rowCount,
      };
      expect(days, {15: 1, 11: 0, 10: 0});

      api.priceCalls.clear();
      await run();

      expect(api.priceCalls, ['20260916', '20260914']);
    });

    test('뒤 기준일 시세를 받은 적이 없으면 빈 날을 휴장일로 확정하지 않는다', () async {
      // 공급처 게시가 며칠 밀리는 동안 거래일을 휴장일로 못박아 영영 빠뜨리면 안 된다.
      api.prices['20260910'] = [price('KR7005930003', '005930', '삼성전자')];

      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: MarketSnapshotSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await MarketSnapshotSync(
        session,
        api.client(),
        job.id!,
        backfillFrom: DateTime.utc(2026, 9, 10),
        callInterval: Duration.zero,
        clock: () => now,
      ).run();

      final days = {
        for (final d in await MarketSnapshotDay.db.find(session))
          d.baseDate.day: d.rowCount,
      };
      expect(days, {10: 1});
    });

    test('서비스키 오류면 작업을 실패로 끝낸다', () async {
      api.errorBody =
          '<OpenAPI_ServiceResponse><cmmMsgHeader>'
          '<returnAuthMsg>SERVICE_KEY_IS_NOT_REGISTERED_ERROR</returnAuthMsg>'
          '<returnReasonCode>30</returnReasonCode></cmmMsgHeader></OpenAPI_ServiceResponse>';

      final job = await runSync();

      expect(job.status, IngestStatus.failed);
      expect(job.message, contains('SERVICE_KEY_IS_NOT_REGISTERED'));
    });

    test('호출 한도 초과(22)면 멈추고 다음 날 이어받기를 예약한다', () async {
      api.errorBody =
          '<OpenAPI_ServiceResponse><cmmMsgHeader>'
          '<returnAuthMsg>LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR</returnAuthMsg>'
          '<returnReasonCode>22</returnReasonCode></cmmMsgHeader></OpenAPI_ServiceResponse>';

      final job = await runSync();

      expect(job.status, IngestStatus.succeeded);
      expect(job.message, contains('예산'));
      expect(resumes, [DateTime.utc(2026, 9, 17, 15, 10)]);
    });
  });
}
