import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../research/issuer_financials_html.dart';
import '../research/ipo_issuer_financials_html.dart';
import '../research/issuer_financials_feed.dart';
import '../research/research_snapshot_store.dart';

/// Internal normal business worker only. No generated financial reports/facts.
abstract final class IssuerFinancialsSync {
  static const kind = 'issuerFinancials';
  static const provider = 'verified-primary-html-rule';
  static const reference =
      'source-bound-partial-current-core;no-api-report-or-xbrl-assertion';
  static bool supports(Map<String, dynamic> doc) =>
      IssuerFinancialsHtml.supports(doc) ||
      IpoIssuerFinancialsHtml.supports(doc);
  static bool supportsCorp(String code) =>
      code == IssuerFinancialsHtml.corp ||
      IpoIssuerFinancialsHtml.supportsCorp(code);
  static Future<List<Map<String, dynamic>>> rows(
    Directory cache,
    List<Map<String, dynamic>> documents,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final d in documents.where(supports)) {
      final m = d['metadata'] as Map, p = d['proof'] as Map;
      for (final name in ['${m['sha256']}.html', '${p['shellSha256']}.html']) {
        if (await File('${cache.path}/$name').length() > 20 * 1024 * 1024) {
          throw const FormatException('Financial cache size bound');
        }
      }
      rows.addAll(
        (IssuerFinancialsHtml.supports(d)
            ? IssuerFinancialsHtml.parse
            : IpoIssuerFinancialsHtml.parse)(
          document: d,
          shellBytes: await File('${cache.path}/${p['shellSha256']}.html')
              .readAsBytes(),
          statementBytes: await File('${cache.path}/${m['sha256']}.html')
              .readAsBytes(),
        ),
      );
    }
    return rows.isEmpty ? rows : IssuerFinancialsFeed.validate(rows);
  }

  static Future<int> store(
    Session session,
    Company company,
    Directory cache,
    List<Map<String, dynamic>> documents,
    Future<bool> Function() cancelled,
  ) async {
    if (!supportsCorp(company.corpCode) || await cancelled()) {
      return 0;
    }
    final parsed = await rows(cache, documents);
    if (parsed.isEmpty || await cancelled()) return 0;
    if (parsed.any((r) => r['corpCode'] != company.corpCode)) {
      throw const FormatException(
        'Numeric snapshot company/source binding mismatch',
      );
    }
    await ResearchSnapshotStore.store(
      session,
      company,
      kind,
      parsed,
      provider,
      'https://dart.fss.or.kr',
      reference,
      SourceKind.officialFile,
      sourceTitle: jsonEncode({
        'kind': 'partial-primary-issuer-financials',
        'parsers': parsed.map((r) => r['parserVersion']).toSet().toList(),
        'actualOwnDocuments': documents.where(supports).length,
        'periodBasisGroups': parsed.length,
        'primaryAccountsPerGroup': parsed
            .map((r) => (r['accounts'] as List).length)
            .toList(),
        'unextractedMetricsPerGroup': parsed
            .map((r) => r['unextractedMetrics'] ?? [])
            .toList(),
        'wholeFinancialStatementsComplete': false,
        'regularApiCompletion': false,
      }),
      cancelled: cancelled,
    );
    return parsed.length;
  }

  static Future<bool> pending(
    Session session,
    Company company,
    Directory cache,
    List<Map<String, dynamic>> documents,
  ) async {
    if (!supportsCorp(company.corpCode)) return false;
    try {
      final expected = await rows(cache, documents);
      if (expected.isEmpty) return false;
      if (expected.any((r) => r['corpCode'] != company.corpCode)) return true;
      final latest = await ResearchSnapshot.db.findFirstRow(
        session,
        where: (t) => t.companyId.equals(company.id!) & t.kind.equals(kind),
        orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      );
      if (latest == null ||
          latest.payload != jsonEncode(expected) ||
          latest.provider != provider) {
        return true;
      }
      final source = await Source.db.findById(session, latest.sourceId);
      return source?.kind != SourceKind.officialFile ||
          source?.url != 'https://dart.fss.or.kr' ||
          source?.reference != reference;
    } on FormatException {
      return true;
    } on FileSystemException {
      return true;
    }
  }
}
