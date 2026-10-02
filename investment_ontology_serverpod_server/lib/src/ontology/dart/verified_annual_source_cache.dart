import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';
import 'dart_report_name.dart';
import 'public_financial_html_fetch.dart';

/// One reviewed immutable official raw package; never accepts submitted rows.
/// Its raw HTTP adapter has no network client and serves only three pinned URIs.
final class VerifiedAnnualSourceCache {
  VerifiedAnnualSourceCache({Future<List<int>> Function(String)? readAsset})
    : _read = readAsset ?? ((path) => File(path).readAsBytes());

  static const receipt = '20260323001652';
  static const corpCode = '01020269';
  static const ruleVersion = 'talos-cfs-pure-literal-v1';
  static const manifestDigest =
      '039849225de164921a9aeb65fa3458fadcbe6574b4ab56e6bb035b7084e6ebf4';
  static const assetDirectory = 'assets/financial_source_cache/talos-cfs-2025';
  static const auditReference =
      'financial-cache-replay:$manifestDigest:$receipt:consolidated:$ruleVersion';
  final Future<List<int>> Function(String) _read;
  static const pimReceipt = '20250321001900';
  static const pimCorpCode = '00765897';
  static const pimRuleVersion = 'pim-cfs-whole-ce-v1';
  static const pimManifestDigest =
      'c964aef1f97af016e1d54595c8b05c5fb5762bc80ab02cc363b504ea1c62ac80';
  static const pimAssetDirectory = 'assets/financial_source_cache/pim-cfs-2024';
  static bool isPim(DartFiling filing) => filing.rceptNo == pimReceipt;
  static String digestFor(DartFiling filing) =>
      isPim(filing) ? pimManifestDigest : manifestDigest;
  static String ruleFor(DartFiling filing) =>
      isPim(filing) ? pimRuleVersion : ruleVersion;
  static String referenceFor(DartFiling filing) =>
      'financial-cache-replay:${digestFor(filing)}:${filing.rceptNo}:consolidated:${ruleFor(filing)}';
  static bool eligibleAny(DartFiling filing) =>
      isPim(filing) ? eligiblePim(filing) : eligible(filing);
  static bool eligiblePim(DartFiling filing) {
    final report = DartReportName.parse(filing.reportName);
    final attempts = RegExp(r'api-noData-annual-public:attempt=(\d+);')
        .firstMatch(filing.lastError ?? '');
    return filing.rceptNo == pimReceipt &&
        filing.corpCode == pimCorpCode &&
        filing.bsnsYear == 2024 &&
        filing.reportCode == FinancialReportCode.annual &&
        report?.kind == DartReportKind.annual &&
        report?.periodYear == 2024 &&
        report?.periodMonth == 12 &&
        attempts?.group(1) == '3' &&
        (filing.consolidatedStatus == FilingFetchStatus.failed ||
            filing.consolidatedStatus == FilingFetchStatus.pending);
  }

  static bool eligible(DartFiling filing) {
    final report = DartReportName.parse(filing.reportName);
    final attempts = RegExp(r'api-noData-annual-public:attempt=(\d+);')
        .firstMatch(filing.lastError ?? '');
    return filing.rceptNo == receipt &&
        filing.corpCode == corpCode &&
        filing.bsnsYear == 2025 &&
        filing.reportCode == FinancialReportCode.annual &&
        report?.kind == DartReportKind.annual &&
        report?.periodYear == 2025 &&
        report?.periodMonth == 12 &&
        attempts?.group(1) == '3' &&
        (filing.consolidatedStatus == FilingFetchStatus.failed ||
            filing.consolidatedStatus == FilingFetchStatus.pending);
  }

  Future<PublicFinancialHtmlBasisNotApplicable> verify(
    DartFiling filing,
    Company company,
  ) async {
    if (!eligible(filing) ||
        company.corpCode != corpCode ||
        filing.companyId != company.id ||
        company.stockCode == null) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final manifestBytes = await _read('$assetDirectory/manifest.json');
    if (sha256.convert(manifestBytes).toString() != manifestDigest) {
      throw const FormatException('Cached annual manifest digest mismatch');
    }
    final manifest = jsonDecode(utf8.decode(manifestBytes)) as Map;
    if (manifest['receipt'] != receipt ||
        manifest['corpCode'] != corpCode ||
        manifest['basis'] != 'consolidated' ||
        manifest['kind'] != 'annual' ||
        manifest['year'] != 2025 ||
        manifest['periodStart'] != '2025-01-01' ||
        manifest['periodEnd'] != '2025-12-31' ||
        manifest['ruleVersion'] != ruleVersion) {
      throw const FormatException('Cached annual declared identity mismatch');
    }
    final documents = <Uri, List<int>>{};
    for (final source in manifest['sources'] as List) {
      final label = source['label'];
      if (!{'shell', 'cover', 'cfs'}.contains(label) ||
          source['file'] != '$label.html') {
        throw const FormatException('Unknown cached annual document');
      }
      final uri = Uri.parse(source['url'] as String);
      final raw = await _read('$assetDirectory/${source['file']}');
      if (documents.containsKey(uri) ||
          sha256.convert(raw).toString() != source['sha256']) {
        throw const FormatException('Cached annual raw digest mismatch');
      }
      documents[uri] = raw;
    }
    if (documents.length != 3) {
      throw const FormatException('Cached annual package incomplete');
    }
    final client = _PinnedRawClient(documents);
    try {
      await PublicFinancialHtmlFetcher(client).fetchAnnual(
        receipt,
        reportName: filing.reportName,
        corpCode: company.corpCode,
        companyName: company.name,
        bsnsYear: filing.bsnsYear!,
        periodEnd: DateTime.utc(2025, 12, 31),
        consolidated: true,
      );
    } on PublicFinancialHtmlBasisNotApplicable catch (verified) {
      if (client.requests != 3 ||
          verified.sourceReceipt != receipt ||
          verified.corpCode != corpCode ||
          verified.periodStart != DateTime.utc(2025) ||
          verified.periodEnd != DateTime.utc(2025, 12, 31) ||
          verified.evidence.replaceAll(' ', '') != '해당사항없음') {
        throw const FormatException('Cached annual verified absence mismatch');
      }
      return verified;
    } finally {
      client.close();
    }
    throw const FormatException('Cached annual expected typed absence missing');
  }

  Future<PublicFinancialHtmlSource> verifyPim(
    DartFiling filing,
    Company company,
  ) async {
    if (!eligiblePim(filing) ||
        company.corpCode != pimCorpCode ||
        filing.companyId != company.id ||
        company.stockCode == null) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final manifestBytes = await _read('$pimAssetDirectory/manifest.json');
    if (sha256.convert(manifestBytes).toString() != pimManifestDigest) {
      throw const FormatException('Cached annual manifest digest mismatch');
    }
    final manifest = jsonDecode(utf8.decode(manifestBytes)) as Map;
    if (manifest['receipt'] != pimReceipt ||
        manifest['corpCode'] != pimCorpCode ||
        manifest['basis'] != 'consolidated' ||
        manifest['kind'] != 'annual' ||
        manifest['year'] != 2024 ||
        manifest['periodStart'] != '2024-01-01' ||
        manifest['periodEnd'] != '2024-12-31' ||
        manifest['ruleVersion'] != pimRuleVersion) {
      throw const FormatException('Cached annual declared identity mismatch');
    }
    final documents = <Uri, List<int>>{};
    for (final source in manifest['sources'] as List) {
      final label = source['label'];
      if (!{'shell', 'cover', 'cfs'}.contains(label) ||
          source['file'] != '$label.html') {
        throw const FormatException('Unknown cached annual document');
      }
      final uri = Uri.parse(source['url'] as String);
      final raw = await _read('$pimAssetDirectory/${source['file']}');
      if (documents.containsKey(uri) ||
          sha256.convert(raw).toString() != source['sha256']) {
        throw const FormatException('Cached annual raw digest mismatch');
      }
      documents[uri] = raw;
    }
    if (documents.length != 3) {
      throw const FormatException('Cached annual package incomplete');
    }
    final client = _PinnedRawClient(documents);
    try {
      final verified = await PublicFinancialHtmlFetcher(client).fetchAnnual(
        pimReceipt,
        reportName: filing.reportName,
        corpCode: company.corpCode,
        companyName: company.name,
        bsnsYear: filing.bsnsYear!,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: true,
      );
      if (client.requests != 3 ||
          verified.sourceReceipt != pimReceipt ||
          verified.periodStart != DateTime.utc(2024) ||
          verified.periodEnd != DateTime.utc(2024, 12, 31) ||
          verified.rows.length < 7 ||
          verified.rows.any((r) => r['account_id'] != null)) {
        throw const FormatException(
          'Cached annual verified numeric scope mismatch',
        );
      }
      return verified;
    } finally {
      client.close();
    }
  }
}

class _PinnedRawClient extends http.BaseClient {
  _PinnedRawClient(this.documents);
  final Map<Uri, List<int>> documents;
  int requests = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = documents[request.url];
    if (request.method != 'GET' || bytes == null || ++requests > 3) {
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
