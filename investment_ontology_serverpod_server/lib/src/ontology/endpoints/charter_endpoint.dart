import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/public_charter_source.dart';
import '../disclosure/charter_comparison_rules.dart';
import '../auth/ontology_access.dart';
import '../dart/dart_api_key.dart';
import '../ingest/charter_hooks.dart';
import '../ingest/charter_future_call.dart';
import '../ingest/ingest_jobs.dart';

/// Public read-only acquisition from receipt-bound official charter sections.
/// No AI, shared-data writes, arbitrary URLs, or authentication overrides.
class CharterEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;
  static final _cache =
      <String, ({DateTime until, Map<String, dynamic> data})>{};
  static final _pending = <String, Future<Map<String, dynamic>>>{};
  static final _failedUntil = <String, DateTime>{};

  Future<IngestJob> startCollection(Session session) async {
    OntologyAccess.requireAdmin(session);
    if (DartApiKey.read(session) == null) {
      throw IngestException(message: 'DART API 키가 설정되지 않았습니다.');
    }
    return IngestJobs.startAndSchedule(
      session,
      'charter_notices',
      (job) => CharterHooks.schedule(session, job.id!, DateTime.now().toUtc()),
    );
  }

  /// Explicit authenticated continuation for development servers with workers off.
  Future<IngestJob?> advanceCollection(Session session) async {
    OntologyAccess.requireAdmin(session);
    if (!session.serverpod.config.futureCallExecutionEnabled) {
      await CharterFutureCall().run(session);
    }
    return IngestJobs.latest(session, 'charter_notices');
  }

  Future<IngestJob?> collectionStatus(Session session) =>
      IngestJobs.latest(session, 'charter_notices');

  /// Actual source coverage, rather than treating job completion as full data.
  Future<String> collectionCoverage(Session session) async {
    final index = jsonDecode(
      await File('assets/charter/notice_index.json').readAsString(),
    ) as Map<String, dynamic>;
    final companies = await Company.db.find(
      session,
      where: (t) => t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
    );
    final codes = {for (final c in companies) c.id!: c.corpCode};
    final expected = (index['notices'] as List)
        .cast<Map<String, dynamic>>()
        .where((n) => codes.containsValue(n['corpCode']))
        .toList();
    final stored = await ResearchSnapshot.db.find(
      session,
      where: (t) => t.kind.equals('charterNotice'),
    );
    final expectedReceipts = expected.map((n) => n['receipt']).toSet();
    final received = <String>{};
    final comparisons = <String>{};
    var rows = 0, comparisonNotices = 0;
    for (final snapshot in stored) {
      final value = jsonDecode(snapshot.payload) as Map<String, dynamic>;
      if (!expectedReceipts.contains(snapshot.digest) ||
          codes[snapshot.companyId] != value['corpCode'] ||
          snapshot.digest != value['receipt']) {
        continue;
      }
      received.add(snapshot.digest);
      final changes = value['changes'] as List;
      rows += changes.length;
      if (changes.isNotEmpty) {
        comparisonNotices++;
        comparisons.add(value['corpCode'] as String);
      }
    }
    final missing = expected
        .where((n) => !received.contains(n['receipt']))
        .toList();
    final noticeCodes = expected.map((n) => n['corpCode']).toSet();
    final indexedCodes =
        (await Directory('assets/charter/notices')
                .list()
                .where((f) => f.path.endsWith('.json'))
                .toList())
            .map((f) => f.path.split('/').last.replaceAll('.json', ''))
            .toSet();
    final unindexed = companies
        .where((c) => !indexedCodes.contains(c.corpCode))
        .map((c) => c.corpCode)
        .toList();
    return jsonEncode({
      'fromDate': index['fromDate'],
      'toDate': index['toDate'],
      'companies': companies.length,
      'expectedNotices': expected.length,
      'storedNotices': expected.length - missing.length,
      'missingNotices': missing.length,
      'missing': missing,
      'companiesWithoutNotice': companies
          .where(
            (c) =>
                indexedCodes.contains(c.corpCode) &&
                !noticeCodes.contains(c.corpCode),
          )
          .length,
      'unindexedCompanies': unindexed,
      'companiesWithComparisons': comparisons.length,
      'comparisonNotices': comparisonNotices,
      'changeRows': rows,
    });
  }

  Future<Map<String, dynamic>> _read(
    String receipt,
    String corpCode, {
    bool notice = false,
  }) async {
    final key = '$corpCode/$receipt/$notice';
    final now = DateTime.now().toUtc();
    if (_failedUntil[key]?.isAfter(now) ?? false) {
      throw const FormatException('Charter source cooling down');
    }
    final cached = _cache[key];
    if (cached != null && cached.until.isAfter(now)) return cached.data;
    if (_pending[key] case final future?) return future;
    final future = () async {
      final reader = PublicCharterSource();
      try {
        final source = await reader.fetch(receipt, corpCode, notice: notice);
        final data = {
          ...CharterComparisonRules.parse(source.document),
          'receipt': receipt,
          'sourceUrl': source.urls.single,
          'source': Source(
            kind: SourceKind.dartReport,
            title: notice ? 'DART 주주총회소집공고 정관 대비표' : 'DART 정관에 관한 사항',
            reference: receipt,
            url: source.urls.single,
            retrievedAt: DateTime.now().toUtc(),
          ).toJson(),
          'retrievedAt': DateTime.now().toUtc().toIso8601String(),
          'sha256': sha256.convert(utf8.encode(source.document)).toString(),
        };
        if (_cache.length >= 128) _cache.remove(_cache.keys.first);
        _cache[key] = (until: now.add(const Duration(hours: 6)), data: data);
        return data;
      } catch (_) {
        _failedUntil[key] = DateTime.now().toUtc().add(
          const Duration(minutes: 5),
        );
        rethrow;
      } finally {
        reader.close();
      }
    }();
    // This request awaits the shared future below; concurrent reads also await it.
    // ignore: unawaited_futures
    _pending[key] = future;
    try {
      return await future;
    } finally {
      // Removing an already-awaited reference does not launch work.
      // ignore: unawaited_futures
      _pending.remove(key);
    }
  }

  Future<Map<String, dynamic>> _proposal(
    Session session,
    String corpCode,
  ) async {
    final today = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 9))
        .toIso8601String()
        .substring(0, 10);
    final file = File('assets/charter/notices/$corpCode.json');
    if (await file.exists()) {
      final saved =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (saved['corpCode'] == corpCode) {
        final company = await Company.db.findFirstRow(
          session,
          where: (t) => t.corpCode.equals(corpCode),
        );
        final snapshots = await ResearchSnapshot.db.find(
          session,
          where: (t) =>
              t.companyId.equals(company!.id!) & t.kind.equals('charterNotice'),
        );
        final notices = {
          for (final n
              in (saved['notices'] as List).cast<Map<String, dynamic>>())
            n['receipt'] as String: n,
        };
        for (final s in snapshots) {
          final n = jsonDecode(s.payload) as Map<String, dynamic>;
          if (n['corpCode'] == corpCode) notices[n['receipt'] as String] = n;
        }
        final rows = notices.values.toList()
          ..sort(
            (a, b) =>
                (b['receipt'] as String).compareTo(a['receipt'] as String),
          );
        return {
          ...saved,
          'notices': rows,
          'inspectedCount': rows.length,
          'noticeState':
              rows.length >= (saved['noticeCount'] as int) && rows.isNotEmpty
              ? 'ready'
              : saved['noticeState'],
        };
      }
    }
    final key = 'notices/$corpCode/$today';
    if (_cache[key] case final cached?
        when cached.until.isAfter(DateTime.now().toUtc())) {
      return cached.data;
    }
    final reader = PublicCharterSource();
    try {
      final notices = await reader.discover(corpCode);
      final inspected = <Map<String, dynamic>>[];
      var failed = 0;
      for (final notice in notices.take(3)) {
        try {
          inspected.add({
            ...await _read(notice.receipt, corpCode, notice: true),
            'reportName': notice.name,
            'filingDate':
                '${notice.receipt.substring(0, 4)}-${notice.receipt.substring(4, 6)}-${notice.receipt.substring(6, 8)}',
            'stage': 'proposal',
          });
        } catch (_) {
          failed++;
        }
      }
      final result = <String, dynamic>{
        'corpCode': corpCode,
        'toDate': today,
        'noticeState': notices.isEmpty
            ? 'noNotice'
            : failed > 0
            ? 'partial'
            : 'ready',
        'notices': inspected,
        'noticeCount': notices.length,
        'inspectedCount': inspected.length,
        'failedCount': failed,
      };
      _cache[key] = (
        until: DateTime.now().toUtc().add(
          Duration(minutes: failed > 0 ? 5 : 360),
        ),
        data: result,
      );
      return result;
    } finally {
      reader.close();
    }
  }

  Future<String> summary(Session session, String corpCode) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) throw ArgumentError('기업 코드 오류');
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return jsonEncode({'state': 'noCompany'});
    final filing = await DartFiling.db.findFirstRow(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) & t.reportCode.notEquals(null),
      orderByList: (t) => [t.rceptNo.desc()],
    );
    Map<String, dynamic>? history;
    String? acquisitionState;
    if (filing != null) {
      try {
        history = await _read(
          filing.rceptNo,
          corpCode,
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        acquisitionState = 'unavailable';
      }
    }
    Map<String, dynamic>? noticeData;
    try {
      noticeData = await _proposal(session, corpCode);
    } catch (_) {
      noticeData = {'noticeState': 'unavailable'};
    }
    final notices = (noticeData['notices'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    Map<String, dynamic>? proposal = notices
        .where((n) => (n['changes'] as List).isNotEmpty)
        .firstOrNull;
    // Legacy reproducible PDF corpus remains a fallback, never overrides DART.
    final file = File('assets/charter/$corpCode.json');
    if (proposal == null && await file.exists()) {
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      String normalize(String s) =>
          CharterComparisonRules.compact(s)
              .replaceAll(RegExp(r'주식회사|\(주\)|㈜'), '');
      if (raw['corpCode'] == corpCode &&
          normalize(raw['company'] as String) == normalize(company.name)) {
        final tables = (raw['tables'] as List)
            .map(
              (t) =>
                  (t as List).map((r) => (r as List).cast<String>()).toList(),
            )
            .toList();
        proposal = {
          ...CharterComparisonRules.fromTables(tables),
          'meetingDate': raw['meetingDate'],
          'stage': 'proposal',
          'source': Source(
            kind: SourceKind.officialFile,
            title: '${company.name} 주총 소집공고 정관 대비표',
            reference: '$corpCode/${raw['meetingDate']}',
            url: raw['sourceUrl'] as String,
            retrievedAt: DateTime.parse(raw['retrievedAt'] as String),
          ).toJson(),
          'sourceUrl': raw['sourceUrl'],
          'sourcePages': raw['sourcePages'],
          'sha256': raw['sourceSha256'],
          'retrievedAt': raw['retrievedAt'],
        };
      }
    }
    return jsonEncode({
      'state': history == null && proposal == null
          ? acquisitionState ?? 'notCollected'
          : 'ready',
      'corpCode': corpCode,
      'reportName': filing?.reportName,
      'history': history,
      'proposal': proposal,
      'notices': notices,
      'noticeState': noticeData['noticeState'],
      'noticeCount': noticeData['noticeCount'],
      'noticeFromDate': noticeData['fromDate'],
      'noticeToDate': noticeData['toDate'],
      'inspectedCount': noticeData['inspectedCount'],
      'historyState':
          acquisitionState ?? (history == null ? 'notCollected' : 'ready'),
    });
  }
}
