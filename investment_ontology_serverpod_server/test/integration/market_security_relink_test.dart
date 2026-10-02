import 'dart:convert';
import 'dart:async';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_hooks.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_schedule.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_security_relink.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_future_call.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_snapshot_sync.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('DB-only market relink', (builder, endpoints) {
    late Session session;
    late Company company;
    late Security security;
    late Source originalSource;
    final launched = <int>[];
    Future<List<int>> counts() async => [
      await Source.db.count(session),
      await MarketSnapshot.db.count(session),
      await MarketSnapshotDay.db.count(session),
      await MarketIndexSnapshot.db.count(session),
      await MarketIndexDay.db.count(session),
      await ApiCallUsage.db.count(session),
    ];
    Future<List<Object>> rawLedgers() async => [
      (await MarketSnapshot.db.find(session)).map((r) => r.toJson()).toList(),
      (await MarketSnapshotDay.db.find(session))
          .map((r) => r.toJson())
          .toList(),
      (await MarketIndexSnapshot.db.find(session))
          .map((r) => r.toJson())
          .toList(),
      (await MarketIndexDay.db.find(session)).map((r) => r.toJson()).toList(),
    ];
    Future<IngestJob> start() async =>
        (await IngestJobs.start(session, MarketSecurityRelink.kind))!;
    Future<IngestJob> job(int id) async =>
        (await IngestJob.db.findById(session, id))!;
    setUp(() async {
      session = builder.build();
      launched.clear();
      IngestHooks.marketSnapshotNow = (_, id) async => launched.add(id);
      IngestHooks.marketSecurityRelinkLater =
          IngestSchedule.marketSecurityRelinkLater;
      await sp.FutureCallEntry.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await MarketSnapshot.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await MarketSnapshotDay.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await MarketIndexSnapshot.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await MarketIndexDay.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      await Security.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await Company.db.deleteWhere(session, where: (_) => Constant.bool(true));
      await IngestJob.db.deleteWhere(
        session,
        where: (_) => Constant.bool(true),
      );
      originalSource = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: 'Saved market source',
          reference: '20261001',
          retrievedAt: DateTime.utc(2026, 10, 2),
        ),
      );
      company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00126380',
          name: '삼성전자',
          market: Market.kospi,
          stockCode: '005930',
          jurirNo: '130111-0006246',
        ),
      );
      security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR7005930003',
          shortCode: '005930',
          name: '삼성전자',
          crno: '1301110006246',
          sourceId: originalSource.id,
          lastSeenDate: DateTime.utc(2026, 10, 1),
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: DateTime.utc(2026, 10, 1),
          sourceId: originalSource.id!,
          closePrice: BigInt.from(71000),
          volume: BigInt.from(12345),
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(
          baseDate: DateTime.utc(2026, 10, 1),
          rowCount: 1,
          sourceId: originalSource.id,
          fetchedAt: DateTime.utc(2026, 10, 2),
        ),
      );
      await MarketIndexSnapshot.db.insertRow(
        session,
        MarketIndexSnapshot(
          baseDate: DateTime.utc(2026, 10, 1),
          series: 'kospi',
          name: '코스피',
          close: 3000.25,
          sourceId: originalSource.id!,
        ),
      );
      await MarketIndexDay.db.insertRow(
        session,
        MarketIndexDay(
          baseDate: DateTime.utc(2026, 10, 1),
          rowCount: 1,
          sourceId: originalSource.id,
          fetchedAt: DateTime.utc(2026, 10, 2),
        ),
      );
    });
    tearDown(IngestSchedule.installHooks);
    test('registered dispatcher is API0, preserves raw security and market ledgers', () async {
      final before = security.toJson()
        ..remove('companyId')
        ..remove('linkBasis');
      final original = await counts();
      final raw = await rawLedgers();
      final j = await start();
      await MarketSnapshotFutureCall().run(session, j.id!);
      final linked = (await Security.db.findById(session, security.id!))!;
      expect(linked.companyId, company.id);
      expect(linked.linkBasis, SecurityLinkBasis.crno);
      expect(
        linked.toJson()
          ..remove('companyId')
          ..remove('linkBasis'),
        before,
      );
      expect(await counts(), original);
      expect(await rawLedgers(), raw);
      expect(
        (await Source.db.findById(session, originalSource.id!))!.toJson(),
        originalSource.toJson(),
      );
      expect((await job(j.id!)).apiCalls, 0);
      expect((await job(j.id!)).status, IngestStatus.succeeded);
      await MarketSnapshotFutureCall().run(session, j.id!);
      expect((await job(j.id!)).updated, 1);
      expect(await counts(), original);
      expect(await rawLedgers(), raw);
    });
    test(
      'unmatched conflicting number changes no links, sources or ledgers',
      () async {
        security = await Security.db.updateRow(
          session,
          security.copyWith(crno: '9999999999999'),
        );
        final before = security.toJson(),
            raw = await rawLedgers(),
            original = await counts();
        await MarketSecurityRelink.requestIfNeeded(session);
        expect(launched, isEmpty);
        final j = await start();
        await MarketSnapshotFutureCall().run(session, j.id!);
        expect((await job(j.id!)).updated, 0);
        expect(
          (await Security.db.findById(session, security.id!))!.toJson(),
          before,
        );
        expect(await rawLedgers(), raw);
        expect(await counts(), original);
      },
    );
    test(
      'concurrent master requests coalesce, then no-match request is skipped',
      () async {
        await Future.wait([
          for (var i = 0; i < 6; i++)
            MarketSecurityRelink.requestIfNeeded(builder.build()),
        ]);
        expect(launched, hasLength(1));
        await MarketSecurityRelink.run(session, launched.single);
        await MarketSecurityRelink.requestIfNeeded(session);
        expect(launched, hasLength(1));
      },
    );
    test('running market defers one existing job, resumes without changing market counters', () async {
      final market = (await IngestJobs.start(
        session,
        MarketSnapshotSync.kind,
      ))!;
      final j = await start();
      await MarketSecurityRelink.run(session, j.id!);
      await MarketSecurityRelink.run(session, j.id!);
      final entries = await sp.FutureCallEntry.db.find(
        session,
        where: (t) => t.identifier.equals(MarketSecurityRelink.resumeId),
      );
      expect(entries, hasLength(1));
      expect(entries.single.name, 'MarketSnapshotRunFutureCall');
      expect(jsonDecode(entries.single.serializedObject!)['jobId'], j.id);
      expect((await job(market.id!)).toJson(), market.toJson());
      expect((await job(j.id!)).status, IngestStatus.running);
      expect(
        (await Security.db.findById(session, security.id!))!.companyId,
        isNull,
      );
      await IngestJob.db.updateRow(
        session,
        market.copyWith(status: IngestStatus.succeeded),
      );
      await MarketSecurityRelink.run(session, j.id!);
      expect((await job(j.id!)).status, IngestStatus.succeeded);
    });
    test(
      'admin cancel prevents deferred dispatch; reader cannot mutate',
      () async {
        await IngestJobs.start(session, MarketSnapshotSync.kind);
        final j = await start();
        await MarketSecurityRelink.run(session, j.id!);
        await endpoints.ingest.cancel(builder.asAdmin, j.id!);
        final before = await sp.FutureCallEntry.db.count(session);
        await MarketSecurityRelink.run(session, j.id!);
        expect((await job(j.id!)).status, IngestStatus.cancelled);
        expect(
          (await Security.db.findById(session, security.id!))!.companyId,
          isNull,
        );
        expect(await sp.FutureCallEntry.db.count(session), before);
        await expectLater(
          endpoints.ingest.cancel(builder.asReader, j.id!),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
      },
    );
    test(
      'startup restores orphan once, keeps registered queued dispatcher',
      () async {
        final j = await start();
        await IngestSchedule.onServerStart(session);
        expect((await job(j.id!)).status, IngestStatus.failed);
        final fresh = (await IngestJobs.latest(
          session,
          MarketSecurityRelink.kind,
        ))!;
        await IngestSchedule.onServerStart(session);
        expect((await job(fresh.id!)).status, IngestStatus.running);
        expect(
          await IngestJob.db.count(
            session,
            where: (t) => t.kind.equals(MarketSecurityRelink.kind),
          ),
          2,
        );
        await MarketSecurityRelink.run(session, fresh.id!);
        await IngestSchedule.onServerStart(session);
        expect(
          await IngestJob.db.count(
            session,
            where: (t) => t.kind.equals(MarketSecurityRelink.kind),
          ),
          2,
        );
      },
    );
    test('only changed successful master jobs request DB relink', () async {
      for (final (kind, status, updated) in [
        ('company_master', IngestStatus.failed, 1),
        ('company_master', IngestStatus.cancelled, 1),
        ('company_master', IngestStatus.succeeded, 0),
        ('financial_facts', IngestStatus.succeeded, 1),
      ]) {
        final j = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: kind,
            status: status,
            updated: updated,
            startedAt: DateTime.now().toUtc(),
          ),
        );
        await MarketSecurityRelink.afterMasterCompletion(session, j.id!);
      }
      expect(launched, isEmpty);
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: 'company_master',
          status: IngestStatus.succeeded,
          updated: 1,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await MarketSecurityRelink.afterMasterCompletion(session, j.id!);
      expect(launched, hasLength(1));
    });
    test(
      'unknown kind and failed old relink call do not revive API work',
      () async {
        for (final kind in ['financial_facts', MarketSecurityRelink.kind]) {
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: kind,
              status: IngestStatus.failed,
              startedAt: DateTime.now().toUtc(),
            ),
          );
          await MarketSnapshotFutureCall().run(session, j.id!);
          expect((await job(j.id!)).toJson(), j.toJson());
        }
        expect(
          (await Security.db.findById(session, security.id!))!.companyId,
          isNull,
        );
      },
    );
    test(
      'market claim and new market start both wait for relink shared lock',
      () async {
        final failed = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: MarketSnapshotSync.kind,
            status: IngestStatus.failed,
            startedAt: DateTime.now().toUtc(),
          ),
        );
        final locked = Completer<void>(), release = Completer<void>();
        final hold = session.db.transaction((tx) async {
          await IngestJobs.lockKind(session, MarketSnapshotSync.kind, tx);
          locked.complete();
          await release.future;
        });
        await locked.future;
        var resumed = false, started = false;
        final resume = IngestJobs.claim(
          builder.build(),
          failed.id!,
        ).then((_) => resumed = true);
        final start = IngestJobs.start(
          builder.build(),
          MarketSnapshotSync.kind,
        ).then((_) => started = true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(resumed, isFalse);
        expect(started, isFalse);
        release.complete();
        await hold;
        await Future.wait([resume, start]);
        expect(resumed, isTrue);
        expect(started, isTrue);
      },
    );
    test(
      'duplicate dispatch finishes once and does not rewrite sources',
      () async {
        final j = await start(), before = await counts();
        await Future.wait([
          for (var i = 0; i < 4; i++)
            MarketSecurityRelink.run(builder.build(), j.id!),
        ]);
        expect((await job(j.id!)).updated, 1);
        expect(await counts(), before);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
