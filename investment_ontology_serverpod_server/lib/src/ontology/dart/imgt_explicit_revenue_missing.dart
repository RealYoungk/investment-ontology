import 'dart:convert';

import '../../generated/protocol.dart';

/// Exact normal-ingest proof for one printed missing amount; never infers zero.
abstract final class ImgtExplicitRevenueMissing {
  static const receipt = '20260330001850';
  static const corp = '01579020';
  static const rule = 'imgt-explicit-revenue-null-v1';
  static const note = '부분 핵심6계정 · 영업수익 당기 금액 원문 미기재(-), 0·전기 대체 없음';
  static Uri source(FsDiv basis) => Uri.parse(
    'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt&dcmNo=11198920&eleId=${basis == FsDiv.consolidated ? '19' : '21'}&offset=${basis == FsDiv.consolidated ? '354048' : '739348'}&length=${basis == FsDiv.consolidated ? '51356' : '45486'}&dtd=dart4.xsd',
  );
  static String label(Object? value) =>
      value.toString().replaceAll(RegExp(r'\s'), '');
  static bool rowsProof(
    List<Map<String, dynamic>> rows,
    String company,
    String target,
    FsDiv basis,
    Uri? uri,
  ) {
    if (company != corp || target != receipt || uri != source(basis)) {
      return false;
    }
    final missing = rows.where((r) => r['thstrm_amount'] == null).toList();
    if (missing.length != 1) return false;
    final row = missing.single;
    final p = row['html_provenance'];
    if (row['rcept_no'] != receipt ||
        row['corp_code'] != corp ||
        row['bsns_year'] != '2025' ||
        row['reprt_code'] != '11011' ||
        row['sj_div'] != 'CIS' ||
        row['account_id'] != null ||
        !{'I.영업수익', 'Ⅰ.영업수익'}.contains(label(row['account_nm'])) ||
        p is! Map) {
      return false;
    }
    final ce = p['supportingPeriodEvidence'];
    return p['partialCoreRule'] == rule &&
        p['explicitMissingAmount'] == 'printed-dash-no-zero-or-prior' &&
        p['source'] == uri.toString() &&
        p['basis'] == (basis == FsDiv.consolidated ? 'CFS' : 'OFS') &&
        p['periodStart'] == '2025-01-01' &&
        p['periodEnd'] == '2025-12-31' &&
        p['unit'] == '원' &&
        p['currentColumn'] == 2 &&
        p['currentColumnSpan'] == 1 &&
        p['printedCurrentCells'] is List &&
        (p['printedCurrentCells'] as List).length == 1 &&
        (p['printedCurrentCells'] as List).single == '-' &&
        ce is Map &&
        ce['mode'] == rule &&
        ce['source'] == uri.toString() &&
        rows.where((r) => r['thstrm_amount'] != null).length >= 6;
  }

  static String? reason({
    required String company,
    required FinancialReport report,
    required Source source,
    required Source audit,
    required List<FinancialFact> facts,
    required FinancialLine line,
  }) {
    if (company != corp ||
        report.rceptNo != receipt ||
        report.bsnsYear != 2025 ||
        report.reportCode != FinancialReportCode.annual ||
        line.key != 'revenue' ||
        line.amount != null ||
        line.cumulativeAmount != null ||
        source.id != report.sourceId ||
        source.reference != receipt ||
        source.kind != SourceKind.dartReport ||
        source.url !=
            ImgtExplicitRevenueMissing.source(report.fsDiv).toString() ||
        audit.reference !=
            'financial-api-noData-source:$receipt:${report.fsDiv.name}' ||
        audit.kind != SourceKind.dartReport ||
        audit.url != source.url) {
      return null;
    }
    try {
      final payload = jsonDecode(audit.title);
      if (payload is! Map ||
          payload['corpCode'] != corp ||
          payload['sourceReceipt'] != receipt ||
          payload['targetReceipt'] != receipt ||
          payload['fsDiv'] != report.fsDiv.name ||
          payload['format'] != 'html' ||
          payload['sha256'] is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(payload['sha256']) ||
          !source.title.contains('SHA256:${payload['sha256']}')) {
        return null;
      }
      final rows = (payload['coreRowProvenance'] as List)
          .cast<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
      if (!rowsProof(
        rows,
        company,
        receipt,
        report.fsDiv,
        Uri.parse(source.url!),
      )) {
        return null;
      }
      final actual = facts.where((f) => f.id == line.factId).toList();
      if (actual.length != 1) return null;
      final f = actual.single;
      if (f.sourceId != source.id ||
          f.reportId != report.id ||
          f.companyId != report.companyId ||
          f.fsDiv != report.fsDiv ||
          f.bsnsYear != 2025 ||
          f.reportCode != FinancialReportCode.annual ||
          f.accountId != null ||
          f.amount != null ||
          f.cumulativeAmount != null ||
          f.statement != FinancialStatementKind.comprehensiveIncome ||
          label(f.accountName) !=
              label(
                rows.singleWhere(
                  (r) => r['thstrm_amount'] == null,
                )['account_nm'],
              )) {
        return null;
      }
      // Audit numeric rows must correspond to the same source's actual facts.
      for (final row in rows.where((r) => r['thstrm_amount'] != null)) {
        final found = facts
            .where(
              (f) =>
                  f.sourceId == source.id &&
                  f.reportId == report.id &&
                  f.companyId == report.companyId &&
                  f.fsDiv == report.fsDiv &&
                  f.bsnsYear == 2025 &&
                  f.reportCode == FinancialReportCode.annual &&
                  f.currency == 'KRW' &&
                  f.accountId == null &&
                  f.accountName == row['account_nm'] &&
                  f.amount?.toString() == row['thstrm_amount'],
            )
            .toList();
        if (found.length != 1) return null;
      }
      return '2025 원문 영업수익 당기 금액 미기재(-) · 0으로 간주하지 않습니다';
    } catch (_) {
      return null;
    }
  }
}
