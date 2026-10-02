import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/data_go_kr/data_go_kr_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_sync.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given saved market data and a later company master', (
    builder,
    _,
  ) {
    final now = DateTime.utc(2026, 9, 17, 3);
    final date = DateTime.utc(2026, 9, 16);
    var requests = 0;

    Future<Security> seed({
      String code = '468670',
      String? crno = '1201110746711',
    }) async {
      final session = builder.build();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: '합성 격리 시세 출처',
          reference: '20260916',
          url: 'https://apis.data.go.kr/synthetic-test',
          retrievedAt: now,
        ),
      );
      final security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR7468670005',
          shortCode: code,
          name: '합성종목',
          crno: crno,
          lastSeenDate: date,
          sourceId: source.id,
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: date,
          closePrice: BigInt.from(12345),
          marketCap: BigInt.from(67890),
          sourceId: source.id!,
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(baseDate: date, rowCount: 1, fetchedAt: now),
      );
      await MarketIndexDay.db.insertRow(
        session,
        MarketIndexDay(baseDate: date, rowCount: 1, fetchedAt: now),
      );
      return security;
    }

    Future<IngestJob> run({bool cancelled = false}) async {
      final session = builder.build();
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: MarketSnapshotSync.kind,
          status: cancelled ? IngestStatus.cancelled : IngestStatus.running,
          startedAt: now,
        ),
      );
      await MarketSnapshotSync(
        session,
        DataGoKrClient(
          'synthetic-key',
          httpClient: MockClient((req) async {
            requests++;
            throw StateError('No HTTP is needed for stored days');
          }),
        ),
        job.id!,
        dailyBudget: 0,
        backfillFrom: date,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    setUp(() => requests = 0);

    test('new master links by exact corporate number with no HTTP and preserves price/source', () async {
      final session = builder.build();
      final original = await seed();
      final price = (await MarketSnapshot.db.find(session)).single.toJson();
      final sources = (await Source.db.find(session))
          .map((s) => s.toJson())
          .toList();
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '01801026',
          name: '주식회사 브릴스',
          stockCode: '468670',
          market: Market.kosdaq,
          jurirNo: '1201110746711',
        ),
      );
      final job = await run();
      final actual = (await Security.db.findById(session, original.id!))!;
      expect(
        actual.toJson(),
        original
            .copyWith(companyId: company.id, linkBasis: SecurityLinkBasis.crno)
            .toJson(),
      );
      expect((await MarketSnapshot.db.find(session)).single.toJson(), price);
      expect(
        (await Source.db.find(session)).map((s) => s.toJson()).toList(),
        sources,
      );
      expect(job.status, IngestStatus.succeeded);
      expect(job.updated, 0, reason: '회사 연결은 신규 시세일 저장이 아님');
      expect(job.apiCalls, 0);
      expect(job.message, contains('기업 연결 종목 1개'));
      final replay = await run();
      expect(replay.message, contains('기업 연결 종목 0개'));
      expect(
        (await Security.db.findById(session, original.id!))!.toJson(),
        actual.toJson(),
      );
      expect(requests, 0);
    });

    test(
      'missing corporate number allows only a unique exact stock-code match',
      () async {
        final session = builder.build();
        final security = await seed(crno: null);
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '01801026',
            name: '합성 신규마스터',
            stockCode: '468670',
            market: Market.kosdaq,
          ),
        );
        await run();
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security
              .copyWith(
                companyId: company.id,
                linkBasis: SecurityLinkBasis.dartStockCode,
              )
              .toJson(),
        );
        expect(requests, 0);
      },
    );

    test(
      'duplicate corporate number cannot fall through to a unique stock match',
      () async {
        final session = builder.build();
        final security = await seed();
        for (var i = 1; i <= 2; i++) {
          await Company.db.insertRow(
            session,
            Company(
              corpCode: '9900000$i',
              name: '합성 번호중복$i',
              market: Market.kosdaq,
              jurirNo: '1201110746711',
              stockCode: i == 1 ? '468670' : null,
            ),
          );
        }
        await run();
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security.toJson(),
        );
        expect(requests, 0);
      },
    );

    test(
      'duplicate stock codes cannot fall through to a unique corporate match',
      () async {
        final session = builder.build();
        final security = await seed();
        for (var i = 1; i <= 2; i++) {
          await Company.db.insertRow(
            session,
            Company(
              corpCode: '9900000$i',
              name: '합성 코드중복$i',
              market: Market.kosdaq,
              stockCode: '468670',
              jurirNo: i == 1 ? '1201110746711' : null,
            ),
          );
        }
        await run();
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security.toJson(),
        );
      },
    );

    test(
      'different corporate-number and stock-code issuers remain unlinked',
      () async {
        final session = builder.build();
        final security = await seed();
        await Company.db.insertRow(
          session,
          Company(
            corpCode: '99000001',
            name: '합성 번호회사',
            market: Market.kosdaq,
            jurirNo: '1201110746711',
          ),
        );
        await Company.db.insertRow(
          session,
          Company(
            corpCode: '99000002',
            name: '합성 코드회사',
            market: Market.kosdaq,
            stockCode: '468670',
          ),
        );
        await run();
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security.toJson(),
        );
      },
    );

    test(
      'delisted master and cancelled jobs do not link the saved security',
      () async {
        final session = builder.build();
        final security = await seed();
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '01801026',
            name: '합성 비상장마스터',
            stockCode: '468670',
            market: Market.other,
            jurirNo: '1201110746711',
          ),
        );
        await run();
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security.toJson(),
        );
        await Company.db.updateRow(
          session,
          company.copyWith(market: Market.kosdaq),
        );
        final job = await run(cancelled: true);
        expect(job.status, IngestStatus.cancelled);
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          security.toJson(),
        );
        expect(requests, 0);
      },
    );
  });
}
