import 'dart:convert';

import '../../generated/protocol.dart';
import '../dart/dart_report_name.dart';

/// Metadata-only repair guards; never approve or modify monetary values.
abstract final class FinancialPeriodProvenance {
  static bool originalMatches(DartFiling original, DartFiling target) {
    final a = DartReportName.parse(original.reportName);
    final b = DartReportName.parse(target.reportName);
    return original.companyId == target.companyId &&
        original.corpCode == target.corpCode &&
        original.bsnsYear == target.bsnsYear &&
        original.reportCode == target.reportCode &&
        a != null &&
        b != null &&
        a.kind == b.kind &&
        a.periodYear == b.periodYear &&
        a.periodMonth == b.periodMonth;
  }

  static bool sourceUriMatches(String? url, String receipt) {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'dart.fss.or.kr' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return false;
    }
    final key = uri.path == '/pdf/download/ifrs.do' ? 'rcp_no' : 'rcpNo';
    return {'/report/viewer.do', '/pdf/download/ifrs.do'}.contains(uri.path) &&
        uri.queryParametersAll[key]?.length == 1 &&
        uri.queryParameters[key] == receipt;
  }
}

/// Honest metadata-only traversal state in job history; never a Source proof.
class MetadataProgress {
  const MetadataProgress(
    this.scope,
    this.target,
    this.receipt,
    this.complete,
    this.failed, {
    this.transient = false,
    this.retryAt,
    this.periodHold = false,
  });
  final String scope;
  final int? target;
  final String? receipt;
  final bool complete;
  final bool failed;
  final bool transient;
  final DateTime? retryAt;
  final bool periodHold;
  static const marker = ' · metadata-progress-v1:';
  bool after(int id, String r) =>
      target == null ||
      id > target! ||
      (id == target && r.compareTo(receipt!) > 0);
  String get suffix =>
      '$marker$scope:${base64Url.encode(utf8.encode(jsonEncode({'v': 1, 'scope': scope, 'target': target, 'receipt': receipt, 'complete': complete, 'failed': failed, 'transient': transient, 'retryAt': retryAt?.toIso8601String(), 'periodHold': periodHold})))}';
  static MetadataProgress? read(String? text, String scope) {
    if (text == null || !text.contains(marker)) return null;
    try {
      final p = jsonDecode(
        utf8.decode(base64Url.decode(text.split('$marker$scope:').last)),
      );
      if (p is! Map ||
          p['v'] != 1 ||
          p['scope'] != scope ||
          p['complete'] is! bool ||
          p['failed'] is! bool ||
          (p['target'] != null &&
              (p['target'] is! int ||
                  p['receipt'] is! String ||
                  !RegExp(r'^\d{14}$').hasMatch(p['receipt'])))) {
        return null;
      }
      return MetadataProgress(
        scope,
        p['target'] as int?,
        p['receipt'] as String?,
        p['complete'] as bool,
        p['failed'] as bool,
        transient: p['transient'] == true,
        periodHold: p['periodHold'] == true,
        retryAt: p['retryAt'] is String
            ? DateTime.tryParse(p['retryAt'])
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
