import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'ingest_hooks.dart';
import 'ingest_jobs.dart';
import 'market_snapshot_sync.dart';

/// Connect saved securities to a changed master; never requests market data.
abstract final class MarketSecurityRelink {
  static const kind = 'market_security_relink';
  static const resumeId = 'market_security_relink_resume';
  static const retryDelay = Duration(seconds: 30);

  /// A unique identifier must agree across both master fields when present.
  static Map<int, SecurityLinkBasis> matches(
    List<Company> companies,
    List<Security> securities,
  ) {
    final byId = {for (final c in companies) c.id!: c};
    final byCrno = <String, Set<int>>{};
    final byCode = <String, Set<int>>{};
    for (final c in companies) {
      if (!{Market.kospi, Market.kosdaq, Market.konex}.contains(c.market)) {
        continue;
      }
      final crno = MarketSnapshotSync.digits(c.jurirNo);
      if (crno != null) (byCrno[crno] ??= {}).add(c.id!);
      if (c.stockCode != null) (byCode[c.stockCode!] ??= {}).add(c.id!);
    }
    final result = <int, SecurityLinkBasis>{};
    for (final s in securities) {
      if (s.companyId != null) continue;
      final crno = MarketSnapshotSync.digits(s.crno);
      final numbers = crno == null ? null : byCrno[crno];
      final codes = byCode[s.shortCode];
      if ((numbers?.length ?? 0) > 1 || (codes?.length ?? 0) > 1) continue;
      final number = numbers?.singleOrNull;
      final code = codes?.singleOrNull;
      if (number != null && code != null && number != code) continue;
      final id = number ?? code;
      if (id != null &&
          MarketSnapshotSync.registrationNumbersAgree(
            s.crno,
            byId[id]?.jurirNo,
          )) {
        result[s.id!] = number != null
            ? SecurityLinkBasis.crno
            : SecurityLinkBasis.dartStockCode;
      }
    }
    return result;
  }

  static int? companyFor(
    Security s,
    List<Company> companies,
    SecurityLinkBasis basis,
  ) {
    final eligible = companies.where(
      (c) => {Market.kospi, Market.kosdaq, Market.konex}.contains(c.market),
    );
    return (basis == SecurityLinkBasis.crno
            ? eligible.where(
                (c) =>
                    MarketSnapshotSync.digits(c.jurirNo) ==
                    MarketSnapshotSync.digits(s.crno),
              )
            : eligible.where((c) => c.stockCode == s.shortCode))
        .single
        .id;
  }

  static Future<({List<Company> companies, List<Security> securities})> _read(
    Session session, {
    Transaction? transaction,
  }) async => (
    companies: await Company.db.find(
      session,
      where: (t) => t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
      transaction: transaction,
      lockMode: transaction == null ? null : LockMode.forShare,
    ),
    securities: await Security.db.find(
      session,
      where: (t) => t.companyId.equals(null),
      transaction: transaction,
    ),
  );

  /// Master completion and startup only enqueue when an actual match exists.
  static Future<void> requestIfNeeded(Session session) async {
    final rows = await _read(session);
    if (matches(rows.companies, rows.securities).isEmpty) return;
    await IngestJobs.startAndSchedule(
      session,
      kind,
      (job) => IngestHooks.require(
        IngestHooks.marketSnapshotNow,
        'marketSnapshotNow',
      )(session, job.id!),
    );
  }

  static Future<void> afterMasterCompletion(Session session, int jobId) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job?.kind == 'company_master' &&
        job?.status == IngestStatus.succeeded &&
        (job?.updated ?? 0) > 0) {
      await requestIfNeeded(session);
    }
  }

  /// The same generated marketSnapshot.run(jobId) dispatch handles this kind.
  /// Both locks precede row locks: requests cannot disappear across completion,
  /// and a new price job cannot start during the database-only transaction.
  static Future<void> run(Session session, int jobId) async {
    // Interrupted running jobs are recovered by startup; old failed calls
    // must not revive alongside a newly scheduled relink job.
    final before = await IngestJob.db.findById(session, jobId);
    if (before?.kind != kind || before?.status != IngestStatus.running) return;
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null || claimed.kind != kind) return;
    try {
      await session.db.transaction((tx) async {
        await IngestJobs.lockKind(session, kind, tx);
        await IngestJobs.lockKind(session, MarketSnapshotSync.kind, tx);
        final job = await IngestJob.db.findById(
          session,
          jobId,
          transaction: tx,
          lockMode: LockMode.forUpdate,
        );
        if (job == null ||
            job.kind != kind ||
            job.status != IngestStatus.running) {
          return;
        }
        // Do not expire or modify a price job from this database-only worker.
        final market = await IngestJob.db.findFirstRow(
          session,
          where: (t) =>
              t.kind.equals(MarketSnapshotSync.kind) &
              t.status.equals(IngestStatus.running),
          transaction: tx,
        );
        if (market != null) {
          await IngestHooks.require(
            IngestHooks.marketSecurityRelinkLater,
            'marketSecurityRelinkLater',
          )(session, jobId, DateTime.now().toUtc().add(retryDelay));
          await IngestJob.db.updateRow(
            session,
            job.copyWith(message: '시장 작업 종료 후 기존 종목 재연결 대기'),
            transaction: tx,
          );
          return;
        }
        final rows = await _read(session, transaction: tx);
        final links = matches(rows.companies, rows.securities);
        var updated = 0;
        for (final s in rows.securities) {
          final basis = links[s.id];
          if (basis == null) continue;
          // Only these two fields are changed. Source/market identifiers stay.
          updated += (await Security.db.updateWhere(
            session,
            where: (t) =>
                t.id.equals(s.id!) &
                t.companyId.equals(null) &
                t.shortCode.equals(s.shortCode) &
                t.crno.equals(s.crno),
            columnValues: (t) => [
              t.companyId(companyFor(s, rows.companies, basis)),
              t.linkBasis(basis),
            ],
            transaction: tx,
          )).length;
        }
        await IngestJob.db.updateRow(
          session,
          job.copyWith(
            status: IngestStatus.succeeded,
            finishedAt: DateTime.now().toUtc(),
            total: links.length,
            processed: links.length,
            updated: updated,
            message: '기존 종목 $updated개 재연결 · 시세 API 호출 없음',
          ),
          transaction: tx,
        );
      });
    } catch (e) {
      await IngestJobs.fail(session, jobId, '기존 종목 재연결 실패: $e');
      rethrow;
    }
  }
}
