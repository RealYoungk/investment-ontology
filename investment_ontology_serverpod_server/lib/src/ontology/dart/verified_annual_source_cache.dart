import 'dart:convert';

import 'public_financial_html.dart';
import 'sk_signet_identity.dart';

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';
import 'dart_report_name.dart';
import 'public_financial_html_fetch.dart';
import 'verified_annual_source_registry.dart';
import 'same_receipt_audit_source.dart';
import 'pureun_six_core_profile.dart';

/// Only compiled, byte-pinned official packages; the adapter has no network.
final class VerifiedAnnualSourceCache {
  VerifiedAnnualSourceCache({Future<List<int>> Function(String)? readAsset})
    : _read = readAsset ?? ((path) => File(path).readAsBytes());
  final Future<List<int>> Function(String) _read;
  static const receipt = '20260323001652';
  static const corpCode = '01020269';
  static const ruleVersion = 'talos-cfs-pure-literal-v1';
  static const manifestDigest =
      '039849225de164921a9aeb65fa3458fadcbe6574b4ab56e6bb035b7084e6ebf4';
  static const assetDirectory = 'assets/financial_source_cache/talos-cfs-2025';
  static const auditReference =
      'financial-cache-replay:$manifestDigest:$receipt:consolidated:$ruleVersion';
  static const pimReceipt = '20250321001900';
  static const pimCorpCode = '00765897';
  static const pimRuleVersion = 'pim-cfs-whole-ce-v1';
  static const pimManifestDigest =
      'c964aef1f97af016e1d54595c8b05c5fb5762bc80ab02cc363b504ea1c62ac80';
  static const pimAssetDirectory = 'assets/financial_source_cache/pim-cfs-2024';

  static bool isPim(DartFiling filing) => filing.rceptNo == pimReceipt;
  static String digestFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).manifestDigest;
  static String ruleFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).ruleVersion;
  static String referenceFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).auditReference;
  static AnnualSourceCacheEntry _entry(DartFiling filing, FsDiv basis) =>
      VerifiedAnnualSourceRegistry.find(filing.rceptNo, basis) ??
      (throw const FormatException('Unknown immutable annual package'));
  static bool eligible(DartFiling filing) =>
      filing.rceptNo == receipt &&
      eligibleFor(filing, _entry(filing, FsDiv.consolidated));
  static bool eligiblePim(DartFiling filing) =>
      filing.rceptNo == pimReceipt &&
      eligibleFor(filing, _entry(filing, FsDiv.consolidated));
  static bool eligibleAny(DartFiling filing) => VerifiedAnnualSourceRegistry
      .entries
      .any((entry) => eligibleFor(filing, entry));
  static bool eligibleFor(DartFiling filing, AnnualSourceCacheEntry entry) {
    if (!identical(
      VerifiedAnnualSourceRegistry.find(entry.receipt, entry.basis),
      entry,
    )) {
      return false;
    }
    final report = DartReportName.parse(filing.reportName);
    final attempts = RegExp(r'api-noData-annual-public:attempt=(\d+);')
        .firstMatch(filing.lastError ?? '');
    final status = entry.basis == FsDiv.consolidated
        ? filing.consolidatedStatus
        : filing.separateStatus;
    return filing.rceptNo == entry.receipt &&
        filing.corpCode == entry.corpCode &&
        filing.bsnsYear == entry.year &&
        filing.reportCode == FinancialReportCode.annual &&
        report?.kind == DartReportKind.annual &&
        report?.periodYear == entry.year &&
        report?.periodMonth == 12 &&
        attempts?.group(1) == '3' &&
        (status == FilingFetchStatus.failed ||
            status == FilingFetchStatus.pending);
  }

  Future<PublicFinancialHtmlBasisNotApplicable> verify(
    DartFiling f,
    Company c,
  ) async {
    if (!eligible(f)) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final result = await verifyRegistered(f, c, FsDiv.consolidated);
    return result.absence ??
        (throw const FormatException(
          'Cached annual expected typed absence missing',
        ));
  }

  Future<PublicFinancialHtmlSource> verifyPim(DartFiling f, Company c) async {
    if (!eligiblePim(f)) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final result = await verifyRegistered(f, c, FsDiv.consolidated);
    return result.numeric ??
        (throw const FormatException(
          'Cached annual expected numeric source missing',
        ));
  }

  Future<
    ({
      PublicFinancialHtmlSource? numeric,
      PublicFinancialHtmlBasisNotApplicable? absence,
    })
  >
  verifyRegistered(DartFiling filing, Company company, FsDiv basis) async {
    final entry = _entry(filing, basis);
    if (!eligibleFor(filing, entry) ||
        company.corpCode != entry.corpCode ||
        filing.companyId != company.id ||
        company.stockCode == null) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final rawManifest = await _read('${entry.assetDirectory}/manifest.json');
    if (sha256.convert(rawManifest).toString() != entry.manifestDigest) {
      throw const FormatException('Cached annual manifest digest mismatch');
    }
    final manifest = jsonDecode(utf8.decode(rawManifest)) as Map;
    final start = DateTime.utc(entry.year),
        end = DateTime.utc(entry.year, 12, 31);
    if (manifest['receipt'] != entry.receipt ||
        manifest['corpCode'] != entry.corpCode ||
        manifest['basis'] != basis.name ||
        manifest['kind'] != 'annual' ||
        manifest['year'] != entry.year ||
        manifest['periodStart'] != '${entry.year}-01-01' ||
        manifest['periodEnd'] != '${entry.year}-12-31' ||
        manifest['ruleVersion'] != entry.ruleVersion) {
      throw const FormatException('Cached annual declared identity mismatch');
    }
    final linkedAudit =
        entry.ruleVersion == 'same-receipt-audit-immutable-v1' &&
        SameReceiptAuditSource.eligible(
          receipt: entry.receipt,
          corpCode: entry.corpCode,
          consolidated: basis == FsDiv.consolidated,
          start: start,
          end: end,
        );
    final requiredLabels = {
      'shell',
      'cover',
      entry.statementLabel,
      if (linkedAudit) 'auditShell',
      if (entry.requiresIssuerOverview) 'overview',
    };
    final documentCount = requiredLabels.length;
    final documents = <Uri, List<int>>{};
    final labels = <String>{};
    for (final source in manifest['sources'] as List) {
      final label = source['label'];
      if (!requiredLabels.contains(label) ||
          !labels.add(label as String) ||
          source['file'] != '$label.html') {
        throw const FormatException('Unknown cached annual document');
      }
      final uri = Uri.parse(source['url'] as String),
          bytes = await _read('${entry.assetDirectory}/${source['file']}');
      if (documents.containsKey(uri) ||
          sha256.convert(bytes).toString() != source['sha256']) {
        throw const FormatException('Cached annual raw digest mismatch');
      }
      documents[uri] = bytes;
    }
    if (documents.length != documentCount || labels.length != documentCount) {
      throw const FormatException('Cached annual package incomplete');
    }
    if (entry.ruleVersion == 'sk-signet-direct-rename-event-v1') {
      String raw(String label) => utf8.decode(
        documents[Uri.parse(
          label == 'shell'
              ? 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}'
              : SkSignetIdentity.urls[label]!,
        )]!,
      );
      final cover = raw('cover'), statement = raw('ofs');
      final coverUri = Uri.parse(SkSignetIdentity.urls['cover']!),
          statementUri = Uri.parse(SkSignetIdentity.urls['ofs']!);
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: statement,
        coverSource: coverUri,
        statementSource: statementUri,
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        periodStart: start,
        periodEnd: end,
        consolidated: false,
        skSignetIdentity: SkSignetIdentity(
          shell: raw('shell'),
          overview: raw('overview'),
          overviewSource: Uri.parse(SkSignetIdentity.urls['overview']!),
        ),
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: cover,
          coverSource: coverUri,
          statementHtml: statement,
          statementSource: statementUri,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    final client = _PinnedRawClient(documents, maxRequests: documentCount);
    try {
      final numeric = await PublicFinancialHtmlFetcher(client).fetchAnnual(
        entry.receipt,
        reportName: filing.reportName,
        corpCode: company.corpCode,
        companyName: company.name,
        bsnsYear: filing.bsnsYear!,
        periodEnd: end,
        consolidated: basis == FsDiv.consolidated,
        allowPrimaryHistoricalIssuer:
            entry.ruleVersion == 'primary-historical-issuer-whole-seven-v1',
      );
      if (entry.absenceLiteral != null ||
          client.requests != documentCount ||
          numeric.sourceReceipt != entry.receipt ||
          numeric.periodStart != start ||
          numeric.periodEnd != end ||
          (numeric.rows.length < 7 &&
              !PureunSixCoreProfile.storedProof(
                numeric.rows,
                sourceDigest: numeric.sourceDigest,
                sourceUrl: numeric.statementSource.toString(),
                companyCode: company.corpCode,
                targetReceipt: filing.rceptNo,
                basis: basis.name,
                year: filing.bsnsYear!,
                reportName: filing.reportName,
              )) ||
          numeric.rows.length > 8 ||
          numeric.rows.any((r) => r['account_id'] != null)) {
        throw const FormatException(
          'Cached annual verified numeric scope mismatch',
        );
      }
      return (numeric: numeric, absence: null);
    } on PublicFinancialHtmlBasisNotApplicable catch (absence) {
      if (entry.absenceLiteral == null ||
          basis != FsDiv.consolidated ||
          client.requests != documentCount ||
          absence.sourceReceipt != entry.receipt ||
          absence.corpCode != entry.corpCode ||
          absence.periodStart != start ||
          absence.periodEnd != end ||
          absence.evidence.replaceAll(RegExp(r'\s+'), '') !=
              entry.absenceLiteral!.replaceAll(RegExp(r'\s+'), '')) {
        throw const FormatException('Cached annual verified absence mismatch');
      }
      return (numeric: null, absence: absence);
    } finally {
      client.close();
    }
  }
}

class _PinnedRawClient extends http.BaseClient {
  _PinnedRawClient(this.documents, {this.maxRequests = 3});
  final int maxRequests;
  final Map<Uri, List<int>> documents;
  int requests = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = documents[request.url];
    if (request.method != 'GET' || bytes == null || ++requests > maxRequests) {
      throw const FormatException('Unpinned cached annual source request');
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
      request: request,
    );
  }
}
