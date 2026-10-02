import 'dart:convert';

import '../../generated/protocol.dart';

/// Exact normal-ingest proof for IMGT and two verified SPAC OFS sources.
/// Every printed missing amount remains null; this never infers zero.
abstract final class ImgtExplicitRevenueMissing {
  static const receipt = '20260330001850';
  static const corp = '01579020';
  static const rule = 'imgt-explicit-revenue-null-v1';
  static const note = '부분 핵심6계정 · 영업수익 당기 금액 원문 미기재(-), 0·전기 대체 없음';
  static const spac = {
    '20230315000997': (
      corp: '01601222',
      dcm: '9059566',
      offset: '123918',
      length: '36101',
    ),
    '20230308000311': (
      corp: '01476219',
      dcm: '9041541',
      offset: '99116',
      length: '33528',
    ),
  };
  static bool supports(String company, String target) =>
      (company == corp && target == receipt) || spac[target]?.corp == company;
  static String ruleFor(String target) =>
      target == receipt ? rule : 'spac-explicit-revenue-null-v1';
  static int yearFor(String target) => target == receipt ? 2025 : 2022;
  static Uri sourceFor(String target, FsDiv basis) {
    if (target == receipt) return source(basis);
    final p = spac[target]!;
    return Uri.parse(
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=$target&dcmNo=${p.dcm}&eleId=21&offset=${p.offset}&length=${p.length}&dtd=dart3.xsd',
    );
  }

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
    if (!supports(company, target) ||
        (target != receipt && basis != FsDiv.separate) ||
        uri != sourceFor(target, basis)) {
      return false;
    }
    final missing = rows.where((r) => r['thstrm_amount'] == null).toList();
    if (missing.length != 1) return false;
    final row = missing.single;
    final p = row['html_provenance'];
    if (row['rcept_no'] != target ||
        row['corp_code'] != company ||
        row['bsns_year'] != '${yearFor(target)}' ||
        row['reprt_code'] != '11011' ||
        row['sj_div'] != 'CIS' ||
        row['account_id'] != null ||
        !{
          'I.영업수익',
          'Ⅰ.영업수익',
          if (target != receipt) '영업수익',
        }.contains(label(row['account_nm'])) ||
        p is! Map) {
      return false;
    }
    final ce = p['supportingPeriodEvidence'];
    if (target != receipt) {
      if (ce is! Map ||
          ce['unit'] != '원' ||
          ce['periodStart'] != '2022-01-01' ||
          ce['periodEnd'] != '2022-12-31' ||
          ce['wholeTotalColumn'] != (target == '20230315000997' ? 5 : 6) ||
          p['printedCurrentCells'] is! List ||
          jsonEncode(p['printedCurrentCells']) != '["","-"]') {
        return false;
      }
      String? value(Set<String> labels) {
        final matches = rows
            .where(
              (r) => labels.contains(
                label(r['account_nm'])
                    .replaceFirst(RegExp(r'^[Ⅰ-ⅫIVXLCDM0-9]+[.)]'), ''),
              ),
            )
            .toList();
        return matches.length == 1
            ? matches.single['thstrm_amount'] as String?
            : null;
      }

      final assets = value({'자산총계'}),
          liabilities = value({'부채총계'}),
          equity = value({'자본총계'});
      final profit = value({'당기순이익', '당기순이익(손실)'});
      if (assets == null ||
          liabilities == null ||
          equity == null ||
          profit == null ||
          ce['closingEquity'] != equity ||
          ce['currentProfit'] != profit) {
        return false;
      }
      final a = BigInt.tryParse(assets),
          l = BigInt.tryParse(liabilities),
          e = BigInt.tryParse(equity);
      if (a == null || l == null || e == null || a != l + e) {
        return false;
      }
    }
    return p['partialCoreRule'] == ruleFor(target) &&
        p['explicitMissingAmount'] == 'printed-dash-no-zero-or-prior' &&
        p['source'] == uri.toString() &&
        p['basis'] == (basis == FsDiv.consolidated ? 'CFS' : 'OFS') &&
        p['periodStart'] == '${yearFor(target)}-01-01' &&
        p['periodEnd'] == '${yearFor(target)}-12-31' &&
        p['unit'] == '원' &&
        p['currentColumn'] == 2 &&
        p['currentColumnSpan'] == (target == receipt ? 1 : 2) &&
        p['printedCurrentCells'] is List &&
        (p['printedCurrentCells'] as List).length ==
            (target == receipt ? 1 : 2) &&
        (p['printedCurrentCells'] as List).where((c) => c == '-').length == 1 &&
        (p['printedCurrentCells'] as List).every((c) => c == '-' || c == '') &&
        ce is Map &&
        ce['mode'] == ruleFor(target) &&
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
    final target = report.rceptNo;
    final year = yearFor(target);
    if (!supports(company, target) ||
        report.bsnsYear != year ||
        report.reportCode != FinancialReportCode.annual ||
        line.key != 'revenue' ||
        line.amount != null ||
        line.cumulativeAmount != null ||
        source.id != report.sourceId ||
        source.reference != target ||
        source.kind != SourceKind.dartReport ||
        source.url != sourceFor(target, report.fsDiv).toString() ||
        audit.reference !=
            'financial-api-noData-source:$target:${report.fsDiv.name}' ||
        audit.kind != SourceKind.dartReport ||
        audit.url != source.url) {
      return null;
    }
    try {
      final payload = jsonDecode(audit.title);
      if (payload is! Map ||
          payload['corpCode'] != company ||
          payload['sourceReceipt'] != target ||
          payload['targetReceipt'] != target ||
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
        target,
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
          f.bsnsYear != year ||
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
                  f.bsnsYear == year &&
                  f.reportCode == FinancialReportCode.annual &&
                  f.currency == 'KRW' &&
                  f.accountId == null &&
                  f.accountName == row['account_nm'] &&
                  f.amount?.toString() == row['thstrm_amount'],
            )
            .toList();
        if (found.length != 1) return null;
      }
      return '$year 원문 영업수익 당기 금액 미기재(-) · 0으로 간주하지 않습니다';
    } catch (_) {
      return null;
    }
  }
}
