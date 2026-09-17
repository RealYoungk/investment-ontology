import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_values.dart';
import '../data_go_kr/data_go_kr_client.dart';
import 'api_call_budget.dart';
import 'ingest_jobs.dart';

/// 공공데이터포털 금융위원회 시세·상장종목 수집.
///
/// 1. 받지 않은 평일 기준일을 최신순으로 주식시세정보(getStockPriceInfo) 전 종목을 받아
///    [Security]와 [MarketSnapshot]에 넣는다. 기준일마다 [MarketSnapshotDay]를 남긴다.
/// 2. 가장 최근 기준일의 KRX상장종목정보(getItemInfo)로 종목의 법인등록번호를 받아
///    Company.jurirNo와 같은 기업에 잇는다.
class MarketSnapshotSync {
  MarketSnapshotSync(
    this.session,
    this.client,
    this.jobId, {
    this.dailyBudget = 9000,
    this.backfillYears = 5,
    this.backfillFrom,
    this.callInterval = const Duration(milliseconds: 100),
    this.scheduleResume,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const kind = 'market_snapshot';

  /// 시세는 다음 영업일 오후에 올라온다. 이 기간 안의 빈 기준일은 휴장일로 확정하지 않는다.
  static const publishGrace = Duration(days: 3);

  static const _insertChunk = 1000;

  final Session session;
  final DataGoKrClient client;
  final int jobId;

  /// 공공데이터포털 일일 호출 예산 (개발계정 서비스당 10,000건).
  final int dailyBudget;

  /// 처음 수집할 때 거슬러 올라갈 햇수.
  final int backfillYears;

  /// 지정하면 [backfillYears] 대신 이 날짜부터 받는다 (UTC 자정).
  final DateTime? backfillFrom;
  final Duration callInterval;
  final Future<void> Function(DateTime at)? scheduleResume;
  final DateTime Function() _clock;

  late final _meter = ApiCallMeter(ApiProvider.dataGoKr, () => client.calls);
  late int _allowance;
  bool _budgetExhausted = false;

  bool get _hasAllowance {
    if (client.calls >= _allowance) _budgetExhausted = true;
    return !_budgetExhausted;
  }

  /// KST 날짜의 UTC 자정.
  static DateTime kstDate(DateTime now) {
    final k = now.toUtc().add(const Duration(hours: 9));
    return DateTime.utc(k.year, k.month, k.day);
  }

  static Market? marketOf(Object? mrktCtg) =>
      switch (DartValues.text(mrktCtg)?.toUpperCase()) {
        'KOSPI' => Market.kospi,
        'KOSDAQ' => Market.kosdaq,
        'KONEX' => Market.konex,
        _ => null,
      };

  /// `A005930`처럼 앞에 A가 붙어 와도 6자리 단축코드로.
  static String? shortCodeOf(Object? srtnCd) {
    final v = DartValues.text(srtnCd);
    if (v == null) return null;
    return RegExp(r'^A[0-9A-Z]{6}$').hasMatch(v) ? v.substring(1) : v;
  }

  static String? digits(String? v) {
    final d = v?.replaceAll(RegExp(r'\D'), '');
    return (d == null || d.isEmpty) ? null : d;
  }

  Future<void> run() async {
    var job = (await IngestJob.db.findById(session, jobId))!;
    var processed = 0, stored = 0, failed = 0;
    final failures = <String>[];
    try {
      final now = _clock().toUtc();
      _allowance =
          dailyBudget -
          await ApiCallBudget.usedToday(
            session,
            ApiProvider.dataGoKr,
            now: now,
          );

      final today = kstDate(now);
      final start =
          backfillFrom ??
          DateTime.utc(today.year - backfillYears, today.month, today.day);
      final fetched = {
        for (final d in await MarketSnapshotDay.db.find(session))
          d.baseDate.millisecondsSinceEpoch,
      };
      final dates = <DateTime>[
        for (
          var d = today.subtract(const Duration(days: 1));
          !d.isBefore(start);
          d = d.subtract(const Duration(days: 1))
        )
          if (d.weekday != DateTime.saturday &&
              d.weekday != DateTime.sunday &&
              !fetched.contains(d.millisecondsSinceEpoch))
            d,
      ];
      job = await IngestJobs.save(session, job.copyWith(total: dates.length));

      final securities = {
        for (final s in await Security.db.find(session)) s.isinCode: s,
      };

      for (final date in dates) {
        if (processed % 5 == 0 &&
            await IngestJobs.isCancelled(session, jobId)) {
          job = job.copyWith(status: IngestStatus.cancelled);
          break;
        }
        if (!_hasAllowance) break;
        try {
          final items = await _allPages(
            (page) => client.fetchStockPrices(date, page: page),
          );
          if (items == null) break;
          if (items.isNotEmpty) {
            await _storeDay(date, items, securities);
            stored++;
          } else if (!today.difference(date).isNegative &&
              today.difference(date) > publishGrace) {
            await MarketSnapshotDay.db.insertRow(
              session,
              MarketSnapshotDay(
                baseDate: date,
                rowCount: 0,
                fetchedAt: DateTime.now().toUtc(),
              ),
            );
          }
        } on DataGoKrApiException catch (e) {
          if (e.code == '22') {
            _budgetExhausted = true;
            break;
          }
          if (e.isFatal) rethrow;
          failed++;
          if (failures.length < 5) {
            failures.add('${DartValues.formatYmd(date)}: $e');
          }
          session.log(
            '시세 수집 실패 ${DartValues.formatYmd(date)}: $e',
            level: LogLevel.warning,
          );
        }
        processed++;
        if (processed % 5 == 0) {
          await _meter.flush(session);
          job = await IngestJobs.save(
            session,
            job.copyWith(
              processed: processed,
              updated: stored,
              failed: failed,
              apiCalls: client.calls,
            ),
          );
        }
      }

      var linked = 0;
      final cancelled = job.status == IngestStatus.cancelled;
      final latestDay = await MarketSnapshotDay.db.findFirstRow(
        session,
        where: (t) => t.rowCount > 0,
        orderBy: (t) => t.baseDate.desc(),
      );
      if (!cancelled &&
          latestDay != null &&
          _hasAllowance &&
          (stored > 0 || securities.values.every((s) => s.crno == null))) {
        try {
          linked = await _refreshListing(latestDay.baseDate, securities);
        } on DataGoKrApiException catch (e) {
          if (e.code == '22') {
            _budgetExhausted = true;
          } else if (e.isFatal) {
            rethrow;
          } else {
            failures.add(
              '상장종목 ${DartValues.formatYmd(latestDay.baseDate)}: $e',
            );
          }
        }
      }

      final remaining = dates.length - processed;
      var message = '시세 $stored일 저장, 남은 기준일 $remaining일, 기업 연결 종목 $linked개';
      if (_budgetExhausted && !cancelled) {
        final at = ApiCallBudget.nextKstMidnight(
          now,
        ).add(const Duration(minutes: 10));
        await scheduleResume?.call(at);
        message += ' · 일일 호출 예산($dailyBudget건) 소진';
      }
      if (failures.isNotEmpty) message += ' · 실패 예시: ${failures.join(' / ')}';
      await IngestJobs.save(
        session,
        job.copyWith(
          status: cancelled ? IngestStatus.cancelled : IngestStatus.succeeded,
          processed: processed,
          updated: stored,
          failed: failed,
          apiCalls: client.calls,
          finishedAt: DateTime.now().toUtc(),
          message: message,
        ),
      );
    } catch (e, st) {
      session.log(
        '시세 수집 실패',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      await IngestJobs.fail(session, jobId, '$e', apiCalls: client.calls);
    } finally {
      await _meter.flush(session);
      client.close();
    }
  }

  /// 모든 페이지를 받는다. 도중에 예산이 떨어지면 null.
  Future<List<Map<String, dynamic>>?> _allPages(
    Future<DataGoKrPage> Function(int page) fetch,
  ) async {
    final items = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      if (!_hasAllowance) return null;
      final result = await fetch(page);
      await Future<void>.delayed(callInterval);
      items.addAll(result.items);
      if (result.items.isEmpty || result.isLast) return items;
    }
  }

  Future<void> _storeDay(
    DateTime date,
    List<Map<String, dynamic>> items,
    Map<String, Security> securities,
  ) async {
    final ymd = DartValues.formatYmd(date);
    await session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: '공공데이터포털 금융위원회_주식시세정보 (getStockPriceInfo) $ymd',
          reference: ymd,
          url: DataGoKrClient.publicUrl(
            DataGoKrClient.stockPricePath,
            date,
          ).toString(),
          retrievedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );

      final newSecurities = <String, Security>{};
      final changed = <String, Security>{};
      for (final item in items) {
        final isin = DartValues.text(item['isinCd']);
        final shortCode = shortCodeOf(item['srtnCd']);
        if (isin == null || shortCode == null) continue;
        final name = DartValues.text(item['itmsNm']) ?? shortCode;
        final market = marketOf(item['mrktCtg']);
        final current = securities[isin];
        if (current == null) {
          newSecurities[isin] = Security(
            isinCode: isin,
            shortCode: shortCode,
            name: name,
            market: market,
            lastSeenDate: date,
            sourceId: source.id,
          );
        } else if (date.isAfter(current.lastSeenDate)) {
          changed[isin] = current.copyWith(
            shortCode: shortCode,
            name: name,
            market: market ?? current.market,
            lastSeenDate: date,
            sourceId: source.id,
          );
        }
      }
      if (newSecurities.isNotEmpty) {
        for (final s in await Security.db.insert(
          session,
          newSecurities.values.toList(),
          transaction: tx,
        )) {
          securities[s.isinCode] = s;
        }
      }
      if (changed.isNotEmpty) {
        for (final s in await Security.db.update(
          session,
          changed.values.toList(),
          transaction: tx,
        )) {
          securities[s.isinCode] = s;
        }
      }

      final existing = {
        for (final s in await MarketSnapshot.db.find(
          session,
          where: (t) => t.baseDate.equals(date),
          transaction: tx,
        ))
          s.securityId,
      };
      final rows = <MarketSnapshot>[];
      for (final item in items) {
        final security = securities[DartValues.text(item['isinCd'])];
        if (security == null || !existing.add(security.id!)) continue;
        rows.add(
          MarketSnapshot(
            securityId: security.id!,
            baseDate: date,
            closePrice: DartValues.amount(item['clpr']),
            change: DartValues.amount(item['vs']),
            openPrice: DartValues.amount(item['mkp']),
            highPrice: DartValues.amount(item['hipr']),
            lowPrice: DartValues.amount(item['lopr']),
            volume: DartValues.amount(item['trqu']),
            tradingValue: DartValues.amount(item['trPrc']),
            listedShares: DartValues.amount(item['lstgStCnt']),
            marketCap: DartValues.amount(item['mrktTotAmt']),
            sourceId: source.id!,
          ),
        );
      }
      for (var i = 0; i < rows.length; i += _insertChunk) {
        await MarketSnapshot.db.insert(
          session,
          rows.sublist(i, (i + _insertChunk).clamp(0, rows.length)),
          transaction: tx,
        );
      }
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(
          baseDate: date,
          rowCount: rows.length,
          sourceId: source.id,
          fetchedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
    });
  }

  /// 상장종목 목록으로 종목의 법인등록번호와 기업을 잇는다. 기업에 이어진 종목 수.
  Future<int> _refreshListing(
    DateTime date,
    Map<String, Security> securities,
  ) async {
    final items = await _allPages(
      (page) => client.fetchListedItems(date, page: page),
    );
    if (items == null || items.isEmpty) return 0;

    final companies = <String, int>{
      for (final c in await Company.db.find(
        session,
        where: (t) => t.jurirNo.notEquals(null),
      ))
        if (digits(c.jurirNo) != null) digits(c.jurirNo)!: c.id!,
    };
    final ymd = DartValues.formatYmd(date);
    return session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: '공공데이터포털 금융위원회_KRX상장종목정보 (getItemInfo) $ymd',
          reference: ymd,
          url: DataGoKrClient.publicUrl(
            DataGoKrClient.listedItemPath,
            date,
          ).toString(),
          retrievedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
      final inserts = <Security>[];
      final updates = <Security>[];
      for (final item in items) {
        final isin = DartValues.text(item['isinCd']);
        final shortCode = shortCodeOf(item['srtnCd']);
        if (isin == null || shortCode == null) continue;
        final crno = digits(DartValues.text(item['crno']));
        final corpName = DartValues.text(item['corpNm']);
        final companyId = crno == null ? null : companies[crno];
        final current = securities[isin];
        if (current == null) {
          inserts.add(
            Security(
              isinCode: isin,
              shortCode: shortCode,
              name: DartValues.text(item['itmsNm']) ?? shortCode,
              market: marketOf(item['mrktCtg']),
              crno: crno,
              corpName: corpName,
              companyId: companyId,
              lastSeenDate: date,
              sourceId: source.id,
            ),
          );
        } else if (current.crno != crno ||
            current.corpName != corpName ||
            current.companyId != companyId) {
          // nullable 필드는 copyWith에 null을 넘기면 지워진다. 원천에 없으면 비우는 게 맞다.
          updates.add(
            current.copyWith(
              crno: crno,
              corpName: corpName,
              companyId: companyId,
              sourceId: source.id,
            ),
          );
        }
      }
      if (inserts.isNotEmpty) {
        for (final s in await Security.db.insert(
          session,
          inserts,
          transaction: tx,
        )) {
          securities[s.isinCode] = s;
        }
      }
      if (updates.isNotEmpty) {
        for (final s in await Security.db.update(
          session,
          updates,
          transaction: tx,
        )) {
          securities[s.isinCode] = s;
        }
      }
      return securities.values.where((s) => s.companyId != null).length;
    });
  }
}
