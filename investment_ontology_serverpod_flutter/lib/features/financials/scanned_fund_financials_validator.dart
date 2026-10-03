import 'dart:convert';

import 'scanned_fund_source_registry.dart';

BigInt? scannedFundInteger(String text) {
  final raw = text.trim();
  if (raw == '-') return null;
  if (!RegExp(
    r'^(?:-?\d{1,3}(?:[.,]\s*\d{3})+|\(\d{1,3}(?:[.,]\s*\d{3})+\)|-?\d+)$',
  ).hasMatch(raw)) {
    throw const FormatException('Invalid scanned source-local integer grammar');
  }
  final n = raw.replaceAll(RegExp(r'[.,\s]'), '');
  return BigInt.parse(
    n.startsWith('(') ? '-${n.substring(1, n.length - 1)}' : n,
  );
}

String _signForm(String raw) => raw.trim().startsWith('(')
    ? 'parentheses'
    : raw.trim().startsWith('-')
    ? 'minus'
    : 'unsigned';
List<Map<String, dynamic>> validateScannedFundRows(dynamic raw) {
  if (raw is! List || raw.isEmpty || raw.length > 2) {
    throw const FormatException('Two exact scanned fund periods required');
  }
  final seen = <String>{};
  return raw.map((v) {
    if (v is! Map) {
      throw const FormatException('Scanned fund row required');
    }
    final r = Map<String, dynamic>.from(v),
        pins = ScannedFundSourceRegistry.rows.where(
          (p) => p['officialUrl'] == r['officialUrl'],
        );
    if (pins.length != 1) {
      throw const FormatException('Bound original scan required');
    }
    final pin = pins.single;
    if (!seen.add(r['officialUrl']) ||
        pin.entries
            .where((e) => e.key != 'accounts')
            .any((e) => jsonEncode(r[e.key]) != jsonEncode(e.value)) ||
        r['categorySchema'] != 'printedScannedFundCategories' ||
        r['basis'] != 'singleFundEntity' ||
        r['periodKind'] != 'ownTwelveMonthFiscalYear' ||
        r['auditStatus'] != 'opinionNotExtracted' ||
        r['observationRole'] != 'currentOwn' ||
        r['currency'] != 'KRW' ||
        r['printedUnit'] != '원' ||
        r['precisionUnit'] != '1' ||
        r['numericState'] != 'partialPrintedScannedFundCategories' ||
        r['publicContent'] != 'sourceLinkAndValues' ||
        r['extractedBy'] != 'sourceBoundDualLocalOcrRule' ||
        r['parserVersion'] != 'mkif-scanned-own-current-v1' ||
        r['acceptedSeparatorGrammar'] != 'grouped-integer-comma-or-dot-v1' ||
        r['rawOcrRewritten'] != false ||
        r['regularReportCode'] != null ||
        r['xbrlAccountId'] != null ||
        r['fullStatementCollected'] != false ||
        r['notesDecodedOrVerified'] != false ||
        r['wholeDocumentOcrReviewed'] != false ||
        r['accounts'] is! List ||
        r['accounts'].length != 8 ||
        r['validation'] is! Map) {
      throw const FormatException('Scanned source/category contract mismatch');
    }
    for (var i = 0; i < 8; i++) {
      final a = r['accounts'][i], bound = pin['accounts'][i];
      if (a is! Map ||
          bound.entries.any(
            (e) => jsonEncode(a[e.key]) != jsonEncode(e.value),
          ) ||
          a['ocrText'] is! String ||
          a['independentOcrText'] is! String ||
          a['cashDirection'] != (i >= 6 ? 'outflow' : null) ||
          a['amountScope'] !=
              (i < 3 ? 'stockAtPeriodEnd' : 'ownFiscalDuration') ||
          a['periodStart'] != (i < 3 ? r['periodEnd'] : r['periodStart']) ||
          a['periodEnd'] != r['periodEnd'] ||
          a['amountRole'] != 'derivedIntegerFromDualOCR;rawOCRUnchanged' ||
          a['acceptedSeparatorGrammar'] != 'grouped-integer-comma-or-dot-v1' ||
          a['accountLabel'] is! String ||
          a['currency'] != 'KRW' ||
          a['printedUnit'] != '원' ||
          a['precisionUnit'] != '1') {
        throw const FormatException(
          'Scanned source coordinate/current category mismatch',
        );
      }
      final n = scannedFundInteger(a['ocrText']),
          other = scannedFundInteger(a['independentOcrText']);
      if (n == null ||
          n != other ||
          _signForm(a['ocrText']) != _signForm(a['independentOcrText']) ||
          a['amountInteger'] != n.toString() ||
          a['printedSign'] !=
              (n.isNegative
                  ? 'negative'
                  : n == BigInt.zero
                  ? 'zero'
                  : 'positive')) {
        throw const FormatException('Independent OCR digit/sign disagreement');
      }
    }
    return r;
  }).toList();
}
