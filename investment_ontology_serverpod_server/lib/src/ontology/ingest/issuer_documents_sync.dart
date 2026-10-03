import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../research/issuer_documents_collector.dart';
import '../research/research_snapshot_store.dart';

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

  static Future<void> run(
    Session session, {
    required Future<bool> Function() cancelled,
  }) async {
    if (session.serverpod.runMode != 'production' ||
        _running ||
        await cancelled()) {
      return;
    }
    final cachePath = Platform.environment['ISSUER_DOCUMENT_CACHE_DIR'];
    if (cachePath == null || cachePath.isEmpty) {
      session.log('공식 원문 비공개 영속 cache 경로 설정 전입니다.', level: LogLevel.warning);
      return;
    }
    _running = true;
    final collector = IssuerDocumentsCollector(cache: Directory(cachePath));
    try {
      await collectAndStore(
        session,
        manifestText: await combinedManifestText(),
        collector: collector,
        cancelled: cancelled,
      );
    } catch (e, st) {
      // Raw-source failure never rewrites the regular business job's status/count.
      session.log(
        '고정 투자회사 원문 메타데이터 보존 미완료: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: st,
      );
    } finally {
      collector.client.close();
      _running = false;
    }
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

  /// Read-only startup eligibility. Only the existing scheduled worker collects.
  static Future<bool> hasPending(Session session) async {
    final docs = IssuerDocumentsCollector.manifest(
      await combinedManifestText(),
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
    }
    return false;
  }

  /// Internal dependency-injected execution, also exercised in isolated tests.
  /// Runtime caller is the normal scheduled business FutureCall, never a new RPC.
  static Future<void> collectAndStore(
    Session session, {
    required String manifestText,
    required IssuerDocumentsCollector collector,
    required Future<bool> Function() cancelled,
  }) async {
    final mode = await session.db.unsafeQuery('SHOW transaction_read_only');
    if (mode.first.first == 'on') return;
    final docs = IssuerDocumentsCollector.manifest(manifestText);
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final d in docs) {
      final code = (d['metadata'] as Map)['corpCode'] as String;
      groups.putIfAbsent(code, () => []).add(d);
    }
    for (final entry in groups.entries) {
      if (await cancelled()) return;
      final company = await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals(entry.key),
      );
      if (company == null) {
        continue; // Never creates guessed company bindings.
      }
      var verified = true;
      for (final doc in entry.value) {
        if (!await collector.ensure(doc, cancelled: cancelled)) {
          verified = false;
          break;
        }
      }
      if (!verified || await cancelled()) return;
      final rows = entry.value
          .map((d) => Map<String, dynamic>.from(d['metadata'] as Map))
          .toList();
      final first = rows.first;
      final downloadedAt = entry.value
          .map(
            (d) =>
                DateTime.parse((d['proof'] as Map)['downloadedAt'] as String),
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
    }
  }
}
