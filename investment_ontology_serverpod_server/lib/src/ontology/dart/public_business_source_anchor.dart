import 'dart:convert';

import 'package:http/http.dart' as http;

import 'public_financial_period_metadata.dart';

/// Metadata-only verification of an existing original business document.
/// Never relabels its receipt as the attachment correction.
abstract final class PublicBusinessSourceAnchor {
  /// Bounded discovery from the exact correction shell, followed by the same
  /// source-family, corporation and explicit cover-period verification.
  static Future<PublicBusinessAnchorProof> discover(
    http.Client client, {
    required String targetReceipt,
    required String corpCode,
    required String companyName,
    required DateTime periodEnd,
    required bool halfYear,
    Duration interval = const Duration(seconds: 1),
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(targetReceipt)) {
      throw const FormatException('Invalid business correction receipt');
    }
    final uri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': targetReceipt,
    });
    await Future<void>.delayed(interval);
    final response = await client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        (response.request?.url ?? uri) != uri ||
        response.bodyBytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid business discovery shell');
    }
    final receipt = _latestFamilyReceipt(
      utf8.decode(response.bodyBytes),
      targetReceipt,
      corpCode,
      halfYear,
    );
    return verify(
      client,
      targetReceipt: targetReceipt,
      sourceReceipt: receipt,
      corpCode: corpCode,
      companyName: companyName,
      periodEnd: periodEnd,
      halfYear: halfYear,
      interval: interval,
    );
  }

  static String _latestFamilyReceipt(
    String shell,
    String targetReceipt,
    String corpCode,
    bool halfYear,
  ) {
    final companies = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m.group(1)!).toSet();
    final families = RegExp(
      r'''<select\b[^>]*\bid=["']family["'][^>]*>(.*?)</select>''',
      dotAll: true,
    ).allMatches(shell).toList();
    if (companies.length != 1 ||
        companies.single != corpCode ||
        families.length != 1 ||
        !shell.contains("openPdfDownload('$targetReceipt',")) {
      throw const FormatException('Unbound business correction identity');
    }
    final kind = halfYear ? '반기보고서' : '사업보고서';
    final receipts =
        RegExp(
              r'''<option[^>]+value=["']rcpNo=(\d{14})["'][^>]*>([^<]+)</option>''',
            )
            .allMatches(families.single.group(1)!)
            .where(
              (m) => m.group(2)!.replaceAll(RegExp(r'\s+'), '').contains(kind),
            )
            .map((m) => m.group(1)!)
            .toSet()
            .toList()
          ..sort();
    if (receipts.isEmpty) {
      throw const PublicBusinessFamilyUnavailable();
    }
    if (receipts.last.compareTo(targetReceipt) >= 0) {
      throw const FormatException('Business family receipt is not earlier');
    }
    return receipts.last;
  }

  static Future<PublicBusinessAnchorProof> verify(
    http.Client client, {
    required String targetReceipt,
    required String sourceReceipt,
    required String corpCode,
    required String companyName,
    required DateTime periodEnd,
    required bool halfYear,
    Duration interval = const Duration(seconds: 1),
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(targetReceipt) ||
        !RegExp(r'^\d{14}$').hasMatch(sourceReceipt) ||
        sourceReceipt.compareTo(targetReceipt) >= 0) {
      throw const FormatException('Invalid business source receipt order');
    }
    final uri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': targetReceipt,
    });
    await Future<void>.delayed(interval);
    final response = await client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        (response.request?.url ?? uri) != uri ||
        response.bodyBytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid business correction shell');
    }
    final shell = utf8.decode(response.bodyBytes);
    if (_latestFamilyReceipt(shell, targetReceipt, corpCode, halfYear) !=
        sourceReceipt) {
      throw const FormatException(
        'Original business receipt is not latest same-kind body',
      );
    }
    await Future<void>.delayed(interval);
    final observed = _StrictBusinessCoverClient(client, companyName);
    final metadata = await PublicFinancialPeriodMetadata.fetch(
      observed,
      receipt: sourceReceipt,
      targetReceipt: sourceReceipt,
      corpCode: corpCode,
      companyName: companyName,
      periodEnd: periodEnd,
      halfYear: halfYear,
      interval: interval,
    );
    return PublicBusinessAnchorProof(
      metadata,
      observed.observedCompany,
      observed.nameMatch,
    );
  }
}

class _StrictBusinessCoverClient extends http.BaseClient {
  _StrictBusinessCoverClient(this.delegate, this.companyName);
  final http.Client delegate;
  final String companyName;
  String? observedCompany;
  bool nameMatch = false;
  static String legal(String value) => value
      .replaceAll(RegExp(r'\s+'), '')
      .replaceFirst(RegExp(r'^(?:주식회사|\(주\)|㈜)'), '')
      .replaceFirst(RegExp(r'(?:주식회사|\(주\)|㈜)$'), '');
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await delegate.send(request);
    if (request.url.path != '/report/viewer.do') return response;
    final bytes = await response.stream.toBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Oversized business cover');
    }
    final text = utf8
        .decode(bytes)
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), '');
    final names = RegExp(r'회사명:(.*?)대표이사:').allMatches(text).toList();
    observedCompany = names.length == 1 ? names.single.group(1)! : null;
    nameMatch =
        observedCompany != null &&
        legal(observedCompany!) == legal(companyName);
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      request: response.request,
    );
  }
}

class PublicBusinessAnchorProof extends PublicFinancialPeriodMetadata {
  PublicBusinessAnchorProof(
    PublicFinancialPeriodMetadata value,
    this.observedCoverCompany,
    this.coverNameMatches,
  ) : super(
        receipt: value.receipt,
        corpCode: value.corpCode,
        periodStart: value.periodStart,
        periodEnd: value.periodEnd,
        shellSource: value.shellSource,
        coverSource: value.coverSource,
        digest: value.digest,
      );
  final String? observedCoverCompany;
  final bool coverNameMatches;
}

/// A valid exact shell has no earlier same-kind candidate. This is not evidence
/// that the filing has no business content; the normal API wait remains pending.
class PublicBusinessFamilyUnavailable extends FormatException {
  const PublicBusinessFamilyUnavailable()
    : super('No earlier same-kind business family');
}
