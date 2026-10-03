import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'scanned_fund_profiles.dart';

/// Exact two MKIF scans; punctuation grammar is local to this source category.
abstract final class ScannedFundFinancials {
  static const category = 'printedScannedFundCategories';
  static const version = 'mkif-scanned-own-current-v1';
  static const grammar = 'grouped-integer-comma-or-dot-v1';
  static Map<String, dynamic>? profile(Map metadata) {
    final matches = ScannedFundProfiles.rows.where(
      (p) =>
          metadata.length == (p['metadata'] as Map).length &&
          (p['metadata'] as Map).entries.every(
            (e) => jsonEncode(metadata[e.key]) == jsonEncode(e.value),
          ),
    );
    return matches.length == 1 ? matches.single : null;
  }

  static bool supports(Map d) =>
      d['metadata'] is Map && profile(d['metadata']) != null;
  static BigInt? integer(String text) {
    final raw = text.trim();
    if (raw == '-') return null;
    if (!RegExp(
      r'^(?:-?\d{1,3}(?:[.,]\s*\d{3})+|\(\d{1,3}(?:[.,]\s*\d{3})+\)|-?\d+)$',
    ).hasMatch(raw)) {
      throw const FormatException(
        'Invalid source-local separator grammar or digit/letter',
      );
    }
    final n = raw.replaceAll(RegExp(r'[.,\s]'), '');
    return BigInt.parse(
      n.startsWith('(') ? '-${n.substring(1, n.length - 1)}' : n,
    );
  }

  static String _form(String text) => text.trim().startsWith('(')
      ? 'parentheses'
      : text.trim().startsWith('-')
      ? 'minus'
      : 'unsigned';
  static void verifyPdf(Map metadata, List<int> raw) {
    if (profile(metadata) == null ||
        raw.length < 5 ||
        raw.length > 20 * 1024 * 1024 ||
        utf8.decode(raw.take(5).toList()) != '%PDF-' ||
        sha256.convert(raw).toString() != metadata['sha256']) {
      throw const FormatException('Exact scanned original PDF required');
    }
  }

  static Map<String, dynamic> parse(Map metadata, List<int> raw) {
    final p = profile(metadata);
    if (p == null ||
        raw.length > 4 * 1024 * 1024 ||
        sha256.convert(raw).toString() != p['sidecarSha256']) {
      throw const FormatException(
        'Exact immutable scanned OCR sidecar required',
      );
    }
    final side = jsonDecode(utf8.decode(raw)) as Map;
    if (side['schemaVersion'] != 1 ||
        jsonEncode(side['metadata']) != jsonEncode(p['metadata']) ||
        jsonEncode(side['pipeline']) != jsonEncode(p['pipeline']) ||
        side['acceptedSeparatorGrammar'] != grammar ||
        side['rawOcrRewritten'] != false ||
        side['regularApiOrXbrl'] != false ||
        side['notesVerified'] != false ||
        side['wholeStatementVerified'] != false ||
        side['pages'] is! List ||
        side['pages'].length != 6) {
      throw const FormatException(
        'Scanned original/pipeline contract mismatch',
      );
    }
    final pages = <int, Map<String, dynamic>>{};
    for (var i = 0; i < 6; i++) {
      final source = side['pages'][i],
          pin = (p['sourcePages'] as List)[i] as Map;
      if (source is! Map ||
          pin.entries.any((e) => source[e.key] != e.value) ||
          source['koJson'] is! String ||
          source['enJson'] is! String ||
          sha256.convert(utf8.encode(source['koJson'])).toString() !=
              pin['koSha256'] ||
          sha256.convert(utf8.encode(source['enJson'])).toString() !=
              pin['enSha256']) {
        throw const FormatException('Exact image and dual raw OCR required');
      }
      pages[pin['pageOrdinal']] = {
        'ko': jsonDecode(source['koJson']),
        'en': jsonDecode(source['enJson']),
      };
    }
    final cells = <String, dynamic>{};
    for (final e in (p['cells'] as Map).entries) {
      final pin = e.value as Map, page = pages[pin['pageOrdinal']]!;
      final ko = page['ko']['rows'][pin['koRowIndex']],
          en = pin['enRowIndex'] == null
              ? null
              : page['en']['rows'][pin['enRowIndex']];
      final amount = integer(ko['text']);
      if ((en == null && amount != null) ||
          (en != null &&
              (integer(en['text']) != amount ||
                  _form(en['text']) != _form(ko['text'])))) {
        throw const FormatException('Independent OCR digits/sign disagreement');
      }
      cells[e.key] = {
        'key': e.key,
        ...Map<String, dynamic>.from(pin),
        'ko': ko,
        'en': en,
        'amountInteger': amount?.toString(),
        'acceptedSeparatorGrammar': grammar,
      };
    }
    final validation = _proof(p, cells);
    final accounts = (p['observations'] as List).map((bound) {
      final c = cells[bound['cellKey']], n = integer(c['ko']['text']);
      if (n == null) {
        throw const FormatException('Selected current source amount required');
      }
      return <String, dynamic>{
        ...Map<String, dynamic>.from(bound),
        'pageOrdinal': c['pageOrdinal'],
        'ocrRowIndex': c['koRowIndex'],
        'independentOcrRowIndex': c['enRowIndex'],
        'koBoundingBox': c['koBox'],
        'enBoundingBox': c['enBox'],
        'ocrText': c['ko']['text'],
        'independentOcrText': c['en']['text'],
        'amountInteger': n.toString(),
        'amountRole': 'derivedIntegerFromDualOCR;rawOCRUnchanged',
        'acceptedSeparatorGrammar': grammar,
        'currency': 'KRW',
        'printedUnit': '원',
        'precisionUnit': '1',
        'printedSign': n.isNegative
            ? 'negative'
            : n == BigInt.zero
            ? 'zero'
            : 'positive',
        'periodStart': bound['amountScope'] == 'stockAtPeriodEnd'
            ? metadata['periodEnd']
            : metadata['periodStart'],
        'periodEnd': metadata['periodEnd'],
      };
    }).toList();
    return {
      'corpCode': metadata['corpCode'],
      'categorySchema': category,
      'documentType': metadata['documentType'],
      'provider': metadata['provider'],
      'providerReceipt': metadata['providerReceipt'],
      'officialUrl': metadata['officialUrl'],
      'sha256': metadata['sha256'],
      'periodStart': metadata['periodStart'],
      'periodEnd': metadata['periodEnd'],
      'basis': 'singleFundEntity',
      'periodKind': 'ownTwelveMonthFiscalYear',
      'auditStatus': 'opinionNotExtracted',
      'observationRole': 'currentOwn',
      'currency': 'KRW',
      'printedUnit': '원',
      'precisionUnit': '1',
      'numericState': 'partialPrintedScannedFundCategories',
      'publicContent': 'sourceLinkAndValues',
      'extractedBy': 'sourceBoundDualLocalOcrRule',
      'parserVersion': version,
      'sidecarSha256': p['sidecarSha256'],
      'acceptedSeparatorGrammar': grammar,
      'pipeline': p['pipeline'],
      'sourcePages': p['sourcePages'],
      'visualReadScope': p['visualReadScope'],
      'rawOcrRewritten': false,
      'regularReportCode': null,
      'xbrlAccountId': null,
      'fullStatementCollected': false,
      'notesDecodedOrVerified': false,
      'wholeDocumentOcrReviewed': false,
      'accounts': accounts,
      'validation': validation,
    };
  }

  static Map<String, dynamic> _proof(Map p, Map cells) {
    if (cells.keys.toSet().length != (p['cells'] as Map).length ||
        cells.keys
            .toSet()
            .difference((p['cells'] as Map).keys.toSet())
            .isNotEmpty) {
      throw const FormatException('Exact source witness set required');
    }
    for (final e in (p['cells'] as Map).entries) {
      final c = cells[e.key], pin = e.value as Map;
      if (c is! Map ||
          c['ko'] is! Map ||
          pin.entries.any((e) => jsonEncode(c[e.key]) != jsonEncode(e.value)) ||
          c['acceptedSeparatorGrammar'] != grammar) {
        throw const FormatException('Bound source OCR witness required');
      }
      for (final lang in ['ko', 'en']) {
        final r = c[lang], box = pin['${lang}Box'];
        if (box == null) {
          if (r != null) {
            throw const FormatException('Missing witness cannot become amount');
          }
          continue;
        }
        if (r is! Map ||
            r['text'] is! String ||
            (box as Map).entries.any((e) => r[e.key] != e.value)) {
          throw const FormatException('Immutable source numeric bbox required');
        }
      }
      if (sha256.convert(utf8.encode(c['ko']['text'])).toString() !=
              pin['koTokenSha256'] ||
          (c['en'] != null &&
              sha256.convert(utf8.encode(c['en']['text'])).toString() !=
                  pin['enTokenSha256'])) {
        throw const FormatException('Exact original OCR token digest required');
      }
      final n = integer(c['ko']['text']);
      if (n?.toString() != c['amountInteger'] ||
          (c['en'] == null && n != null) ||
          (c['en'] != null &&
              (integer(c['en']['text']) != n ||
                  _form(c['ko']['text']) != _form(c['en']['text'])))) {
        throw const FormatException('Stored dual OCR digits/sign disagreement');
      }
    }
    final checks = <Map<String, dynamic>>[];
    for (final bound in p['checks'] as List) {
      final left = integer(cells[bound['left']]['ko']['text']);
      var total = BigInt.zero, missing = 0;
      for (final term in bound['terms'] as List) {
        final n = integer(cells[term['key']]['ko']['text']);
        if ((n == null) != term['missing']) {
          throw const FormatException(
            'Missing witness cannot become numeric zero',
          );
        }
        if (n == null) {
          missing++;
        } else {
          total += n * BigInt.from(term['coefficient']);
        }
      }
      if (left == null || left != total) {
        throw const FormatException('Scanned BS/PL/CE/CF equation mismatch');
      }
      checks.add({
        ...Map<String, dynamic>.from(bound),
        'difference': '0',
        'missingTerms': missing,
      });
    }
    return {
      'checks': checks,
      'cells': cells,
      'printedMissingCEComponents': p['printedMissingCEComponents'],
      'cashScope':
          'numericalPrintedRowsAgree;differentCashLabelsNotDeclaredEquivalent',
      'missingWitnessesAreAmountFacts': false,
      'taxDashIsAmountFact': false,
    };
  }

  static List<Map<String, dynamic>> validateRows(dynamic raw) {
    if (raw is! List || raw.isEmpty || raw.length > 2) {
      throw const FormatException('Two exact MKIF scan periods only');
    }
    final seen = <String>{};
    return raw.map((value) {
      if (value is! Map) {
        throw const FormatException('Scanned source row required');
      }
      final row = Map<String, dynamic>.from(value),
          matches = ScannedFundProfiles.rows.where(
            (p) => p['metadata']['officialUrl'] == row['officialUrl'],
          );
      if (matches.length != 1) {
        throw const FormatException('Unbound scanned source');
      }
      final p = matches.single, m = p['metadata'] as Map;
      if (!seen.add(row['officialUrl']) ||
          [
            'corpCode',
            'documentType',
            'provider',
            'providerReceipt',
            'officialUrl',
            'sha256',
            'periodStart',
            'periodEnd',
          ].any((k) => row[k] != m[k]) ||
          row['categorySchema'] != category ||
          row['basis'] != 'singleFundEntity' ||
          row['periodKind'] != 'ownTwelveMonthFiscalYear' ||
          row['auditStatus'] != 'opinionNotExtracted' ||
          row['observationRole'] != 'currentOwn' ||
          row['currency'] != 'KRW' ||
          row['printedUnit'] != '원' ||
          row['precisionUnit'] != '1' ||
          row['numericState'] != 'partialPrintedScannedFundCategories' ||
          row['publicContent'] != 'sourceLinkAndValues' ||
          row['extractedBy'] != 'sourceBoundDualLocalOcrRule' ||
          row['parserVersion'] != version ||
          row['sidecarSha256'] != p['sidecarSha256'] ||
          row['acceptedSeparatorGrammar'] != grammar ||
          row['rawOcrRewritten'] != false ||
          row['regularReportCode'] != null ||
          row['xbrlAccountId'] != null ||
          row['fullStatementCollected'] != false ||
          row['notesDecodedOrVerified'] != false ||
          row['wholeDocumentOcrReviewed'] != false ||
          [
            'pipeline',
            'sourcePages',
            'visualReadScope',
          ].any((k) => jsonEncode(row[k]) != jsonEncode(p[k])) ||
          row['validation'] is! Map ||
          row['accounts'] is! List ||
          row['accounts'].length != 8) {
        throw const FormatException(
          'Scanned exact source/category contract mismatch',
        );
      }
      const keys = {
        'corpCode',
        'categorySchema',
        'documentType',
        'provider',
        'providerReceipt',
        'officialUrl',
        'sha256',
        'periodStart',
        'periodEnd',
        'basis',
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
        'sidecarSha256',
        'acceptedSeparatorGrammar',
        'pipeline',
        'sourcePages',
        'visualReadScope',
        'rawOcrRewritten',
        'regularReportCode',
        'xbrlAccountId',
        'fullStatementCollected',
        'notesDecodedOrVerified',
        'wholeDocumentOcrReviewed',
        'accounts',
        'validation',
      };
      if (row.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(row.keys.toSet()).isNotEmpty) {
        throw const FormatException('Unexpected scanned financial fields');
      }
      final v = row['validation'] as Map;
      if (v['cells'] is! Map ||
          jsonEncode(_proof(p, v['cells'])) != jsonEncode(v)) {
        throw const FormatException(
          'Stored scanned equations/witnesses mismatch',
        );
      }
      for (var i = 0; i < 8; i++) {
        final a = row['accounts'][i],
            bound = p['observations'][i],
            c = v['cells'][bound['cellKey']],
            n = integer(c['ko']['text']);
        if (a is! Map ||
            bound.entries.any((e) => a[e.key] != e.value) ||
            n == null ||
            a['amountInteger'] != n.toString() ||
            a['ocrText'] != c['ko']['text'] ||
            a['independentOcrText'] != c['en']['text'] ||
            a['pageOrdinal'] != c['pageOrdinal'] ||
            a['ocrRowIndex'] != c['koRowIndex'] ||
            a['independentOcrRowIndex'] != c['enRowIndex'] ||
            jsonEncode(a['koBoundingBox']) != jsonEncode(c['koBox']) ||
            jsonEncode(a['enBoundingBox']) != jsonEncode(c['enBox']) ||
            a['periodStart'] != (i < 3 ? m['periodEnd'] : m['periodStart']) ||
            a['periodEnd'] != m['periodEnd'] ||
            a['currency'] != 'KRW' ||
            a['printedUnit'] != '원' ||
            a['precisionUnit'] != '1' ||
            a['amountRole'] != 'derivedIntegerFromDualOCR;rawOCRUnchanged' ||
            a['acceptedSeparatorGrammar'] != grammar ||
            a['printedSign'] !=
                (n.isNegative
                    ? 'negative'
                    : n == BigInt.zero
                    ? 'zero'
                    : 'positive')) {
          throw const FormatException(
            'Scanned source current category mismatch',
          );
        }
      }
      return row;
    }).toList();
  }
}
