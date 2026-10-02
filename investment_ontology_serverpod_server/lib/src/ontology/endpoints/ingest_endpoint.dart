import '../ingest/latest_business_body_coverage.dart';

import 'dart:convert';

import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import '../disclosure/business_text_repair.dart';
import '../data_go_kr/data_go_kr_service_key.dart';
import '../disclosure/disclosure_links.dart';
import '../disclosure/production_facts.dart';
import '../disclosure/rnd_facts.dart';
import '../disclosure/supplier_relations.dart';
import '../ingest/api_call_budget.dart';
import '../ingest/company_master_sync.dart';
import '../ingest/disclosure_sync.dart';
import '../ingest/financial_facts_sync.dart';
import '../ingest/business_collection_scope.dart';
import '../ingest/market_collection_coverage.dart';
import '../ingest/ingest_jobs.dart';
import '../ingest/ingest_hooks.dart';
import '../ingest/market_snapshot_sync.dart';
import '../ingest/market_security_relink.dart';

/// 외부 원천 수집 제어.
///
/// 로그인 사용자는 상태를 읽고, 관리자는 수집 실행·취소·재계산을 요청한다.
class IngestEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {Scope.admin};

  /// 상장사 마스터 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 평소에는 DART 변경일이 바뀐 기업만 다시 받는다. [force]이거나 마지막 전체
  /// 갱신 후 [CompanyMasterSync.fullRefreshInterval]이 지났으면 전체를 다시 받는다.
  Future<IngestJob> startCompanyMaster(
    Session session, {
    bool? force,
  }) async {
    OntologyAccess.requireAdmin(session);
    _requireDartKey(session);

    final running = await IngestJobs.running(session, CompanyMasterSync.kind);
    if (running != null) return running;

    final full =
        (force ?? false) || await CompanyMasterSync.isFullRefreshDue(session);
    return IngestJobs.startAndSchedule(
      session,
      CompanyMasterSync.kind,
      (job) => IngestHooks.require(
        IngestHooks.companyMasterNow,
        'companyMasterNow',
      )(session, job.id!, full),
      fullRefresh: full,
    );
  }

  /// 재무제표 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 공시 목록에서 새 정기보고서를 찾고, 받지 않은 보고서를 최신순으로 받는다.
  /// DART 일일 호출 예산을 다 쓰면 멈추고 다음 날 이어서 받는다.
  /// [corpCode]를 주면 그 기업의 정기보고서만 찾아 바로 받는다. 전체 수집이 돌고 있어도 된다.
  Future<IngestJob> startFinancials(Session session, {String? corpCode}) async {
    OntologyAccess.requireAdmin(session);
    _requireDartKey(session);
    // 기업 하나 수집은 따로 세어, 전체 백필이 도는 중에도 바로 받을 수 있게 한다.
    final kind = corpCode == null
        ? FinancialFactsSync.kind
        : FinancialFactsSync.companyKind;
    return IngestJobs.startAndSchedule(session, kind, (job) async {
      if (corpCode == null) {
        await IngestHooks.require(IngestHooks.financialsNow, 'financialsNow')(
          session,
          job.id!,
        );
      } else {
        await IngestHooks.require(
          IngestHooks.financialsForCompanyNow,
          'financialsForCompanyNow',
        )(session, job.id!, corpCode);
      }
    });
  }

  /// 정기보고서 주요정보(주주·임원·출자·배당 등 28종) 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 재무 수집이 장부에 넣은 사업보고서의 항목을 최신 사업연도·핵심 항목부터 받는다.
  /// 재무 백필이 남아 있으면 최신 사업연도의 핵심 항목만 받는다.
  /// [corpCode]를 주면 그 기업의 사업보고서 항목만 바로 받는다.
  Future<IngestJob> startDisclosures(
    Session session, {
    String? corpCode,
  }) async {
    OntologyAccess.requireAdmin(session);
    _requireDartKey(session);
    final kind = corpCode == null
        ? DisclosureSync.kind
        : DisclosureSync.companyKind;
    // 로컬은 예약 실행이 꺼져 있다. 명시적인 관리자 기업 수집은 요청 안에서
    // 실행하고, 전체 자동 수집 설정은 변경하지 않는다.
    if (corpCode != null &&
        !session.serverpod.config.futureCallExecutionEnabled) {
      final result = await IngestJobs.startOrRunning(session, kind);
      if (!result.created) {
        // 이전 버전이 남긴 동일 기업의 미실행 예약만 원자적으로 인수한다.
        final claimed = await session.db.transaction((tx) async {
          final entries = await sp.FutureCallEntry.db.find(
            session,
            where: (t) => t.name.equals('DisclosureRunCompanyFutureCall'),
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          for (final entry in entries) {
            final args = jsonDecode(entry.serializedObject ?? '{}');
            if (args is Map &&
                args['jobId'] == result.job.id &&
                args['corpCode'] == corpCode) {
              await sp.FutureCallEntry.db.deleteRow(
                session,
                entry,
                transaction: tx,
              );
              return true;
            }
          }
          return false;
        });
        if (!claimed) return result.job;
      }
      await DisclosureSync(
        session,
        DartClient(DartApiKey.read(session)!),
        result.job.id!,
        corpCode: corpCode,
      ).run();
      return (await IngestJobs.latest(session, kind))!;
    }
    return IngestJobs.startAndSchedule(session, kind, (job) async {
      if (corpCode == null) {
        await IngestHooks.require(IngestHooks.disclosuresNow, 'disclosuresNow')(
          session,
          job.id!,
        );
      } else {
        await IngestHooks.require(
          IngestHooks.disclosuresForCompanyNow,
          'disclosuresForCompanyNow',
        )(session, job.id!, corpCode);
      }
    });
  }

  /// 주요정보 28종과 별도로 과거 5년 사업 본문과 최신 분기·반기 본문을 받는다.
  Future<IngestJob> startBusinessDocuments(Session session) async {
    OntologyAccess.requireAdmin(session);
    _requireDartKey(session);
    return IngestJobs.startAndSchedule(
      session,
      DisclosureSync.businessKind,
      (job) => IngestHooks.require(
        IngestHooks.businessDocumentsNow,
        'businessDocumentsNow',
      )(session, job.id!),
    );
  }

  /// 주요정보의 인물 연결과 관계 색인을 다시 만든다 (DART 호출 없음). 연결 규칙을 고친 뒤 쓴다.
  Future<String> rebuildDisclosureLinks(Session session) async {
    OntologyAccess.requireAdmin(session);
    final r = await DisclosureLinks(session).rebuild();
    return '관계 ${r.relations}건, 추정 인물 연결 ${r.estimatedLinks}건';
  }

  /// 시세 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 받지 않은 평일 기준일을 최신순으로 받고(처음에는 5년), 가장 최근 기준일의
  /// 상장종목 정보로 종목을 기업에 잇는다.
  Future<IngestJob> startMarketSnapshot(Session session) async {
    OntologyAccess.requireAdmin(session);
    if (DataGoKrServiceKey.read(session) == null) {
      throw IngestException(
        message: DataGoKrServiceKey.secret.missingMessage('공공데이터포털 서비스'),
      );
    }
    return IngestJobs.startAndSchedule(
      session,
      MarketSnapshotSync.kind,
      (job) => IngestHooks.require(
        IngestHooks.marketSnapshotNow,
        'marketSnapshotNow',
      )(session, job.id!),
    );
  }

  Future<IngestJob?> cancel(Session session, int jobId) async {
    OntologyAccess.requireAdmin(session);
    return IngestJobs.cancel(session, jobId);
  }

  /// 수집 현황. 층마다 얼마나 받았는지 한 번에 센다.
  Future<IngestCoverage> coverage(Session session) async {
    final rows = await session.db.unsafeQuery('''
      WITH ${BusinessCollectionScope.cte}
      SELECT
        (SELECT count(*) FROM company WHERE "stockCode" IS NOT NULL),
        (SELECT count(DISTINCT r."companyId") FROM financial_report r
           JOIN company c ON c.id = r."companyId" WHERE c."stockCode" IS NOT NULL),
        (SELECT count(*) FROM financial_scope),
        (SELECT count(*) FROM financial_scope
           WHERE "consolidatedStatus" IN ('pending', 'failed')
              OR "separateStatus" IN ('pending', 'failed')
              OR ("consolidatedStatus"='stored' AND NOT consolidated_period_stored)
              OR ("separateStatus"='stored' AND NOT separate_period_stored)),
        (SELECT count(*) FROM dart_filing_section WHERE "yearRank" = 0 AND tier = 0),
        (SELECT count(*) FROM dart_filing_section
           WHERE "yearRank" = 0 AND tier = 0 AND status IN ('stored', 'noData')),
        (SELECT count(*) FROM dart_filing_section WHERE section <> 'businessContent'),
        (SELECT count(*) FROM dart_filing_section WHERE section <> 'businessContent' AND status IN ('stored', 'noData')),
        (SELECT count(*) FROM dart_filing_section WHERE section <> 'businessContent' AND status = 'failed'),
        (SELECT count(DISTINCT "companyId") FROM dart_filing_section WHERE section <> 'businessContent' AND status = 'stored'),
        (SELECT count(*) FROM ontology_relation),
        (SELECT count(*) FROM person),
        (SELECT count(DISTINCT "companyId") FROM business_document),
        (SELECT count(DISTINCT "companyId") FROM business_digest_section),
        (SELECT count(*) FROM latest_period lp
          JOIN dart_filing f ON f.id=lp.id
          WHERE ${LatestBusinessBodyCoverage.existsSql('f')}),
        (SELECT count(*) FROM financial_scope WHERE
          ("consolidatedStatus"='stored' AND consolidated_period_stored)
          OR ("separateStatus"='stored' AND separate_period_stored)),
        (SELECT count(*) FROM financial_scope WHERE "consolidatedStatus"='noData' AND "separateStatus"='noData'),
        (SELECT count(*) FROM financial_scope WHERE "consolidatedStatus"='failed' OR "separateStatus"='failed'),
        (SELECT count(*) FROM financial_scope WHERE "consolidatedStatus"='pending' OR "separateStatus"='pending'
          OR ("consolidatedStatus"='stored' AND NOT consolidated_period_stored)
          OR ("separateStatus"='stored' AND NOT separate_period_stored)),
        (SELECT count(*) FROM business_scope),
        (SELECT count(*) FROM business_scope WHERE body_stored),
        (SELECT count(*) FROM business_scope WHERE NOT body_stored AND NOT (body_status IN ('failed','unsupported') OR (body_status='noData' AND body_attempts>=${DisclosureSync.maxAttempts}))),
        (SELECT count(*) FROM business_scope WHERE NOT body_stored AND (body_status IN ('failed','unsupported') OR (body_status='noData' AND body_attempts>=${DisclosureSync.maxAttempts})))
    ''');
    final v = [for (final x in rows.first) (x as int?) ?? 0];
    final market = await MarketCollectionCoverage.read(session);
    return IngestCoverage(
      listedCompanies: v[0],
      companiesWithFinancials: v[1],
      filingsTotal: v[2],
      filingsPending: v[3],
      prioritySections: v[4],
      prioritySectionsDone: v[5],
      sections: v[6],
      sectionsDone: v[7],
      sectionsFailed: v[8],
      companiesWithDisclosures: v[9],
      relations: v[10],
      persons: v[11],
      companiesWithBusinessText: v[12],
      companiesWithDigest: v[13],
      companiesWithLatestBusinessText: v[14],
      financialStoredFilings: v[15],
      financialNoDataFilings: v[16],
      financialFailedFilings: v[17],
      financialPendingFilings: v[18],
      bodyScopeTotal: v[19],
      bodyScopeStored: v[20],
      bodyScopePending: v[21],
      bodyScopeFailed: v[22],
      marketLatestPriceDate: market.latestPriceDate,
      marketLatestPriceSecurities: market.latestPriceSecurities,
      marketLatestIndexDate: market.latestIndexDate,
      marketLatestIndexCount: market.latestIndexCount,
      marketScopeStart: market.scopeStart,
      marketScopeThrough: market.scopeThrough,
      marketExpectedWeekdays: market.expectedWeekdays,
      marketPriceDaysStored: market.priceDaysStored,
      marketIndexDaysStored: market.indexDaysStored,
      marketHistoricalPendingDates: market.historicalPendingDates,
      marketRecentUnconfirmedDates: market.recentUnconfirmedDates,
      dartCallsToday: await ApiCallBudget.usedToday(session, ApiProvider.dart),
      dartDailyLimit: ApiCallBudget.dartDailyLimit,
      dartFinancialBudget: ApiCallBudget.dartFinancialBudget,
      dartDisclosurePriorityBudget: ApiCallBudget.dartDisclosurePriorityBudget,
    );
  }

  Future<IngestJob?> latest(Session session) =>
      IngestJobs.latest(session, CompanyMasterSync.kind);

  /// [kind]의 최근 작업 (`company_master`, `financial_facts`, `market_snapshot`, `disclosures` …).
  Future<IngestJob?> latestOf(Session session, String kind) =>
      IngestJobs.latest(session, kind);

  /// 자동 수집의 예약과 마지막 실행. 데이터 화면이 "돌고 있음 · 대기 중(다음 실행) · 끝남"을
  /// 한눈에 보이는 데 쓴다. 예약 식별자는 [IngestSchedule]과 같다 (그 파일은 생성 코드를
  /// 참조하므로 여기서 가져오지 않는다).
  Future<List<IngestScheduleEntry>> schedule(Session session) async {
    const plan = [
      (
        CompanyMasterSync.kind,
        '기업 기본정보',
        '매일 08:30 · 신규·변경 기업, 30일마다 전체 갱신',
        'company_master_daily',
        'company_master_resume',
      ),
      (
        MarketSnapshotSync.kind,
        '시세',
        '매일 18:00',
        'market_snapshot_daily',
        'market_snapshot_resume',
      ),
      (
        MarketSecurityRelink.kind,
        '기존 종목 재연결',
        '기업 기본정보 변경 후 · 시세 API 호출 없음',
        'market_security_relink_now',
        MarketSecurityRelink.resumeId,
      ),
      (
        FinancialFactsSync.kind,
        'DART 재무',
        '매일 18:30 (한도를 다 쓰면 다음 날 00:10에 이어서)',
        'financial_facts_daily',
        'financial_facts_resume',
      ),
      (
        DisclosureSync.businessKind,
        '사업 본문',
        '매일 18:45 · 과거 5년 사업보고서와 최신 분기·반기',
        'business_documents_daily',
        'business_documents_resume',
      ),
      (
        DisclosureSync.kind,
        'DART 주요정보',
        '매일 19:00 (한도를 다 쓰면 다음 날 00:05에 이어서)',
        'disclosures_daily',
        'disclosures_resume',
      ),
    ];
    final calls = await sp.FutureCallEntry.db.find(
      session,
      where: (t) => t.identifier.inSet({
        for (final p in plan) ...{p.$4, p.$5},
      }),
    );
    final out = <IngestScheduleEntry>[];
    for (final (kind, label, timing, dailyId, resumeId) in plan) {
      DateTime? next;
      var resuming = false;
      for (final c in calls) {
        if (c.identifier != dailyId && c.identifier != resumeId) continue;
        if (next == null || c.time.isBefore(next)) {
          next = c.time;
          resuming = c.identifier == resumeId;
        }
      }
      out.add(
        IngestScheduleEntry(
          kind: kind,
          label: label,
          timing: timing,
          nextRunAt: next,
          resuming: resuming,
          lastJob: await IngestJobs.latest(session, kind),
        ),
      );
    }
    return out;
  }

  /// 여러 종류의 마지막 작업을 한 번에. 앱이 15초마다 부르므로 왕복을 한 번으로 줄인다.
  /// 없는 종류는 빠지므로 `kind`로 맞춰 읽는다.
  Future<List<IngestJob>> latestOfKinds(
    Session session,
    List<String> kinds,
  ) async => [
    for (final kind in kinds) ?await IngestJobs.latest(session, kind),
  ];

  /// 이미 받아 둔 본문에서 생산능력·생산실적·가동률 표를 다시 읽는다 (호출 없음).
  ///
  /// 규칙을 고친 뒤 되돌려 읽을 때 쓴다. 사람이 이미 결정한 항목은 건드리지 않는다.
  Future<String> rebuildProductionFacts(
    Session session, {
    String? corpCode,
  }) async {
    OntologyAccess.requireAdmin(session);
    final company = corpCode == null
        ? null
        : await Company.db.findFirstRow(
            session,
            where: (t) => t.corpCode.equals(corpCode),
          );
    if (corpCode != null && company == null) return '기업을 찾지 못했습니다.';
    final clause = company == null ? '' : 'WHERE "companyId" = ${company.id!}';
    // 본문 하나가 수십만 자다. 전부 메모리에 올리지 않고 한 건씩 읽는다.
    final ids = [
      for (final r in await session.db.unsafeQuery(
        'SELECT id FROM business_document $clause ORDER BY id',
      ))
        r[0] as int,
    ];
    final keys = await ProductionFacts.listedKeys(session);
    // 상장사 목록은 한 번만 읽는다 (문서마다 다시 읽으면 3,000번이 된다).
    final listed = await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
    );
    var stored = 0, links = 0, repaired = 0;
    // A targeted replay also repairs malformed legacy text, with the existing
    // DART budget and admin gate. Global offline replay never makes API calls.
    final key = company == null ? null : DartApiKey.read(session);
    final dart = key == null ? null : DartClient(key);
    final meter = dart == null
        ? null
        : ApiCallMeter(ApiProvider.dart, () => dart.calls);
    try {
      for (final id in ids) {
        final doc = await BusinessDocument.db.findById(session, id);
        if (doc == null) continue;
        if (dart != null &&
            doc.text.contains('\uFFFD') &&
            !await ApiCallBudget.reached(
              session,
              ApiProvider.dart,
              ApiCallBudget.dartDailyLimit,
            )) {
          try {
            if (await BusinessTextRepair.repair(
              session,
              doc,
              dart.fetchDocument,
            )) {
              repaired++;
            }
          } finally {
            await meter!.flush(session);
          }
        }
        stored += await ProductionFacts.store(session, doc, companyKeys: keys);
        stored += await RndFacts.store(session, doc);
        links += await SupplierRelations.store(session, doc, listed: listed);
      }
    } finally {
      dart?.close();
    }
    return '본문 ${ids.length}건에서 값 $stored건, 공급 관계 $links건을 읽었습니다. 원문 $repaired건 복구.';
  }

  static void _requireDartKey(Session session) {
    if (DartApiKey.read(session) == null) {
      throw IngestException(
        message: DartApiKey.secret.missingMessage('DART API'),
      );
    }
  }
}
