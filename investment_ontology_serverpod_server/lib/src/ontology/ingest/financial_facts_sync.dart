import '../dart/known_annual_source_conflict.dart';
import '../dart/exact_statement_rows.dart';
import 'exact_statement_enrichment.dart';
import '../dart/imgt_explicit_revenue_missing.dart';
import '../dart/verified_annual_source_cache.dart';
import '../dart/linked_correction_audit_source.dart';
import '../dart/header18_linked_primary_source.dart';
import '../dart/verified_annual_source_registry.dart';
import '../dart/verified_half_basis_absence.dart';
import '../financial/financial_accounts.dart';
import '../dart/bnk_six_core_profile.dart';
import '../dart/pureun_six_core_profile.dart';

import 'dart:math';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import '../dart/dart_report_name.dart';
import '../dart/dart_values.dart';
import '../dart/public_financial_xbrl.dart';
import '../dart/public_financial_html.dart';
import '../dart/public_financial_html_fetch.dart';
import '../dart/public_financial_period_metadata.dart';
import 'api_call_budget.dart';
import 'financial_rows.dart';
import 'financial_collection_scope.dart';
import 'financial_period_repair.dart';
import 'financial_current_core_recovery.dart';
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
    VerifiedAnnualSourceCache? sourceCache,
  }) : dailyBudget = dailyBudget ?? ApiCallBudget.dartFinancialBudget,
       _explicitBudget = dailyBudget != null,
       _clock = clock ?? DateTime.now,
       _sourceCache = sourceCache ?? VerifiedAnnualSourceCache();

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
  int _periodNameMetadataRepaired = 0;
  static const calendarYearRepairReserve = 40;

  final DateTime Function() _clock;
  final VerifiedAnnualSourceCache _sourceCache;
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
      final deferredMetadataTargets = <int>{};
      var metadataAnchored = 0;
      var metadataBatchDeferred = false;
      final failedMetadataReceipts = <String>{};
      final attemptedMetadataReceipts = <String>{};
      if (job.status != IngestStatus.cancelled) {
        final candidates = await session.db.unsafeQuery(
          'WITH ${FinancialCollectionScope.cte} '
          'SELECT DISTINCT p.id, r."rceptNo" FROM financial_scope p '
          'JOIN financial_report r ON r."companyId"=p."companyId" AND r."bsnsYear"=p."bsnsYear" AND r."reportCode"=p."reportCode" '
          'JOIN source s ON s.id=r."sourceId" AND s.reference=r."rceptNo" '
          'WHERE p.id=ANY(@scope) AND p."reportCode" IN (\'annual\',\'halfYear\') '
          'AND substring(r."reportName" from \'[0-9]{4}[.][0-9]{2}\')=p.actual_period '
          'AND ((p."consolidatedStatus"=\'stored\' AND r."fsDiv"=\'consolidated\' AND NOT p.consolidated_period_stored) OR '
          '(p."separateStatus"=\'stored\' AND r."fsDiv"=\'separate\' AND NOT p.separate_period_stored)) '
          'AND EXISTS(SELECT 1 FROM financial_fact v WHERE v."reportId"=r.id AND v."sourceId"=r."sourceId" AND v.amount IS NOT NULL) '
          'AND NOT EXISTS(SELECT 1 FROM dart_filing a WHERE a."rceptNo"=r."rceptNo") ORDER BY p.id',
          parameters: QueryParameters.named({'scope': scopeIds.toList()}),
        );
        if (candidates.isNotEmpty) {
          job = await IngestJobs.save(
            session,
            job.copyWith(message: '공식 원접수 표지·보고기간 출처 확인 중(최대20건)'),
          );
        }
        var metadataRequests = 0;
        for (final candidate in candidates) {
          final targetId = candidate[0] as int;
          final metadataReceipt = candidate[1] as String;
          if (attemptedMetadataReceipts.contains(metadataReceipt)) {
            if (failedMetadataReceipts.contains(metadataReceipt)) {
              deferredMetadataTargets.add(targetId);
            }
            continue;
          }
          if (metadataRequests >= 20) {
            metadataBatchDeferred = true;
            deferredMetadataTargets.add(targetId);
            continue;
          }
          if (await IngestJobs.isCancelled(session, jobId)) {
            job = job.copyWith(status: IngestStatus.cancelled);
            break;
          }
          final target = (await DartFiling.db.findById(session, targetId))!;
          final company = companies[target.corpCode];
          final parsed = DartReportName.parse(target.reportName);
          if (company == null ||
              parsed == null ||
              !const [
                DartReportKind.annual,
                DartReportKind.halfYear,
              ].contains(parsed.kind)) {
            continue;
          }
          final end = DateTime.utc(
            parsed.periodYear,
            parsed.periodMonth + 1,
            0,
          );
          if (metadataRequests > 0 && callInterval != Duration.zero) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
          metadataRequests++;
          attemptedMetadataReceipts.add(metadataReceipt);
          PublicFinancialPeriodMetadata metadata;
          try {
            metadata = await dart.fetchAnnualPeriodMetadata(
              candidate[1] as String,
              corpCode: company.corpCode,
              companyName: company.name,
              targetReceipt: target.rceptNo,
              periodEnd: end,
              halfYear: parsed.kind == DartReportKind.halfYear,
            );
            if (metadata.receipt != candidate[1] ||
                metadata.corpCode != company.corpCode ||
                metadata.periodEnd != end) {
              throw const FormatException('Unbound recovered metadata');
            }
          } on PublicFinancialMetadataPeriodMismatch {
            // Independent actual-cover mismatch may proceed to exact target recovery.
            continue;
          } catch (e) {
            deferredMetadataTargets.add(targetId);
            failedMetadataReceipts.add(metadataReceipt);
            session.log('Source period metadata deferred: ${e.runtimeType}');
            continue;
          }
          final sourceName =
              '${parsed.kind == DartReportKind.halfYear ? '반기보고서' : '사업보고서'} (${parsed.periodYear}.${parsed.periodMonth.toString().padLeft(2, '0')})';
          await session.db.transaction((tx) async {
            await DartFiling.db.insertRow(
              session,
              DartFiling(
                rceptNo: metadata.receipt,
                corpCode: company.corpCode,
                companyId: company.id,
                reportName: sourceName,
                bsnsYear: target.bsnsYear,
                reportCode: target.reportCode,
                consolidatedStatus: FilingFetchStatus.pending,
                separateStatus: FilingFetchStatus.pending,
                lastError: 'verified-source-cover-metadata: ${target.rceptNo}',
                discoveredAt: now,
              ),
              transaction: tx,
            );
            await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference:
                    'financial-source-period-anchor:${metadata.receipt}:${target.rceptNo}',
                url: metadata.coverSource.toString(),
                retrievedAt: now,
                title: jsonEncode({
                  'kind': 'verified-source-cover-period-metadata',
                  'sourceReceipt': metadata.receipt,
                  'targetReceipt': target.rceptNo,
                  'corpCode': metadata.corpCode,
                  'shellSource': metadata.shellSource.toString(),
                  'coverSource': metadata.coverSource.toString(),
                  'sha256': metadata.digest,
                  'periodStart': metadata.periodStart.toIso8601String(),
                  'periodEnd': metadata.periodEnd.toIso8601String(),
                  'validationNote': '공식 표지 기간·회사·보고서 종류와 명시 원접수 연결만 검증; 기존 재무 숫자/출처 변경·전체 금액 재검증 없음',
                }),
              ),
              transaction: tx,
            );
          });
          metadataAnchored++;
        }
      }
      // Stored ledger status alone is insufficient when same-year annual
      // periods differ. Requeue only missing bases within this run's scope.
      if (job.status != IngestStatus.cancelled) {
        final gaps = await session.db.unsafeQuery(
          'WITH ${FinancialCollectionScope.cte} '
          'SELECT id, consolidated_period_stored, separate_period_stored FROM financial_scope '
          'WHERE id=ANY(@scope) AND "reportCode"=\'annual\' AND '
          '(("consolidatedStatus"=\'stored\' AND NOT consolidated_period_stored) OR '
          '("separateStatus"=\'stored\' AND NOT separate_period_stored))',
          parameters: QueryParameters.named({'scope': scopeIds.toList()}),
        );
        for (final gap in gaps) {
          if (deferredMetadataTargets.contains(gap[0])) continue;
          final f = (await DartFiling.db.findById(session, gap[0] as int))!;
          if (DartReportName.parse(f.reportName)?.kind !=
              DartReportKind.annual) {
            continue;
          }
          await DartFiling.db.updateRow(
            session,
            f.copyWith(
              consolidatedStatus:
                  f.consolidatedStatus == FilingFetchStatus.stored &&
                      gap[1] != true
                  ? FilingFetchStatus.pending
                  : f.consolidatedStatus,
              separateStatus:
                  f.separateStatus == FilingFetchStatus.stored && gap[2] != true
                  ? FilingFetchStatus.pending
                  : f.separateStatus,
              lastError: '$_storedPeriodGapMarker; ${f.reportName}',
            ),
          );
        }
      }
      // One source-reviewed latest half-year exception; ordinary API noData
      // ledgers remain untouched. CFS noData is explicitly preserved.
      if (job.status != IngestStatus.cancelled) {
        for (final f in await DartFiling.db.find(
          session,
          where: (t) =>
              t.id.inSet(scopeIds) &
              t.corpCode.equals('00337296') &
              t.rceptNo.equals('20260814002145'),
        )) {
          if (_isKnownHalfYearHtmlPeriod(f) &&
              f.separateStatus == FilingFetchStatus.noData &&
              f.attempts < maxAttempts &&
              !(f.lastError?.contains(_halfYearHtmlMarker) ?? false)) {
            await DartFiling.db.updateRow(
              session,
              f.copyWith(
                separateStatus: FilingFetchStatus.pending,
                lastError: _halfYearHtmlMarker,
              ),
            );
          }
        }
      }
      // One source-proved receipt: restore only its missing current core, once.
      if (job.status != IngestStatus.cancelled) {
        for (final f in await DartFiling.db.find(
          session,
          where: (t) =>
              t.id.inSet(scopeIds) &
              t.rceptNo.equals(FinancialCurrentCoreRecovery.receipt),
        )) {
          if (FinancialCurrentCoreRecovery.eligible(f) &&
              (f.lastError?.contains('storedCurrentAmountsMissing') ?? false) &&
              !(f.lastError?.contains(FinancialCurrentCoreRecovery.marker) ??
                  false)) {
            await DartFiling.db.updateRow(
              session,
              f.copyWith(
                consolidatedStatus:
                    f.consolidatedStatus == FilingFetchStatus.failed
                    ? FilingFetchStatus.pending
                    : f.consolidatedStatus,
                separateStatus: f.separateStatus == FilingFetchStatus.failed
                    ? FilingFetchStatus.pending
                    : f.separateStatus,
                lastError:
                    '${FinancialCurrentCoreRecovery.marker}; ${f.lastError}',
              ),
            );
          }
        }
      }
      if (job.status != IngestStatus.cancelled) {
        job = await IngestJobs.save(
          session,
          job.copyWith(message: 'API 자료없음 보고서 공식 원문 확인 중(최대10기간)'),
        );
      }
      if (job.status != IngestStatus.cancelled) {
        processed += await _classifyVerifiedHalfBasisAbsence(
          scopeIds,
          companies,
        );
      }
      final cached = job.status == IngestStatus.cancelled
          ? (processed: 0, failed: 0, stored: 0, remaining: 0)
          : await _replayVerifiedAnnualSourceCache(scopeIds, companies);
      processed += cached.processed;
      failed += cached.failed;
      stored += cached.stored;
      final enriched = await _enrichStoredExactStatements(scopeIds, companies);
      failed += enriched.failed;
      final halfPublic = !_hasAllowance && job.status != IngestStatus.cancelled
          ? await _recoverPendingHalfXbrl(scopeIds, companies)
          : (stored: 0, failed: 0, processed: 0, remaining: 0, fresh: false);
      stored += halfPublic.stored;
      failed += halfPublic.failed;
      processed += halfPublic.processed;
      final annualPublic = job.status == IngestStatus.cancelled
          ? (stored: 0, failed: 0, processed: 0, remaining: 0, fresh: false)
          : await _recoverAnnualApiNoData(
              scopeIds,
              companies,
              maxPeriods: max(0, 10 - cached.processed),
              initialConsecutiveFailures: cached.failed,
            );
      stored += annualPublic.stored;
      failed += annualPublic.failed;
      processed += annualPublic.processed;
      if (await IngestJobs.isCancelled(session, jobId)) {
        job = job.copyWith(status: IngestStatus.cancelled);
      }
      final rawTargets = job.status == IngestStatus.cancelled
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
                          (t.lastError.like('%$_storedPeriodGapMarker%') |
                              (t.lastError.like(
                                    '%${FinancialCurrentCoreRecovery.marker}%',
                                  ) &
                                  (t.consolidatedStatus.equals(
                                        FilingFetchStatus.pending,
                                      ) |
                                      t.separateStatus.equals(
                                        FilingFetchStatus.pending,
                                      ))) |
                              t.lastError.like('%DartApiException(mismatch)%') |
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
      final targets = rawTargets
          .where(
            (f) =>
                !_isAnnualPublicRecovery(f) &&
                !(FinancialCurrentCoreRecovery.eligible(f) &&
                    (f.lastError?.contains(
                          FinancialCurrentCoreRecovery.marker,
                        ) ??
                        false) &&
                    f.attempts >= maxAttempts &&
                    !_isCurrentCoreRecovery(f)),
          )
          .toList();
      final byId = {for (final c in companies.values) c.id!: c};
      job = await IngestJobs.save(
        session,
        job.copyWith(
          total: processed + targets.length + annualPublic.remaining,
        ),
      );

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
            !_isCalendarYearRepair(filing) &&
            !_isHalfYearHtmlRecovery(filing)) {
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
      if (_periodNameMetadataRepaired > 0) {
        message +=
            ', 동일 원접수·당기 핵심 7계정 검증 후 보고기간 명칭 복구 $_periodNameMetadataRepaired벌(전체 계정값 재검증 아님)';
      }
      if (metadataAnchored > 0) {
        message += ', 공식 원접수 표지 기간 연결 $metadataAnchored건(숫자 변경 없음)';
      }
      // Source reads may outlast either delay; reserve from the current time.
      final resumeNow = _clock().toUtc();
      DateTime? earliestResume;
      void requestResume(DateTime at) {
        if (earliestResume == null || at.isBefore(earliestResume!)) {
          earliestResume = at;
        }
      }

      if (deferredMetadataTargets.isNotEmpty && !cancelled) {
        requestResume(
          resumeNow.add(
            metadataBatchDeferred
                ? const Duration(seconds: 30)
                : const Duration(minutes: 15),
          ),
        );
        message +=
            ', 원접수 표지 확인 20건 묶음 이후 ${deferredMetadataTargets.length}건 다음 실행 재개';
      }
      if (cached.processed > 0 || cached.remaining > 0) {
        message +=
            ', 고정 공식 원문 재검증 ${cached.processed}건·남은 ${cached.remaining}건(연결·별도 구분별 한 번)';
      }
      if (enriched.periods > 0 || enriched.failed > 0) {
        message +=
            ', 고정 당기 원문 행 보완 ${enriched.periods}기간·${enriched.facts}금액행'
            '·실패 ${enriched.failed}기간(전체 공시·주석 수집 아님)';
      }
      if (cached.remaining > 0 && !cancelled) {
        requestResume(
          resumeNow.add(
            cached.stored > 0 || (cached.processed > 0 && cached.failed == 0)
                ? const Duration(seconds: 30)
                : const Duration(minutes: 15),
          ),
        );
      }
      if (annualPublic.processed > 0 || annualPublic.remaining > 0) {
        message +=
            ', API 자료없음 연간 원문 확인 ${annualPublic.processed}건·남은 ${annualPublic.remaining}건(핵심계정 부분 수집)';
      }
      if (annualPublic.remaining > 0 && !cancelled) {
        requestResume(
          resumeNow.add(
            annualPublic.fresh ||
                    annualPublic.stored > 0 ||
                    (annualPublic.processed > 0 && annualPublic.failed == 0) ||
                    cached.stored > 0 ||
                    metadataBatchDeferred
                ? const Duration(seconds: 30)
                : const Duration(minutes: 15),
          ),
        );
      }
      if (halfPublic.processed > 0 || halfPublic.remaining > 0) {
        message +=
            ', API 예산 소진 반기 원문 XBRL 부분 핵심7계정 ${halfPublic.processed}건·남은 ${halfPublic.remaining}건';
      }
      if (halfPublic.remaining > 0 && !cancelled) {
        requestResume(
          resumeNow.add(
            halfPublic.fresh
                ? const Duration(seconds: 30)
                : const Duration(minutes: 15),
          ),
        );
      }
      if (feedRows > 0) message += ', 공시 피드 $feedRows건';
      if (only != null) message = '${only.name}: $message';
      if (_budgetExhausted &&
          !cancelled &&
          only == null &&
          deferredMetadataTargets.isEmpty &&
          annualPublic.remaining == 0 &&
          halfPublic.remaining == 0) {
        final at = ApiCallBudget.nextKstMidnight(
          resumeNow,
        ).add(const Duration(minutes: 10));
        requestResume(at);
        message +=
            ' · 일일 호출 예산($_activeBudget건) 소진, '
            '${scheduleResume != null ? '다음 날 이어서 받음' : '다음 실행에서 이어서 받음'}';
      }
      if (!cancelled && earliestResume != null) {
        await scheduleResume?.call(earliestResume!);
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

  static const _annualPublicMarker = 'api-noData-annual-public';
  static bool _isAnnualPublicRecovery(DartFiling f) =>
      f.reportCode == FinancialReportCode.annual &&
      (f.lastError?.contains(_annualPublicMarker) ?? false);
  static int _annualPublicAttempts(DartFiling f) =>
      int.tryParse(
        RegExp(r'api-noData-annual-public:attempt=(\d+)')
                .firstMatch(f.lastError ?? '')
                ?.group(1) ??
            '',
      ) ??
      0;

  /// Priority only for the exact official TXR annual fixture; never resets retries.
  static bool verifiedTxrRecoveryPriority(DartFiling f) =>
      f.rceptNo == '20250526000504' &&
      f.corpCode == '01458161' &&
      f.reportCode == FinancialReportCode.annual &&
      f.bsnsYear == 2024 &&
      DartReportName.parse(f.reportName)?.periodYear == 2024 &&
      DartReportName.parse(f.reportName)?.periodMonth == 12 &&
      _annualPublicAttempts(f) < 3 &&
      [f.consolidatedStatus, f.separateStatus].any(
        (s) =>
            s == FilingFetchStatus.pending ||
            s == FilingFetchStatus.failed ||
            s == FilingFetchStatus.noData,
      );

  /// Queue order only for exact actual source fixtures validated by this revision.
  /// A verified non-preparer CFS is eligible for evidence-backed noData, not
  /// numeric storage; unsupported bases, completed bases and exhausted public
  /// attempts never gain priority. Existing API/ledger attempt counters remain.
  static const _verifiedDurationSourceFixtures =
      <String, ({String corp, int year, Set<String> bases})>{
        '20240401000698': (corp: '01229240', year: 2023, bases: {'OFS'}),
        '20220315000038': (corp: '01035942', year: 2021, bases: {'CFS'}),
        '20220328001074': (corp: '01118139', year: 2021, bases: {'CFS'}),
        '20220324000019': (corp: '01085187', year: 2021, bases: {'CFS'}),
        '20220323000615': (corp: '01365384', year: 2021, bases: {'CFS'}),
        '20220322000927': (corp: '00145190', year: 2021, bases: {'CFS'}),
        '20220322000896': (corp: '00537221', year: 2021, bases: {'CFS'}),
        '20220322000703': (corp: '00445869', year: 2021, bases: {'CFS'}),
        '20220322000302': (corp: '00156910', year: 2021, bases: {'CFS'}),
        '20220318000876': (corp: '00886792', year: 2021, bases: {'CFS'}),
        '20220318000845': (corp: '00407036', year: 2021, bases: {'CFS'}),
        '20260709000400': (corp: '00925967', year: 2026, bases: {'CFS'}),
        '20250806000052': (corp: '00756163', year: 2021, bases: {'CFS'}),
        '20221004000119': (corp: '01060735', year: 2021, bases: {'CFS'}),
        '20220930000228': (corp: '00963000', year: 2021, bases: {'CFS'}),
        '20220919000208': (corp: '01146220', year: 2021, bases: {'CFS'}),
        '20220616000321': (corp: '01524507', year: 2021, bases: {'CFS'}),
        '20220602000449': (corp: '00531078', year: 2021, bases: {'CFS'}),
        '20220411001806': (corp: '00976615', year: 2021, bases: {'CFS'}),
        '20220330001266': (corp: '01351080', year: 2021, bases: {'CFS'}),
        '20220315001280': (corp: '00340096', year: 2021, bases: {'OFS'}),
        '20230315001270': (corp: '00340096', year: 2022, bases: {'OFS'}),
        '20240320001438': (corp: '00963000', year: 2023, bases: {'OFS'}),
        '20250317000968': (corp: '00963000', year: 2024, bases: {'OFS'}),
        '20260804000177': (corp: '01872459', year: 2025, bases: {'CFS', 'OFS'}),
        '20260316001360': (corp: '00614089', year: 2025, bases: {'OFS'}),
        '20260323000673': (corp: '01063237', year: 2025, bases: {'OFS'}),
        '20250321000751': (corp: '01020269', year: 2024, bases: {'CFS'}),
        '20250321000101': (corp: '01867749', year: 2024, bases: {'CFS'}),
        '20250320001652': (corp: '01118139', year: 2024, bases: {'CFS'}),
        '20240322000131': (corp: '00867034', year: 2023, bases: {'CFS', 'OFS'}),
        '20240322000095': (corp: '01118139', year: 2023, bases: {'CFS'}),
        '20240320001618': (corp: '01060735', year: 2023, bases: {'CFS'}),
        '20240320000976': (corp: '01466832', year: 2023, bases: {'CFS'}),
        '20231120000719': (corp: '01085187', year: 2022, bases: {'CFS'}),
        '20230718000394': (corp: '00450931', year: 2022, bases: {'CFS'}),
        '20230717000306': (corp: '01466832', year: 2022, bases: {'CFS'}),
        '20230323001556': (corp: '00886792', year: 2022, bases: {'CFS'}),
        '20230323001499': (corp: '00145190', year: 2022, bases: {'CFS'}),
        '20230317000395': (corp: '01101254', year: 2022, bases: {'CFS'}),
        '20230317001056': (corp: '00267942', year: 2022, bases: {'CFS'}),
        '20230321001490': (corp: '01060735', year: 2022, bases: {'CFS'}),
        '20230321001529': (corp: '01118139', year: 2022, bases: {'CFS'}),
        '20230322001276': (corp: '00302236', year: 2022, bases: {'CFS'}),
        '20230321000800': (corp: '00445869', year: 2022, bases: {'CFS'}),
        '20230321000691': (corp: '00156910', year: 2022, bases: {'CFS'}),
        '20250710000060': (corp: '00445869', year: 2024, bases: {'CFS'}),
        '20250321001022': (corp: '01023822', year: 2024, bases: {'CFS'}),
        '20250321001939': (corp: '01156795', year: 2024, bases: {'CFS'}),
        '20250321001395': (corp: '01363924', year: 2024, bases: {'CFS'}),
        '20250321000819': (corp: '00929228', year: 2024, bases: {'CFS'}),
        '20250321000661': (corp: '01345724', year: 2024, bases: {'CFS'}),
        '20240328001866': (corp: '01085187', year: 2023, bases: {'CFS'}),
        // Exact attachment target; actual financial Source remains its original annual.
        '20260318000344': (corp: '00963000', year: 2025, bases: {'CFS', 'OFS'}),
        '20230321001265': (corp: '01344363', year: 2022, bases: {'OFS'}),
        '20220819000262': (corp: '00450931', year: 2021, bases: {'OFS'}),
        '20250331002057': (corp: '01229240', year: 2024, bases: {'CFS', 'OFS'}),
        '20250321001451': (corp: '00541862', year: 2024, bases: {'CFS'}),
        '20240409003743': (corp: '01022142', year: 2022, bases: {'OFS'}),
        '20230714000369': (corp: '00565215', year: 2022, bases: {'OFS'}),
        '20240814001895': (corp: '01022142', year: 2023, bases: {'OFS'}),
        '20241104000113': (corp: '01518506', year: 2023, bases: {'OFS'}),
        '20230328000161': (corp: '01315042', year: 2022, bases: {'OFS'}),
        '20240808000099': (corp: '00565215', year: 2023, bases: {'OFS'}),
        '20230323000665': (corp: '01026616', year: 2022, bases: {'OFS'}),
        '20250320001369': (corp: '01353848', year: 2024, bases: {'OFS'}),
        '20260323000238': (corp: '01867749', year: 2025, bases: {'CFS'}),
        '20260323001434': (corp: '01281541', year: 2025, bases: {'CFS'}),
        '20260323000522': (corp: '01156795', year: 2025, bases: {'CFS'}),
        '20260323000750': (corp: '01583953', year: 2025, bases: {'CFS'}),
        '20260324001035': (corp: '01023822', year: 2025, bases: {'CFS'}),
        '20260323000081': (corp: '01345724', year: 2025, bases: {'CFS'}),
        '20260320000168': (corp: '01363924', year: 2025, bases: {'CFS'}),
        '20260323001181': (corp: '01396931', year: 2025, bases: {'CFS'}),
        '20260319000875': (corp: '01060735', year: 2025, bases: {'CFS'}),
        '20260327001816': (corp: '01085187', year: 2025, bases: {'CFS'}),
        '20250326000875': (corp: '01085187', year: 2024, bases: {'CFS', 'OFS'}),
        '20250409000365': (corp: '00925967', year: 2024, bases: {'OFS'}),
        '20250407003814': (corp: '01119651', year: 2024, bases: {'CFS'}),
        '20220316000721': (corp: '00337296', year: 2021, bases: {'OFS'}),
        '20220322000487': (corp: '00521433', year: 2021, bases: {'OFS'}),
        '20220321000166': (corp: '01117422', year: 2021, bases: {'OFS'}),
        '20260330001850': (corp: '01579020', year: 2025, bases: {'CFS', 'OFS'}),
        '20230315000997': (corp: '01601222', year: 2022, bases: {'OFS'}),
        '20230308000311': (corp: '01476219', year: 2022, bases: {'OFS'}),
        '20250328001780': (corp: '01563667', year: 2024, bases: {'CFS', 'OFS'}),
        '20230320000571': (corp: '01267958', year: 2022, bases: {'CFS', 'OFS'}),
        '20250319000477': (corp: '01518506', year: 2024, bases: {'OFS'}),
        '20260326000605': (corp: '01139497', year: 2025, bases: {'OFS'}),
        '20240320000531': (corp: '00663289', year: 2023, bases: {'OFS'}),
        '20250318000507': (corp: '01281541', year: 2024, bases: {'OFS'}),
        '20250321001749': (corp: '00366517', year: 2024, bases: {'OFS'}),
        '20250407004206': (corp: '00414540', year: 2024, bases: {'OFS'}),
        '20260309001820': (corp: '01205514', year: 2025, bases: {'OFS'}),
        '20240321000933': (corp: '01206717', year: 2023, bases: {'CFS'}),
        '20260320000871': (corp: '01065785', year: 2025, bases: {'CFS', 'OFS'}),
        '20230317000589': (corp: '01113499', year: 2022, bases: {'CFS', 'OFS'}),
        '20250321001825': (corp: '00990396', year: 2024, bases: {'CFS', 'OFS'}),
        '20260316001455': (corp: '00445869', year: 2025, bases: {'OFS'}),
        '20260326000677': (corp: '01290132', year: 2025, bases: {'OFS'}),
        '20220331002887': (corp: '01366824', year: 2021, bases: {'OFS'}),
        '20230427000895': (corp: '01366824', year: 2022, bases: {'OFS'}),
        '20220331003444': (corp: '01085026', year: 2021, bases: {'CFS'}),
        '20250328002132': (corp: '01396931', year: 2024, bases: {'OFS'}),
        '20240320001359': (corp: '01281541', year: 2023, bases: {'OFS'}),
        '20240704000080': (corp: '00666329', year: 2023, bases: {'OFS'}),
        '20260323000759': (corp: '00886792', year: 2025, bases: {'CFS', 'OFS'}),
        '20260330001644': (corp: '00669450', year: 2025, bases: {'CFS', 'OFS'}),
        '20260327001807': (corp: '01018617', year: 2025, bases: {'CFS'}),
        '20230320001037': (corp: '00296290', year: 2022, bases: {'CFS'}),
        '20230321000972': (corp: '01063556', year: 2022, bases: {'CFS'}),
        '20260323000876': (corp: '01352575', year: 2025, bases: {'OFS'}),
        '20260323000661': (corp: '01262023', year: 2025, bases: {'OFS'}),
        '20260323000763': (corp: '01119651', year: 2025, bases: {'CFS'}),
        '20260330001331': (corp: '01118643', year: 2025, bases: {'OFS'}),
        '20260319001111': (corp: '01188730', year: 2025, bases: {'OFS'}),
        '20260331003389': (corp: '00414540', year: 2025, bases: {'OFS'}),
        '20260323001652': (corp: '01020269', year: 2025, bases: {'OFS'}),
        '20260709000504': (corp: '01034730', year: 2025, bases: {'OFS'}),
        '20250321001900': (corp: '00765897', year: 2024, bases: {'OFS'}),
        '20260319000348': (corp: '00521433', year: 2025, bases: {'OFS'}),
        '20260319000707': (corp: '00553025', year: 2025, bases: {'CFS'}),
        '20260323001028': (corp: '00611286', year: 2025, bases: {'OFS'}),
        '20250321001632': (corp: '00816696', year: 2024, bases: {'OFS'}),
        '20250321000468': (corp: '01117422', year: 2024, bases: {'OFS'}),
        '20250325000306': (corp: '01290132', year: 2024, bases: {'OFS'}),
        '20251124000372': (corp: '01669794', year: 2024, bases: {'OFS'}),
        '20250320001616': (corp: '00442631', year: 2024, bases: {'OFS', 'CFS'}),
        '20250318000596': (corp: '01352575', year: 2024, bases: {'OFS', 'CFS'}),
        '20260318001043': (corp: '01018802', year: 2025, bases: {'CFS'}),
        '20260318001370': (corp: '01507722', year: 2025, bases: {'CFS'}),
        '20260318000161': (corp: '00533809', year: 2025, bases: {'CFS'}),
        '20260313000656': (corp: '00393618', year: 2025, bases: {'CFS'}),
        '20260316001089': (corp: '01187458', year: 2025, bases: {'CFS'}),
        '20260309001126': (corp: '00965062', year: 2025, bases: {'CFS'}),
        '20251127001320': (corp: '01507722', year: 2024, bases: {'CFS'}),
        '20251127001311': (corp: '01507722', year: 2023, bases: {'CFS'}),
        '20250319000677': (corp: '01187458', year: 2024, bases: {'CFS'}),
        '20250318000162': (corp: '00533809', year: 2024, bases: {'CFS'}),
        '20250314001680': (corp: '00965062', year: 2024, bases: {'CFS'}),
        '20250314001180': (corp: '00393618', year: 2024, bases: {'CFS'}),
        '20240320000695': (corp: '01187458', year: 2023, bases: {'CFS'}),
        '20240318000263': (corp: '00533809', year: 2023, bases: {'CFS'}),
        '20240315000148': (corp: '00393618', year: 2023, bases: {'CFS'}),
        '20240313000197': (corp: '00965062', year: 2023, bases: {'CFS'}),
        '20230711000155': (corp: '01507722', year: 2022, bases: {'CFS'}),
        '20230327000966': (corp: '00533809', year: 2022, bases: {'CFS'}),
        '20230323001231': (corp: '01187458', year: 2022, bases: {'CFS'}),
        '20230317000730': (corp: '00965062', year: 2022, bases: {'CFS'}),
        '20230317000450': (corp: '00393618', year: 2022, bases: {'CFS'}),
        '20220722000193': (corp: '00533809', year: 2021, bases: {'CFS'}),
        '20220321000662': (corp: '01187458', year: 2021, bases: {'CFS'}),
        '20220318000594': (corp: '00965062', year: 2021, bases: {'CFS'}),
        '20220317000026': (corp: '00393618', year: 2021, bases: {'CFS'}),
      };

  static bool verifiedDurationSourceRecoveryPriority(DartFiling filing) {
    final proof = _verifiedDurationSourceFixtures[filing.rceptNo];
    final name = DartReportName.parse(filing.reportName);
    if (proof == null ||
        filing.corpCode != proof.corp ||
        filing.reportCode != FinancialReportCode.annual ||
        filing.bsnsYear != proof.year ||
        name?.kind != DartReportKind.annual ||
        name?.periodYear != proof.year ||
        name?.periodMonth !=
            switch (filing.rceptNo) {
              '20260709000400' => 3,
              '20220602000449' => 9,
              _ => 12,
            } ||
        _annualPublicAttempts(filing) >= 3) {
      return false;
    }
    bool needs(FilingFetchStatus status) =>
        status == FilingFetchStatus.pending ||
        status == FilingFetchStatus.failed ||
        status == FilingFetchStatus.noData && !_isAnnualPublicRecovery(filing);
    return proof.bases.contains('CFS') && needs(filing.consolidatedStatus) ||
        proof.bases.contains('OFS') && needs(filing.separateStatus);
  }

  Future<({int stored, int failed, int processed, int remaining, bool fresh})>
  _recoverAnnualApiNoData(
    Set<int> scopeIds,
    Map<String, Company> companies, {
    int maxPeriods = 10,
    int initialConsecutiveFailures = 0,
  }) async {
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.id.inSet(scopeIds) &
          t.reportCode.equals(FinancialReportCode.annual),
    );
    final queue = filings
        .where(
          (f) =>
              DartReportName.parse(f.reportName)?.kind ==
                  DartReportKind.annual &&
              _annualPublicAttempts(f) < 3 &&
              ((_isAnnualPublicRecovery(f) &&
                      (f.consolidatedStatus == FilingFetchStatus.failed ||
                          f.consolidatedStatus == FilingFetchStatus.pending ||
                          f.separateStatus == FilingFetchStatus.failed ||
                          f.separateStatus == FilingFetchStatus.pending)) ||
                  (f.consolidatedStatus == FilingFetchStatus.noData &&
                      f.separateStatus == FilingFetchStatus.noData &&
                      !_isAnnualPublicRecovery(f))),
        )
        .toList();
    final periodRanks = <int, int>{};
    final byCompany = <int?, List<DartFiling>>{};
    for (final f in queue) {
      (byCompany[f.companyId] ??= []).add(f);
    }
    for (final companyFilings in byCompany.values) {
      companyFilings.sort(
        (a, b) => apiRequestYear(b).compareTo(apiRequestYear(a)) != 0
            ? apiRequestYear(b).compareTo(apiRequestYear(a))
            : DartReportName.parse(b.reportName)!.periodMonth
                  .compareTo(DartReportName.parse(a.reportName)!.periodMonth),
      );
      for (var i = 0; i < companyFilings.length; i++) {
        periodRanks[companyFilings[i].id!] = i;
      }
    }
    // Exact official fixtures verified by this parser revision. This affects
    // queue order only: existing per-period attempts and failed-basis gates stay.
    const verifiedParserReceipts = <String, Set<String>>{
      '20230309000759': {'OFS'},
      '20230315000460': {'OFS'},
      '20250320001633': {'CFS', 'OFS'},
      '20260318000509': {'OFS'},
      '20260617000188': {'OFS'},
      '20260731000744': {'OFS'},
      '20260708000510': {'OFS'},
      '20260709000504': {'CFS'},
      '20260629000311': {'OFS'},
      '20260423000673': {'CFS'},
      '20260429001057': {'CFS'},
      '20260430001951': {'CFS'},
      '20260430001147': {'CFS'},
      '20260709000400': {'OFS'},
      '20250326000042': {'CFS'},
      '20230621000034': {'CFS'},
      '20230321001219': {'OFS'},
      '20230622000218': {'CFS', 'OFS'},
      '20260331001824': {'CFS'},
      '20260323001144': {'CFS'},
      '20240320001370': {'CFS', 'OFS'},
      '20230317000589': {'CFS', 'OFS'},
      '20250321001825': {'CFS', 'OFS'},
      '20260316001455': {'OFS'},
      '20260319000105': {'CFS', 'OFS'},
      '20260319000677': {'OFS'},
      '20250321001022': {'OFS'},
      '20240322000131': {'OFS'},
      '20260318000962': {'OFS'},
      '20260331000297': {'OFS'},
      '20260331004755': {'OFS'},
    };
    bool verifiedParserPending(DartFiling f) {
      if (_verifiedDurationSourceFixtures.containsKey(f.rceptNo)) {
        return verifiedDurationSourceRecoveryPriority(f);
      }
      if (f.rceptNo == '20250526000504') {
        return verifiedTxrRecoveryPriority(f);
      }
      if (f.rceptNo == BnkSixCoreProfile.receipt &&
          f.corpCode != BnkSixCoreProfile.corpCode) {
        return false;
      }
      if (f.rceptNo == PureunSixCoreProfile.receipt &&
          f.corpCode != PureunSixCoreProfile.corpCode) {
        return false;
      }
      final bases = verifiedParserReceipts[f.rceptNo];
      if (bases == null) return false;
      if (f.rceptNo == '20250320001633' && f.corpCode != '01188730') {
        return false;
      }
      if (f.rceptNo == '20260318000509' && f.corpCode != '00832700') {
        return false;
      }
      bool needs(FilingFetchStatus status) =>
          status == FilingFetchStatus.failed ||
          status == FilingFetchStatus.pending ||
          status == FilingFetchStatus.noData;
      return (bases.contains('CFS') && needs(f.consolidatedStatus)) ||
          (bases.contains('OFS') && needs(f.separateStatus));
    }

    queue.sort((a, b) {
      final priority = (verifiedParserPending(b) ? 1 : 0).compareTo(
        verifiedParserPending(a) ? 1 : 0,
      );
      if (priority != 0) return priority;
      final attempts = _annualPublicAttempts(a)
          .compareTo(_annualPublicAttempts(b));
      if (attempts != 0) return attempts;
      final rank = periodRanks[a.id!]!.compareTo(periodRanks[b.id!]!);
      if (rank != 0) return rank;
      final pa = DartReportName.parse(a.reportName),
          pb = DartReportName.parse(b.reportName);
      final periods = (pb?.periodYear ?? 0).compareTo(pa?.periodYear ?? 0);
      if (periods != 0) return periods;
      final months = (pb?.periodMonth ?? 0).compareTo(pa?.periodMonth ?? 0);
      return months != 0 ? months : b.rceptNo.compareTo(a.rceptNo);
    });
    var stored = 0,
        failed = 0,
        processed = 0,
        consecutiveFailures = initialConsecutiveFailures;
    final attempted = <int>{};
    for (final f in queue) {
      if (processed >= maxPeriods ||
          consecutiveFailures >= 6 ||
          await IngestJobs.isCancelled(session, jobId)) {
        break;
      }
      final company = companies[f.corpCode];
      if (company == null ||
          DartReportName.parse(f.reportName)?.kind != DartReportKind.annual) {
        continue;
      }
      if (processed > 0 && callInterval != Duration.zero) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final auditReference = 'financial-api-noData-origin:${f.rceptNo}';
      if (!_isAnnualPublicRecovery(f)) {
        if (await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(auditReference),
            ) ==
            null) {
          await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference: auditReference,
              url: DartClient.filingViewerUrl(f.rceptNo).toString(),
              retrievedAt: _clock().toUtc(),
              title: jsonEncode({
                'action': 'preserved-api-noData-before-keyless-public-recovery',
                'receipt': f.rceptNo,
                'corpCode': f.corpCode,
                'reportName': f.reportName,
                'originalConsolidatedStatus': f.consolidatedStatus.name,
                'originalSeparateStatus': f.separateStatus.name,
                'originalAttempts': f.attempts,
                'originalLastError': f.lastError,
                'note':
                    '원 API 자료없음 장부 근거 보존; API 재요청 없음. 공개 원문 오류는 자료없음으로 확정하지 않음',
              }),
            ),
          );
        }
      }
      final knownCfsAbsent =
          _isAnnualPublicRecovery(f) &&
          f.consolidatedStatus == FilingFetchStatus.noData &&
          await Source.db.findFirstRow(
                session,
                where: (t) => t.reference.equals(
                  'financial-public-basis-not-applicable:${f.rceptNo}:consolidated',
                ),
              ) !=
              null;
      final sourceRequest = f.copyWith(
        consolidatedStatus: knownCfsAbsent
            ? FilingFetchStatus.noData
            : f.consolidatedStatus == FilingFetchStatus.stored
            ? FilingFetchStatus.stored
            : FilingFetchStatus.pending,
        separateStatus: f.separateStatus == FilingFetchStatus.stored
            ? FilingFetchStatus.stored
            : FilingFetchStatus.pending,
        lastError:
            '$_annualPublicMarker:attempt=${_annualPublicAttempts(f)}; ${f.lastError ?? ''}',
      );
      final result = await _fetchFiling(sourceRequest, company);
      final updated = (await DartFiling.db.findById(session, f.id!))!;
      await DartFiling.db.updateRow(
        session,
        updated.copyWith(
          lastError:
              '$_annualPublicMarker:attempt=${_annualPublicAttempts(f) + (await IngestJobs.isCancelled(session, jobId) ? 0 : 1)}; ${updated.lastError ?? ''}',
        ),
      );
      stored += result.stored;
      failed += result.failed ? 1 : 0;
      processed++;
      attempted.add(f.id!);
      // Only this attempt's stored values or verified completion are progress.
      // A report already stored in the other basis cannot clear this failure.
      final progressed = result.stored > 0 || !result.failed;
      consecutiveFailures = progressed ? 0 : consecutiveFailures + 1;
    }
    var remaining = 0;
    var fresh = false;
    for (final f in queue) {
      final current = (await DartFiling.db.findById(session, f.id!))!;
      final pending =
          _annualPublicAttempts(current) < 3 &&
          (!attempted.contains(f.id!) ||
              current.consolidatedStatus == FilingFetchStatus.failed ||
              current.consolidatedStatus == FilingFetchStatus.pending ||
              current.separateStatus == FilingFetchStatus.failed ||
              current.separateStatus == FilingFetchStatus.pending);
      if (pending) {
        remaining++;
        if (!attempted.contains(f.id!) && _annualPublicAttempts(current) == 0) {
          fresh = true;
        }
      }
    }
    return (
      stored: stored,
      failed: failed,
      processed: processed,
      remaining: remaining,
      fresh: fresh,
    );
  }

  Future<bool> _verifiedDuksanSeparateSource(
    DartFiling f, {
    Transaction? transaction,
  }) async {
    final reports = await FinancialReport.db.find(
      session,
      where: (t) =>
          t.rceptNo.equals(f.rceptNo) & t.fsDiv.equals(FsDiv.separate),
      transaction: transaction,
    );
    if (reports.length != 1) return false;
    final r = reports.single;
    if (r.id != 115176 ||
        r.factCount != 7 ||
        r.companyId != f.companyId ||
        r.bsnsYear != 2026 ||
        r.reportCode != FinancialReportCode.halfYear ||
        r.reportName != '반기보고서 (2026.06)' ||
        r.supersededById != null) {
      return false;
    }
    final source = await Source.db.findById(
      session,
      r.sourceId,
      transaction: transaction,
    );
    if (source == null ||
        source.kind != SourceKind.dartReport ||
        source.reference != f.rceptNo) {
      return false;
    }
    final uri = Uri.tryParse(source.url ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.hasPort ||
        uri.host != 'dart.fss.or.kr' ||
        uri.path != '/pdf/download/ifrs.do' ||
        uri.queryParameters['rcp_no'] != f.rceptNo ||
        uri.queryParameters['dcm_no'] != '11523776' ||
        uri.queryParametersAll['rcp_no']?.length != 1 ||
        uri.queryParametersAll['dcm_no']?.length != 1) {
      return false;
    }
    final facts = await FinancialFact.db.find(
      session,
      where: (t) => t.reportId.equals(r.id!),
      transaction: transaction,
    );
    if (facts.length != 7) return false;
    if (facts.any(
      (x) =>
          x.sourceId != r.sourceId ||
          x.companyId != f.companyId ||
          x.fsDiv != FsDiv.separate ||
          x.currency != 'KRW' ||
          x.supersededById != null,
    )) {
      return false;
    }
    final picked = FinancialAccounts.pick(facts);
    const expected = {
      'assets': '62819162719',
      'liabilities': '31242471301',
      'equity': '31576691418',
      'revenue': '11795577500',
      'operatingIncome': '523580344',
      'netIncome': '482854478',
      'operatingCashFlow': '-4053641467',
    };
    for (final e in expected.entries) {
      final matches = picked.where((x) => x.key == e.key).toList();
      if (matches.length != 1 ||
          matches.single.amount != BigInt.parse(e.value)) {
        return false;
      }
    }
    const cumulative = {
      'revenue': '23769258694',
      'operatingIncome': '750396681',
      'netIncome': '725163143',
    };
    for (final e in cumulative.entries) {
      if (picked.singleWhere((x) => x.key == e.key).cumulativeAmount !=
          BigInt.parse(e.value)) {
        return false;
      }
    }
    return true;
  }

  Future<int> _classifyVerifiedHalfBasisAbsence(
    Set<int> scopeIds,
    Map<String, Company> companies,
  ) async {
    const receipt = VerifiedHalfBasisAbsence.receipt;
    const attemptRef =
        'financial-public-half-basis-classification-attempt:$receipt:CFS';
    const proofRef = 'financial-public-half-basis-not-applicable:$receipt:CFS';
    final f = await DartFiling.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(receipt),
    );
    final company = companies[VerifiedHalfBasisAbsence.corpCode];
    bool eligible(DartFiling x) =>
        scopeIds.contains(x.id) &&
        company != null &&
        x.companyId == company.id &&
        x.corpCode == VerifiedHalfBasisAbsence.corpCode &&
        x.reportName == '반기보고서 (2026.06)' &&
        x.reportCode == FinancialReportCode.halfYear &&
        x.bsnsYear == 2026 &&
        x.consolidatedStatus == FilingFetchStatus.failed &&
        x.separateStatus == FilingFetchStatus.stored &&
        _halfXbrlAttempts(x) == 3;
    if (f == null ||
        !eligible(f) ||
        await IngestJobs.isCancelled(session, jobId)) {
      return 0;
    }
    Source? attempt;
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtextextended(@receipt,0))',
        parameters: QueryParameters.named({'receipt': receipt}),
        transaction: tx,
      );
      if (await IngestJobs.isCancelled(session, jobId)) return;
      final current = await DartFiling.db.findById(
        session,
        f.id!,
        transaction: tx,
      );
      if (current == null ||
          !eligible(current) ||
          !await _verifiedDuksanSeparateSource(current, transaction: tx)) {
        return;
      }
      if (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(attemptRef),
            transaction: tx,
          ) !=
          null) {
        return;
      }
      attempt = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: attemptRef,
          url: DartClient.filingViewerUrl(receipt).toString(),
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'one-time-source-basis-classification',
            'receipt': receipt,
            'corpCode': f.corpCode,
            'status': 'started',
            'numericAttempt': 3,
            'preservedSeparateReport': 115176,
          }),
        ),
        transaction: tx,
      );
    });
    if (attempt == null) return 0;
    try {
      final proof = await dart.classifyVerifiedHalfBasisAbsence(
        receipt: receipt,
        corpCode: f.corpCode,
        companyName: company!.name,
        cancelled: () => IngestJobs.isCancelled(session, jobId),
      );
      if (await IngestJobs.isCancelled(session, jobId)) {
        throw VerifiedHalfBasisCancelled();
      }
      await session.db.transaction((tx) async {
        final current = await DartFiling.db.findById(
          session,
          f.id!,
          transaction: tx,
        );
        if (await IngestJobs.isCancelled(session, jobId) ||
            current == null ||
            !eligible(current) ||
            !await _verifiedDuksanSeparateSource(current, transaction: tx)) {
          throw VerifiedHalfBasisCancelled();
        }
        if (proof.cover.receipt != receipt ||
            proof.cover.corpCode != f.corpCode ||
            proof.cover.periodStart != DateTime.utc(2026) ||
            proof.cover.periodEnd != DateTime.utc(2026, 6, 30) ||
            proof.statementSha256 != VerifiedHalfBasisAbsence.bodySha ||
            proof.statementSource !=
                Uri.https('dart.fss.or.kr', '/report/viewer.do', {
                  'rcpNo': receipt,
                  'dcmNo': '11523776',
                  'eleId': '19',
                  'offset': '155297',
                  'length': '182',
                  'dtd': 'dart4.xsd',
                })) {
          throw const FormatException('Invalid typed source classification');
        }
        await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: proofRef,
            url: proof.statementSource.toString(),
            retrievedAt: _clock().toUtc(),
            title: jsonEncode({
              'action': 'official-exact-half-consolidated-not-applicable',
              'receipt': receipt,
              'corpCode': f.corpCode,
              'basis': 'CFS',
              'periodStart': proof.cover.periodStart.toIso8601String(),
              'periodEnd': proof.cover.periodEnd.toIso8601String(),
              'shellSource': proof.cover.shellSource.toString(),
              'coverSource': proof.cover.coverSource.toString(),
              'coverSha256': VerifiedHalfBasisAbsence.coverSha,
              'metadataSha256': proof.cover.digest,
              'statementSource': proof.statementSource.toString(),
              'sha256': proof.statementSha256,
              'evidence': '해당사항 없음.',
              'numericAttemptPreserved': 3,
              'preservedSeparateReport': 115176,
            }),
          ),
          transaction: tx,
        );
        await DartFiling.db.updateRow(
          session,
          current.copyWith(
            consolidatedStatus: FilingFetchStatus.noData,
            lastError:
                '연결 원문 명시 비적용 확인 완료 [$proofRef]; pending-half-exact-xbrl:attempt=3',
          ),
          transaction: tx,
        );
        await Source.db.updateRow(
          session,
          attempt!.copyWith(
            title: jsonEncode({
              'action': 'one-time-source-basis-classification',
              'receipt': receipt,
              'status': 'resolved',
              'proofReference': proofRef,
              'numericAttempt': 3,
            }),
          ),
          transaction: tx,
        );
      });
    } catch (e) {
      await Source.db.updateRow(
        session,
        attempt!.copyWith(
          title: jsonEncode({
            'action': 'one-time-source-basis-classification',
            'receipt': receipt,
            'status': e is VerifiedHalfBasisCancelled ? 'cancelled' : 'failed',
            'errorType': e.runtimeType.toString(),
            'numericAttempt': 3,
          }),
        ),
      );
    }
    return 1;
  }

  static const _halfXbrlMarker = 'pending-half-exact-xbrl';

  static int _halfXbrlAttempts(DartFiling f) =>
      int.tryParse(
        RegExp(r'pending-half-exact-xbrl:attempt=(\d+)')
                .firstMatch(f.lastError ?? '')
                ?.group(1) ??
            '',
      ) ??
      0;

  Future<({int stored, int failed, int processed, int remaining, bool fresh})>
  _recoverPendingHalfXbrl(
    Set<int> scopeIds,
    Map<String, Company> companies,
  ) async {
    bool eligible(DartFiling f) =>
        f.rceptNo == '20260813000889' &&
        f.corpCode == '00960623' &&
        f.attempts < maxAttempts &&
        _halfXbrlAttempts(f) < 3 &&
        f.reportCode == FinancialReportCode.halfYear &&
        DartReportName.parse(f.reportName)?.kind == DartReportKind.halfYear &&
        (f.consolidatedStatus == FilingFetchStatus.pending ||
            f.separateStatus == FilingFetchStatus.pending ||
            (f.lastError?.contains(_halfXbrlMarker) == true &&
                (f.consolidatedStatus == FilingFetchStatus.failed ||
                    f.separateStatus == FilingFetchStatus.failed)));
    final all = await DartFiling.db.find(
      session,
      where: (t) =>
          t.id.inSet(scopeIds) &
          t.reportCode.equals(FinancialReportCode.halfYear),
    );
    final queue = all.where(eligible).toList()
      ..sort(
        (a, b) => _halfXbrlAttempts(a).compareTo(_halfXbrlAttempts(b)) != 0
            ? _halfXbrlAttempts(a).compareTo(_halfXbrlAttempts(b))
            : b.rceptNo.compareTo(a.rceptNo),
      );
    var stored = 0, failed = 0, processed = 0, consecutive = 0;
    final attempted = <int>{};
    for (final f in queue) {
      if (processed >= 5 ||
          consecutive >= 3 ||
          await IngestJobs.isCancelled(session, jobId)) {
        break;
      }
      final company = companies[f.corpCode];
      if (company == null) continue;
      if (processed > 0 && callInterval != Duration.zero) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final period = DartReportName.parse(f.reportName)!;
      final end = DateTime.utc(period.periodYear, period.periodMonth + 1, 0);
      ({List<int> zip, Uri source})? original;
      String? transportError;
      try {
        original = await dart.fetchPublicAnnualXbrl(f.rceptNo);
      } catch (e) {
        final clean = e is FormatException
            ? e.message.replaceAll(RegExp(r'[\r\n\x00-\x1f]'), ' ')
            : e.runtimeType.toString();
        transportError = clean.substring(0, min(200, clean.length));
      }
      if (await IngestJobs.isCancelled(session, jobId)) break;
      var next = f, itemFailed = false;
      var basisProcessed = false;
      for (final div in FsDiv.values) {
        final status = div == FsDiv.consolidated
            ? next.consolidatedStatus
            : next.separateStatus;
        if (status != FilingFetchStatus.pending &&
            !(status == FilingFetchStatus.failed &&
                f.lastError?.contains(_halfXbrlMarker) == true)) {
          continue;
        }
        if (await IngestJobs.isCancelled(session, jobId)) break;
        List<Map<String, dynamic>>? rows;
        String? error = transportError;
        if (original != null) {
          try {
            rows = PublicFinancialXbrl.parseHalfYear(
              original.zip,
              receipt: f.rceptNo,
              corpCode: company.corpCode,
              bsnsYear: apiRequestYear(f),
              periodEnd: end,
              consolidated: div == FsDiv.consolidated,
              sourceUri: original.source,
            );
          } catch (e) {
            error = e is FormatException
                ? e.message.toString()
                : e.runtimeType.toString();
          }
        }
        if (await IngestJobs.isCancelled(session, jobId)) break;
        basisProcessed = true;
        if (rows == null) {
          itemFailed = true;
          next = next.copyWith(
            consolidatedStatus: div == FsDiv.consolidated
                ? FilingFetchStatus.failed
                : null,
            separateStatus: div == FsDiv.separate
                ? FilingFetchStatus.failed
                : null,
            lastError:
                '$_halfXbrlMarker:attempt=${_halfXbrlAttempts(f) + 1}; ${div.name}: ${error ?? 'strict source validation failed'}',
          );
          continue;
        }
        final saved = await _store(
          f,
          company,
          div,
          rows,
          originalSource: original!.source,
          originalDigest: PublicFinancialXbrl.digest(original.zip),
          originalFormat: 'half-xbrl',
        );
        if (saved.inserted) stored++;
        next = next.copyWith(
          consolidatedStatus: div == FsDiv.consolidated ? saved.status : null,
          separateStatus: div == FsDiv.separate ? saved.status : null,
        );
      }
      if (!basisProcessed) break;
      processed++;
      attempted.add(f.id!);
      if (itemFailed) {
        failed++;
        consecutive++;
      } else {
        consecutive = 0;
      }
      await DartFiling.db.updateRow(
        session,
        next.copyWith(attempts: f.attempts, checkedAt: _clock().toUtc()),
      );
    }
    var remaining = 0;
    var fresh = false;
    for (final old in queue) {
      final f = (await DartFiling.db.findById(session, old.id!))!;
      if (eligible(f)) {
        remaining++;
        if (!attempted.contains(f.id!)) fresh = true;
      }
    }
    return (
      stored: stored,
      failed: failed,
      processed: processed,
      remaining: remaining,
      fresh: fresh,
    );
  }

  static const _storedPeriodGapMarker = 'source-annual-actual-period-gap';

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
      ((_isCurrentCoreRecovery(filing)) ||
          _isAnnualPublicRecovery(filing) ||
          (filing.lastError?.contains(_storedPeriodGapMarker) ?? false) ||
          (filing.attempts < maxAttempts &&
              (filing.lastError?.contains('storedCurrentAmountsMissing') ??
                  false)) ||
          (filing.lastError?.contains('DartApiException(mismatch)') ?? false) ||
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

  static bool _isCurrentCoreRecovery(DartFiling f) =>
      FinancialCurrentCoreRecovery.eligible(f) &&
      (f.consolidatedStatus == FilingFetchStatus.pending ||
          f.separateStatus == FilingFetchStatus.pending) &&
      (f.lastError?.contains(FinancialCurrentCoreRecovery.marker) ?? false);

  static const _halfYearHtmlMarker = 'verified-half-html-noData-once';
  static bool _isKnownHalfYearHtmlPeriod(DartFiling f) {
    final period = DartReportName.parse(f.reportName);
    return f.corpCode == '00337296' &&
        f.rceptNo == '20260814002145' &&
        f.reportCode == FinancialReportCode.halfYear &&
        f.bsnsYear == 2026 &&
        period?.kind == DartReportKind.halfYear &&
        period?.periodYear == 2026 &&
        period?.periodMonth == 6;
  }

  static bool _isHalfYearHtmlRecovery(DartFiling f) =>
      _isKnownHalfYearHtmlPeriod(f) &&
      (f.lastError?.contains(_halfYearHtmlMarker) ?? false);

  Future<({int stored, bool failed})> _fetchHalfYearHtmlRecovery(
    DartFiling filing,
    Company company,
  ) async {
    if (filing.separateStatus != FilingFetchStatus.pending &&
        filing.separateStatus != FilingFetchStatus.failed) {
      return (stored: 0, failed: false);
    }
    final end = DateTime.utc(2026, 6, 30);
    final name = company.name.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s+'), '');
    FilingFetchStatus result;
    var inserted = false;
    String? error;
    ({
      List<Map<String, dynamic>> rows,
      Uri statementSource,
      Uri coverSource,
      String digest,
    })?
    verified;
    try {
      if (name.isEmpty) {
        throw const FormatException('Empty half-year company identity');
      }
      final html = await dart.fetchHalfYearHtml(
        filing.rceptNo,
        reportName: filing.reportName,
        corpCode: company.corpCode,
        companyName: company.name,
        bsnsYear: filing.bsnsYear!,
        periodEnd: end,
        consolidated: false,
      );
      if (html.sourceReceipt != filing.rceptNo ||
          html.correctionReceipt != null ||
          html.correctionSource != null ||
          html.periodEnd != end) {
        throw const FormatException('Half-year exact-source identity mismatch');
      }
      final rows = PublicFinancialHtml.parseHalfYear(
        coverHtml: html.coverHtml,
        statementHtml: html.statementHtml,
        coverSource: html.coverSource,
        statementSource: html.statementSource,
        receipt: filing.rceptNo,
        corpCode: company.corpCode,
        companyName: name,
        periodStart: html.periodStart,
        periodEnd: end,
        consolidated: false,
      );
      verified = (
        rows: rows,
        statementSource: html.statementSource,
        coverSource: html.coverSource,
        digest: html.sourceDigest,
      );
    } catch (_) {
      error =
          '$_halfYearHtmlMarker; verified exact half-year HTML source failed';
    }
    if (verified != null) {
      // Persistence failures must propagate, never masquerade as transport gaps.
      final saved = await _store(
        filing,
        company,
        FsDiv.separate,
        verified.rows,
        originalSource: verified.statementSource,
        originalDigest: verified.digest,
        originalFormat: 'html',
      );
      result = saved.status;
      inserted = saved.inserted;
      if (inserted) _htmlCoreRecovered++;
      if (result == FilingFetchStatus.stored) {
        final reference =
            'financial-half-html-recovery:${filing.rceptNo}:separate';
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
              url: verified.statementSource.toString(),
              retrievedAt: _clock().toUtc(),
              title: jsonEncode({
                'action': 'verified-exact-half-html-source',
                'receipt': filing.rceptNo,
                'corpCode': company.corpCode,
                'reportName': filing.reportName,
                'fsDiv': 'separate',
                'coverSource': verified.coverSource.toString(),
                'statementSource': verified.statementSource.toString(),
                'originalSha256': verified.digest,
                'coreRows': verified.rows.length,
                'note': '손익 3개월 값과 반기 누적값, 현금흐름 누적값 보존. XBRL계정ID 미제공.',
              }),
            ),
          );
        }
      }
    } else {
      result = FilingFetchStatus.failed;
    }
    await DartFiling.db.updateRow(
      session,
      filing.copyWith(
        separateStatus: result,
        attempts: result == FilingFetchStatus.failed
            ? filing.attempts + 1
            : filing.attempts,
        lastError:
            error ??
            '$_halfYearHtmlMarker; verified-half-html-source:${filing.rceptNo}',
        checkedAt: _clock().toUtc(),
      ),
    );
    return (
      stored: inserted ? 1 : 0,
      failed: result == FilingFetchStatus.failed,
    );
  }

  /// 공시 하나의 연결·별도 재무제표를 받는다. 새로 저장한 벌 수와 실패 여부.
  Future<({int stored, bool failed})> _fetchFiling(
    DartFiling filing,
    Company company,
  ) async {
    if (_isHalfYearHtmlRecovery(filing)) {
      return _fetchHalfYearHtmlRecovery(filing, company);
    }
    var next = filing;
    ({List<int> zip, Uri source})? originalAnnual;
    var stored = 0;
    var failed = false;
    for (final div in FsDiv.values) {
      if (_isAnnualPublicRecovery(filing) &&
          await IngestJobs.isCancelled(session, jobId)) {
        break;
      }
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

      final existingCurrent = await FinancialReport.db.findFirstRow(
        session,
        where: (t) => t.rceptNo.equals(filing.rceptNo) & t.fsDiv.equals(div),
      );
      if (existingCurrent != null &&
          existingCurrent.companyId == company.id &&
          existingCurrent.bsnsYear == filing.bsnsYear &&
          existingCurrent.reportCode == filing.reportCode &&
          _sameActualPeriod(existingCurrent.reportName, filing.reportName) &&
          !await _hasCurrentAmounts(existingCurrent) &&
          !_isCurrentCoreRecovery(filing)) {
        failed = true;
        next = next.copyWith(
          consolidatedStatus: div == FsDiv.consolidated
              ? FilingFetchStatus.failed
              : null,
          separateStatus: div == FsDiv.separate
              ? FilingFetchStatus.failed
              : null,
          lastError:
              'storedCurrentAmountsMissing: ${filing.rceptNo}; 기존 비교기간 숫자·출처 보존, 별도 원문 검증 필요',
        );
        continue;
      }
      FilingFetchStatus result;
      String? error;
      PublicFinancialHtmlBasisNotApplicable? verifiedBasisNotApplicable;
      try {
        if (_priorAnnualMismatch(filing)) {
          // The ledger already records a verified API mismatch. Public original
          // recovery needs no new key-bearing API call or allowance.
          throw DartApiException(
            'mismatch',
            _isAnnualPublicRecovery(filing)
                ? 'preserved API noData; keyless original recovery'
                : 'previous annual API period mismatch',
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
                sourceUri: original.source,
              ),
              source: original.source,
              digest: PublicFinancialXbrl.digest(original.zip),
              sourceFiling: sourceFiling,
              correctionSource: correctionSource,
              format: 'xbrl',
              coverSource: null,
            );
          } on FormatException {
            if (_isAnnualPublicRecovery(filing) &&
                !filing.reportName.contains('첨부정정')) {
              try {
                final period = DartReportName.parse(filing.reportName)!;
                final end = DateTime.utc(
                  period.periodYear,
                  period.periodMonth + 1,
                  0,
                );
                final html = await dart.fetchAnnualHtml(
                  filing.rceptNo,
                  reportName: filing.reportName,
                  corpCode: company.corpCode,
                  companyName: company.name,
                  bsnsYear: filing.bsnsYear!,
                  periodEnd: end,
                  consolidated: div == FsDiv.consolidated,
                );
                final verifiedLinkedAudit =
                    LinkedCorrectionAuditSource.eligible(
                      receipt: filing.rceptNo,
                      corpCode: company.corpCode,
                      consolidated: div == FsDiv.consolidated,
                      start: html.periodStart,
                      end: html.periodEnd,
                    ) &&
                    html.sourceReceipt ==
                        LinkedCorrectionAuditSource.originalFor(
                          filing.rceptNo,
                        ) &&
                    html.correctionReceipt == filing.rceptNo &&
                    html.correctionSource ==
                        Uri.parse(
                          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${filing.rceptNo}',
                        );
                if ((!verifiedLinkedAudit &&
                        (html.sourceReceipt != filing.rceptNo ||
                            html.correctionReceipt != null ||
                            html.correctionSource != null)) ||
                    html.periodEnd != end) {
                  throw const FormatException(
                    'Exact annual HTML source identity mismatch',
                  );
                }
                final rows = PublicFinancialHtml.parseStandardAnnual(
                  issuerProof: html.issuerProof,
                  coverHtml: html.coverHtml,
                  statementHtml: html.statementHtml,
                  coverSource: html.coverSource,
                  statementSource: html.statementSource,
                  receipt: html.sourceReceipt,
                  corpCode: company.corpCode,
                  companyName: company.name,
                  periodStart: html.periodStart,
                  periodEnd: end,
                  consolidated: div == FsDiv.consolidated,
                );
                fallback = (
                  rows: rows,
                  source: html.statementSource,
                  digest: html.sourceDigest,
                  sourceFiling: verifiedLinkedAudit
                      ? await _verifiedAttachmentSource(
                          filing,
                          company,
                          html.sourceReceipt,
                        )
                      : filing,
                  correctionSource: html.correctionSource,
                  format: 'html',
                  coverSource: html.coverSource,
                );
              } on PublicFinancialHtmlBasisNotApplicable catch (absence) {
                final period = DartReportName.parse(filing.reportName)!;
                final end = DateTime.utc(
                  period.periodYear,
                  period.periodMonth + 1,
                  0,
                );
                bool bound(Uri uri) =>
                    uri.scheme == 'https' &&
                    uri.host == 'dart.fss.or.kr' &&
                    uri.path == '/report/viewer.do' &&
                    uri.queryParameters['rcpNo'] == filing.rceptNo &&
                    RegExp(r'^\d+$')
                        .hasMatch(uri.queryParameters['dcmNo'] ?? '');
                if ((absence.issuerProof != null &&
                        absence.issuerIdentityEvidence == null) ||
                    div != FsDiv.consolidated ||
                    absence.sourceReceipt != filing.rceptNo ||
                    absence.corpCode != company.corpCode ||
                    absence.reportName != filing.reportName ||
                    absence.periodEnd != end ||
                    !bound(absence.coverSource) ||
                    !bound(absence.statementSource) ||
                    absence.coverSource.queryParameters['dcmNo'] !=
                        absence.statementSource.queryParameters['dcmNo']) {
                  error = 'Unbound explicit source basis absence';
                  failed = true;
                } else {
                  verifiedBasisNotApplicable = absence;
                }
              } catch (sourceError) {
                if (sourceError is KnownAnnualSourceConflict) {
                  await _recordKnownSourceConflict(
                    filing,
                    company,
                    div,
                    sourceError,
                  );
                }
                final detail = sourceError is FormatException
                    ? sourceError.message.toString().replaceAll(
                        RegExp(r'[\r\n\x00-\x1f]'),
                        ' ',
                      )
                    : '';
                error =
                    'public annual source verification failed: ${sourceError.runtimeType}${detail.isEmpty ? '' : ': ${detail.substring(0, min(200, detail.length))}'}';
                failed = true;
              }
            } else if (filing.reportName.contains('첨부정정')) {
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
                final parseOriginal =
                    html.sourceReceipt == '20260317000808' &&
                        company.corpCode == '00963000' &&
                        end == DateTime.utc(2025, 12, 31)
                    ? PublicFinancialHtml.parseStandardAnnual
                    : PublicFinancialHtml.parse;
                final rows = parseOriginal(
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
            late ({FilingFetchStatus status, bool inserted}) saved;
            try {
              saved = await _store(
                fallback.sourceFiling,
                company,
                div,
                fallback.rows,
                originalSource: fallback.source,
                originalDigest: fallback.digest,
                originalFormat: fallback.format,
                verifiedAttachmentSource: fallback.correctionSource != null,
              );
            } on DartApiException catch (e) {
              if (!_isCurrentCoreRecovery(filing) ||
                  e.status != 'storedCurrentAmountsMissing') {
                rethrow;
              }
              saved = (status: FilingFetchStatus.failed, inserted: false);
              error =
                  '${FinancialCurrentCoreRecovery.marker}; storedCurrentAmountsMissing: verified current-core recovery rejected';
            }
            result = saved.status;
            if (saved.status == FilingFetchStatus.stored &&
                _isAnnualPublicRecovery(filing)) {
              await _recordVerifiedAnnualNumericSource(
                filing,
                company,
                div,
                sourceReceipt: fallback.sourceFiling.rceptNo,
                source: fallback.source,
                format: fallback.format,
                digest: fallback.digest,
                rows: fallback.rows,
                coverSource: fallback.coverSource,
              );
            }
            if (saved.status == FilingFetchStatus.stored &&
                (filing.rceptNo == LinkedCorrectionAuditSource.target ||
                    filing.rceptNo == LinkedCorrectionAuditSource.bonTarget) &&
                fallback.sourceFiling.rceptNo ==
                    LinkedCorrectionAuditSource.originalFor(filing.rceptNo)) {
              await _recordVerifiedAnnualNumericSource(
                fallback.sourceFiling,
                company,
                div,
                sourceReceipt: fallback.sourceFiling.rceptNo,
                source: fallback.source,
                format: fallback.format,
                digest: fallback.digest,
                rows: fallback.rows,
                coverSource: fallback.coverSource,
              );
            }
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
                coreRows: fallback.rows,
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
          } else if (verifiedBasisNotApplicable != null) {
            final absence = verifiedBasisNotApplicable;
            await _storeVerifiedBasisAbsence(filing, div, absence);
            result = FilingFetchStatus.noData;
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
          lastError: _isCurrentCoreRecovery(filing)
              ? '${FinancialCurrentCoreRecovery.marker}; $error'
              : _isAnnualRecovery(filing)
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

  /// Failed primary-source audit only; never creates financial rows.
  Future<void> _recordKnownSourceConflict(
    DartFiling filing,
    Company company,
    FsDiv div,
    KnownAnnualSourceConflict conflict,
  ) async {
    final proof = conflict.evidence;
    final period = DartReportName.parse(filing.reportName);
    if (proof['receipt'] != filing.rceptNo ||
        proof['corpCode'] != company.corpCode ||
        proof['year'] != filing.bsnsYear ||
        proof['consolidated'] != (div == FsDiv.consolidated) ||
        filing.reportCode != FinancialReportCode.annual ||
        period == null ||
        period.periodYear != proof['year'] ||
        period.periodMonth != 12 ||
        await IngestJobs.isCancelled(session, jobId)) {
      return;
    }
    final reference = 'financial-source-conflict:${filing.rceptNo}:${div.name}';
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@ref))',
        parameters: QueryParameters.named({'ref': reference}),
        transaction: tx,
      );
      if (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(reference),
            transaction: tx,
          ) !=
          null) {
        return;
      }
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: reference,
          url: conflict.evidence['statementSource'] as String,
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'verified-primary-source-conflict',
            'targetReceipt': filing.rceptNo,
            'reportName': filing.reportName,
            'corpCode': company.corpCode,
            'fsDiv': div.name,
            'evidence': conflict.evidence,
            'status': 'failed',
            'financialFactsStored': false,
          }),
        ),
        transaction: tx,
      );
    });
  }

  /// Reuses the exact same typed source-evidence store as normal HTTP recovery.
  Future<void> _recordVerifiedAnnualNumericSource(
    DartFiling filing,
    Company company,
    FsDiv div, {
    required String sourceReceipt,
    required Uri source,
    required String format,
    required String digest,
    required List<Map<String, dynamic>> rows,
    Uri? coverSource,
    Transaction? transaction,
  }) async {
    final reference =
        'financial-api-noData-source:${filing.rceptNo}:${div.name}';
    if (await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(reference),
          transaction: transaction,
        ) ==
        null) {
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: reference,
          url: source.toString(),
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'verified-keyless-annual-source-after-api-noData',
            'targetReceipt': filing.rceptNo,
            'sourceReceipt': sourceReceipt,
            'corpCode': company.corpCode,
            'reportName': filing.reportName,
            'fsDiv': div.name,
            'format': format,
            'sha256': digest,
            'coverSource': coverSource?.toString(),
            'coreRows': rows.length,
            if (BnkSixCoreProfile.storedProof(
              rows,
              sourceDigest: digest,
              sourceUrl: source.toString(),
              companyCode: company.corpCode,
              targetReceipt: filing.rceptNo,
              basis: div.name,
              year: filing.bsnsYear!,
              reportName: filing.reportName,
            )) ...{
              'missingRequiredAccounts': ['revenue'],
              'uncollectedOptionalAccounts': ['capex'],
              'missingReason': '해당 정확원문 전체 손익표에 매출 총액 행 없음; 합산·0 대체 없음',
            },
            if (PureunSixCoreProfile.storedProof(
              rows,
              sourceDigest: digest,
              sourceUrl: source.toString(),
              companyCode: company.corpCode,
              targetReceipt: filing.rceptNo,
              basis: div.name,
              year: filing.bsnsYear!,
              reportName: filing.reportName,
            )) ...{
              'missingRequiredAccounts': ['revenue'],
              'uncollectedOptionalAccounts': ['capex'],
              'missingReason': '해당 정확원문 전체 손익표에 매출 총액 행 없음; 합산·0 대체 없음',
            },
            'coreRowProvenance': [
              for (final row in rows)
                {
                  if (row['html_provenance'] is Map &&
                      (row['html_provenance'] as Map)['partialCoreRule'] ==
                          ImgtExplicitRevenueMissing.ruleFor(
                            filing.rceptNo,
                          )) ...{
                    'rcept_no': row['rcept_no'],
                    'corp_code': row['corp_code'],
                    'bsns_year': row['bsns_year'],
                    'reprt_code': row['reprt_code'],
                    'sj_div': row['sj_div'],
                  },
                  'account_nm': row['account_nm'],
                  'account_id': row['account_id'],
                  'thstrm_amount': row['thstrm_amount'],
                  'currency': row['currency'],
                  'html_provenance': row['html_provenance'],
                  'xbrl_provenance': row['xbrl_provenance'],
                },
            ],
            'note': '공식 원문 핵심계정 부분 수집·전체 재무제표 복구 아님. 원 API 자료없음 기록 및 기존 전체 계정·출처 보존.',
          }),
        ),
        transaction: transaction,
      );
    }
  }

  Future<void> _storeVerifiedBasisAbsence(
    DartFiling filing,
    FsDiv div,
    PublicFinancialHtmlBasisNotApplicable absence, {
    Transaction? transaction,
  }) async {
    final reference =
        'financial-public-basis-not-applicable:${filing.rceptNo}:${div.name}';
    if (await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(reference),
          transaction: transaction,
        ) ==
        null) {
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: reference,
          url: absence.statementSource.toString(),
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'official-exact-annual-consolidated-not-applicable',
            'receipt': absence.sourceReceipt,
            'corpCode': absence.corpCode,
            'reportName': filing.reportName,
            'fsDiv': div.name,
            'coverSource': absence.coverSource.toString(),
            'statementSource': absence.statementSource.toString(),
            'sha256': absence.sourceDigest,
            'periodStart': absence.periodStart.toIso8601String(),
            'periodEnd': absence.periodEnd.toIso8601String(),
            'evidence': absence.evidence,
            if (absence.issuerIdentityEvidence != null)
              'historicalCompanyIdentity': absence.issuerIdentityEvidence,
            'note': '공식 원문에 연결 작성 비적용이 명시됨. 원 API 자료없음 상태 보존; 빈 파싱 결과로 부재를 추정하지 않음.',
          }),
        ),
        transaction: transaction,
      );
    }
  }

  /// A finite raw recomputation, not an additional public/API fetch attempt.
  Future<({int periods, int facts, int failed})> _enrichStoredExactStatements(
    Set<int> scopeIds,
    Map<String, Company> companies,
  ) async {
    var periods = 0, facts = 0, failed = 0;
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.id.inSet(scopeIds) &
          t.rceptNo.inSet({'20250320000036', '20220310001159'}),
    );
    for (final filing in filings) {
      if (await IngestJobs.isCancelled(session, jobId)) break;
      final company = companies[filing.corpCode];
      final basis = filing.rceptNo == '20250320000036'
          ? FsDiv.separate
          : FsDiv.consolidated;
      if (company == null ||
          (basis == FsDiv.separate
                  ? filing.separateStatus
                  : filing.consolidatedStatus) !=
              FilingFetchStatus.stored) {
        continue;
      }
      final report = await FinancialReport.db.findFirstRow(
        session,
        where: (t) => t.rceptNo.equals(filing.rceptNo) & t.fsDiv.equals(basis),
      );
      if (report == null || report.supersededById != null) continue;
      try {
        final prepared = await ExactStatementRows.prepare(
          filing,
          company,
          basis,
        );
        final added = await ExactStatementEnrichment.append(
          session,
          jobId: jobId,
          report: report,
          filing: filing,
          company: company,
          prepared: prepared,
        );
        if (added > 0) {
          periods++;
          facts += added;
        }
      } catch (e, st) {
        failed++;
        session.log(
          '고정 당기 원문 행 보완 실패: ${filing.rceptNo}',
          level: LogLevel.warning,
          exception: e,
          stackTrace: st,
        );
      }
    }
    return (periods: periods, facts: facts, failed: failed);
  }

  Future<({int processed, int failed, int stored, int remaining})>
  _replayVerifiedAnnualSourceCache(
    Set<int> scopeIds,
    Map<String, Company> companies,
  ) async {
    if (await IngestJobs.isCancelled(session, jobId)) {
      return (processed: 0, failed: 0, stored: 0, remaining: 0);
    }
    final entries = VerifiedAnnualSourceRegistry.entries
        .where((e) => corpCode == null || e.corpCode == corpCode)
        .toList();
    final filings = await DartFiling.db.find(
      session,
      where: (t) =>
          t.id.inSet(scopeIds) &
          t.rceptNo.inSet(entries.map((e) => e.receipt).toSet()),
    );
    final candidates = [
      for (final filing in filings)
        for (final entry in entries)
          if (entry.receipt == filing.rceptNo) (filing: filing, entry: entry),
    ];
    var processed = 0, failed = 0, stored = 0, consecutiveFailures = 0;
    for (final candidate in candidates) {
      final f = candidate.filing, entry = candidate.entry;
      if (processed >= 10 ||
          consecutiveFailures >= 6 ||
          await IngestJobs.isCancelled(session, jobId)) {
        break;
      }
      if (!VerifiedAnnualSourceCache.eligibleFor(f, entry)) continue;
      final auditReference = entry.auditReference;
      final company = companies[f.corpCode];
      if (company == null) continue;
      final outcome = await session.db.transaction((tx) async {
        await session.db.unsafeQuery(
          'SELECT pg_advisory_xact_lock(hashtextextended(@reference,0))',
          parameters: QueryParameters.named({
            'reference': auditReference,
          }),
          transaction: tx,
        );
        if (await IngestJobs.isCancelled(session, jobId)) return 'skipped';
        if (await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(auditReference),
              transaction: tx,
            ) !=
            null) {
          return 'skipped';
        }
        final current = await DartFiling.db.findFirstRow(
          session,
          where: (t) => t.id.equals(f.id!),
          transaction: tx,
          lockMode: LockMode.forUpdate,
        );
        final currentCompany = await Company.db.findById(
          session,
          company.id!,
          transaction: tx,
        );
        final active = await session.db.unsafeQuery(
          'WITH ${FinancialCollectionScope.cte} SELECT id FROM financial_scope WHERE id=@id',
          parameters: QueryParameters.named({'id': f.id!}),
          transaction: tx,
        );
        if (current == null ||
            currentCompany == null ||
            active.isEmpty ||
            !VerifiedAnnualSourceCache.eligibleFor(current, entry) ||
            current.companyId != currentCompany.id ||
            currentCompany.corpCode != current.corpCode) {
          return 'skipped';
        }
        PublicFinancialHtmlBasisNotApplicable? verified;
        PublicFinancialHtmlSource? numeric;
        String? rejection;
        try {
          // Any existing numeric CFS source must not be reclassified as absence.
          final existing = await FinancialReport.db.findFirstRow(
            session,
            where: (t) =>
                t.rceptNo.equals(current.rceptNo) & t.fsDiv.equals(entry.basis),
            transaction: tx,
          );
          if (existing != null) {
            throw const FormatException(
              'Cached source conflicts with existing CFS report',
            );
          }
          if (entry.absenceLiteral == null) {
            final orphan = await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:${current.rceptNo}:${entry.basis.name}',
              ),
              transaction: tx,
            );
            if (orphan != null) {
              throw const FormatException(
                'Cached numeric source conflicts with existing period audit',
              );
            }
            numeric = (await _sourceCache.verifyRegistered(
              current,
              currentCompany,
              entry.basis,
            )).numeric;
            if (numeric != null) {
              _rejectUnapprovedGenericPartialCore(numeric.rows);
            }
          } else {
            verified = (await _sourceCache.verifyRegistered(
              current,
              currentCompany,
              entry.basis,
            )).absence;
          }
          if (verified != null) {
            final existingAudits = await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:${current.rceptNo}:${entry.basis.name}',
              ),
              transaction: tx,
            );
            if (existingAudits.length > 1) {
              throw const FormatException(
                'Cached absence existing evidence ambiguous',
              );
            }
            if (existingAudits.isNotEmpty) {
              final audit = existingAudits.single;
              final payload = jsonDecode(audit.title);
              if (audit.kind != SourceKind.dartReport ||
                  audit.url != verified.statementSource.toString() ||
                  payload['receipt'] != verified.sourceReceipt ||
                  payload['corpCode'] != verified.corpCode ||
                  payload['fsDiv'] != entry.basis.name ||
                  payload['periodStart'] !=
                      verified.periodStart.toIso8601String() ||
                  payload['periodEnd'] !=
                      verified.periodEnd.toIso8601String() ||
                  payload['sha256'] != verified.sourceDigest) {
                throw const FormatException(
                  'Cached absence existing source evidence conflict',
                );
              }
            }
          }
        } catch (e) {
          verified = null;
          numeric = null;
          rejection = e is FormatException
              ? e.message.toString()
              : '${e.runtimeType}';
        }
        if (await IngestJobs.isCancelled(session, jobId)) return 'skipped';
        if (numeric != null) {
          var numericFiling = current;
          if (numeric.sourceReceipt != current.rceptNo) {
            final linkedPrimary = Header18LinkedPrimarySource.sourceEligible(
              receipt: current.rceptNo,
              corp: currentCompany.corpCode,
              basis: entry.basis,
              start: numeric.periodStart,
              end: numeric.periodEnd,
              sourceReceipt: numeric.sourceReceipt,
            );
            final linkedAudit =
                LinkedCorrectionAuditSource.eligible(
                  receipt: current.rceptNo,
                  corpCode: currentCompany.corpCode,
                  consolidated: entry.basis == FsDiv.consolidated,
                  start: numeric.periodStart,
                  end: numeric.periodEnd,
                ) &&
                numeric.sourceReceipt ==
                    LinkedCorrectionAuditSource.originalFor(current.rceptNo);
            if (!linkedPrimary && !linkedAudit) {
              throw const FormatException(
                'Cached numeric original receipt unverified',
              );
            }
            numericFiling = await _verifiedAttachmentSource(
              current,
              currentCompany,
              numeric.sourceReceipt,
              transaction: tx,
            );
          }
          final stored = await _store(
            numericFiling,
            currentCompany,
            entry.basis,
            numeric.rows,
            originalSource: numeric.statementSource,
            originalDigest: numeric.sourceDigest,
            originalFormat: 'html',
            transaction: tx,
          );
          if (stored.status != FilingFetchStatus.stored || !stored.inserted) {
            throw const FormatException(
              'Cached annual numeric normal store not inserted',
            );
          }
          await _recordVerifiedAnnualNumericSource(
            current,
            currentCompany,
            entry.basis,
            sourceReceipt: numeric.sourceReceipt,
            source: numeric.statementSource,
            format: 'html',
            digest: numeric.sourceDigest,
            rows: numeric.rows,
            coverSource: numeric.coverSource,
            transaction: tx,
          );
          if (numericFiling.rceptNo != current.rceptNo) {
            await _recordVerifiedAnnualNumericSource(
              numericFiling,
              currentCompany,
              entry.basis,
              sourceReceipt: numeric.sourceReceipt,
              source: numeric.statementSource,
              format: 'html',
              digest: numeric.sourceDigest,
              rows: numeric.rows,
              coverSource: numeric.coverSource,
              transaction: tx,
            );
          }
          _htmlCoreRecovered++;
        }
        final status = numeric != null
            ? 'completed-source-numeric'
            : verified != null
            ? 'completed-source-not-applicable'
            : 'failed';
        await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: auditReference,
            url: DartClient.filingViewerUrl(current.rceptNo).toString(),
            retrievedAt: _clock().toUtc(),
            title: jsonEncode({
              'action': 'one-time-immutable-official-source-cache-revalidation',
              'status': status,
              'manifestDigest': entry.manifestDigest,
              'ruleVersion': entry.ruleVersion,
              'receipt': current.rceptNo,
              'corpCode': current.corpCode,
              'fsDiv': entry.basis.name,
              'publicAttemptPreserved': _annualPublicAttempts(current),
              'generalAttemptPreserved': current.attempts,
              'reportName': current.reportName,
              'failureReason': ?rejection,
              if (verified != null) ...{
                'coverSource': verified.coverSource.toString(),
                'statementSource': verified.statementSource.toString(),
                'sha256': verified.sourceDigest,
                'periodStart': verified.periodStart.toIso8601String(),
                'periodEnd': verified.periodEnd.toIso8601String(),
                'evidence': verified.evidence,
              },
              if (numeric != null) ...{
                'coverSource': numeric.coverSource.toString(),
                'statementSource': numeric.statementSource.toString(),
                'sha256': numeric.sourceDigest,
                'periodStart': numeric.periodStart.toIso8601String(),
                'periodEnd': numeric.periodEnd.toIso8601String(),
                'numericCoreRows': numeric.rows.length,
              },
              'networkRequests': 0,
              'apiCalls': 0,
              'note': '승인된 고정 공식 원문 바이트 재검증 1회; 수집 재시도 한도·기존 숫자·출처 보존',
            }),
          ),
          transaction: tx,
        );
        if (numeric != null) {
          await DartFiling.db.updateRow(
            session,
            current.copyWith(
              consolidatedStatus: entry.basis == FsDiv.consolidated
                  ? FilingFetchStatus.stored
                  : current.consolidatedStatus,
              separateStatus: entry.basis == FsDiv.separate
                  ? FilingFetchStatus.stored
                  : current.separateStatus,
              checkedAt: _clock().toUtc(),
            ),
            transaction: tx,
          );
        } else if (verified != null) {
          await _storeVerifiedBasisAbsence(
            current,
            entry.basis,
            verified,
            transaction: tx,
          );
          await DartFiling.db.updateRow(
            session,
            current.copyWith(
              consolidatedStatus: entry.basis == FsDiv.consolidated
                  ? FilingFetchStatus.noData
                  : current.consolidatedStatus,
              separateStatus: entry.basis == FsDiv.separate
                  ? FilingFetchStatus.noData
                  : current.separateStatus,
              checkedAt: _clock().toUtc(),
            ),
            transaction: tx,
          );
        } else {
          await DartFiling.db.updateRow(
            session,
            current.copyWith(
              lastError:
                  '${current.lastError ?? ''}; verified-source-cache: $rejection',
            ),
            transaction: tx,
          );
        }
        return status;
      });
      if (outcome == 'skipped') continue;
      if (outcome == 'completed-source-numeric') stored++;
      processed++;
      if (outcome == 'failed') {
        failed++;
        consecutiveFailures++;
      } else {
        consecutiveFailures = 0;
      }
    }
    var remaining = 0;
    if (!await IngestJobs.isCancelled(session, jobId)) {
      final active = await session.db.unsafeQuery(
        'WITH ${FinancialCollectionScope.cte} SELECT id FROM financial_scope',
      );
      final activeIds = {for (final row in active) row[0] as int};
      for (final candidate in candidates) {
        if (!activeIds.contains(candidate.filing.id)) continue;
        final current = await DartFiling.db.findById(
          session,
          candidate.filing.id!,
        );
        final company = current?.companyId == null
            ? null
            : await Company.db.findById(session, current!.companyId!);
        if (current != null &&
            company != null &&
            company.corpCode == current.corpCode &&
            company.stockCode != null &&
            companies.containsKey(current.corpCode) &&
            VerifiedAnnualSourceCache.eligibleFor(current, candidate.entry) &&
            await Source.db.findFirstRow(
                  session,
                  where: (t) =>
                      t.reference.equals(candidate.entry.auditReference),
                ) ==
                null) {
          remaining++;
        }
      }
    }
    return (
      processed: processed,
      failed: failed,
      stored: stored,
      remaining: remaining,
    );
  }

  Future<DartFiling> _verifiedAttachmentSource(
    DartFiling target,
    Company company,
    String receipt, {
    Transaction? transaction,
  }) async {
    if (transaction != null) {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtextextended(@receipt,0))',
        parameters: QueryParameters.named({'receipt': receipt}),
        transaction: transaction,
      );
      final all = await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.equals(receipt),
        transaction: transaction,
      );
      if (all.length > 1) {
        throw const FormatException('Ambiguous original receipt ledger');
      }
    }
    final existing = await DartFiling.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(receipt),
      transaction: transaction,
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
      transaction: transaction,
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
    List<Map<String, dynamic>>? coreRows,
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
            if (coreRows != null)
              'coreRowProvenance': [
                for (final row in coreRows)
                  {
                    'account_nm': row['account_nm'],
                    'thstrm_amount': row['thstrm_amount'],
                    'currency': row['currency'],
                    'html_provenance': row['html_provenance'],
                  },
              ],
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

  /// The official linked original proves its period independently of today's
  /// master fiscal month. Verify seven current whole-company core values only;
  /// never claim a full-statement revalidation or rewrite amounts/sources.
  Future<bool> _repairVerifiedOriginalPeriodName(
    FinancialReport existing,
    DartFiling filing,
    Company company,
    FsDiv div,
    List<Map<String, dynamic>> rows,
    Uri verifiedSource,
    String digest,
  ) async {
    final oldPeriod = DartReportName.parse(existing.reportName);
    final actual = DartReportName.parse(filing.reportName);
    if (existing.rceptNo != filing.rceptNo ||
        existing.companyId != company.id ||
        existing.fsDiv != div ||
        existing.reportCode != FinancialReportCode.annual ||
        filing.reportCode != FinancialReportCode.annual ||
        existing.bsnsYear != filing.bsnsYear ||
        oldPeriod == null ||
        actual == null ||
        oldPeriod.kind != DartReportKind.annual ||
        actual.kind != DartReportKind.annual ||
        oldPeriod.periodYear != actual.periodYear ||
        oldPeriod.periodMonth == actual.periodMonth ||
        actual.periodYear != filing.bsnsYear ||
        verifiedSource.scheme != 'https' ||
        verifiedSource.host != 'dart.fss.or.kr' ||
        verifiedSource.path != '/pdf/download/ifrs.do' ||
        verifiedSource.queryParameters['rcp_no'] != filing.rceptNo ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      return false;
    }
    const requiredIds = {
      'ifrs-full_Assets',
      'ifrs-full_Liabilities',
      'ifrs-full_Equity',
      'ifrs-full_Revenue',
      'dart_OperatingIncomeLoss',
      'ifrs-full_ProfitLoss',
      'ifrs-full_CashFlowsFromUsedInOperatingActivities',
    };
    final fresh = FinancialRows.toFacts(
      rows,
      reportId: existing.id!,
      companyId: company.id!,
      bsnsYear: filing.bsnsYear!,
      reportCode: FinancialReportCode.annual,
      fsDiv: div,
      sourceId: existing.sourceId,
    );
    if (fresh.invalidAmounts != 0 ||
        fresh.skippedRows != 0 ||
        fresh.facts.length != 7 ||
        fresh.facts
            .map((f) => f.accountId)
            .toSet()
            .difference(requiredIds)
            .isNotEmpty ||
        !fresh.facts.map((f) => f.accountId).toSet().containsAll(requiredIds)) {
      return false;
    }
    String group(FinancialFact f) => switch (f.statement) {
      FinancialStatementKind.incomeStatement ||
      FinancialStatementKind.comprehensiveIncome => 'income',
      _ => f.statement.name,
    };
    return session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        'SELECT pg_advisory_xact_lock(461101,hashtext(@key))',
        parameters: QueryParameters.named({
          'key': '${company.id}:${filing.bsnsYear}:annual:${div.name}',
        }),
        transaction: tx,
      );
      final current = await FinancialReport.db.findById(
        session,
        existing.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (current == null ||
          current.reportName != existing.reportName ||
          current.sourceId != existing.sourceId ||
          current.bsnsYear != existing.bsnsYear ||
          current.supersededById != null) {
        return false;
      }
      final source = await Source.db.findById(
        session,
        current.sourceId,
        transaction: tx,
      );
      if (source == null ||
          source.kind != SourceKind.dartReport ||
          source.reference != filing.rceptNo ||
          !source.title.startsWith('DART 전체 재무제표 (fnlttSinglAcntAll)')) {
        return false;
      }
      final facts = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(current.id!),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (facts.length != current.factCount ||
          facts.any(
            (f) =>
                f.companyId != company.id ||
                f.bsnsYear != existing.bsnsYear ||
                f.reportCode != existing.reportCode ||
                f.fsDiv != div ||
                f.sourceId != existing.sourceId ||
                f.supersededById != null,
          )) {
        return false;
      }
      if (await FinancialReport.db.count(
                session,
                where: (t) => t.supersededById.equals(current.id!),
                transaction: tx,
              ) >
              0 ||
          await FinancialFact.db.count(
                session,
                where: (t) =>
                    t.supersededById.inSet({for (final f in facts) f.id!}),
                transaction: tx,
              ) >
              0) {
        return false;
      }
      final verified = <Map<String, dynamic>>[];
      for (final expected in fresh.facts) {
        final matches = facts
            .where(
              (f) =>
                  f.accountId == expected.accountId &&
                  group(f) == group(expected) &&
                  (f.accountDetail == null || f.accountDetail == '-'),
            )
            .toList();
        if (matches.length != 1 ||
            expected.amount == null ||
            expected.currency != 'KRW' ||
            matches.single.amount != expected.amount ||
            matches.single.currency != expected.currency) {
          return false;
        }
        verified.add({
          'accountId': expected.accountId,
          'statement': group(expected),
          'amount': expected.amount.toString(),
          'currency': expected.currency,
        });
      }
      BigInt value(String id) =>
          fresh.facts.singleWhere((f) => f.accountId == id).amount!;
      if (value('ifrs-full_Assets') !=
          value('ifrs-full_Liabilities') + value('ifrs-full_Equity')) {
        return false;
      }
      await FinancialReport.db.updateRow(
        session,
        current.copyWith(reportName: filing.reportName),
        transaction: tx,
      );
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: 'financial-report-period-name-repair:${current.id}',
          url: verifiedSource.toString(),
          retrievedAt: _clock().toUtc(),
          title: jsonEncode({
            'action': 'verified-original-period-name-repair',
            'receipt': filing.rceptNo,
            'companyId': company.id,
            'fsDiv': div.name,
            'oldReportName': existing.reportName,
            'verifiedReportName': filing.reportName,
            'originalSourceId': current.sourceId,
            'unchangedFacts': facts.length,
            'verifiedCurrentCore': verified,
            'originalSha256': digest,
            'auditNote': '당기 whole-company 핵심 7계정만 검증; 전체 계정·비교기간 값 재검증 아님. 숫자·Source IDs·정정 연결 보존.',
          }),
        ),
        transaction: tx,
      );
      return true;
    });
  }

  /// DART 요청 제한 초과.
  static const _limitExceeded = '020';

  /// 한 번에 넣는 사실 행 수 (PostgreSQL 파라미터 수 제한 대비).
  static const _insertChunk = 1000;

  Future<bool> _hasCurrentAmounts(FinancialReport report) async =>
      await FinancialFact.db.count(
        session,
        where: (t) =>
            t.reportId.equals(report.id!) &
            (t.amount.notEquals(null) | t.cumulativeAmount.notEquals(null)),
      ) >
      0;

  // Generic six-core parsing remains inspectable, but its storage metadata
  // contract is not approved. Existing separately approved partial profiles
  // have distinct proof markers and are unaffected.
  static void _rejectUnapprovedGenericPartialCore(
    List<Map<String, dynamic>> rows,
  ) {
    for (final row in rows) {
      final provenance = row['html_provenance'];
      final proof = provenance is Map ? provenance['partialCoreProof'] : null;
      if (proof is Map &&
          proof['rule'] == 'source-six-with-unavailable-whole-revenue-v1') {
        throw const FormatException(
          'Generic six-core source storage pending approved partial metadata; collection remains incomplete',
        );
      }
    }
  }

  /// 응답을 저장한다. 같은 접수번호·구분을 이미 저장했으면 넣지 않는다.
  Future<({FilingFetchStatus status, bool inserted})> _store(
    DartFiling filing,
    Company company,
    FsDiv div,
    List<Map<String, dynamic>>? rows, {
    Uri? originalSource,
    String? originalDigest,
    String originalFormat = 'xbrl',
    bool verifiedAttachmentSource = false,
    Transaction? transaction,
  }) async {
    if (rows == null || rows.isEmpty) {
      return (status: FilingFetchStatus.noData, inserted: false);
    }
    _rejectUnapprovedGenericPartialCore(rows);
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
            transaction: transaction,
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
      transaction: transaction,
    );
    if (existing != null) {
      if (existing.companyId != company.id ||
          existing.bsnsYear != filing.bsnsYear ||
          existing.reportCode != filing.reportCode ||
          existing.fsDiv != div ||
          !_sameActualPeriod(existing.reportName, actualFiling.reportName)) {
        if (verifiedAttachmentSource &&
            originalSource != null &&
            originalFormat == 'xbrl' &&
            await _repairVerifiedOriginalPeriodName(
              existing,
              filing,
              company,
              div,
              rows,
              originalSource,
              originalDigest!,
            )) {
          _periodNameMetadataRepaired++;
          return (status: FilingFetchStatus.stored, inserted: false);
        }
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
      if (!await _hasCurrentAmounts(existing) &&
          _isCurrentCoreRecovery(filing) &&
          originalSource != null &&
          originalFormat == 'xbrl' &&
          originalDigest != null &&
          await FinancialCurrentCoreRecovery.append(
            session,
            report: existing,
            filing: actualFiling,
            company: company,
            div: div,
            rows: rows,
            source: originalSource,
            digest: originalDigest,
          )) {
        return (status: FilingFetchStatus.stored, inserted: true);
      }
      if (!await _hasCurrentAmounts(existing)) {
        throw DartApiException(
          'storedCurrentAmountsMissing',
          '기존 재무보고서 당기 금액 미확보; 비교기간 숫자·출처 보존',
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
                transaction: transaction,
              ))?.reportName ??
              filing.reportName.replaceFirst(RegExp(r'^(\[[^\]]+\]\s*)+'), '');
    try {
      if (originalFormat == 'half-xbrl' &&
          await IngestJobs.isCancelled(session, jobId)) {
        return (status: FilingFetchStatus.pending, inserted: false);
      }
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
        transaction: transaction,
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
    Transaction? transaction,
  }) async {
    final now = DateTime.now().toUtc();
    final bsnsYear = filing.bsnsYear!;
    final reportCode = filing.reportCode!;
    final partialCore =
        originalSource != null &&
        rows.any((r) => r['xbrl_partial_core'] == true);
    final explicitMissingRevenue =
        originalFormat == 'html' &&
        ImgtExplicitRevenueMissing.rowsProof(
          rows,
          company.corpCode,
          rceptNo,
          div,
          originalSource,
        );
    final partialNote = explicitMissingRevenue
        ? ' · ${ImgtExplicitRevenueMissing.note}'
        : partialCore
        ? ' · 부분 핵심계정 · 당기순손익 미확보 · '
              '${rows.firstWhere((r) => r['xbrl_partial_core'] == true)['xbrl_collection_note']}'
        : '';
    Future<void> storeInTransaction(Transaction tx) async {
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
              ? '${originalFormat == 'half-xbrl'
                    ? 'DART 원문 XBRL 반기 부분 핵심7계정(손익3개월·누적6개월)'
                    : originalFormat == 'html'
                    ? (BnkSixCoreProfile.storedProof(rows, sourceDigest: originalDigest ?? '', sourceUrl: originalSource.toString(), companyCode: company.corpCode, targetReceipt: rceptNo, basis: div.name, year: bsnsYear, reportName: reportName)
                          ? BnkSixCoreProfile.title
                          : PureunSixCoreProfile.storedProof(rows, sourceDigest: originalDigest ?? '', sourceUrl: originalSource.toString(), companyCode: company.corpCode, targetReceipt: rceptNo, basis: div.name, year: bsnsYear, reportName: reportName)
                          ? PureunSixCoreProfile.title
                          : 'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공)')
                    : 'DART 원문 XBRL 핵심계정'} · $reportName · ${FinancialCodes.fsDivName(div)} · SHA256:$originalDigest$partialNote'
              : 'DART 전체 재무제표 (fnlttSinglAcntAll) · $reportName · '
                    '${FinancialCodes.fsDivName(div)}',
          reference: rceptNo,
          url: (originalSource ?? DartClient.filingViewerUrl(rceptNo))
              .toString(),
          retrievedAt: now,
        ),
        transaction: tx,
      );
      if (originalFormat == 'half-xbrl') {
        await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: 'pending-half-xbrl-source:$rceptNo:${div.name}',
            url: originalSource!.toString(),
            retrievedAt: now,
            title: jsonEncode({
              'action':
                  'verified-keyless-pending-half-after-api-budget-exhaustion',
              'sourceReceipt': rceptNo,
              'corpCode': company.corpCode,
              'reportName': reportName,
              'fsDiv': div.name,
              'sha256': originalDigest,
              'format': 'xbrl',
              'coreRows': rows.length,
              'coreRowProvenance': rows,
              'savedSourceId': source.id,
              'originalBasisStatus':
                  (div == FsDiv.consolidated
                          ? filing.consolidatedStatus
                          : filing.separateStatus)
                      .name,
              'note': '원문 반기 부분 핵심7계정; 손익3개월·누적6개월, 현금흐름6개월. 전체 재무제표 복구 아님; CFS없음 추론 없음',
            }),
          ),
          transaction: tx,
        );
      }
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

      final sourceFilings = await DartFiling.db.find(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.corpCode.equals(company.corpCode) &
            t.bsnsYear.equals(bsnsYear) &
            t.reportCode.equals(reportCode),
        transaction: tx,
      );
      final verifiedReceipts = {
        for (final f in sourceFilings)
          if (_sameActualPeriod(f.reportName, reportName)) f.rceptNo,
      };
      final rivals = candidates
          .where(
            (r) =>
                verifiedReceipts.contains(r.rceptNo) &&
                _sameActualPeriod(r.reportName, reportName),
          )
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
    }

    if (transaction != null) {
      await storeInTransaction(transaction);
    } else {
      await session.db.transaction(storeInTransaction);
    }
  }

  Future<T> _callDart<T>(Future<T> Function() call) async {
    try {
      return await call();
    } finally {
      await Future<void>.delayed(callInterval);
    }
  }
}
