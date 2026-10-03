import 'mkif_halfyear_five.dart';
import 'issuer_financials_html.dart';
import 'fund_financials_text.dart';
import 'infrastructure_fund_financials.dart';
import 'scanned_fund_financials.dart';
import 'retrospective_fund_contract.dart';
import 'ipo_issuer_financials_html.dart';
import 'reviewed_dart_issuer_sources.dart';

/// Only immutable internal source-parser observations; external import is blocked.
abstract final class IssuerFinancialsFeed {
  static List<Map<String, dynamic>> validate(dynamic input) {
    if (input is List &&
        input.isNotEmpty &&
        input.every(
          (r) =>
              r is Map &&
              {
                InfrastructureFundFinancials.category,
                MkifHalfYearFive.category,
                ScannedFundFinancials.category,
                RetrospectiveFundContract.category,
              }.contains(r['categorySchema']),
        )) {
      if (input.length > 5 ||
          input.map((r) => r['corpCode']).toSet().length != 1 ||
          input
                  .map(
                    (r) =>
                        '${r['officialUrl']}|${r['periodStart']}|${r['periodEnd']}',
                  )
                  .toSet()
                  .length !=
              input.length) {
        throw const FormatException(
          'Exact same-issuer bounded fund sources required',
        );
      }
      final text = input
          .where(
            (r) => r['categorySchema'] == InfrastructureFundFinancials.category,
          )
          .toList();
      final retrospective = input
          .where(
            (r) => r['categorySchema'] == RetrospectiveFundContract.category,
          )
          .toList();
      final scans = input
          .where((r) => r['categorySchema'] == ScannedFundFinancials.category)
          .toList();
      return [
        if (input.any((r) => r['categorySchema'] == MkifHalfYearFive.category))
          ...MkifHalfYearFive.validateRows(
            input
                .where((r) => r['categorySchema'] == MkifHalfYearFive.category)
                .toList(),
          ),
        if (text.isNotEmpty) ...InfrastructureFundFinancials.validateRows(text),
        if (scans.isNotEmpty) ...ScannedFundFinancials.validateRows(scans),
        if (retrospective.isNotEmpty)
          ...RetrospectiveFundContract.validateRows(retrospective),
      ];
    }
    if (input is List &&
        input.isNotEmpty &&
        input.first is Map &&
        input.first['categorySchema'] == FundFinancialsText.category) {
      return FundFinancialsText.validateRows(input);
    }
    if (input is! List || input.isEmpty || input.length > 5) {
      throw const FormatException('Partial issuer financial rows required');
    }
    if (input.first is Map &&
        IpoIssuerFinancialsHtml.supportsCorp('${input.first['corpCode']}')) {
      return IpoIssuerFinancialsHtml.validateRows(input);
    }
    final seen = <String>{};
    return input.map((raw) {
      if (raw is! Map) {
        throw const FormatException('Issuer financial row object required');
      }
      final r = Map<String, dynamic>.from(raw),
          doc = ReviewedDartIssuerSources.findUrl(
            '${raw['officialUrl']}',
            '${raw['corpCode']}',
          );
      if (doc == null || !IssuerFinancialsHtml.supports(doc)) {
        throw const FormatException('Unreviewed numeric issuer source');
      }
      final m = doc['metadata'] as Map,
          annual = m['documentType'] == 'auditReport',
          basis = r['basis'];
      const keys = {
        'corpCode',
        'documentType',
        'provider',
        'providerReceipt',
        'officialUrl',
        'sha256',
        'basis',
        'periodStart',
        'periodEnd',
        'periodKind',
        'auditStatus',
        'observationRole',
        'currency',
        'printedUnit',
        'precisionUnit',
        'numericState',
        'publicContent',
        'extractedBy',
        'parserVersion',
        'accounts',
        'regularReportCode',
        'xbrlAccountId',
        'completenessNote',
      };
      if (r.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(r.keys.toSet()).isNotEmpty ||
          [
            'corpCode',
            'documentType',
            'provider',
            'providerReceipt',
            'officialUrl',
            'sha256',
            'periodStart',
            'periodEnd',
          ].any((k) => r[k] != m[k]) ||
          !{'CFS', 'OFS'}.contains(basis) ||
          annual && basis != 'OFS' ||
          r['periodKind'] != (annual ? 'ownAnnual' : 'halfYear') ||
          r['auditStatus'] != (annual ? 'audited' : 'reviewed') ||
          r['observationRole'] != 'currentOwn' ||
          r['currency'] != 'KRW' ||
          r['printedUnit'] != '원' ||
          r['precisionUnit'] != '1' ||
          r['numericState'] != 'partialCore' ||
          r['publicContent'] != 'sourceLinkAndValues' ||
          r['extractedBy'] != 'fixedHtmlRule' ||
          r['parserVersion'] != IssuerFinancialsHtml.version ||
          r['regularReportCode'] != null ||
          r['xbrlAccountId'] != null ||
          r['completenessNote'] !=
              '대체 공식 원문 현재기간 핵심 8계정 · 정기 API 집계와 분리 · 비교기간 미추출' ||
          !seen.add('${r['officialUrl']}|$basis') ||
          r['accounts'] is! List ||
          (r['accounts'] as List).length != 8) {
        throw const FormatException('Issuer numeric provenance mismatch');
      }
      final values = <String, BigInt>{};
      for (final a in r['accounts'] as List) {
        const ak = {
          'metric',
          'accountLabel',
          'printedAmount',
          'amountInteger',
          'statement',
          'amountScope',
          'cashDirection',
          'tableOrdinal',
          'rowOrdinal',
          'cellOrdinal',
          'headerCells',
          'rowCells',
        };
        if (a is! Map ||
            a.keys.toSet().difference(ak).isNotEmpty ||
            ak.difference(a.keys.toSet()).isNotEmpty ||
            !IssuerFinancialsHtml.metrics.contains(a['metric']) ||
            values.containsKey(a['metric']) ||
            a['printedAmount'] is! String ||
            IssuerFinancialsHtml.integer(a['printedAmount']) !=
                a['amountInteger'] ||
            a['rowCells'] is! List ||
            a['headerCells'] is! List ||
            a['rowOrdinal'] is! int ||
            (a['rowOrdinal'] as int) < 1 ||
            (a['rowOrdinal'] as int) > 50) {
          throw const FormatException('Financial cell proof mismatch');
        }
        final metric = a['metric'] as String,
            index = IssuerFinancialsHtml.metrics.indexOf(metric),
            st = index < 3
                ? 'BS'
                : index < 6
                ? 'IS'
                : 'CF';
        final ti = annual
            ? (st == 'BS'
                  ? 6
                  : st == 'IS'
                  ? 9
                  : 15)
            : basis == 'CFS'
            ? (st == 'BS'
                  ? 5
                  : st == 'IS'
                  ? 9
                  : 15)
            : (st == 'BS'
                  ? 163
                  : st == 'IS'
                  ? 167
                  : 173);
        final ci = annual
            ? 2
            : st == 'IS'
            ? 2
            : 1;
        final labels = {
          'assets': '자산총계',
          'liabilities': '부채총계',
          'equity': '자본총계',
          'revenue': annual ? 'I.매출' : 'I.매출액',
          'operatingProfit': 'V.영업이익',
          'netProfit': annual || basis == 'OFS' ? 'XII.당기순이익' : 'XII.반기순이익',
          'operatingCashFlow': annual ? 'Ⅰ.영업활동으로인한현금흐름' : 'I.영업활동으로인한현금흐름',
          'propertyPlantEquipmentAcquisitions': '유형자산의취득',
        };
        final header = a['headerCells'] as List,
            label = a['accountLabel'],
            term = DateTime.parse(r['periodEnd'] as String).year - 2014;
        if (label is! String ||
            !IssuerFinancialsHtml.compact(label).startsWith(labels[metric]!) ||
            header.length < 3 ||
            header.any((cell) => cell is! String) ||
            (annual
                ? (st == 'BS'
                      ? !IssuerFinancialsHtml.compact(header[2])
                            .startsWith('제$term(당)기말')
                      : IssuerFinancialsHtml.compact(header[2]) != '제$term(당)기')
                : header[1] != '2026연도 반기 (제12기)')) {
          throw const FormatException(
            'Printed account/current period mismatch',
          );
        }
        if (a['tableOrdinal'] != ti ||
            a['cellOrdinal'] != ci ||
            a['statement'] != st ||
            a['amountScope'] != (st == 'BS' ? 'instant' : 'cumulative') ||
            a['cashDirection'] !=
                (metric == 'propertyPlantEquipmentAcquisitions'
                    ? 'outflow'
                    : null) ||
            (a['rowCells'] as List).length <= ci ||
            (a['rowCells'] as List)[ci] != a['printedAmount'] ||
            (a['rowCells'] as List).first != a['accountLabel']) {
          throw const FormatException('Current primary cell/basis mismatch');
        }
        values[metric] = BigInt.parse(a['amountInteger'] as String);
      }
      if (values['assets'] != values['liabilities']! + values['equity']!) {
        throw const FormatException('Issuer balance equation mismatch');
      }
      return r;
    }).toList();
  }
}
