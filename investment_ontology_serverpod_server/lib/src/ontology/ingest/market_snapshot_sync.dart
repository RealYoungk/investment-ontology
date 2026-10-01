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
  ///
  /// 이 기간이 지나도, 그 뒤 기준일의 시세를 받은 적이 없으면 아직 공개가 늦는 것으로 보고
  /// 휴장일로 확정하지 않는다 (확정하면 다시 받지 않아 거래일을 영영 빠뜨린다).
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
  final _recentEmptyDates = <DateTime>{};

  bool get _hasAllowance {
    if (client.calls >= _allowance) _budgetExhausted = true;
    return !_budgetExhausted;
  }

  /// KST 날짜의 UTC 자정.
  /// 이 기준일보다 뒤의 시세를 받은 적이 있는지. 공개가 늦는 것과 휴장일을 가른다.
  Future<bool> _hasLaterDay(DateTime date) async =>
      await MarketSnapshotDay.db.findFirstRow(
        session,
        where: (t) => (t.rowCount > 0) & (t.baseDate > date),
      ) !=
      null;

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

  /// 숫자만 남긴다. 비었거나 0뿐이면(외국 기업의 법인등록번호 `0000000000000`) null.
  static String? digits(String? v) {
    final d = v?.replaceAll(RegExp(r'\D'), '');
    return (d == null || d.isEmpty || RegExp(r'^0+$').hasMatch(d)) ? null : d;
  }

  /// ISIN의 발행체 코드. 국내 주식 ISIN은 `KR7` + 발행체 5자리 + 종목 구분 + … 이다.
  static String? isinIssuer(String isin) =>
      RegExp(r'^KR7[0-9A-Z]{9}$').hasMatch(isin) ? isin.substring(3, 8) : null;

  Future<void> run() async {
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) {
      client.close();
      return;
    }
    var job = claimed;
    var processed = 0, stored = 0, failed = 0;
    final failures = <String>[];
    var targetDates = <DateTime>[];
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
      final dates = targetDates = <DateTime>[
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
          if (items.isEmpty &&
              today.difference(date) <= publishGrace &&
              !today.difference(date).isNegative) {
            _recentEmptyDates.add(date);
          }
          if (items.isNotEmpty) {
            await _storeDay(date, items, securities);
            stored++;
          } else if (!today.difference(date).isNegative &&
              today.difference(date) > publishGrace &&
              await _hasLaterDay(date)) {
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
          if (e.isFatal || e.code == 'http') rethrow;
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

      var indexDays = 0;
      if (job.status != IngestStatus.cancelled) {
        indexDays = await _syncIndexes(start, failures);
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
          } else if (e.isFatal || e.code == 'http') {
            rethrow;
          } else {
            failures.add(
              '상장종목 ${DartValues.formatYmd(latestDay.baseDate)}: $e',
            );
          }
        }
      }

      final remaining = await _pendingPriceDates(targetDates);
      final priceDays = await MarketSnapshotDay.db.find(
        session,
        where: (t) => t.baseDate >= start,
      );
      final indexDates = {
        for (final day in await MarketIndexDay.db.find(session))
          day.baseDate.millisecondsSinceEpoch,
      };
      final pendingIndexes = priceDays
          .where(
            (day) => !indexDates.contains(day.baseDate.millisecondsSinceEpoch),
          )
          .length;
      var message =
          '시세 $stored일 저장, 남은 기준일 $remaining일, 지수 $indexDays일 저장, 지수 미완료 $pendingIndexes일, 기업 연결 종목 $linked개';
      if (_budgetExhausted && !cancelled) {
        final at = ApiCallBudget.nextKstMidnight(
          now,
        ).add(const Duration(minutes: 10));
        await scheduleResume?.call(at);
        message += ' · 일일 호출 예산($dailyBudget건) 소진';
      }
      // Recent empty responses remain unconfirmed; reuse the single resume hook.
      // Never compete with the earlier daily run or create unlimited hourly jobs.
      if (!cancelled &&
          failures.isEmpty &&
          !_budgetExhausted &&
          client.calls < _allowance &&
          _recentEmptyDates.isNotEmpty &&
          scheduleResume != null) {
        final at = now.add(const Duration(hours: 1));
        var dailyAt = DateTime.utc(today.year, today.month, today.day, 9);
        if (!dailyAt.isAfter(now)) {
          dailyAt = dailyAt.add(const Duration(days: 1));
        }
        const retryNote = '최근 미확보 기준일 1시간 후 재확인';
        final recentRetries = await IngestJob.db.count(
          session,
          where: (t) =>
              t.kind.equals(kind) &
              (t.startedAt >= now.subtract(const Duration(days: 1))) &
              t.message.like('%$retryNote%'),
        );
        if (at.isBefore(dailyAt) && recentRetries < 24) {
          await scheduleResume!(at);
          message += ' · $retryNote';
        }
      }
      if (failures.isNotEmpty) message += ' · 실패 예시: ${failures.join(' / ')}';
      await IngestJobs.save(
        session,
        job.copyWith(
          status: cancelled
              ? IngestStatus.cancelled
              : failures.isNotEmpty
              ? IngestStatus.failed
              : IngestStatus.succeeded,
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
      final retry =
          e is DataGoKrApiException &&
          e.code == 'http' &&
          scheduleResume != null &&
          !await IngestJobs.isCancelled(session, jobId);
      if (retry) {
        await scheduleResume!(
          _clock().toUtc().add(const Duration(minutes: 15)),
        );
      }
      await IngestJobs.save(
        session,
        job.copyWith(
          status: IngestStatus.failed,
          processed: processed,
          updated: stored,
          failed: failed + 1,
          apiCalls: client.calls,
          finishedAt: DateTime.now().toUtc(),
          message:
              '시세 $stored일 저장, 미완료 기준일 ${await _pendingPriceDates(targetDates)}일 · $e'
              '${retry ? ' · 15분 후 자동 재시도 예약' : ''}',
        ),
      );
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
          title: '공공데이터포털 금융위원회_주식시세정보 (getStockPriceInfo_V2) $ymd',
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

  Future<int> _pendingPriceDates(List<DateTime> dates) async {
    final storedDates = {
      for (final day in await MarketSnapshotDay.db.find(session))
        day.baseDate.millisecondsSinceEpoch,
    };
    return dates
        .where(
          (date) => !storedDates.contains(date.millisecondsSinceEpoch),
        )
        .length;
  }

  /// 지수시세를 받는다. 거래일·휴장일은 시세 장부([MarketSnapshotDay])를 따른다 —
  /// 시세가 있는 날만 부르고, 시세가 0건으로 확정된 휴장일은 부르지 않고 0건으로 적는다.
  /// 저장한 기준일 수를 돌려준다.
  Future<int> _syncIndexes(DateTime start, List<String> failures) async {
    final fetched = {
      for (final d in await MarketIndexDay.db.find(session))
        d.baseDate.millisecondsSinceEpoch,
    };
    final days = await MarketSnapshotDay.db.find(
      session,
      where: (t) => t.baseDate >= start,
      orderBy: (t) => t.baseDate.desc(),
    );
    var stored = 0;
    for (final day in days) {
      if (fetched.contains(day.baseDate.millisecondsSinceEpoch)) continue;
      if (day.rowCount == 0) {
        await MarketIndexDay.db.insertRow(
          session,
          MarketIndexDay(
            baseDate: day.baseDate,
            rowCount: 0,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        continue;
      }
      if (!_hasAllowance) break;
      try {
        final items = await _allPages(
          (page) => client.fetchMarketIndexes(day.baseDate, page: page),
        );
        if (items == null) break;
        // Empty index responses do not establish publication or holiday status.
        if (items.isEmpty) {
          final age = kstDate(_clock().toUtc()).difference(day.baseDate);
          if (!age.isNegative && age <= publishGrace) {
            _recentEmptyDates.add(day.baseDate);
          }
          continue;
        }
        await _storeIndexDay(day.baseDate, items);
        stored++;
      } on DataGoKrApiException catch (e) {
        if (e.code == '22') {
          _budgetExhausted = true;
          break;
        }
        if (e.isFatal || e.code == 'http') rethrow;
        if (failures.length < 5) {
          failures.add('지수 ${DartValues.formatYmd(day.baseDate)}: $e');
        }
        session.log(
          '지수 수집 실패 ${DartValues.formatYmd(day.baseDate)}: $e',
          level: LogLevel.warning,
        );
      }
      if (stored % 20 == 0) await _meter.flush(session);
    }
    return stored;
  }

  /// 원문 소수 문자열 → double. 비었거나 숫자가 아니면 null.
  static double? decimal(Object? value) {
    final v = DartValues.text(value)?.replaceAll(',', '');
    if (v == null || v == '-') return null;
    return double.tryParse(v);
  }

  Future<void> _storeIndexDay(
    DateTime date,
    List<Map<String, dynamic>> items,
  ) async {
    final ymd = DartValues.formatYmd(date);
    await session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: '공공데이터포털 금융위원회_지수시세정보 (getStockMarketIndex_V2) $ymd',
          reference: ymd,
          url: DataGoKrClient.publicUrl(
            DataGoKrClient.marketIndexPath,
            date,
          ).toString(),
          retrievedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
      final seen = <String>{};
      final rows = <MarketIndexSnapshot>[];
      for (final item in items) {
        final name = DartValues.text(item['idxNm']);
        final series = DartValues.text(item['idxCsf']);
        final close = decimal(item['clpr']);
        if (name == null || series == null || close == null) continue;
        if (!seen.add('$series|$name')) continue;
        rows.add(
          MarketIndexSnapshot(
            baseDate: date,
            series: series,
            name: name,
            close: close,
            change: decimal(item['vs']),
            changeRate: decimal(item['fltRt']),
            open: decimal(item['mkp']),
            high: decimal(item['hipr']),
            low: decimal(item['lopr']),
            volume: DartValues.amount(item['trqu']),
            tradingValue: DartValues.amount(item['trPrc']),
            marketCap: DartValues.amount(item['lstgMrktTotAmt']),
            constituentCount: int.tryParse(
              DartValues.text(item['epyItmsCnt']) ?? '',
            ),
            sourceId: source.id!,
          ),
        );
      }
      await MarketIndexSnapshot.db.deleteWhere(
        session,
        where: (t) => t.baseDate.equals(date),
        transaction: tx,
      );
      if (rows.isNotEmpty) {
        await MarketIndexSnapshot.db.insert(session, rows, transaction: tx);
      }
      await MarketIndexDay.db.insertRow(
        session,
        MarketIndexDay(
          baseDate: date,
          rowCount: rows.length,
          sourceId: source.id,
          fetchedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
    });
  }

  /// 법인등록번호로 잇지 못한 종목을 DART 종목코드, 그다음 ISIN 발행체 코드로 잇는다.
  ///
  /// 상장종목정보에는 우선주가 없어(2026-09-16 기준 시세 2,871종목 중 115종목) 법인등록번호가
  /// 없다. 같은 발행체 코드의 종목이 이미 한 기업에 연결되어 있을 때만 그 기업으로 잇는다.
  Future<void> _linkRemaining(
    Map<String, Security> securities,
    Map<String, int> byStockCode, {
    required Transaction transaction,
  }) async {
    final updates = <String, Security>{};
    void link(Security s, int companyId, SecurityLinkBasis basis) {
      final next = s.copyWith(companyId: companyId, linkBasis: basis);
      updates[s.isinCode] = next;
      securities[s.isinCode] = next;
    }

    for (final s in securities.values.toList()) {
      if (s.companyId != null && s.linkBasis == SecurityLinkBasis.crno) {
        continue;
      }
      final byCode = byStockCode[s.shortCode];
      if (byCode != null &&
          (s.companyId != byCode ||
              s.linkBasis != SecurityLinkBasis.dartStockCode)) {
        link(s, byCode, SecurityLinkBasis.dartStockCode);
      }
    }

    final issuers = <String, Set<int>>{};
    for (final s in securities.values) {
      final issuer = isinIssuer(s.isinCode);
      final basis = s.linkBasis;
      if (issuer == null || s.companyId == null) continue;
      if (basis != SecurityLinkBasis.crno &&
          basis != SecurityLinkBasis.dartStockCode) {
        continue;
      }
      (issuers[issuer] ??= {}).add(s.companyId!);
    }
    for (final s in securities.values.toList()) {
      if (s.linkBasis == SecurityLinkBasis.crno ||
          s.linkBasis == SecurityLinkBasis.dartStockCode) {
        continue;
      }
      final candidates = issuers[isinIssuer(s.isinCode)];
      // 한 발행체 코드가 여러 기업에 걸리면 추측하지 않는다.
      if (candidates != null && candidates.length == 1) {
        if (s.companyId != candidates.single ||
            s.linkBasis != SecurityLinkBasis.isinIssuer) {
          link(s, candidates.single, SecurityLinkBasis.isinIssuer);
        }
      }
    }
    if (updates.isNotEmpty) {
      await Security.db.update(
        session,
        updates.values.toList(),
        transaction: transaction,
      );
    }
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

    final listed = await Company.db.find(
      session,
      where: (t) => t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
    );
    final companies = <String, int>{
      for (final c in listed)
        if (digits(c.jurirNo) != null) digits(c.jurirNo)!: c.id!,
    };
    final byStockCode = <String, int>{
      for (final c in listed)
        if (c.stockCode != null) c.stockCode!: c.id!,
    };
    final ymd = DartValues.formatYmd(date);
    return session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dataGoKrApi,
          title: '공공데이터포털 금융위원회_KRX상장종목정보 (getItemInfo_V2) $ymd',
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
        final basis = companyId == null ? null : SecurityLinkBasis.crno;
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
              linkBasis: basis,
              lastSeenDate: date,
              sourceId: source.id,
            ),
          );
        } else if (current.crno != crno ||
            current.corpName != corpName ||
            current.companyId != companyId ||
            current.linkBasis != basis) {
          // nullable 필드는 copyWith에 null을 넘기면 지워진다. 원천에 없으면 비우는 게 맞다.
          updates.add(
            current.copyWith(
              crno: crno,
              corpName: corpName,
              companyId: companyId,
              linkBasis: basis,
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
      await _linkRemaining(securities, byStockCode, transaction: tx);
      return securities.values.where((s) => s.companyId != null).length;
    });
  }
}
