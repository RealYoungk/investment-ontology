import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../research/issuer_financials_html.dart';
import '../research/ipo_issuer_financials_html.dart';
import '../research/issuer_financials_feed.dart';
import '../research/fund_financials_text.dart';
import '../research/infrastructure_fund_financials.dart';
import '../research/scanned_fund_financials.dart';

import 'package:crypto/crypto.dart';

import '../research/research_snapshot_store.dart';

/// Internal normal business worker only. No generated financial reports/facts.
abstract final class IssuerFinancialsSync {
  static const kind = 'issuerFinancials';
  static const provider = 'verified-primary-html-rule';
  static const reference =
      'source-bound-partial-current-core;no-api-report-or-xbrl-assertion';
  static bool supports(Map<String, dynamic> doc) =>
      IssuerFinancialsHtml.supports(doc) ||
      IpoIssuerFinancialsHtml.supports(doc) ||
      FundFinancialsText.supports(doc) ||
      InfrastructureFundFinancials.supports(doc) ||
      ScannedFundFinancials.supports(doc);
  static bool supportsCorp(String code) =>
      code == IssuerFinancialsHtml.corp ||
      IpoIssuerFinancialsHtml.supportsCorp(code) ||
      FundFinancialsText.supportsCorp(code) ||
      InfrastructureFundFinancials.supportsCorp(code);
  static Future<List<Map<String, dynamic>>> rows(
    Directory cache,
    List<Map<String, dynamic>> documents,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final d in documents.where(supports)) {
      final m = d['metadata'] as Map, p = d['proof'] as Map;
      if (ScannedFundFinancials.supports(d)) {
        final profile = ScannedFundFinancials.profile(m)!;
        final pdf = File('${cache.path}/${m['sha256']}.pdf');
        final sidecar = File('${cache.path}/${m['sha256']}.scanned-ocr.json');
        if (await pdf.length() > 20 * 1024 * 1024 ||
            await sidecar.length() > 4 * 1024 * 1024) {
          throw const FormatException('Scanned private source size bound');
        }
        ScannedFundFinancials.verifyPdf(m, await pdf.readAsBytes());
        for (final page in profile['sourcePages'] as List) {
          final image = File(
            '${cache.path}/${m['sha256']}.p${(page['pageOrdinal'] as int).toString().padLeft(2, '0')}.png',
          );
          if (await image.length() > 20 * 1024 * 1024 ||
              sha256.convert(await image.readAsBytes()).toString() !=
                  page['imageSha256']) {
            throw const FormatException(
              'Exact private PDF page image required',
            );
          }
        }
        rows.add(ScannedFundFinancials.parse(m, await sidecar.readAsBytes()));
        continue;
      }
      if (InfrastructureFundFinancials.supports(d)) {
        final pdf = File('${cache.path}/${m['sha256']}.pdf'),
            raw = File('${cache.path}/${m['sha256']}.infrastructure.raw.txt');
        if (await pdf.length() > 20 * 1024 * 1024 ||
            await raw.length() > 4 * 1024 * 1024) {
          throw const FormatException(
            'Infrastructure private cache size bound',
          );
        }
        InfrastructureFundFinancials.verifyPdf(m, await pdf.readAsBytes());
        rows.add(
          InfrastructureFundFinancials.parseRaw(m, await raw.readAsBytes()),
        );
        continue;
      }
      if (FundFinancialsText.supports(d)) {
        final pdf = File('${cache.path}/${m['sha256']}.pdf');
        final text = File('${cache.path}/${m['sha256']}.fund.txt');
        if (await pdf.length() > 20 * 1024 * 1024 ||
            await text.length() > 4 * 1024 * 1024) {
          throw const FormatException('Fund private cache size bound');
        }
        FundFinancialsText.verifyPdf(m, await pdf.readAsBytes());
        rows.add(FundFinancialsText.parseText(m, await text.readAsBytes()));
        continue;
      }
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
    Future<bool> Function() cancelled, {
    void Function(int)? onQuarantined,
  }) async {
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
      sourceProvider(company.corpCode),
      sourceUrl(company.corpCode),
      sourceReference(company.corpCode),
      SourceKind.officialFile,
      sourceTitle: jsonEncode({
        'kind': 'partial-primary-issuer-financials',
        'retrievalMethod':
            'verified-local-original-cache;no-request-time-extraction',
        'sourceDocuments': parsed
            .map(
              (r) => {
                for (final k in [
                  'corpCode',
                  'officialUrl',
                  'sha256',
                  'periodStart',
                  'periodEnd',
                  'basis',
                  'categorySchema',
                  'extractedTextSha256',
                  'extractionTool',
                  'rawTextSha256',
                  'decodedTextSha256',
                  'decodedPages',
                  'textTransformation',
                  'numericState',
                  'sidecarSha256',
                  'acceptedSeparatorGrammar',
                  'pipeline',
                  'sourcePages',
                  'visualReadScope',
                ])
                  if (r.containsKey(k)) k: r[k],
              },
            )
            .toList(),
        'quarantinedPeriodGroups': parsed
            .where((r) => r['numericState'] == 'pendingCashScope')
            .length,
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
    final quarantined = parsed
        .where((r) => r['numericState'] == 'pendingCashScope')
        .length;
    onQuarantined?.call(quarantined);
    return parsed.length - quarantined;
  }

  static String sourceProvider(String corp) =>
      (FundFinancialsText.supportsCorp(corp) ||
          InfrastructureFundFinancials.supportsCorp(corp))
      ? 'verified-primary-pdf-text-rule'
      : provider;
  static String sourceUrl(String corp) => corp == '00435297'
      ? 'https://www.mkif.com'
      : corp == '01880801'
      ? 'https://kbif.co.kr'
      : FundFinancialsText.supportsCorp(corp)
      ? 'https://re1.miraeasset.com'
      : 'https://dart.fss.or.kr';
  static String sourceReference(String corp) =>
      InfrastructureFundFinancials.supportsCorp(corp)
      ? 'source-bound-partial-printed-infrastructure-fund;no-regular-api-or-xbrl'
      : FundFinancialsText.supportsCorp(corp)
      ? 'source-bound-partial-printed-fund;cash-quarantine;no-regular-api-or-xbrl'
      : reference;

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
          latest.provider != sourceProvider(company.corpCode)) {
        return true;
      }
      final source = await Source.db.findById(session, latest.sourceId);
      return source?.kind != SourceKind.officialFile ||
          source?.url != sourceUrl(company.corpCode) ||
          source?.reference != sourceReference(company.corpCode);
    } on FormatException {
      return true;
    } on FileSystemException {
      return true;
    }
  }
}
