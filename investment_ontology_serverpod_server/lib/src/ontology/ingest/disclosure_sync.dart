import '../business/business_profiles.dart';
import '../peers/peer_catalog.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import '../dart/public_business_document.dart';
import '../dart/dart_report_name.dart';
import '../dart/dart_sections.dart';
import '../dart/dart_values.dart';
import '../disclosure/business_text.dart';
import '../disclosure/disclosure_links.dart';
import '../disclosure/disclosure_rows.dart';
import '../disclosure/disclosure_values.dart';
import '../disclosure/production_facts.dart';
import '../disclosure/rnd_facts.dart';
import '../disclosure/supplier_relations.dart';
import '../market/market_caps.dart';
import 'api_call_budget.dart';
import 'financial_facts_sync.dart';
import 'financial_collection_scope.dart';
import 'financial_rows.dart';
import 'ingest_jobs.dart';

/// DART 정기보고서 주요정보(주주·임원·출자·배당·자기주식 … 28종)를 수집한다.
///
/// 1. 재무 수집이 쌓은 [DartFiling] 장부의 사업보고서마다 28개 항목을 [DartFilingSection]에 넣는다.
/// 2. 받지 않은 (보고서, 항목)을 기업마다 최근 사업보고서 → 핵심 항목(tier 0) 순으로 받는다.
/// 3. 원문 행([DisclosureRow])과 타입 층(주주·임원·출자·배당·자기주식)을 저장하고,
///    끝나면 [DisclosureLinks]로 인물·관계 색인을 다시 만든다 (호출 없음).
///
/// 재무 백필이 남아 있으면 기업마다 가장 최근 사업보고서의 핵심 항목만 [priorityBudget]까지 받는다.
/// 결산월이 기업마다 달라 "가장 최근"은 기업별로 정한다 ([DartFilingSection.yearRank]).
class DisclosureSync {
  DisclosureSync(
    this.session,
    this.dart,
    this.jobId, {
    int? dailyBudget,
    this.priorityBudget = ApiCallBudget.dartDisclosurePriorityBudget,
    this.businessBudget = defaultBusinessBudget,
    this.publicFallbackEnabled = true,
    PublicBusinessDocument? publicDocuments,
    this.callInterval = const Duration(milliseconds: 200),
    this.scheduleResume,
    this.corpCode,
    DateTime Function()? clock,
  }) : dailyBudget =
           dailyBudget ??
           // 기업 하나(28회)는 기업마스터처럼 DART 전체 한도 안에서 바로 받는다.
           (corpCode == null
               ? ApiCallBudget.dartDisclosureBudget
               : ApiCallBudget.dartDailyLimit - 100),
       _clock = clock ?? DateTime.now,
       _publicDocuments = publicDocuments ?? PublicBusinessDocument();

  /// 재무 백필이 끝나기를 기다리면 본문이 몇 주 동안 안 쌓이므로, 백필 중에도
  /// 기업별 최신 정기보고서 본문을 핵심 주요정보보다 먼저 받는다. 전체 기업의
  /// 최신 본문이 300건 상한에 막히지 않도록 공용 우선수집 몫 안에서 처리한다.
  static const defaultBusinessBudget =
      ApiCallBudget.dartDisclosurePriorityBudget;

  static const kind = 'disclosures';

  /// 기업 하나만 받는 수집.
  static const companyKind = 'disclosures_company';

  /// (보고서, 항목)별 실패 허용 횟수. 실패는 다음 실행에서 다시 받는다.
  static const maxAttempts = 3;

  static const _batch = 500;
  static const _progressEvery = 20;
  static const _insertChunk = 1000;

  final Session session;
  final DartClient dart;
  final int jobId;
  final int dailyBudget;
  final int priorityBudget;

  /// 실행마다 우선수집할 최신 "사업의 내용" 본문 수 (공용 호출 한도 안에서 처리).
  final int businessBudget;
  final bool publicFallbackEnabled;
  final PublicBusinessDocument _publicDocuments;
  int _publicAttempts = 0;
  int _publicFailureStreak = 0;

  bool get _canFetchPublic =>
      publicFallbackEnabled &&
      _publicAttempts < businessBudget &&
      _publicFailureStreak < 6;
  final Duration callInterval;
  final Future<void> Function(DateTime at)? scheduleResume;

  /// 지정하면 이 기업의 사업보고서만 받는다 (재무 백필과 관계없이 전 항목).
  final String? corpCode;

  final DateTime Function() _clock;
  late final _meter = ApiCallMeter(ApiProvider.dart, () => dart.calls);

  late int _allowance;
  bool _budgetExhausted = false;

  bool get _hasAllowance {
    if (dart.calls >= _allowance) _budgetExhausted = true;
    return !_budgetExhausted;
  }

  /// 이번 실행에서 한 번만 읽는 상장사 목록 (본문 규칙 추출에 쓴다).
  Set<String>? _companyKeys;
  List<Company>? _listedCompanies;

  /// 이번 실행에서 인물 키 → id (같은 사람을 여러 번 찾지 않도록).
  final _persons = <String, int>{};

  Future<void> run() async {
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) {
      dart.close();
      _publicDocuments.close();
      return;
    }
    var job = claimed;
    var stored = 0, noData = 0, failed = 0, processed = 0;
    try {
      final now = _clock().toUtc();
      final companies = await Company.db.find(
        session,
        where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
      );
      final byId = {for (final c in companies) c.id!: c};
      final only = corpCode == null
          ? null
          : companies.where((c) => c.corpCode == corpCode).firstOrNull;
      if (corpCode != null && only == null) {
        throw StateError('상장사 원장에 없는 기업: $corpCode');
      }
      final byName = DisclosureLinks.companiesByName(companies);

      await _ensureLedger(now, only);
      await _rankYears();
      await _retryFailed(only);

      final backlog = only == null && await _financialBacklog();
      final used = await ApiCallBudget.usedToday(
        session,
        ApiProvider.dart,
        now: now,
      );
      _allowance = dailyBudget - used;
      if (backlog && priorityBudget < _allowance) _allowance = priorityBudget;
      // 재무 백필 중에도 최신 연간 및 중간보고서의 핵심 항목은 받는다.
      final priorityOnly = backlog;

      Expression scope(DartFilingSectionTable t) {
        Expression e = t.status.equals(FilingFetchStatus.pending);
        if (only != null) e = e & t.companyId.equals(only.id!);
        if (priorityOnly) {
          e = e & t.yearRank.equals(0) & t.tier.equals(0);
        }
        return e;
      }

      {
        final n = await _fetchBusinessDocuments(byId, byName, only: only);
        stored += n.stored;
        failed += n.failed;
        processed += n.stored + n.failed;
      }

      final total = await DartFilingSection.db.count(session, where: scope);
      job = await IngestJobs.save(
        session,
        job.copyWith(total: processed + total),
      );

      outer:
      while (true) {
        final batch = await DartFilingSection.db.find(
          session,
          where: scope,
          orderByList: (t) => [
            t.yearRank.asc(),
            t.tier.asc(),
            t.bsnsYear.desc(),
            t.id.asc(),
          ],
          limit: _batch,
        );
        if (batch.isEmpty) break;
        final filings = {
          for (final f in await DartFiling.db.find(
            session,
            where: (t) => t.id.inSet(<int>{for (final s in batch) s.filingId}),
          ))
            f.id!: f,
        };
        for (final item in batch) {
          if (processed % _progressEvery == 0) {
            if (await IngestJobs.isCancelled(session, jobId)) {
              job = job.copyWith(status: IngestStatus.cancelled);
              break outer;
            }
            await _meter.flush(session);
            // 재무 수집이 함께 돌면 시작할 때 계산한 몫만으로는 하루 한도를 넘길 수 있다.
            if (processed > 0 &&
                await ApiCallBudget.reached(
                  session,
                  ApiProvider.dart,
                  dailyBudget,
                )) {
              _budgetExhausted = true;
              break outer;
            }
            job = await IngestJobs.save(
              session,
              job.copyWith(
                processed: processed,
                updated: stored,
                failed: failed,
                apiCalls: dart.calls,
                message: '주요정보 수집 중 · 저장 $stored건, 자료 없음 $noData건',
              ),
            );
          }
          if (!_hasAllowance) break outer;
          final filing = filings[item.filingId];
          final company = filing == null ? null : byId[filing.companyId];
          final result = filing == null || company == null
              ? FilingFetchStatus.unsupported
              : await _fetch(item, filing, company, byName);
          if (_budgetExhausted && result == FilingFetchStatus.pending) {
            break outer;
          }
          switch (result) {
            case FilingFetchStatus.stored:
              stored++;
            case FilingFetchStatus.noData:
              noData++;
            case FilingFetchStatus.failed:
              failed++;
            case FilingFetchStatus.pending || FilingFetchStatus.unsupported:
              break;
          }
          if (result == FilingFetchStatus.unsupported) {
            await DartFilingSection.db.updateRow(
              session,
              item.copyWith(status: FilingFetchStatus.unsupported),
            );
          }
          processed++;
        }
      }
      await _meter.flush(session);

      if (stored > 0) {
        job = await IngestJobs.save(
          session,
          job.copyWith(
            processed: processed,
            updated: stored,
            failed: failed,
            apiCalls: dart.calls,
            message: '관계 색인을 다시 만드는 중 (호출 없음)',
          ),
        );
        await DisclosureLinks(session).rebuild();
      }

      final remainingAll = await DartFilingSection.db.count(
        session,
        where: (t) {
          Expression e = t.status.equals(FilingFetchStatus.pending);
          if (only != null) e = e & t.companyId.equals(only.id!);
          return e;
        },
      );
      final remainingScope = await DartFilingSection.db.count(
        session,
        where: scope,
      );
      final cancelled = job.status == IngestStatus.cancelled;
      var message =
          '저장 $stored건, 자료 없음 $noData건, 실패 $failed건 · 남은 항목 $remainingAll건';
      if (only != null) message = '${only.name}: $message';
      if (priorityOnly) {
        message += remainingScope == 0
            ? ' · 최신 정기보고서의 핵심 항목 완료, 나머지는 재무 백필 뒤에 받음'
            : ' · 재무 백필 중이라 최신 정기보고서의 핵심 항목부터 받는 중';
      }
      if (_budgetExhausted &&
          remainingScope > 0 &&
          !cancelled &&
          only == null) {
        final at = ApiCallBudget.nextKstMidnight(
          now,
          // 재무 재개(00:05)보다 먼저 실행해 최신 지배구조가 매일 굶지 않게 한다.
        ).add(const Duration(minutes: 1));
        await scheduleResume?.call(at);
        message +=
            ' · ${_allowance <= 0 ? '오늘 DART 호출 한도를 다른 수집이 이미 씀' : '오늘 몫의 호출($_allowance건)을 다 씀'}, '
            '${scheduleResume != null ? '다음 날 이어서 받음' : '다음 실행에서 이어서 받음'}';
      }
      await IngestJobs.save(
        session,
        job.copyWith(
          status: cancelled
              ? IngestStatus.cancelled
              : failed > 0
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
        '주요정보 수집 실패',
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
      _publicDocuments.close();
    }
  }

  /// 사업보고서마다 28개 항목의 장부 행을 만든다. 같은 기업·사업연도에 정정공시가 있으면
  /// 가장 늦은 접수번호만 넣는다 (주요정보 API는 그 기간의 최종 보고서 값을 준다).
  Future<void> _ensureLedger(DateTime now, Company? only) async {
    final values = [
      for (final s in DartSection.values)
        "('${s.name}', ${DartSections.of(s).tier})",
    ].join(', ');
    await session.db.unsafeExecute(
      'INSERT INTO "dart_filing_section" '
      '("filingId", "companyId", "bsnsYear", "section", "tier", "status", "attempts") '
      'SELECT f."id", f."companyId", f."bsnsYear", s.section, s.tier, '
      "'${FilingFetchStatus.pending.name}', 0 "
      'FROM (SELECT DISTINCT ON ("companyId", "bsnsYear") * FROM "dart_filing" '
      "WHERE \"reportCode\" = '${FinancialReportCode.annual.name}' "
      'AND "companyId" IS NOT NULL AND "bsnsYear" >= @first '
      '${only == null ? '' : 'AND "companyId" = @company '}'
      'ORDER BY "companyId", "bsnsYear", "rceptNo" DESC) f '
      'CROSS JOIN (VALUES $values) AS s(section, tier) '
      'ON CONFLICT ("filingId", "section") DO NOTHING',
      parameters: QueryParameters.named({
        'first': FinancialFactsSync.firstAnnualYear(now),
        'company': ?only?.id,
      }),
    );
    // 사업 본문과 지배구조 핵심 항목은 최신 연간 이후의 최신 중간보고서도 받는다.
    await session.db.unsafeExecute(
      '''INSERT INTO dart_filing_section
        ("filingId", "companyId", "bsnsYear", section, tier, status, attempts)
      SELECT f.id, f."companyId", f."bsnsYear", s.section, s.tier, 'pending', 0
      FROM (
        SELECT DISTINCT ON ("companyId") * FROM dart_filing
        WHERE "companyId" IS NOT NULL AND "reportCode" IN ('q1','halfYear','q3')
          AND "bsnsYear" >= @first
          ${only == null ? '' : 'AND "companyId" = @company'}
        ORDER BY "companyId", "bsnsYear" DESC,
          CASE "reportCode" WHEN 'q3' THEN 3 WHEN 'halfYear' THEN 2 ELSE 1 END DESC,
          "rceptNo" DESC
      ) f CROSS JOIN (VALUES ('businessContent', 2), ('largestShareholders', 0),
        ('executives', 0), ('investments', 0), ('minorityShareholders', 0)) AS s(section, tier)
      WHERE NOT EXISTS (SELECT 1 FROM dart_filing a
        WHERE a."companyId"=f."companyId" AND a."reportCode"='annual'
          AND a."bsnsYear">=f."bsnsYear")
      ON CONFLICT ("filingId", section) DO NOTHING''',
      parameters: QueryParameters.named({
        'first': FinancialFactsSync.firstAnnualYear(now),
        'company': ?only?.id,
      }),
    );
  }

  /// 기업마다 사업보고서의 최근 순위(0 = 가장 최근)를 매긴다. 새 사업보고서가 들어오면 바뀐다.
  Future<void> _rankYears() async {
    await session.db.unsafeExecute(
      '''UPDATE dart_filing_section s SET "yearRank"=r.rank
      FROM (SELECT d.id, DENSE_RANK() OVER (
        PARTITION BY d."companyId", d.section, (f."reportCode"='annual')
        ORDER BY d."bsnsYear" DESC) - 1 AS rank
        FROM dart_filing_section d JOIN dart_filing f ON f.id=d."filingId") r
      WHERE s.id=r.id AND s."yearRank"<>r.rank''',
    );
  }

  /// 실패한 항목을 재시도 횟수 안에서 다시 대기로 돌린다.
  Future<void> _retryFailed(Company? only) async {
    await session.db.unsafeExecute(
      'UPDATE "dart_filing_section" SET "status" = @pending '
      'WHERE "status" = @failed AND "attempts" < @max '
      '${only == null ? '' : 'AND "companyId" = @company'}',
      parameters: QueryParameters.named({
        'pending': FilingFetchStatus.pending.name,
        'failed': FilingFetchStatus.failed.name,
        'max': maxAttempts,
        'company': ?only?.id,
      }),
    );
  }

  /// 재무 수집이 받을 공시가 남았는지.
  Future<bool> _financialBacklog() async {
    final rows = await session.db.unsafeQuery(
      '''WITH ${FinancialCollectionScope.cte}
      SELECT EXISTS (SELECT 1 FROM financial_scope
        WHERE attempts < @max AND
          ("consolidatedStatus" IN ('pending','failed') OR
           "separateStatus" IN ('pending','failed'))) AS pending''',
      parameters: QueryParameters.named({
        'max': FinancialFactsSync.maxAttempts,
      }),
    );
    return rows.first.toColumnMap()['pending'] as bool;
  }

  /// 재무 백필 중에 기업별 최신 정기보고서의 본문을 [businessBudget]건까지 받는다.
  /// 최신 중간보고서가 있으면 이전 연간 본문은 이 우선수집에서 제외한다.
  ///
  /// 핵심 항목(tier 0)과 몫을 나눠 쓴다. 본문은 관계·값 추출의 재료라 백필이
  /// 끝날 때까지 기다리면 온톨로지가 자라지 않는다.
  Future<({int stored, int failed})> _fetchBusinessDocuments(
    Map<int, Company> byId,
    Map<String, int> byName, {
    Company? only,
  }) async {
    if (businessBudget <= 0 || (!_hasAllowance && !_canFetchPublic)) {
      return (stored: 0, failed: 0);
    }
    // yearRank는 연간/중간보고서별로 계산되므로 둘 다 0일 수 있다.
    // 저장 상태와 무관하게 기업의 최신 기간·정정 접수번호를 먼저 확정한다.
    // 최신 본문이 이미 저장됐다고 이전 연간 본문이 우선수집으로 승격되면 안 된다.
    final latest = await session.db.unsafeQuery(
      '''SELECT DISTINCT ON ("companyId") id FROM dart_filing
      WHERE "companyId" IS NOT NULL AND "reportCode" IS NOT NULL
      ORDER BY "companyId", "bsnsYear" DESC,
        CASE "reportCode" WHEN 'annual' THEN 4 WHEN 'q3' THEN 3
          WHEN 'halfYear' THEN 2 ELSE 1 END DESC,
        "rceptNo" DESC''',
    );
    final latestIds = {
      for (final row in latest) row.toColumnMap()['id'] as int,
    };
    if (latestIds.isEmpty) return (stored: 0, failed: 0);
    final pending = await DartFilingSection.db.find(
      session,
      where: (t) =>
          t.status.equals(FilingFetchStatus.pending) &
          t.filingId.inSet(latestIds) &
          t.section.equals(DartSection.businessContent) &
          (only == null
              ? t.companyId.notEquals(null)
              : t.companyId.equals(only.id!)),
    );
    if (pending.isEmpty) return (stored: 0, failed: 0);
    final caps = await MarketCaps.latest(session, {
      for (final s in pending) s.companyId,
    });
    pending.sort((a, b) {
      final x = caps.caps[a.companyId] ?? BigInt.zero;
      final y = caps.caps[b.companyId] ?? BigInt.zero;
      final capOrder = y.compareTo(x);
      return capOrder != 0 ? capOrder : a.filingId.compareTo(b.filingId);
    });
    final filings = {
      for (final f in await DartFiling.db.find(
        session,
        where: (t) => t.id.inSet(<int>{
          for (final s in pending.take(businessBudget)) s.filingId,
        }),
      ))
        f.id!: f,
    };
    var stored = 0, failed = 0;
    var done = 0;
    for (final item in pending.take(businessBudget)) {
      if (!_hasAllowance && !_canFetchPublic) break;
      // 재무 수집과 겹쳐 돌면 시작할 때 계산한 몫만으로는 하루 한도를 넘길 수 있다.
      // 본문은 한 건에 여러 번 부를 수도 있어(정정 공시 되짚기) 자주 확인한다.
      if (done > 0 && done % _progressEvery == 0) {
        await _meter.flush(session);
        if (await ApiCallBudget.reached(
          session,
          ApiProvider.dart,
          dailyBudget,
        )) {
          _budgetExhausted = true;
          if (!_canFetchPublic) break;
        }
      }
      done++;
      if (await IngestJobs.isCancelled(session, jobId)) break;
      final filing = filings[item.filingId];
      final company = filing == null ? null : byId[filing.companyId];
      if (filing == null || company == null) continue;
      final result = await _fetch(item, filing, company, byName);
      if (_budgetExhausted && result == FilingFetchStatus.pending) break;
      if (result == FilingFetchStatus.stored) stored++;
      if (result == FilingFetchStatus.failed) failed++;
    }
    await _meter.flush(session);
    return (stored: stored, failed: failed);
  }

  /// 항목 하나를 받는다. 한도에 닿아 받지 못했으면 pending.
  Future<FilingFetchStatus> _fetch(
    DartFilingSection item,
    DartFiling filing,
    Company company,
    Map<String, int> byName,
  ) async {
    final info = DartSections.of(item.section);
    FilingFetchStatus status;
    String? error;
    try {
      if (item.section == DartSection.businessContent) {
        status = await _fetchDocument(item, filing, company);
      } else {
        final rows = await _callDart(
          () => dart.fetchDisclosure(
            api: info.api,
            corpCode: company.corpCode,
            bsnsYear: item.bsnsYear,
            reportCode: FinancialCodes.reportCodeToDart(filing.reportCode!),
          ),
        );
        status = await _store(item, filing, company, rows, byName);
      }
    } on DartApiException catch (e) {
      if (e.status == '020') {
        _budgetExhausted = true;
        return FilingFetchStatus.pending;
      }
      if (e.isFatal || e.status == 'http') rethrow;
      status = FilingFetchStatus.failed;
      error = '${info.label}: $e';
      session.log(
        '주요정보 실패 ${company.corpCode} ${filing.rceptNo} ${info.api}: $e',
        level: LogLevel.warning,
      );
    }
    var next = item.copyWith(
      status: status,
      fetchedAt: DateTime.now().toUtc(),
    );
    if (error != null) {
      next = next.copyWith(lastError: error, attempts: item.attempts + 1);
    }
    await DartFilingSection.db.updateRow(session, next);
    return status;
  }

  Future<FilingFetchStatus> _store(
    DartFilingSection item,
    DartFiling filing,
    Company company,
    List<Map<String, dynamic>>? raw,
    Map<String, int> byName,
  ) async {
    if (raw == null || raw.isEmpty) return FilingFetchStatus.noData;

    // 결산월이 바뀐 리츠처럼 한 사업연도에 정기보고서가 둘이면 두 보고서의 행이 함께 온다.
    // 지금 장부 줄의 접수번호만 남기고, 없으면 가장 최근 접수번호만 남긴다.
    final rceptNos = {for (final r in raw) ?DartValues.text(r['rcept_no'])};
    if (rceptNos.length != 1) {
      if (rceptNos.isEmpty) {
        throw DartApiException('parse', '응답에 접수번호가 없음');
      }
      final pick = rceptNos.contains(filing.rceptNo)
          ? filing.rceptNo
          : (rceptNos.toList()..sort()).last;
      raw = [
        for (final r in raw)
          if (DartValues.text(r['rcept_no']) == pick) r,
      ];
      rceptNos
        ..clear()
        ..add(pick);
    }
    final prepared = DisclosureRows.prepare(raw);
    if (prepared.rows.isEmpty) return FilingFetchStatus.noData;
    for (final r in raw) {
      final corp = DartValues.text(r['corp_code']);
      if (corp != null && corp != company.corpCode) {
        throw DartApiException(
          'mismatch',
          '요청 기업 ${company.corpCode}와 응답 기업 $corp이 다름',
        );
      }
    }
    final rceptNo = rceptNos.single;
    final existing = await DisclosureReport.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(rceptNo) & t.section.equals(item.section),
    );
    if (existing != null) return FilingFetchStatus.stored;

    final executives = item.section == DartSection.executives
        ? await _withPersons(
            DisclosureRows.executives(
              prepared.rows,
              reportId: 0,
              companyId: company.id!,
              bsnsYear: item.bsnsYear,
            ),
          )
        : const <ExecutiveEntry>[];

    try {
      await _insert(
        item,
        company,
        rceptNo,
        raw.first,
        prepared,
        byName,
        executives,
        reportCode: filing.reportCode!,
        reportName: rceptNo == filing.rceptNo
            ? filing.reportName
            : (await DartFiling.db.findFirstRow(
                    session,
                    where: (t) => t.rceptNo.equals(rceptNo),
                  ))?.reportName ??
                  filing.reportName,
      );
    } on DatabaseUniqueViolationException {
      // 기업 하나 수집과 전체 수집이 같은 항목을 동시에 저장하면 늦은 쪽이 여기로 온다.
      return FilingFetchStatus.stored;
    }
    return FilingFetchStatus.stored;
  }

  /// 사업보고서 원본 파일에서 "II. 사업의 내용"을 받아 저장한다.
  ///
  /// 첨부만 고친 정정공시는 원본 파일이 없어(014), 같은 사업연도의 이전 접수번호로 다시 받는다.
  Future<FilingFetchStatus> _fetchDocument(
    DartFilingSection item,
    DartFiling filing,
    Company company,
  ) async {
    final attachmentOnly = filing.reportName.contains("첨부정정");
    final candidates = [
      filing,
      if (attachmentOnly)
        ...await DartFiling.db.find(
          session,
          where: (t) =>
              t.companyId.equals(company.id!) &
              t.bsnsYear.equals(item.bsnsYear) &
              t.reportCode.equals(filing.reportCode) &
              t.rceptNo.notEquals(filing.rceptNo),
          orderByList: (t) => [t.rceptNo.desc()],
        ),
    ];
    // 파일이 없거나(014, null) 파일은 있어도 본문이 아니면(noData — 감사보고서만 든
    // 첨부정정 zip) 다음 후보로 간다. 첨부정정이 두 번이면 첫 zip이 그렇다 (현대제철 FY2025).
    final tried = <String>{};
    for (final f in candidates) {
      if (f.rceptNo.compareTo(filing.rceptNo) > 0) continue;
      final status = await _tryDocument(item, company, f);
      tried.add(f.rceptNo);
      if (status != null && status != FilingFetchStatus.noData) return status;
    }
    // 장부에는 최종 보고서만 있다 (공시 목록을 last_reprt_at=Y로 훑는다). 첨부만 고친
    // 정정공시는 원본 파일이 없어(014) 여기까지 오므로, 그 회사의 같은 해 공시 목록을
    // 한 번 더 물어 원본 사업보고서를 찾는다 — 그러지 않으면 그 해 본문이 통째로 빈다.
    // 원본 공시가 파일이 없으면 정말 없는 것이다. 정정공시일 때만 원본을 찾는다.
    if (!attachmentOnly) return FilingFetchStatus.noData;
    if (!_hasAllowance) return FilingFetchStatus.pending;
    for (final f in await _earlierPeriodFilings(
      filing,
      company,
      item.bsnsYear,
    )) {
      if (tried.contains(f.rceptNo)) continue;
      final status = await _tryDocument(item, company, f);
      if (status != null && status != FilingFetchStatus.noData) return status;
    }
    return FilingFetchStatus.noData;
  }

  /// 공시 하나의 원본을 받아 본문을 저장한다. 파일이 없으면(014) null — 다음 후보로.
  Future<FilingFetchStatus?> _tryDocument(
    DartFilingSection item,
    Company company,
    DartFiling f,
  ) async {
    final existing = await DisclosureReport.db.findFirstRow(
      session,
      where: (t) =>
          t.rceptNo.equals(f.rceptNo) &
          t.section.equals(DartSection.businessContent),
    );
    if (existing != null) return FilingFetchStatus.stored;
    final apiAllowed = _hasAllowance;
    Object? apiFailure;
    StackTrace? apiFailureStack;
    ({String title, String text})? apiDoc;
    if (apiAllowed) {
      try {
        final zip = await _callDart(() => dart.fetchDocument(f.rceptNo));
        if (zip != null) {
          apiDoc = BusinessText.fromZip(zip, f.rceptNo);
          if (apiDoc == null) {
            session.log(
              '사업의 내용 없음 ${company.name} ${f.rceptNo}: '
              '${BusinessText.describeZip(zip)}',
              level: LogLevel.info,
            );
          }
        }
      } catch (e, st) {
        if (e is! DartApiException &&
            e is! http.ClientException &&
            e is! SocketException &&
            e is! TimeoutException) {
          rethrow;
        }
        apiFailure = e;
        apiFailureStack = st;
        if (e is DartApiException && e.status == '020') {
          _budgetExhausted = true;
        }
        session.log(
          'DART 원본 미취득 ${company.name} ${f.rceptNo} '
          'status=${e is DartApiException ? e.status : e.runtimeType}',
          level: LogLevel.warning,
        );
      }
    }
    if (apiDoc != null) {
      await _insertDocument(item, company, f, apiDoc);
      return FilingFetchStatus.stored;
    }
    if (_canFetchPublic) {
      if (await IngestJobs.isCancelled(session, jobId)) {
        return FilingFetchStatus.pending;
      }
      _publicAttempts++;
      final publicInterval = callInterval < const Duration(seconds: 1)
          ? const Duration(seconds: 1)
          : callInterval;
      await Future<void>.delayed(publicInterval);
      late final PublicBusinessBody body;
      try {
        body = await _publicDocuments.fetch(f.rceptNo);
      } catch (e) {
        // Attachment-only receipts may contain solely the changed attachment.
        // Keep real source identity and let the existing same-period fallback run.
        if (e is PublicBusinessNodeMissing && f.reportName.contains('첨부정정')) {
          session.log(
            '첨부정정에 사업 본문 없음 ${company.name} ${f.rceptNo} · 원본 확인',
            level: LogLevel.info,
          );
          return null;
        }
        _publicFailureStreak++;
        if (_publicFailureStreak == 6) {
          session.log(
            "공개 DART 본문 6회 연속 미취득 · 이번 실행 공개 요청 중지",
            level: LogLevel.warning,
          );
        }
        session.log(
          '공개 DART 본문 미취득 ${company.name} ${f.rceptNo} '
          'errorType=${e.runtimeType}',
          level: LogLevel.warning,
        );
        throw DartApiException(
          "publicBody",
          "공개 원문 미취득 · ${e.runtimeType} · 다음 실행 재시도",
        );
      }
      {
        _publicFailureStreak = 0;
        await _insertDocument(
          item,
          company,
          f,
          (title: body.title, text: body.text),
          sourceUri: body.sourceUri,
          bodySha256: body.bodySha256,
        );
        session.log(
          '공개 DART 본문 저장 ${company.name} ${f.rceptNo} '
          'sha256=${body.bodySha256}',
          level: LogLevel.info,
        );
        return FilingFetchStatus.stored;
      }
    }
    if (apiFailure != null) {
      Error.throwWithStackTrace(apiFailure, apiFailureStack!);
    }
    return apiAllowed ? null : FilingFetchStatus.pending;
  }

  /// 정정 이전의 같은 해 사업보고서 (DART 공시 목록, 원본 포함). 최신 것부터.
  Future<List<DartFiling>> _earlierPeriodFilings(
    DartFiling filing,
    Company company,
    int bsnsYear,
  ) async {
    final received = filing.receivedDate;
    if (received == null) return const [];
    final page = await _callDart(
      () => dart.fetchFilings(
        from: received.subtract(const Duration(days: 120)),
        to: received,
        corpCode: company.corpCode,
        lastReportOnly: false,
      ),
    );
    final out = <DartFiling>[];
    for (final it in page.items) {
      if (it.rceptNo.compareTo(filing.rceptNo) >= 0) continue;
      final resolved = DartReportName.parse(
        it.reportName,
      )?.resolve(company.fiscalMonth);
      if (resolved == null ||
          resolved.reportCode !=
              FinancialCodes.reportCodeToDart(filing.reportCode!) ||
          resolved.bsnsYear != bsnsYear) {
        continue;
      }
      out.add(
        DartFiling(
          rceptNo: it.rceptNo,
          corpCode: it.corpCode,
          companyId: company.id,
          reportName: it.reportName,
          receivedDate: it.rceptDate,
          bsnsYear: bsnsYear,
          reportCode: filing.reportCode!,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.noData,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
    }
    out.sort((a, b) => b.rceptNo.compareTo(a.rceptNo));
    return out;
  }

  Future<void> _insertDocument(
    DartFilingSection item,
    Company company,
    DartFiling filing,
    ({String title, String text}) doc, {
    Uri? sourceUri,
    String? bodySha256,
  }) async {
    final period = DartReportName.parse(filing.reportName);
    if (period == null || filing.reportCode == null) {
      throw StateError('정기보고서 기간을 확인할 수 없습니다: ${filing.reportName}');
    }
    final periodEnd = DateTime.utc(
      period.periodYear,
      period.periodMonth + 1,
      0,
    );
    final now = DateTime.now().toUtc();
    await session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title:
              'DART 공시 원본 · ${doc.title} · ${filing.reportName}'
              '${bodySha256 == null ? '' : ' · 공개본문 SHA256=$bodySha256'}',
          reference: filing.rceptNo,
          url: (sourceUri ?? DartClient.filingViewerUrl(filing.rceptNo))
              .toString(),
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.businessContent,
          rceptNo: filing.rceptNo,
          bsnsYear: item.bsnsYear,
          reportCode: filing.reportCode!,
          settlementDate: periodEnd,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: now,
        ),
        transaction: tx,
      );
      await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: item.bsnsYear,
          rceptNo: filing.rceptNo,
          title: doc.title,
          text: doc.text,
          charCount: doc.text.length,
        ),
        transaction: tx,
      );
      final others = await DisclosureReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.bsnsYear.equals(item.bsnsYear) &
            t.reportCode.equals(filing.reportCode) &
            t.section.equals(DartSection.businessContent) &
            t.supersededById.equals(null) &
            t.id.notEquals(report.id!),
        transaction: tx,
      );
      for (final other in others) {
        if (other.rceptNo.compareTo(filing.rceptNo) < 0) {
          await DisclosureReport.db.updateRow(
            session,
            other.copyWith(supersededById: report.id),
            transaction: tx,
          );
        } else {
          // 더 늦은 보고서를 이미 받았다 — 이 보고서가 대체된 쪽이다.
          await DisclosureReport.db.updateRow(
            session,
            report.copyWith(supersededById: other.id),
            transaction: tx,
          );
        }
      }
    });
    // 본문의 생산능력·생산실적·가동률 표는 형식이 일정해 규칙으로 읽는다 (호출 없음).
    final stored = await BusinessDocument.db.findFirstRow(
      session,
      where: (t) => t.rceptNo.equals(filing.rceptNo),
      orderBy: (t) => t.id.desc(),
    );
    if (stored != null) {
      // 상장사 목록·이름 키는 한 실행에서 한 번만 읽는다.
      _companyKeys ??= await ProductionFacts.listedKeys(session);
      _listedCompanies ??= await Company.db.find(
        session,
        where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
      );
      await ProductionFacts.store(session, stored, companyKeys: _companyKeys);
      // 제품 설명은 최신 정기보고서의 제품·서비스를 따른다.
      await BusinessProfiles.store(session, stored);
      // 연간 동종기업/관계 프로필과 R&D 검산은 중간 누적값으로 바꾸지 않는다.
      if (filing.reportCode != FinancialReportCode.annual) return;
      await RndFacts.store(session, stored);
      await PeerProfiles.store(session, stored);
      await SupplierRelations.store(
        session,
        stored,
        listed: _listedCompanies,
      );
    }
  }

  /// 출생년월이 있는 임원을 인물에 잇는다 (없으면 만든다).
  Future<List<ExecutiveEntry>> _withPersons(
    List<ExecutiveEntry> entries,
  ) async {
    final out = <ExecutiveEntry>[];
    for (final e in entries) {
      final y = e.birthYear, m = e.birthMonth;
      final name = DisclosureValues.personName(e.name);
      if (y == null || m == null || name.isEmpty) {
        out.add(e);
        continue;
      }
      final key = DisclosureLinks.executivePersonKey(name, y, m);
      final id =
          _persons[key] ??
          await DisclosureLinks.findOrCreatePerson(
            session,
            Person(
              name: name,
              birthYear: y,
              birthMonth: m,
              sex: e.sex,
              personKey: key,
              estimated: false,
            ),
          );
      _persons[key] = id;
      out.add(e.copyWith(personId: id));
    }
    return out;
  }

  Future<void> _insert(
    DartFilingSection item,
    Company company,
    String rceptNo,
    Map<String, dynamic> first,
    ({List<SourceRow> rows, int empty}) prepared,
    Map<String, int> byName,
    List<ExecutiveEntry> executives, {
    required String reportName,
    required FinancialReportCode reportCode,
  }) async {
    final now = DateTime.now().toUtc();
    final info = DartSections.of(item.section);
    final bsnsYear = item.bsnsYear;
    await session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'DART 정기보고서 주요정보 · ${info.label} (${info.api}) · $reportName',
          reference: rceptNo,
          url: DartClient.filingViewerUrl(rceptNo).toString(),
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: item.section,
          rceptNo: rceptNo,
          bsnsYear: bsnsYear,
          reportCode: reportCode,
          settlementDate: DisclosureValues.date(first['stlm_dt']),
          rowCount: prepared.rows.length,
          emptyRowCount: prepared.empty,
          sourceId: source.id!,
          fetchedAt: now,
        ),
        transaction: tx,
      );
      final reportId = report.id!;

      Future<void> chunked<T extends TableRow>(
        List<T> rows,
        Future<List<T>> Function(List<T> chunk) insert,
      ) async {
        for (var i = 0; i < rows.length; i += _insertChunk) {
          await insert(
            rows.sublist(i, (i + _insertChunk).clamp(0, rows.length)),
          );
        }
      }

      await chunked(
        [
          for (final r in prepared.rows)
            DisclosureRow(
              reportId: reportId,
              ord: r.ord,
              isTotal: r.isTotal,
              rowJson: jsonEncode(r.fields),
            ),
        ],
        (c) => DisclosureRow.db.insert(session, c, transaction: tx),
      );

      final companyId = company.id!;
      switch (item.section) {
        case DartSection.largestShareholders:
          await chunked(
            DisclosureRows.shareholders(
              prepared.rows,
              reportId: reportId,
              companyId: companyId,
              bsnsYear: bsnsYear,
              companiesByName: byName,
            ),
            (c) => ShareholderEntry.db.insert(session, c, transaction: tx),
          );
        case DartSection.executives:
          await chunked(
            [for (final e in executives) e.copyWith(reportId: reportId)],
            (c) => ExecutiveEntry.db.insert(session, c, transaction: tx),
          );
        case DartSection.investments:
          await chunked(
            DisclosureRows.investments(
              prepared.rows,
              reportId: reportId,
              companyId: companyId,
              bsnsYear: bsnsYear,
              companiesByName: byName,
            ),
            (c) => InvestmentEntry.db.insert(session, c, transaction: tx),
          );
        case DartSection.dividend:
          await chunked(
            DisclosureRows.dividends(
              prepared.rows,
              reportId: reportId,
              companyId: companyId,
              bsnsYear: bsnsYear,
            ),
            (c) => DividendEntry.db.insert(session, c, transaction: tx),
          );
        case DartSection.treasuryStock:
          await chunked(
            DisclosureRows.treasuryStock(
              prepared.rows,
              reportId: reportId,
              companyId: companyId,
              bsnsYear: bsnsYear,
            ),
            (c) => TreasuryStockEntry.db.insert(session, c, transaction: tx),
          );
        default:
          break;
      }

      // 같은 기업·사업연도·항목의 이전 보고서(정정 전)는 이 보고서가 대체한다.
      final others = await DisclosureReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(companyId) &
            t.bsnsYear.equals(bsnsYear) &
            t.reportCode.equals(reportCode) &
            t.section.equals(item.section) &
            t.supersededById.equals(null) &
            t.id.notEquals(reportId),
        transaction: tx,
      );
      for (final other in others) {
        if (other.rceptNo.compareTo(rceptNo) < 0) {
          await DisclosureReport.db.updateRow(
            session,
            other.copyWith(supersededById: reportId),
            transaction: tx,
          );
        } else {
          // 더 늦은 보고서를 이미 받았다 — 이 보고서가 대체된 쪽이다.
          await DisclosureReport.db.updateRow(
            session,
            report.copyWith(supersededById: other.id),
            transaction: tx,
          );
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
