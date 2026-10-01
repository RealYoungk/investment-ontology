import 'dart:math';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import '../dart/dart_report_name.dart';
import '../dart/dart_values.dart';
import '../dart/public_financial_xbrl.dart';
import '../dart/public_financial_html.dart';
import 'api_call_budget.dart';
import 'financial_rows.dart';
import 'financial_period_repair.dart';
import 'ingest_jobs.dart';

/// DART 정기보고서의 전체 재무제표를 수집한다.
///
/// 1. 공시 목록(`list.json`)에서 상장사 정기보고서를 찾아 [DartFiling] 장부에 넣는다.
/// 2. 받지 않은 보고서를 최신순으로 연결·별도 각각 `fnlttSinglAcntAll`로 받는다.
/// 3. 정정공시면 새 보고서·사실을 추가하고 이전 것은 supersededBy로 잇는다.
///
/// DART 일일 한도를 다른 수집과 나눠 쓰므로 [dailyBudget]에 닿으면 멈추고
/// [scheduleResume]으로 다음 날 이어서 받는다.
class FinancialFactsSync {
  FinancialFactsSync(
    this.session,
    this.dart,
    this.jobId, {
    int? dailyBudget,
    this.callInterval = const Duration(milliseconds: 200),
    this.scheduleResume,
    this.corpCode,
    DateTime Function()? clock,
  }) : dailyBudget = dailyBudget ?? ApiCallBudget.dartFinancialBudget,
       _explicitBudget = dailyBudget != null,
       _clock = clock ?? DateTime.now;

  static const kind = 'financial_facts';

  /// 기업 하나만 받는 수집. 전체 수집과 따로 세어 백필 중에도 돌 수 있다.
  static const companyKind = 'financial_facts_company';

  /// 공시별 실패 허용 횟수(실행 횟수 기준). 넘으면 다시 시도하지 않는다.
  static const maxAttempts = 3;

  /// DART는 회사를 지정하지 않은 공시 검색을 3개월 이내로 제한한다. 달력 기준이라
  /// 2월이 끼면 90일도 넘치므로(오류 100) 어느 달에서 시작해도 3개월 안인 85일로 자른다.
  static const scanWindow = Duration(days: 85);

  /// 이미 훑은 구간도 이만큼 겹쳐 다시 본다 (늦게 반영되는 공시 대비).
  static const scanOverlap = Duration(days: 7);

  static const _progressEvery = 20;

  /// 먼저 채우는 햇수. 최근 5개 사업연도부터 끝낸다.
  static const historyYears = 5;

  /// 사업보고서 목록 탐색의 시작 사업연도.
  static int firstAnnualYear(DateTime now, [int years = historyYears]) =>
      now.year - years;

  /// 목록 탐색은 연간보고서 발견을 위해 기존 5개년 창을 유지한다.
  /// 발견한 과거 중간보고서는 장부에 보존하지만 재무 취득 대상에는 넣지 않는다.
  static int firstInterimYear(DateTime now, [int years = historyYears]) =>
      now.year - years + 1;

  /// 기업의 최근 연간 5개 사업연도와 최신 공시가 중간보고서인 경우 그 한 기간.
  /// 각 기간은 최종 접수번호만 선택하며 기업별 결산 사업연도를 그대로 사용한다.
  static Set<int> financialScopeIds(Iterable<DartFiling> filings) {
    int actualPeriod(DartFiling f) {
      final parsed = DartReportName.parse(f.reportName);
      if (parsed != null) return parsed.periodYear * 100 + parsed.periodMonth;
      // Retain historical unparseable ledger compatibility; new ingestion
      // never admits an unparseable report name.
      final month = switch (f.reportCode!) {
        FinancialReportCode.annual => 12,
        FinancialReportCode.q3 => 9,
        FinancialReportCode.halfYear => 6,
        FinancialReportCode.q1 => 3,
      };
      return f.bsnsYear! * 100 + month;
    }

    final periods = <String, DartFiling>{};
    for (final f in filings) {
      if (f.companyId == null || f.bsnsYear == null || f.reportCode == null) {
        continue;
      }
      final key = '${f.companyId}:${actualPeriod(f)}:${f.reportCode!.name}';
      final old = periods[key];
      if (old == null || f.rceptNo.compareTo(old.rceptNo) > 0) periods[key] = f;
    }
    final byCompany = <int, List<DartFiling>>{};
    for (final f in periods.values) {
      byCompany.putIfAbsent(f.companyId!, () => []).add(f);
    }
    final ids = <int>{};
    for (final company in byCompany.values) {
      company.sort((a, b) {
        final period = actualPeriod(b).compareTo(actualPeriod(a));
        return period != 0 ? period : b.rceptNo.compareTo(a.rceptNo);
      });
      final annuals = company.where(
        (f) => f.reportCode == FinancialReportCode.annual,
      );
      final latestAnnual = annuals.firstOrNull;
      if (latestAnnual != null) {
        final first = latestAnnual.bsnsYear! - historyYears + 1;
        ids.addAll(
          annuals.where((f) => f.bsnsYear! >= first).map((f) => f.id!),
        );
      }
      final latest = company.first;
      if (latest.reportCode != FinancialReportCode.annual) ids.add(latest.id!);
    }
    return ids;
  }

  static const _listedMarkets = {Market.kospi, Market.kosdaq, Market.konex};

  final Session session;
  final DartClient dart;
  final int jobId;
  final int dailyBudget;
  final bool _explicitBudget;
  late int _activeBudget;
  bool _apiQuotaBlocked = false;
  static const _annualRecoveryMarker = "source-annual-period-reclassified";
  static const annualRecoveryBudget = 19900;
  final Duration callInterval;

  /// 지정하면 이 기업의 정기보고서만 찾아 받는다. 전체 스캔 커서는 움직이지 않는다.
  final String? corpCode;

  /// 한도 소진 시 이어받기를 예약한다. null이면 예약하지 않는다.
  final Future<void> Function(DateTime at)? scheduleResume;
  int _xbrlCoreRecovered = 0;
  int _htmlCoreRecovered = 0;
  int _calendarYearRepairCalls = 0;
  int _periodMetadataRepaired = 0;
  static const calendarYearRepairReserve = 40;

  final DateTime Function() _clock;
  late final _meter = ApiCallMeter(ApiProvider.dart, () => dart.calls);

  /// 이번 작업에서 쓸 수 있는 호출 수.
  late int _allowance;
  late int _usedAtStart;
  late int _sharedAllowance;
  bool _budgetExhausted = false;

  bool get _hasAllowance {
    if (dart.calls >= _allowance) _budgetExhausted = true;
    return !_budgetExhausted;
  }

  /// 최근 공시 피드는 재무 예산을 다 쓴 날에도 돌아야 한다 — 하루 몇 번뿐인 호출이고,
  /// 이걸 거르면 그날 공시가 통째로 빈다. 그래서 재무 예산이 아니라 DART 하루
  /// 한도(20,000)에서 이만큼을 따로 떼어 쓴다.
  static const feedReserve = 60;

  /// 이번 작업에서 피드가 쓸 수 있는 호출 수.
  late int _feedAllowance;

  bool get _hasFeedAllowance => dart.calls < _feedAllowance;

  Future<void> run() async {
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) {
      dart.close();
      return;
    }
    var job = claimed;
    var discovered = 0, stored = 0, failed = 0, processed = 0;
    try {
      final now = _clock().toUtc();
      final usedToday = await ApiCallBudget.usedToday(
        session,
        ApiProvider.dart,
        now: now,
      );
      _usedAtStart = usedToday;
      _activeBudget = dailyBudget;
      _allowance = dailyBudget - usedToday;
      _sharedAllowance = max(0, ApiCallBudget.dartDailyLimit - usedToday);
      _feedAllowance = min(
        feedReserve,
        max(0, ApiCallBudget.dartDailyLimit - usedToday),
      );

      final companies = {
        for (final c in await Company.db.find(
          session,
          where: (t) {
            final listed =
                t.market.inSet(_listedMarkets) | t.stockCode.notEquals(null);
            final code = corpCode;
            return code == null ? listed : listed & t.corpCode.equals(code);
          },
        ))
          c.corpCode: c,
      };
      final only = corpCode == null ? null : companies[corpCode];
      if (corpCode != null && only == null) {
        throw StateError('상장사 원장에 없는 기업: $corpCode');
      }

      final feedRows = await _scanFeed(companies, now);
      discovered = await _scan(companies, now, job);
      if (await IngestJobs.isCancelled(session, jobId)) {
        job = job.copyWith(status: IngestStatus.cancelled);
      }

      // Reclassify only previously unclassified business reports. This does
      // not rewrite existing FinancialReport/FinancialFact numbers or sources.
      if (job.status != IngestStatus.cancelled) {
        for (final f in await DartFiling.db.find(
          session,
          where: (t) =>
              t.companyId.inSet({for (final c in companies.values) c.id!}) &
              (t.reportCode.equals(null) |
                  t.bsnsYear.equals(null) |
                  t.consolidatedStatus.equals(FilingFetchStatus.unsupported) |
                  t.separateStatus.equals(FilingFetchStatus.unsupported)),
        )) {
          final name = DartReportName.parse(f.reportName);
          if (name?.kind != DartReportKind.annual) continue;
          final classification = name!.resolve(null)!;
          await DartFiling.db.updateRow(
            session,
            f.copyWith(
              bsnsYear: classification.bsnsYear,
              reportCode: FinancialReportCode.annual,
              lastError: "$_annualRecoveryMarker: ${f.reportName}",
              consolidatedStatus:
                  (f.reportCode == null || f.bsnsYear == null) ||
                      f.consolidatedStatus == FilingFetchStatus.unsupported
                  ? FilingFetchStatus.pending
                  : f.consolidatedStatus,
              separateStatus:
                  (f.reportCode == null || f.bsnsYear == null) ||
                      f.separateStatus == FilingFetchStatus.unsupported
                  ? FilingFetchStatus.pending
                  : f.separateStatus,
            ),
          );
        }
      }
      final scopeIds = financialScopeIds(
        await DartFiling.db.find(
          session,
          where: (t) =>
              t.companyId.inSet({for (final c in companies.values) c.id!}) &
              t.reportCode.notEquals(null),
        ),
      );
      // A prior interim query used the canonical fiscal-end year as the API
      // year. Retry that precise latest-scope noData once with the report-end
      // calendar year, preserving all historical ledgers and attempt counts.
      if (job.status != IngestStatus.cancelled) {
        for (final f in await DartFiling.db.find(
          session,
          where: (t) => t.id.inSet(scopeIds),
        )) {
          final year = DartReportName.parse(f.reportName)?.periodYear;
          if (f.reportCode == FinancialReportCode.annual ||
              year == null ||
              year == f.bsnsYear ||
              f.consolidatedStatus != FilingFetchStatus.noData ||
              f.separateStatus != FilingFetchStatus.noData ||
              f.attempts >= maxAttempts ||
              (f.lastError?.contains(_apiYearRetryMarker) ?? false)) {
            continue;
          }
          await DartFiling.db.updateRow(
            session,
            f.copyWith(
              consolidatedStatus: FilingFetchStatus.pending,
              separateStatus: FilingFetchStatus.pending,
              lastError:
                  '$_apiYearRetryMarker: request $year, canonical ${f.bsnsYear}',
            ),
          );
        }
      }
      final targets = job.status == IngestStatus.cancelled
          ? const <DartFiling>[]
          : await DartFiling.db.find(
              session,
              where: (t) =>
                  t.id.inSet(scopeIds) &
                  t.reportCode.notEquals(null) &
                  (only == null
                      ? t.companyId.notEquals(null)
                      : t.companyId.equals(only.id!)) &
                  (t.attempts.between(0, maxAttempts - 1) |
                      (t.reportCode.equals(FinancialReportCode.annual) &
                          (t.lastError.like('%DartApiException(mismatch)%') |
                              t.lastError.like(
                                '%DartApiException(receiptPeriodMismatch)%',
                              ) |
                              t.lastError.like(
                                '%API period mismatch; exact-receipt XBRL fallback failed%',
                              )))) &
                  (_needsFetch(t.consolidatedStatus) |
                      _needsFetch(t.separateStatus)),
              orderByList: (t) => [t.receivedDate.desc(), t.rceptNo.desc()],
            );
      final byId = {for (final c in companies.values) c.id!: c};
      job = await IngestJobs.save(session, job.copyWith(total: targets.length));

      for (final filing in targets) {
        if (processed % _progressEvery == 0 &&
            await IngestJobs.isCancelled(session, jobId)) {
          job = job.copyWith(status: IngestStatus.cancelled);
          break;
        }
        _activeBudget = !_explicitBudget && _isAnnualRecovery(filing)
            ? annualRecoveryBudget
            : dailyBudget;
        await _meter.flush(session);
        final currentUsed = await ApiCallBudget.usedToday(
          session,
          ApiProvider.dart,
          now: now,
        );
        _allowance =
            dart.calls +
            max(
              0,
              min(_activeBudget, ApiCallBudget.dartDailyLimit) -
                  max(currentUsed, _usedAtStart + dart.calls),
            );
        _budgetExhausted = _apiQuotaBlocked || dart.calls >= _allowance;
        if (!_hasAllowance &&
            !_priorAnnualMismatch(filing) &&
            !_isCalendarYearRepair(filing)) {
          continue;
        }
        final company = byId[filing.companyId];
        if (company == null) {
          processed++;
          continue;
        }
        final result = await _fetchFiling(filing, company);
        stored += result.stored;
        if (result.failed) failed++;
        processed++;
        // Already verified mismatches can continue with keyless originals.
        // Ordinary API targets remain blocked by _hasAllowance above.
        if (processed % _progressEvery == 0) {
          await _meter.flush(session);
          // 주요정보 수집이 함께 돌면 시작할 때 계산한 몫만으로는 하루 한도를 넘길 수 있다.
          if (await ApiCallBudget.reached(
            session,
            ApiProvider.dart,
            _activeBudget,
          )) {
            _budgetExhausted = true;
          }
          job = await IngestJobs.save(
            session,
            job.copyWith(
              processed: processed,
              updated: stored,
              failed: failed,
              apiCalls: dart.calls,
            ),
          );
        }
      }

      final remaining = await DartFiling.db.count(
        session,
        where: (t) =>
            t.id.inSet(scopeIds) &
            t.reportCode.notEquals(null) &
            (only == null
                ? t.companyId.notEquals(null)
                : t.companyId.equals(only.id!)) &
            (_needsFetch(t.consolidatedStatus) | _needsFetch(t.separateStatus)),
      );
      final exhausted = await DartFiling.db.count(
        session,
        where: (t) =>
            t.id.inSet(scopeIds) &
            t.attempts.between(maxAttempts, 2147483647) &
            (_needsFetch(t.consolidatedStatus) | _needsFetch(t.separateStatus)),
      );
      final cancelled = job.status == IngestStatus.cancelled;
      var message = '새 공시 $discovered건, 저장한 재무제표 $stored벌, 남은 공시 $remaining건';
      if (exhausted > 0) message += ', 재시도 한도에 도달한 미완료 $exhausted건';
      if (_xbrlCoreRecovered > 0) {
        message += ', 원문 XBRL 핵심계정 복구 $_xbrlCoreRecovered벌(전체 재무제표 아님)';
      }
      if (_htmlCoreRecovered > 0) {
        message +=
            ', 원문 HTML 부분 핵심계정 복구 $_htmlCoreRecovered벌(실제 인쇄 계정명, XBRL 계정 ID 미제공·전체 재무제표 아님)';
      }
      if (_calendarYearRepairCalls > 0) {
        message += ', 보고기간 조회연도 보완 $_calendarYearRepairCalls호출(최대40, 공통한도 내)';
      }
      if (_periodMetadataRepaired > 0) {
        message += ', 동일접수·원천값 검증 후 회계연도 메타데이터 복구 $_periodMetadataRepaired벌';
      }
      if (feedRows > 0) message += ', 공시 피드 $feedRows건';
      if (only != null) message = '${only.name}: $message';
      if (_budgetExhausted && !cancelled && only == null) {
        final at = ApiCallBudget.nextKstMidnight(
          now,
        ).add(const Duration(minutes: 10));
        await scheduleResume?.call(at);
        message +=
            ' · 일일 호출 예산($_activeBudget건) 소진, '
            '${scheduleResume != null ? '다음 날 이어서 받음' : '다음 실행에서 이어서 받음'}';
      }
      await IngestJobs.save(
        session,
        job.copyWith(
          status: cancelled
              ? IngestStatus.cancelled
              : failed > 0 || exhausted > 0
              ? IngestStatus.failed
              : IngestStatus.succeeded,
          processed: processed,
          updated: stored,
          failed: failed,
          apiCalls: dart.calls,
          finishedAt: DateTime.now().toUtc(),
          message: message,
        ),
      );
    } catch (e, st) {
      session.log(
        '재무 수집 실패',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      final retry =
          e is DartApiException &&
          (e.status == 'http' || e.status == '800') &&
          corpCode == null &&
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
          apiCalls: dart.calls,
          finishedAt: DateTime.now().toUtc(),
          message: '$e${retry ? ' · 15분 후 자동 재시도 예약' : ''}',
        ),
      );
    } finally {
      await _meter.flush(session);
      dart.close();
    }
  }

  static Expression _needsFetch(ColumnEnum<FilingFetchStatus> status) =>
      status.equals(FilingFetchStatus.pending) |
      status.equals(FilingFetchStatus.failed);

  /// 최근 며칠의 모든 공시를 목록만 받아 둔다 (계약·증자·주요사항 등).
  ///
  /// 기업 화면의 "최근 공시"에 쓴다. 정기보고서만 받는 [_scan]과 달리 종류를
  /// 가리지 않으며, 하루 열 번쯤이면 끝난다.
  static const feedDays = 3;

  Future<int> _scanFeed(Map<String, Company> companies, DateTime now) async {
    if (corpCode != null) return 0;
    final today = DateTime.utc(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: feedDays));
    final seen = {
      for (final d in await DartDisclosure.db.find(
        session,
        where: (t) => t.receivedDate >= from,
      ))
        d.rceptNo,
    };
    var stored = 0;
    for (var page = 1; ; page++) {
      if (!_hasFeedAllowance) break;
      final result = await _callDart(
        () => dart.fetchFilings(
          from: from,
          to: today,
          page: page,
          typeCode: null,
          lastReportOnly: false,
        ),
      );
      final rows = [
        for (final item in result.items)
          // 상장사 것만 남긴다 — 화면은 기업 페이지에서만 이 목록을 본다.
          if (companies.containsKey(item.corpCode) && seen.add(item.rceptNo))
            DartDisclosure(
              rceptNo: item.rceptNo,
              corpCode: item.corpCode,
              companyId: companies[item.corpCode]!.id,
              corpName: item.corpName,
              reportName: item.reportName,
              receivedDate: item.rceptDate ?? today,
              filerName: item.filerName,
              discoveredAt: now,
            ),
      ];
      if (rows.isNotEmpty) {
        await DartDisclosure.db.insert(session, rows);
        stored += rows.length;
      }
      if (page >= result.totalPages) break;
    }
    return stored;
  }

  /// 공시 목록을 훑어 새 정기보고서를 장부에 넣는다. 넣은 건수를 돌려준다.
  Future<int> _scan(
    Map<String, Company> companies,
    DateTime now,
    IngestJob job,
  ) async {
    final today = DateTime.utc(now.year, now.month, now.day);
    const years = historyYears;
    final earliest = DateTime.utc(firstAnnualYear(now, years), 1, 1);
    final code = corpCode;
    if (code != null) {
      return _scanCompany(code, companies, now, earliest, today, years);
    }

    final cursor = await DartFilingScan.db.findFirstRow(session);
    // 수집 범위가 넓어져 커서가 덮지 않는 과거가 생기면 처음부터 다시 훑는다.
    final covers =
        cursor?.scannedFrom != null && !earliest.isBefore(cursor!.scannedFrom!);
    var from = covers ? cursor.scannedThrough.subtract(scanOverlap) : earliest;
    if (from.isBefore(earliest)) from = earliest;

    var inserted = 0;
    while (!from.isAfter(today)) {
      var to = from.add(scanWindow);
      if (to.isAfter(today)) to = today;
      var page = 1;
      while (true) {
        if (!_hasAllowance) return inserted;
        final result = await _callDart(
          () => dart.fetchFilings(from: from, to: to, page: page),
        );
        inserted += await _record(result.items, companies, now, years);
        if (page % 5 == 1) {
          await _meter.flush(session);
          job = await IngestJobs.save(
            session,
            job.copyWith(
              apiCalls: dart.calls,
              message:
                  '공시 목록 확인 중: ${DartValues.formatYmd(from)}~${DartValues.formatYmd(to)} '
                  '$page/${result.totalPages}쪽, 새 정기보고서 $inserted건',
            ),
          );
          if (job.status == IngestStatus.cancelled) return inserted;
        }
        if (page >= result.totalPages) break;
        page++;
      }
      await _saveCursor(covers ? cursor.scannedFrom! : earliest, to);
      from = to.add(const Duration(days: 1));
    }
    return inserted;
  }

  Future<void> _saveCursor(
    DateTime scannedFrom,
    DateTime scannedThrough,
  ) async {
    final row = DartFilingScan(
      scannedFrom: scannedFrom,
      scannedThrough: scannedThrough,
      updatedAt: DateTime.now().toUtc(),
    );
    final existing = await DartFilingScan.db.findFirstRow(session);
    if (existing == null) {
      await DartFilingScan.db.insertRow(session, row);
    } else {
      await DartFilingScan.db.updateRow(session, row.copyWith(id: existing.id));
    }
  }

  /// 기업 하나의 공시 목록. 회사를 지정하면 기간 제한이 없다.
  Future<int> _scanCompany(
    String code,
    Map<String, Company> companies,
    DateTime now,
    DateTime from,
    DateTime to,
    int years,
  ) async {
    var inserted = 0;
    for (var page = 1; ; page++) {
      if (!_hasAllowance) return inserted;
      final result = await _callDart(
        () => dart.fetchFilings(from: from, to: to, page: page, corpCode: code),
      );
      inserted += await _record(result.items, companies, now, years);
      if (page >= result.totalPages) return inserted;
    }
  }

  Future<int> _record(
    List<DartFilingItem> items,
    Map<String, Company> companies,
    DateTime now,
    int years,
  ) async {
    if (items.isEmpty) return 0;
    final known = {
      for (final f in await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.inSet({for (final i in items) i.rceptNo}),
      ))
        f.rceptNo,
    };
    final rows = <DartFiling>[];
    for (final item in items) {
      final company = companies[item.corpCode];
      if (company == null || !known.add(item.rceptNo)) continue;
      final name = DartReportName.parse(item.reportName);
      if (name == null) continue;
      final resolved = name.resolve(company.fiscalMonth);
      final code = FinancialCodes.reportCodeFromDart(resolved?.reportCode);
      if (resolved != null) {
        final firstYear = code == FinancialReportCode.annual
            ? firstAnnualYear(now, years)
            : firstInterimYear(now, years);
        if (resolved.bsnsYear < firstYear) continue;
      } else if (name.periodYear < firstInterimYear(now, years)) {
        continue;
      }
      final status = code == null
          ? FilingFetchStatus.unsupported
          : FilingFetchStatus.pending;
      rows.add(
        DartFiling(
          rceptNo: item.rceptNo,
          corpCode: item.corpCode,
          companyId: company.id,
          reportName: item.reportName,
          receivedDate: item.rceptDate,
          bsnsYear: resolved?.bsnsYear,
          reportCode: code,
          consolidatedStatus: status,
          separateStatus: status,
          discoveredAt: now,
        ),
      );
    }
    if (rows.isEmpty) return 0;
    try {
      await DartFiling.db.insert(session, rows);
      return rows.length;
    } on DatabaseUniqueViolationException {
      // 다른 수집이 같은 공시를 먼저 넣었다. 하나씩 넣으며 이미 있는 것은 건너뛴다.
      var inserted = 0;
      for (final row in rows) {
        try {
          await DartFiling.db.insertRow(session, row);
          inserted++;
        } on DatabaseUniqueViolationException {
          continue;
        }
      }
      return inserted;
    }
  }

  static const _apiYearRetryMarker = 'report-end-calendar-api-year-retried';

  static bool _isCalendarYearRepair(DartFiling filing) =>
      filing.reportCode != FinancialReportCode.annual &&
      DartReportName.parse(filing.reportName)?.periodYear != filing.bsnsYear &&
      (filing.lastError?.contains(_apiYearRetryMarker) ?? false);

  Future<bool> _canRepairCalendarYear() async {
    if (_calendarYearRepairCalls >= calendarYearRepairReserve ||
        dart.calls >= _sharedAllowance) {
      return false;
    }
    // Include feed and other workers' persisted calls before every division.
    await _meter.flush(session);
    return await ApiCallBudget.usedToday(
          session,
          ApiProvider.dart,
          now: _clock().toUtc(),
        ) <
        ApiCallBudget.dartDailyLimit;
  }

  /// Storage uses the fiscal-end year; DART queries use the actual report-end
  /// calendar year. In December these coincide.
  static int apiRequestYear(DartFiling filing) {
    final year = DartReportName.parse(filing.reportName)?.periodYear;
    if (year == null) throw DartApiException('period', '공시 보고기간을 확인할 수 없음');
    return year;
  }

  static bool _sameActualPeriod(String first, String second) {
    final a = DartReportName.parse(first), b = DartReportName.parse(second);
    return a != null &&
        b != null &&
        a.kind == b.kind &&
        a.periodYear == b.periodYear &&
        a.periodMonth == b.periodMonth;
  }

  static bool _priorAnnualMismatch(DartFiling filing) =>
      filing.reportCode == FinancialReportCode.annual &&
      ((filing.lastError?.contains('DartApiException(mismatch)') ?? false) ||
          (filing.lastError?.contains(
                'DartApiException(receiptPeriodMismatch)',
              ) ??
              false) ||
          (filing.lastError?.contains(
                'API period mismatch; exact-receipt XBRL fallback failed',
              ) ??
              false));

  static bool _isAnnualRecovery(DartFiling filing) =>
      filing.reportCode == FinancialReportCode.annual &&
      (filing.lastError?.contains(_annualRecoveryMarker) ?? false);

  /// 공시 하나의 연결·별도 재무제표를 받는다. 새로 저장한 벌 수와 실패 여부.
  Future<({int stored, bool failed})> _fetchFiling(
    DartFiling filing,
    Company company,
  ) async {
    var next = filing;
    ({List<int> zip, Uri source})? originalAnnual;
    var stored = 0;
    var failed = false;
    for (final div in FsDiv.values) {
      final status = div == FsDiv.consolidated
          ? next.consolidatedStatus
          : next.separateStatus;
      if (status != FilingFetchStatus.pending &&
          status != FilingFetchStatus.failed) {
        continue;
      }
      if (!_explicitBudget && _isAnnualRecovery(filing)) {
        await _meter.flush(session);
        final used = await ApiCallBudget.usedToday(
          session,
          ApiProvider.dart,
          now: _clock().toUtc(),
        );
        _allowance =
            dart.calls +
            max(0, annualRecoveryBudget - max(used, _usedAtStart + dart.calls));
        _budgetExhausted = _apiQuotaBlocked || dart.calls >= _allowance;
      }
      final repairCall = !_hasAllowance && _isCalendarYearRepair(filing);
      if (!_hasAllowance && !_priorAnnualMismatch(filing) && !repairCall) break;
      if (repairCall && !await _canRepairCalendarYear()) break;

      FilingFetchStatus result;
      String? error;
      try {
        if (_priorAnnualMismatch(filing)) {
          // The ledger already records a verified API mismatch. Public original
          // recovery needs no new key-bearing API call or allowance.
          throw DartApiException(
            'mismatch',
            'previous annual API period mismatch',
          );
        }
        if (repairCall) _calendarYearRepairCalls++;
        final rows = await _callDart(
          () => dart.fetchFinancialStatements(
            corpCode: company.corpCode,
            bsnsYear: apiRequestYear(filing),
            reportCode: FinancialCodes.reportCodeToDart(filing.reportCode!),
            fsDiv: FinancialCodes.fsDivToDart(div),
          ),
        );
        if (repairCall) await _meter.flush(session);
        final saved = await _store(filing, company, div, rows);
        result = saved.status;
        if (saved.inserted) stored++;
      } on DartApiException catch (e) {
        if (e.status == _limitExceeded) {
          _budgetExhausted = true;
          _apiQuotaBlocked = true;
          break;
        }
        if (e.isFatal || e.status == 'http') rethrow;
        if ((e.status == 'mismatch' || e.status == 'receiptPeriodMismatch') &&
            filing.reportCode == FinancialReportCode.annual) {
          ({
            List<Map<String, dynamic>> rows,
            Uri source,
            String digest,
            DartFiling sourceFiling,
            Uri? correctionSource,
            String format,
            Uri? coverSource,
          })?
          fallback;
          try {
            final period = RegExp(r'\((\d{4})\.(\d{2})\)')
                .firstMatch(filing.reportName);
            if (period == null) {
              throw const FormatException('Annual period missing');
            }
            final end = DateTime.utc(
              int.parse(period.group(1)!),
              int.parse(period.group(2)!) + 1,
              0,
            );
            var sourceFiling = filing;
            Uri? correctionSource;
            ({List<int> zip, Uri source}) original;
            try {
              original = originalAnnual ??= await dart.fetchPublicAnnualXbrl(
                filing.rceptNo,
              );
            } on FormatException {
              if (!filing.reportName.contains('첨부정정')) rethrow;
              final linked = await dart.fetchLinkedAnnualXbrl(
                filing.rceptNo,
                reportName: filing.reportName,
                corpCode: company.corpCode,
                bsnsYear: filing.bsnsYear!,
                periodEnd: end,
                consolidated: div == FsDiv.consolidated,
              );
              if (linked.correctionReceipt != filing.rceptNo ||
                  linked.receipt.compareTo(filing.rceptNo) >= 0) {
                throw const FormatException(
                  'Attachment receipt identity mismatch',
                );
              }
              PublicFinancialXbrl.parse(
                linked.zip,
                receipt: linked.receipt,
                corpCode: company.corpCode,
                bsnsYear: filing.bsnsYear!,
                periodEnd: end,
                consolidated: div == FsDiv.consolidated,
              );
              sourceFiling = await _verifiedAttachmentSource(
                filing,
                company,
                linked.receipt,
              );
              correctionSource = linked.correctionSource;
              original = (zip: linked.zip, source: linked.source);
            }
            fallback = (
              rows: PublicFinancialXbrl.parse(
                original.zip,
                receipt: sourceFiling.rceptNo,
                corpCode: company.corpCode,
                bsnsYear: filing.bsnsYear!,
                periodEnd: end,
                consolidated: div == FsDiv.consolidated,
              ),
              source: original.source,
              digest: PublicFinancialXbrl.digest(original.zip),
              sourceFiling: sourceFiling,
              correctionSource: correctionSource,
              format: 'xbrl',
              coverSource: null,
            );
          } on FormatException {
            if (filing.reportName.contains('첨부정정')) {
              try {
                final period = DartReportName.parse(filing.reportName)!;
                final end = DateTime.utc(
                  period.periodYear,
                  period.periodMonth + 1,
                  0,
                );
                final html = await dart.fetchAttachmentAnnualHtml(
                  filing.rceptNo,
                  reportName: filing.reportName,
                  corpCode: company.corpCode,
                  companyName: company.name,
                  bsnsYear: filing.bsnsYear!,
                  periodEnd: end,
                  consolidated: div == FsDiv.consolidated,
                );
                if (html.correctionReceipt != filing.rceptNo ||
                    html.sourceReceipt.compareTo(filing.rceptNo) >= 0 ||
                    html.periodEnd != end) {
                  throw const FormatException(
                    'HTML attachment source identity mismatch',
                  );
                }
                final htmlCompanyName = company.name.replaceAll(
                  RegExp(r'\(주\)|㈜|주식회사|\s+'),
                  '',
                );
                if (htmlCompanyName.isEmpty) {
                  throw const FormatException('Empty HTML company identity');
                }
                final rows = PublicFinancialHtml.parse(
                  coverHtml: html.coverHtml,
                  statementHtml: html.statementHtml,
                  coverSource: html.coverSource,
                  statementSource: html.statementSource,
                  receipt: html.sourceReceipt,
                  corpCode: company.corpCode,
                  companyName: htmlCompanyName,
                  periodStart: html.periodStart,
                  periodEnd: end,
                  consolidated: div == FsDiv.consolidated,
                );
                final sourceFiling = await _verifiedAttachmentSource(
                  filing,
                  company,
                  html.sourceReceipt,
                );
                fallback = (
                  rows: rows,
                  source: html.statementSource,
                  digest: html.sourceDigest,
                  sourceFiling: sourceFiling,
                  correctionSource: html.correctionSource,
                  format: 'html',
                  coverSource: html.coverSource,
                );
              } catch (_) {
                error =
                    '${FinancialCodes.fsDivName(div)}: API period mismatch; exact-receipt XBRL fallback failed; verified HTML fallback failed';
              }
            } else {
              error =
                  '${FinancialCodes.fsDivName(div)}: API period mismatch; exact-receipt XBRL fallback failed';
            }
          } catch (_) {
            error =
                '${FinancialCodes.fsDivName(div)}: API period mismatch; exact-receipt XBRL fallback failed';
          }
          if (fallback != null) {
            final saved = await _store(
              fallback.sourceFiling,
              company,
              div,
              fallback.rows,
              originalSource: fallback.source,
              originalDigest: fallback.digest,
              originalFormat: fallback.format,
            );
            result = saved.status;
            if (saved.status == FilingFetchStatus.stored &&
                fallback.correctionSource != null) {
              final marker =
                  'verified-attachment-source:${filing.rceptNo}->${fallback.sourceFiling.rceptNo}';
              next = next.copyWith(lastError: marker);
              await _recordAttachmentRecovery(
                filing,
                fallback.sourceFiling,
                div,
                fallback.correctionSource!,
                fallback.digest,
                originalFormat: fallback.format,
                originalSource: fallback.source,
                coverSource: fallback.coverSource,
              );
            }
            if (saved.inserted) {
              stored++;
              if (fallback.format == 'html') {
                _htmlCoreRecovered++;
              } else {
                _xbrlCoreRecovered++;
              }
            }
          } else {
            result = FilingFetchStatus.failed;
            failed = true;
          }
        } else {
          result = FilingFetchStatus.failed;
          error = '${FinancialCodes.fsDivName(div)}: $e';
          failed = true;
          session.log(
            '재무제표 실패 ${company.corpCode} ${filing.rceptNo}: $e',
            level: LogLevel.warning,
          );
        }
      }
      next = next.copyWith(
        consolidatedStatus: div == FsDiv.consolidated ? result : null,
        separateStatus: div == FsDiv.separate ? result : null,
      );
      // 생성된 copyWith는 nullable 필드에 null을 넘기면 지우므로, 실패일 때만 넘긴다.
      if (error != null) {
        next = next.copyWith(
          lastError: _isAnnualRecovery(filing)
              ? "$_annualRecoveryMarker; $error"
              : error,
        );
      }
    }
    // 실패 횟수는 연결·별도를 합쳐 한 번 실행에 공시당 1회만 센다.
    if (failed) next = next.copyWith(attempts: filing.attempts + 1);
    if (!identical(next, filing)) {
      await DartFiling.db.updateRow(
        session,
        next.copyWith(checkedAt: DateTime.now().toUtc()),
      );
    }
    return (stored: stored, failed: failed);
  }

  Future<DartFiling> _verifiedAttachmentSource(
    DartFiling target,
    Company company,
    String receipt,
  ) async {
    final existing = await DartFiling.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(receipt),
    );
    if (existing != null) {
      if (existing.companyId != company.id ||
          existing.corpCode != company.corpCode ||
          existing.bsnsYear != target.bsnsYear ||
          existing.reportCode != target.reportCode ||
          !_sameActualPeriod(existing.reportName, target.reportName)) {
        throw const FormatException('Linked source ledger period mismatch');
      }
      return existing;
    }
    final period = DartReportName.parse(target.reportName)!;
    return DartFiling.db.insertRow(
      session,
      DartFiling(
        rceptNo: receipt,
        corpCode: company.corpCode,
        companyId: company.id,
        bsnsYear: target.bsnsYear,
        reportCode: target.reportCode,
        reportName:
            '사업보고서 (${period.periodYear}.${period.periodMonth.toString().padLeft(2, '0')})',
        discoveredAt: _clock().toUtc(),
        consolidatedStatus: FilingFetchStatus.pending,
        separateStatus: FilingFetchStatus.pending,
        lastError: 'official-attachment-source:${target.rceptNo}',
      ),
    );
  }

  Future<void> _recordAttachmentRecovery(
    DartFiling target,
    DartFiling original,
    FsDiv div,
    Uri correctionSource,
    String digest, {
    String originalFormat = 'xbrl',
    Uri? originalSource,
    Uri? coverSource,
  }) async {
    final reference =
        'financial-attachment-recovery:${target.rceptNo}:${div.name}';
    if (await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(reference),
        ) ==
        null) {
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: reference,
          url: correctionSource.toString(),
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'verified-attachment-source',
            'targetReceipt': target.rceptNo,
            'sourceReceipt': original.rceptNo,
            'corpCode': target.corpCode,
            'reportName': original.reportName,
            'fsDiv': div.name,
            'originalSha256': digest,
            'originalFormat': originalFormat,
            if (originalSource != null)
              'originalSource': originalSource.toString(),
            if (coverSource != null) 'coverSource': coverSource.toString(),
          }),
        ),
      );
    }
    await DartFiling.db.updateRow(
      session,
      original.copyWith(
        consolidatedStatus: div == FsDiv.consolidated
            ? FilingFetchStatus.stored
            : original.consolidatedStatus,
        separateStatus: div == FsDiv.separate
            ? FilingFetchStatus.stored
            : original.separateStatus,
      ),
    );
  }

  /// DART 요청 제한 초과.
  static const _limitExceeded = '020';

  /// 한 번에 넣는 사실 행 수 (PostgreSQL 파라미터 수 제한 대비).
  static const _insertChunk = 1000;

  /// 응답을 저장한다. 같은 접수번호·구분을 이미 저장했으면 넣지 않는다.
  Future<({FilingFetchStatus status, bool inserted})> _store(
    DartFiling filing,
    Company company,
    FsDiv div,
    List<Map<String, dynamic>>? rows, {
    Uri? originalSource,
    String? originalDigest,
    String originalFormat = 'xbrl',
  }) async {
    if (rows == null || rows.isEmpty) {
      return (status: FilingFetchStatus.noData, inserted: false);
    }
    final rceptNos = {
      for (final r in rows) ?DartValues.text(r['rcept_no']),
    };
    if (rceptNos.length != 1) {
      throw DartApiException('parse', '응답 접수번호가 하나가 아님: $rceptNos');
    }
    final rceptNo = rceptNos.single;
    // 사업연도·보고서 코드 판정이 어긋나면 다른 기간의 재무가 온다. 응답의 회사·연도·코드로 확인한다.
    final expected = (
      company.corpCode,
      '${apiRequestYear(filing)}',
      FinancialCodes.reportCodeToDart(filing.reportCode!),
    );
    for (final r in rows) {
      final actual = (
        DartValues.text(r['corp_code']) ?? expected.$1,
        DartValues.text(r['bsns_year']) ?? expected.$2,
        DartValues.text(r['reprt_code']) ?? expected.$3,
      );
      if (actual != expected) {
        throw DartApiException('mismatch', '요청 $expected와 응답 $actual이 다름');
      }
    }
    // The API can return an older receipt for an unchanged attachment. Never
    // infer its period from query parameters: require an actual same-period
    // filing already in the ledger (or the exact requested receipt).
    final actualFiling = rceptNo == filing.rceptNo
        ? filing
        : await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(rceptNo),
          );
    if (actualFiling == null ||
        actualFiling.companyId != company.id ||
        actualFiling.corpCode != company.corpCode ||
        actualFiling.bsnsYear != filing.bsnsYear ||
        actualFiling.reportCode != filing.reportCode ||
        !_sameActualPeriod(actualFiling.reportName, filing.reportName)) {
      throw DartApiException(
        'receiptPeriodMismatch',
        '응답 접수번호 $rceptNo의 동일 기업·보고기간을 확인할 수 없음',
      );
    }
    final existing = await FinancialReport.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(rceptNo) & t.fsDiv.equals(div),
    );
    if (existing != null) {
      if (existing.companyId != company.id ||
          existing.bsnsYear != filing.bsnsYear ||
          existing.reportCode != filing.reportCode ||
          existing.fsDiv != div ||
          !_sameActualPeriod(existing.reportName, actualFiling.reportName)) {
        if (rceptNo == filing.rceptNo &&
            await FinancialPeriodRepair.repair(
              session,
              existing: existing,
              filing: filing,
              company: company,
              div: div,
              freshRows: rows,
            )) {
          _periodMetadataRepaired++;
          return (status: FilingFetchStatus.stored, inserted: false);
        }
        throw DartApiException(
          'storedPeriodMismatch',
          '기존 재무보고서 $rceptNo의 저장 기간이 공시 원장과 다름; 별도 출처 검증·복구 필요',
        );
      }
      return (status: FilingFetchStatus.stored, inserted: false);
    }

    // 첨부추가 등 재무제표가 바뀌지 않은 정정이면 응답은 이전 접수번호를 준다.
    // 목록은 최종 보고서만 주므로 그 이름에서 [기재정정] 같은 표시를 떼어 쓴다.
    final reportName = rceptNo == filing.rceptNo
        ? filing.reportName
        : (await DartFiling.db.findFirstRow(
                session,
                where: (t) => t.rceptNo.equals(rceptNo),
              ))?.reportName ??
              filing.reportName.replaceFirst(RegExp(r'^(\[[^\]]+\]\s*)+'), '');
    try {
      await _insert(
        filing,
        company,
        div,
        rows,
        rceptNo,
        reportName,
        originalSource: originalSource,
        originalDigest: originalDigest,
        originalFormat: originalFormat,
      );
    } on DatabaseUniqueViolationException {
      // 전체 수집과 기업 하나 수집이 같은 보고서를 동시에 저장하면 늦은 쪽이 여기로 온다.
      return (status: FilingFetchStatus.stored, inserted: false);
    }
    return (status: FilingFetchStatus.stored, inserted: true);
  }

  /// [_insert]가 회사·사업연도·보고서 코드·구분 단위로 잡는 PostgreSQL 트랜잭션
  /// advisory lock의 첫 번째 키. [IngestJobs]의 잠금 등 다른 advisory lock과
  /// 겹치지 않게 이 값으로 구분한다. 두 번째 키는 그 넷을 합친 문자열의 hashtext.
  static const _supersedeLockNamespace = 461101;

  Future<void> _insert(
    DartFiling filing,
    Company company,
    FsDiv div,
    List<Map<String, dynamic>> rows,
    String rceptNo,
    String reportName, {
    Uri? originalSource,
    String? originalDigest,
    String originalFormat = 'xbrl',
  }) async {
    final now = DateTime.now().toUtc();
    final bsnsYear = filing.bsnsYear!;
    final reportCode = filing.reportCode!;
    final partialCore =
        originalSource != null &&
        rows.any((r) => r['xbrl_partial_core'] == true);
    final partialNote = partialCore
        ? ' · 부분 핵심계정 · 당기순손익 미확보 · '
              '${rows.firstWhere((r) => r['xbrl_partial_core'] == true)['xbrl_collection_note']}'
        : '';
    await session.db.transaction((tx) async {
      // 같은 (회사, 사업연도, 보고서 코드, 구분)을 동시에 처리하는 다른 실행(전체
      // 수집과 기업 하나 수집 등)과 이 트랜잭션의 대체 판정을 직렬화한다. 잠그지
      // 않으면 두 실행이 서로의 커밋을 보지 못한 채 각자 "활성" 보고서를 하나씩
      // 남겨, 같은 기간에 활성 보고서가 둘 이상 생긴다.
      await session.db.unsafeExecute(
        'SELECT pg_advisory_xact_lock($_supersedeLockNamespace, hashtext(@key))',
        parameters: QueryParameters.named({
          'key': '${company.id}:$bsnsYear:${reportCode.name}:${div.name}',
        }),
        transaction: tx,
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: originalSource != null
              ? '${originalFormat == 'html' ? 'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공)' : 'DART 원문 XBRL 핵심계정'} · $reportName · ${FinancialCodes.fsDivName(div)} · SHA256:$originalDigest$partialNote'
              : 'DART 전체 재무제표 (fnlttSinglAcntAll) · $reportName · '
                    '${FinancialCodes.fsDivName(div)}',
          reference: rceptNo,
          url: (originalSource ?? DartClient.filingViewerUrl(rceptNo))
              .toString(),
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final converted = FinancialRows.toFacts(
        rows,
        reportId: 0,
        companyId: company.id!,
        bsnsYear: bsnsYear,
        reportCode: reportCode,
        fsDiv: div,
        sourceId: source.id!,
      );
      final report = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: company.id!,
          rceptNo: rceptNo,
          fsDiv: div,
          bsnsYear: bsnsYear,
          reportCode: reportCode,
          reportName: reportName,
          // 접수번호 앞 8자리가 접수일이다.
          receivedDate: DartValues.ymd(rceptNo.substring(0, 8)),
          factCount: converted.facts.length,
          invalidAmountCount: converted.invalidAmounts,
          sourceId: source.id!,
          fetchedAt: now,
        ),
        transaction: tx,
      );
      final inserted = <FinancialFact>[];
      final facts = [
        for (final f in converted.facts) f.copyWith(reportId: report.id),
      ];
      for (var i = 0; i < facts.length; i += _insertChunk) {
        inserted.addAll(
          await FinancialFact.db.insert(
            session,
            facts.sublist(i, (i + _insertChunk).clamp(0, facts.length)),
            transaction: tx,
          ),
        );
      }

      // 같은 기간에 아직 활성(supersededById == null)인 다른 보고서. 정상적으로는
      // 많아야 하나지만, 과거에 이 판정이 대칭이 아니었던 시절 생긴 데이터라면
      // 둘 이상일 수 있다 — 그런 기존 행을 되돌아가 고치지는 않되, 이번에 새
      // 보고서가 들어온 김에 함께 바로잡는다(아래에서 활성으로 하나만 남긴다).
      final candidates = await FinancialReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.bsnsYear.equals(bsnsYear) &
            t.reportCode.equals(reportCode) &
            t.fsDiv.equals(div) &
            t.supersededById.equals(null) &
            t.id.notEquals(report.id!),
        transaction: tx,
      );

      final rivals = candidates
          .where((r) => _sameActualPeriod(r.reportName, reportName))
          .toList();

      // 접수번호가 가장 큰(가장 최근) 쪽이 최종본이다. 공시 목록은 수신일
      // 역순으로 훑으므로, 정정본(수신일이 늦음)이 원본보다 먼저 저장되어 있을
      // 수 있다 — 그러면 방금 넣은 [report]가 오히려 지는 쪽이 된다.
      var authoritative = report;
      for (final rival in rivals) {
        if (rival.rceptNo.compareTo(authoritative.rceptNo) > 0) {
          authoritative = rival;
        }
      }
      final authoritativeFacts = identical(authoritative, report)
          ? inserted
          : await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(authoritative.id!),
              transaction: tx,
            );

      for (final loser in [report, ...rivals]) {
        if (loser.id == authoritative.id) continue;
        await FinancialReport.db.updateRow(
          session,
          loser.copyWith(supersededById: authoritative.id),
          transaction: tx,
        );
        final oldFacts = loser.id == report.id
            ? inserted
            : await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(loser.id!),
                transaction: tx,
              );
        final links = FinancialRows.supersessions(oldFacts, authoritativeFacts);
        final updates = [
          for (final f in oldFacts)
            if (links[f.id] != null) f.copyWith(supersededById: links[f.id]),
        ];
        if (updates.isNotEmpty) {
          await FinancialFact.db.update(session, updates, transaction: tx);
        }
      }
    });
  }

  Future<T> _callDart<T>(Future<T> Function() call) async {
    try {
      return await call();
    } finally {
      await Future<void>.delayed(callInterval);
    }
  }
}
