import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:crypto/crypto.dart';

import '../../generated/protocol.dart';
import '../research/issuer_documents_collector.dart';
import '../research/research_snapshot_store.dart';
import 'ingest_jobs.dart';
import 'issuer_financials_sync.dart';
import 'own_annual_financials_sync.dart';

class IssuerDocumentsResult {
  int storedCompanies = 0, storedDocuments = 0, failedCompanies = 0;
  int financialPeriodGroups = 0, financialFailedCompanies = 0;
  int ownAnnualPeriodGroups = 0, ownAnnualFailedCompanies = 0;
  bool cancelled = false, setupFailed = false;
  bool get hasFailure =>
      setupFailed ||
      failedCompanies > 0 ||
      financialFailedCompanies > 0 ||
      ownAnnualFailedCompanies > 0;
  final reasons = <String>[];
  String get message =>
      '공식 별도 원문: 회사 보존 $storedCompanies · 문서 보존 $storedDocuments · 회사 실패 $failedCompanies · 준비 실패 ${setupFailed ? 1 : 0} · 원문 메타데이터 숫자 미추출 · 별도 핵심재무 기간·basis $financialPeriodGroups · 별도 재무 회사 실패 $financialFailedCompanies · 자체 연간 핵심재무 기간·basis $ownAnnualPeriodGroups · 자체 연간 재무 회사 실패 $ownAnnualFailedCompanies${cancelled ? ' · 취소' : ''}${reasons.isEmpty ? '' : ' · ${reasons.join('; ')}'}';
}

/// Internal scheduled worker. Stores raw metadata only, without touching body or
/// financial completion ledgers. There is no public mutation entry point here.
class IssuerDocumentsSync {
  static bool _running = false;
  static const assetPath =
      'assets/issuer_documents/verified_fund_documents.json';
  static const dartAssetPath =
      'assets/issuer_documents/verified_dart_documents.json';
  static const reference =
      'official-links-metadata-only;no-redistribution-license-asserted';

  static Future<IssuerDocumentsResult> run(
    Session session, {
    required Future<bool> Function() cancelled,
  }) async {
    if (session.serverpod.runMode != 'production' ||
        _running ||
        await cancelled()) {
      return IssuerDocumentsResult();
    }
    final cachePath = Platform.environment['ISSUER_DOCUMENT_CACHE_DIR'];
    if (cachePath == null || cachePath.isEmpty) {
      session.log('공식 원문 비공개 영속 cache 경로 설정 전입니다.', level: LogLevel.warning);
      return IssuerDocumentsResult()
        ..setupFailed = true
        ..reasons.add('비공개 영속 cache 경로 미설정');
    }
    _running = true;
    final collector = IssuerDocumentsCollector(cache: Directory(cachePath));
    try {
      return await collectAndStore(
        session,
        manifestText: await combinedManifestText(),
        collector: collector,
        cancelled: cancelled,
      );
    } catch (e, st) {
      // Counts remain separate from regular business-body period counts.
      session.log(
        '고정 투자회사 원문 메타데이터 보존 미완료: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: st,
      );
      return IssuerDocumentsResult()
        ..setupFailed = true
        ..reasons.add('고정 원문 작업 실패 (${e.runtimeType})');
    } finally {
      collector.client.close();
      _running = false;
    }
  }

  static Future<void> recordResult(
    Session session,
    int jobId,
    IssuerDocumentsResult result,
  ) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null ||
        job.status == IngestStatus.cancelled ||
        result.cancelled) {
      return;
    }
    await IngestJobs.save(
      session,
      job.copyWith(
        status: result.hasFailure ? IngestStatus.failed : job.status,
        message: '${job.message ?? ''} · ${result.message}',
      ),
    );
  }

  static Future<String> combinedManifestText() async {
    final fund = jsonDecode(await File(assetPath).readAsString()) as Map;
    final dart = jsonDecode(await File(dartAssetPath).readAsString()) as Map;
    return jsonEncode({
      ...fund,
      'documents': [
        ...(fund['documents'] as List),
        ...(dart['documents'] as List),
      ],
    });
  }

  /// A cache file timestamp is explicitly distinct from a captured GET time.
  static DateTime sourceEvidenceAt(Map<String, dynamic> document) {
    final proof = document['proof'] as Map;
    return DateTime.parse(
      (proof['downloadedAt'] ?? proof['fileSavedAt']) as String,
    );
  }

  static bool canResumeAtStartup({
    required IngestStatus? latestStatus,
    required bool rerunning,
    required bool queued,
  }) =>
      !rerunning &&
      !queued &&
      latestStatus != IngestStatus.cancelled &&
      latestStatus != IngestStatus.running;

  /// Read-only startup eligibility. Only the existing scheduled worker collects.
  static Future<bool> hasPending(
    Session session, {
    Directory? cache,
    String? manifestText,
  }) async {
    final path = Platform.environment['ISSUER_DOCUMENT_CACHE_DIR'];
    cache ??= path == null || path.isEmpty ? null : Directory(path);
    final docs = IssuerDocumentsCollector.manifest(
      manifestText ?? await combinedManifestText(),
    );
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final d in docs) {
      final row = Map<String, dynamic>.from(d['metadata'] as Map);
      groups.putIfAbsent(row['corpCode'] as String, () => []).add(row);
    }
    for (final entry in groups.entries) {
      final company = await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals(entry.key),
      );
      if (company == null) continue;
      if (cache == null) return true;
      for (final d in docs.where(
        (d) => (d['metadata'] as Map)['corpCode'] == entry.key,
      )) {
        final m = d['metadata'] as Map;
        final p = d['proof'] as Map;
        final files = <String, String>{
          '${m['sha256']}.${m['provider'] == 'DART' ? 'html' : 'pdf'}':
              m['sha256'] as String,
          if (m['provider'] == 'DART')
            '${p['shellSha256']}.html': p['shellSha256'] as String,
        };
        for (final entry in files.entries) {
          final file = File('${cache.path}/${entry.key}');
          try {
            if (!await file.exists() ||
                await file.length() > IssuerDocumentsCollector.maxBytes ||
                sha256.convert(await file.readAsBytes()).toString() !=
                    entry.value) {
              return true;
            }
          } on FileSystemException {
            // Missing/unreadable cache is pending work, not a server boot error.
            return true;
          }
        }
      }
      final latest = await ResearchSnapshot.db.findFirstRow(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) & t.kind.equals('issuerDocuments'),
        orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      );
      if (latest == null ||
          latest.payload != jsonEncode(entry.value) ||
          latest.provider != 'reviewed-official-documents') {
        return true;
      }
      final source = await Source.db.findById(session, latest.sourceId);
      final expected =
          'https://${Uri.parse(entry.value.first['officialUrl'] as String).host}';
      if (source?.kind != SourceKind.officialFile ||
          source?.url != expected ||
          source?.reference != reference) {
        return true;
      }
      if (await IssuerFinancialsSync.pending(
        session,
        company,
        cache,
        docs
            .where((d) => (d['metadata'] as Map)['corpCode'] == entry.key)
            .toList(),
      )) {
        return true;
      }
      if (await OwnAnnualFinancialsSync.pending(
        session,
        company,
        cache,
        docs
            .where((d) => (d['metadata'] as Map)['corpCode'] == entry.key)
            .toList(),
      )) {
        return true;
      }
    }
    return false;
  }

  /// Internal dependency-injected execution, also exercised in isolated tests.
  /// Runtime caller is the normal scheduled business FutureCall, never a new RPC.
  static Future<IssuerDocumentsResult> collectAndStore(
    Session session, {
    required String manifestText,
    required IssuerDocumentsCollector collector,
    required Future<bool> Function() cancelled,
  }) async {
    final mode = await session.db.unsafeQuery('SHOW transaction_read_only');
    final result = IssuerDocumentsResult();
    if (mode.first.first == 'on') {
      return result
        ..setupFailed = true
        ..reasons.add('읽기 전용 저장소');
    }
    final docs = IssuerDocumentsCollector.manifest(manifestText);
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final d in docs) {
      final code = (d['metadata'] as Map)['corpCode'] as String;
      groups.putIfAbsent(code, () => []).add(d);
    }
    for (final entry in groups.entries) {
      if (await cancelled()) return result..cancelled = true;
      try {
        final company = await Company.db.findFirstRow(
          session,
          where: (t) => t.corpCode.equals(entry.key),
        );
        if (company == null) {
          result.failedCompanies++;
          result.reasons.add('${entry.key}: 회사 연결 없음');
          continue; // Never creates guessed company bindings.
        }
        var verified = true;
        for (final doc in entry.value) {
          if (!await collector.ensure(doc, cancelled: cancelled)) {
            verified = false;
            break;
          }
        }
        if (!verified || await cancelled()) return result..cancelled = true;
        final rows = entry.value
            .map((d) => Map<String, dynamic>.from(d['metadata'] as Map))
            .toList();
        final first = rows.first;
        final downloadedAt = entry.value
            .map(
              (d) => sourceEvidenceAt(d),
            )
            .reduce((a, b) => a.isAfter(b) ? a : b);
        await ResearchSnapshotStore.store(
          session,
          company,
          'issuerDocuments',
          rows,
          'reviewed-official-documents',
          'https://${Uri.parse(first['officialUrl'] as String).host}',
          reference,
          SourceKind.officialFile,
          sourceRetrievedAt: downloadedAt,
          sourceTitle: jsonEncode({
            'kind': 'verified-fixed-issuer-documents',
            'monetaryExtraction': 'notExtracted',
            'documents': entry.value,
          }),
          cancelled: cancelled,
        );
        result.storedCompanies++;
        result.storedDocuments += entry.value.length;
        try {
          result.financialPeriodGroups += await IssuerFinancialsSync.store(
            session,
            company,
            collector.cache,
            entry.value,
            cancelled,
          );
        } catch (e, st) {
          if (await cancelled()) return result..cancelled = true;
          result.financialFailedCompanies++;
          result.reasons.add('${entry.key}: 별도 핵심재무 검증 실패 (${e.runtimeType})');
          session.log(
            '별도 핵심 재무 실패 ${entry.key}',
            level: LogLevel.warning,
            exception: e,
            stackTrace: st,
          );
        }
        try {
          result.ownAnnualPeriodGroups += await OwnAnnualFinancialsSync.store(
            session,
            company,
            collector.cache,
            entry.value,
            cancelled,
          );
        } catch (e, st) {
          if (await cancelled()) return result..cancelled = true;
          result.ownAnnualFailedCompanies++;
          result.reasons.add(
            '${entry.key}: 자체 연간 핵심재무 검증 실패 (${e.runtimeType})',
          );
          session.log(
            '자체 연간 재무 실패 ${entry.key}',
            level: LogLevel.warning,
            exception: e,
            stackTrace: st,
          );
        }
      } catch (e, st) {
        if (await cancelled()) return result..cancelled = true;
        result.failedCompanies++;
        result.reasons.add(
          '${entry.key}: ${e is FormatException ? e.message : e.runtimeType}',
        );
        session.log(
          '공식 별도 원문 회사별 실패 ${entry.key}',
          level: LogLevel.warning,
          exception: e,
          stackTrace: st,
        );
      }
    }
    return result;
  }
}
