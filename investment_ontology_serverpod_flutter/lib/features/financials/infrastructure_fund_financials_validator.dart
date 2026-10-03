import 'dart:convert';

import 'infrastructure_fund_source_registry.dart';

/// Exact printed fund categories, without industrial or XBRL substitution.
List<Map<String, dynamic>> validateInfrastructureFundRows(dynamic raw) {
  if (raw is! List || raw.isEmpty || raw.length > 3) {
    throw const FormatException('Infrastructure fund periods required');
  }
  final seen = <String>{};
  String? corp;
  return raw.map((v) {
    if (v is! Map) {
      throw const FormatException('Infrastructure fund row required');
    }
    final r = Map<String, dynamic>.from(v);
    final pins = InfrastructureFundSourceRegistry.rows.where(
      (p) => p['officialUrl'] == r['officialUrl'],
    );
    if (pins.length != 1) {
      throw const FormatException('Exact infrastructure PDF required');
    }
    final pin = pins.single;
    corp ??= r['corpCode'];
    if (corp != r['corpCode'] ||
        !seen.add(r['officialUrl']) ||
        pin.entries
            .where((e) => e.key != 'accounts')
            .any((e) => jsonEncode(r[e.key]) != jsonEncode(e.value)) ||
        r['categorySchema'] != 'printedInfrastructureFundCategories' ||
        r['basis'] != 'singleFundEntity' ||
        r['periodKind'] != 'ownTwelveMonthFiscalYear' ||
        r['auditStatus'] != 'opinionNotExtracted' ||
        r['observationRole'] != 'currentOwn' ||
        r['currency'] != 'KRW' ||
        r['printedUnit'] != '원' ||
        r['precisionUnit'] != '1' ||
        r['numericState'] != 'partialPrintedInfrastructureFundCategories' ||
        r['publicContent'] != 'sourceLinkAndValues' ||
        r['extractedBy'] != 'fixedPdfFontRule' ||
        r['parserVersion'] != 'infrastructure-printed-current-v1' ||
        r['extractionTool'] != 'pdftotext 26.02.0 -layout -enc UTF-8' ||
        r['regularReportCode'] != null ||
        r['xbrlAccountId'] != null ||
        r['fullStatementCollected'] != false ||
        r['wholeFontMapVerified'] != false ||
        r['notesDecodedOrVerified'] != false ||
        r['accounts'] is! List ||
        (r['accounts'] as List).length != 8 ||
        r['validation'] is! Map) {
      throw const FormatException(
        'Infrastructure source/fiscal contract mismatch',
      );
    }
    const metrics = [
      'assets',
      'liabilities',
      'equity',
      'fundOperatingIncome',
      'netProfit',
      'assetManagementCashFlow',
      'fundLoanAcquisition',
      'fundEquityAcquisition',
    ];
    final a = r['accounts'] as List;
    for (var i = 0; i < a.length; i++) {
      final c = a[i];
      if (c is! Map ||
          c['metric'] != metrics[i] ||
          (pin['accounts'] as List)[i].entries.any(
            (e) => jsonEncode(c[e.key]) != jsonEncode(e.value),
          ) ||
          c['periodStart'] != (i < 3 ? r['periodEnd'] : r['periodStart']) ||
          c['periodEnd'] != r['periodEnd'] ||
          c['accountLabel'] is! String ||
          c['pageOrdinal'] is! int ||
          c['lineOrdinal'] is! int ||
          c['cashDirection'] != (i >= 6 ? 'outflow' : null) ||
          c['amountScope'] !=
              (i < 3 ? 'stockAtPeriodEnd' : 'ownFiscalDuration') ||
          c['currency'] != 'KRW' ||
          c['printedUnit'] != '원' ||
          c['precisionUnit'] != '1') {
        throw const FormatException('Infrastructure category mismatch');
      }
      final literal = c['printedAmount'];
      if (literal is! String ||
          !RegExp(
            r'^(?:-?\d{1,3}(?:,\d{3})*|-?\d+|\(\d{1,3}(?:,\d{3})*\)|\(\d+\))$',
          ).hasMatch(literal)) {
        throw const FormatException('Printed integer required');
      }
      final amount = BigInt.parse(
        literal.startsWith('(')
            ? '-${literal.substring(1, literal.length - 1).replaceAll(',', '')}'
            : literal.replaceAll(',', ''),
      );
      if (amount.toString() != c['amountInteger'] ||
          c['printedSign'] !=
              (amount.isNegative
                  ? 'negative'
                  : amount == BigInt.zero
                  ? 'zero'
                  : 'positive')) {
        throw const FormatException('Printed sign mismatch');
      }
    }
    return r;
  }).toList()..sort(
    (a, b) => '${b['periodEnd']}'.compareTo('${a['periodEnd']}'),
  );
}
