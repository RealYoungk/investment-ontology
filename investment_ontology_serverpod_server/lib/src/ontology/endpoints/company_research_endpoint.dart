import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import '../ingest/api_call_budget.dart';
import '../ingest/issuer_financials_sync.dart';
import '../ingest/own_annual_financials_sync.dart';
import '../research/research_feed.dart';
import '../research/research_snapshot_store.dart';
import '../research/issuer_documents_feed.dart';
import '../research/dart_research.dart';
import '../research/kis_research_client.dart';

/// Public source-backed reads populate missing DART cache entries.
/// Explicit collection/import remains admin-only.
class ResearchEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;
  static final _busy = <String>{};
  static KisResearchClient? _kis;
  static final _retryAfter = <String, DateTime>{};
  static final _loading = <String, Future<int>>{};

  Future<String?> _fillMissing(
    Session session,
    String corpCode,
    String kind,
  ) async {
    if (!DartResearch.apis.containsKey(kind)) return null;
    if (DartApiKey.read(session) == null) return 'notConfigured';
    final lock = '$corpCode/$kind';
    final now = DateTime.now().toUtc();
    _retryAfter.removeWhere((_, until) => !until.isAfter(now));
    if (await ApiCallBudget.reached(
      session,
      ApiProvider.dart,
      ApiCallBudget.dartDailyLimit - 100,
    )) {
      return 'budgetExhausted';
    }
    if (_retryAfter.containsKey(lock)) return 'retryLater';
    final existing = _loading[lock];
    if (existing != null) {
      // The originating request owns its Session and completes the cache write.
      try {
        await existing;
        return null;
      } catch (_) {
        return 'retryLater';
      }
    }
    if (_loading.isNotEmpty || _busy.contains(lock)) return 'collecting';
    // Concurrent reads share this request-owned acquisition.
    // ignore: unawaited_futures
    final pending = _collect(session, corpCode, kind, onDemand: true);
    _loading[lock] = pending;
    try {
      await pending;
      return null;
    } catch (e) {
      if (_retryAfter.length >= 512) _retryAfter.remove(_retryAfter.keys.first);
      _retryAfter[lock] = DateTime.now().toUtc().add(
        const Duration(minutes: 5),
      );
      session.log(
        'DART research cache fill failed: $corpCode/$kind (${e.runtimeType})',
        level: LogLevel.warning,
      );
      return 'retryLater';
    } finally {
      // Completed above; removal does not start another asynchronous operation.
      // ignore: unawaited_futures
      _loading.remove(lock);
    }
  }

  Future<Company> _company(Session session, String corpCode) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw IngestException(message: '기업코드 오류');
    }
    final c = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (c == null) throw IngestException(message: '기업을 찾을 수 없습니다.');
    return c;
  }

  Future<String> data(Session session, String corpCode, String kind) async {
    if (!ResearchFeed.kinds.contains(kind) &&
        !DartResearch.apis.containsKey(kind)) {
      throw IngestException(message: '자료 종류 오류');
    }
    final company = await _company(session, corpCode);
    ResearchSnapshot? snapshot;
    try {
      snapshot = await ResearchSnapshot.db.findFirstRow(
        session,
        where: (t) => t.companyId.equals(company.id!) & t.kind.equals(kind),
        orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      );
    } on DatabaseQueryException catch (e) {
      if (e.code != '42P01') rethrow;
      return jsonEncode({
        'state': 'schemaPending',
        'message': '분석 자료 저장소가 아직 적용되지 않았습니다.',
        'rows': [],
      });
    }
    if (snapshot == null) {
      final state = await _fillMissing(session, corpCode, kind);
      if (state == null && DartResearch.apis.containsKey(kind)) {
        snapshot = await ResearchSnapshot.db.findFirstRow(
          session,
          where: (t) => t.companyId.equals(company.id!) & t.kind.equals(kind),
          orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
        );
      }
      if (snapshot == null) {
        return jsonEncode({
          'retryAfterSeconds': state == 'budgetExhausted'
              ? ApiCallBudget.nextKstMidnight(DateTime.now())
                        .difference(DateTime.now().toUtc())
                        .inSeconds +
                    5
              : state == 'collecting'
              ? 5
              : state == 'retryLater'
              ? 300
              : null,
          'state': state ?? 'notCollected',
          'message': switch (state) {
            'notConfigured' => 'DART 연결 설정이 없어 수집을 시작하지 못했습니다.',
            'budgetExhausted' => '오늘 DART 수집 한도를 소진했습니다. 내일 조회 시 다시 수집합니다.',
            'collecting' => '다른 공시 수집이 진행 중입니다. 잠시 후 다시 확인합니다.',
            'retryLater' => '공시 수집을 완료하지 못했습니다. 잠시 후 다시 시도합니다.',
            _ => switch (kind) {
              'issuerAnnualFinancials' =>
                '자체 연간 감사 원문 핵심재무 수집 전입니다. 전체 재무제표와 구분합니다.',
              'issuerFinancials' => '대체 공식 원문 핵심 재무 수집 전입니다. 정기 API 집계와 분리합니다.',
              'issuerDocuments' => '공식 원문 문서 수집 전입니다. 재무 계정은 추출하지 않습니다.',
              'consensus' => '공개 제공이 허용된 컨센서스 공급원을 아직 연결하지 않았습니다.',
              'insiders' || 'majorHoldings' => 'DART 보유변동 보고 수집 전입니다.',
              'capital' || 'treasury' => '최근 5년 주요사항보고서 수집 전입니다.',
              _ => '수급·공매도 API 설정과 서비스 제공 권한 확인 후 수집할 수 있습니다.',
            },
          },
          'rows': [],
        });
      }
    }
    final source = await Source.db.findById(session, snapshot.sourceId);
    if (kind == 'issuerFinancials') {
      final rows = ResearchFeed.validate(kind, jsonDecode(snapshot.payload));
      if (rows.any((r) => r['corpCode'] != corpCode) ||
          source?.kind != SourceKind.officialFile ||
          source?.url != 'https://dart.fss.or.kr' ||
          source?.reference != IssuerFinancialsSync.reference ||
          snapshot.provider != IssuerFinancialsSync.provider) {
        throw IngestException(message: '별도 재무 출처 연결 검증 실패');
      }
    }
    if (kind == 'issuerAnnualFinancials') {
      final rows = ResearchFeed.validate(kind, jsonDecode(snapshot.payload));
      if (rows.any((r) => r['corpCode'] != corpCode) ||
          source?.kind != SourceKind.officialFile ||
          source?.url != 'https://dart.fss.or.kr' ||
          source?.reference != OwnAnnualFinancialsSync.reference ||
          snapshot.provider != OwnAnnualFinancialsSync.provider) {
        throw IngestException(message: '별도 재무 출처 연결 검증 실패');
      }
    }
    return jsonEncode({
      'state': 'ready',
      'provider': snapshot.provider,
      'collectedAt': snapshot.createdAt.toIso8601String(),
      'source': source?.toJson(),
      'rows': jsonDecode(snapshot.payload),
    });
  }

  /// Validation and preview do not write and never fetch a user-supplied URL.
  Future<String> preview(Session session, String kind, String payload) async {
    OntologyAccess.requireAdmin(session);
    return jsonEncode(_rows(kind, payload));
  }

  List<Map<String, dynamic>> _rows(String kind, String payload) {
    if (utf8.encode(payload).length > 2000000) {
      throw IngestException(message: '자료는 2MB 이하로 입력하세요.');
    }
    try {
      return ResearchFeed.validate(kind, jsonDecode(payload));
    } on FormatException catch (e) {
      throw IngestException(message: e.message);
    }
  }

  Future<int> importFeed(
    Session session,
    String corpCode,
    String kind,
    String payload,
    String provider,
    String sourceUrl,
    String rightsReference,
  ) async {
    OntologyAccess.requireAdmin(session);
    if ({'issuerFinancials', 'issuerAnnualFinancials'}.contains(kind)) {
      throw IngestException(message: '별도 재무 숫자는 정상 서버 원문 파서만 저장합니다.');
    }
    final c = await _company(session, corpCode);
    final rows = _rows(kind, payload);
    if (provider.trim().isEmpty ||
        provider.length > 100 ||
        rightsReference.trim().isEmpty ||
        rightsReference.length > 500) {
      throw IngestException(message: '공급원과 공개 제공 권한의 근거를 입력하세요.');
    }
    if (kind == 'issuerDocuments') {
      if (rows.any((r) => r['corpCode'] != corpCode)) {
        throw IngestException(message: '원문 메타데이터의 회사가 다릅니다.');
      }
      final root = Uri.tryParse(sourceUrl);
      if (root == null ||
          root.scheme != 'https' ||
          root.host != IssuerDocumentsFeed.hosts[corpCode] ||
          root.hasPort ||
          RegExp(r'^https://[^/]+:').hasMatch(sourceUrl) ||
          root.userInfo.isNotEmpty ||
          root.hasQuery ||
          root.hasFragment) {
        throw IngestException(message: '공식 회사의 HTTPS 목록 주소가 필요합니다.');
      }
      if (rightsReference !=
          'official-links-metadata-only;no-redistribution-license-asserted') {
        throw IngestException(
          message: '원본 재배포 권한을 주장하지 않는 링크·메타데이터 공개 계약이 필요합니다.',
        );
      }
    }
    final uri = Uri.tryParse(sourceUrl);
    if (uri?.scheme != 'https' ||
        uri!.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        sourceUrl.length > 1000) {
      throw IngestException(message: '출처는 인증정보·쿼리가 없는 HTTPS 주소로 입력하세요.');
    }
    await _checkSecurities(session, c, rows);
    return ResearchSnapshotStore.store(
      session,
      c,
      kind,
      rows,
      provider,
      sourceUrl,
      rightsReference,
      SourceKind.officialFile,
    );
  }

  Future<void> _checkSecurities(
    Session session,
    Company company,
    List<Map<String, dynamic>> rows,
  ) async {
    final securities = await Security.db.find(
      session,
      where: (t) => t.companyId.equals(company.id!),
    );
    final codes = securities.map((s) => s.shortCode).toSet();
    if (rows.any(
      (r) => r['stockCode'] != null && !codes.contains(r['stockCode']),
    )) {
      throw IngestException(message: '자료에 해당 기업 소속이 아닌 종목코드가 있습니다.');
    }
  }

  /// Cursor-based batches cover the listed universe without a long HTTP request.
  /// Re-running a cursor is safe; snapshots are immutable and content-deduplicated.
  Future<String> collectBatch(
    Session session,
    String kind, {
    String afterCorpCode = '',
    int limit = 3,
  }) async {
    OntologyAccess.requireAdmin(session);
    if (!DartResearch.apis.containsKey(kind) ||
        limit < 1 ||
        limit > 5 ||
        (afterCorpCode.isNotEmpty &&
            !RegExp(r'^\d{8}$').hasMatch(afterCorpCode))) {
      throw IngestException(message: '수집 항목·기업코드·묶음 크기를 확인하세요.');
    }
    final companies = await Company.db.find(
      session,
      where: (t) =>
          (t.corpCode > afterCorpCode) &
          t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
      orderBy: (t) => t.corpCode,
      limit: limit,
    );
    final completed = <String>[], failed = <Map<String, String>>[];
    for (final c in companies) {
      try {
        await collect(session, c.corpCode, kind);
        completed.add(c.corpCode);
      } catch (e) {
        failed.add({'corpCode': c.corpCode, 'message': '$e'});
        break;
      }
    }
    return jsonEncode({
      'completed': completed,
      'failed': failed,
      'nextCursor': completed.isEmpty ? afterCorpCode : completed.last,
      'done': failed.isEmpty && companies.length < limit,
    });
  }

  Future<String> connectionStatus(Session session) async {
    OntologyAccess.requireAdmin(session);
    return jsonEncode({
      'dart': DartApiKey.read(session) != null,
      'kis':
          Platform.environment['KIS_APP_KEY']?.isNotEmpty == true &&
          Platform.environment['KIS_APP_SECRET']?.isNotEmpty == true,
      'kisPublicLicense':
          Platform.environment['KIS_PUBLIC_DATA_LICENSE']?.isNotEmpty == true,
      'consensus':
          '공개 제공 계약에 따라 검증된 JSON 자료를 가져오세요. 일반 FnSpace 구독은 공개 재배포를 허용하지 않습니다.',
    });
  }

  Future<int> collect(Session session, String corpCode, String kind) async {
    OntologyAccess.requireAdmin(session);
    return _collect(session, corpCode, kind);
  }

  // Only server-selected DART APIs are reachable from the public cache path.
  // User payloads, URLs, force refreshes, batches and KIS are never accepted there.
  Future<int> _collect(
    Session session,
    String corpCode,
    String kind, {
    bool onDemand = false,
  }) async {
    final budget = onDemand
        ? ApiCallBudget.dartDailyLimit - 100
        : ApiCallBudget.dartDisclosureBudget;
    if (!DartResearch.apis.containsKey(kind) &&
        !{'flows', 'shorts'}.contains(kind)) {
      throw IngestException(message: '자동 수집 대상이 아닙니다.');
    }
    final c = await _company(session, corpCode);
    final lock = '$corpCode/$kind';
    if (!_busy.add(lock)) throw IngestException(message: '이미 수집 중입니다.');
    try {
      // A frozen local snapshot must fail BEFORE using provider quota.
      final mode = await session.db.unsafeQuery('SHOW transaction_read_only');
      if (mode.first.first == 'on') {
        throw IngestException(message: '읽기 전용 DB입니다. 운영 관리자 화면에서 실행하세요.');
      }
      if (DartResearch.apis.containsKey(kind)) {
        final key = DartApiKey.read(session);
        if (key == null) {
          throw IngestException(message: 'DART API 키가 설정되지 않았습니다.');
        }
        if (await ApiCallBudget.reached(session, ApiProvider.dart, budget)) {
          throw IngestException(message: '오늘 DART 수집 예산을 소진했습니다.');
        }
        final dart = DartClient(key);
        final meter = ApiCallMeter(ApiProvider.dart, () => dart.calls);
        try {
          final now = DateTime.now().toUtc();
          final from = DateTime.utc(now.year - 5, now.month, now.day);
          final rows = <Map<String, dynamic>>[];
          for (final api in DartResearch.apis[kind]!) {
            await meter.flush(session);
            if (await ApiCallBudget.reached(
              session,
              ApiProvider.dart,
              budget,
            )) {
              throw IngestException(
                message: '오늘 DART 수집 예산을 소진했습니다. 기존 자료는 유지됩니다.',
              );
            }
            final raw = await dart.fetchResearchDisclosure(
              api,
              corpCode,
              from: from,
              to: now,
            );
            for (final r in raw) {
              if (r['corp_code'] != corpCode) {
                throw const FormatException('다른 기업의 DART 응답');
              }
              final row = DartResearch.normalize(api, r);
              if (DateTime.parse(row['date']).isBefore(from)) continue;
              rows.add(row);
            }
          }
          rows.sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String),
          );
          return await ResearchSnapshotStore.store(
            session,
            c,
            kind,
            rows,
            'DART · 최근 5년 공시',
            'https://opendart.fss.or.kr',
            '$corpCode | ${from.toIso8601String()} ~ ${now.toIso8601String()}',
            SourceKind.dartApi,
          );
        } finally {
          await meter.flush(session);
          dart.close();
        }
      }
      final env = Platform.environment;
      final key = env['KIS_APP_KEY'],
          secret = env['KIS_APP_SECRET'],
          license = env['KIS_PUBLIC_DATA_LICENSE'];
      if (key == null ||
          secret == null ||
          key.isEmpty ||
          secret.isEmpty ||
          license == null ||
          license.isEmpty) {
        throw IngestException(message: '서버에 KIS 키와 공개 제공 권한 근거를 설정해야 합니다.');
      }
      _kis ??= KisResearchClient(key, secret);
      final securities = await Security.db.find(
        session,
        where: (t) => t.companyId.equals(c.id!),
      );
      final rows = <Map<String, dynamic>>[];
      for (final s in securities) {
        if (!RegExp(r'^\d{6}$').hasMatch(s.shortCode)) continue;
        rows.addAll(
          await _kis!.fetch(
            kind,
            s.shortCode,
            DateTime.now().toUtc().add(const Duration(hours: 9)),
          ),
        );
      }
      if (securities.isEmpty) throw IngestException(message: '연결된 종목이 없습니다.');
      return await ResearchSnapshotStore.store(
        session,
        c,
        kind,
        ResearchFeed.validate(kind, rows),
        '한국투자증권 · KRX · 최근 응답 페이지',
        'https://apiportal.koreainvestment.com',
        license,
        SourceKind.officialFile,
      );
    } on FormatException catch (e) {
      throw IngestException(message: e.message);
    } finally {
      _busy.remove(lock);
    }
  }
}
