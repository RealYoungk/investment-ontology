import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'fund_financials_text.dart';
import 'infrastructure_fund_profiles.dart';

/// Five exact own audits; recover only bound finance-page font encoding.
abstract final class InfrastructureFundFinancials {
  static const category = 'printedInfrastructureFundCategories';
  static const version = 'infrastructure-printed-current-v1';
  static bool supportsCorp(String corp) =>
      {'00435297', '01880801'}.contains(corp);
  static Map<String, dynamic>? profile(Map metadata) {
    final matches = InfrastructureFundProfiles.rows.where((p) {
      final expected = p['metadata'] as Map;
      return metadata.length == expected.length &&
          expected.entries.every(
            (e) => jsonEncode(metadata[e.key]) == jsonEncode(e.value),
          );
    });
    return matches.length == 1 ? matches.single : null;
  }

  static bool supports(Map document) =>
      document['metadata'] is Map && profile(document['metadata']) != null;
  static void verifyPdf(Map metadata, List<int> bytes) {
    if (profile(metadata) == null ||
        bytes.length < 5 ||
        bytes.length > 20 * 1024 * 1024 ||
        utf8.decode(bytes.take(5).toList()) != '%PDF-' ||
        sha256.convert(bytes).toString() != metadata['sha256']) {
      throw const FormatException(
        'Exact infrastructure fund original required',
      );
    }
  }

  static String _glyphLine(String line) => String.fromCharCodes(
    line.runes.map((n) {
      if (n >= 0x351 && n <= 0x371) return n - 0x331;
      if (n >= 71 && n <= 126) return n - 39;
      if (n + 0x8ecc >= 0xac00 && n + 0x8ecc <= 0xd7a3) return n + 0x8ecc;
      return n;
    }),
  );
  static String decode(String raw, List<dynamic> pages) {
    final split = raw.split('\f');
    for (final pi in pages) {
      split[(pi as int) - 1] = _glyphLine(split[pi - 1]);
    }
    return split.join('\f');
  }

  static bool _glyphProof(Map p, Map c) =>
      c['rawGlyphLine'] is String &&
      c['rawLine'] ==
          ((p['decodedPages'] as List).contains(c['pageOrdinal'])
              ? _glyphLine(c['rawGlyphLine'])
              : c['rawGlyphLine']);

  static final _number = RegExp(
    r'(?<![\w\d가-힣])(?:\(?-?\d{1,3}(?:,\d{3})+\)?|\(?-?\d+\)?|[-–])(?![\d\w.가-힣])',
  );
  static List<String> _tokens(String line) =>
      _number.allMatches(line).map((m) => m[0]!).toList();
  static String _line(List<List<String>> pages, Map c) =>
      pages[(c['pageOrdinal'] as int) - 1][(c['lineOrdinal'] as int) - 1];
  static Map<String, dynamic> _cell(
    List<List<String>> pages,
    List<List<String>> raw,
    Map c,
  ) {
    final line = _line(pages, c), tokens = _tokens(line);
    if (tokens.length != c['tokenCount']) {
      throw const FormatException(
        'Infrastructure exact token coordinates required',
      );
    }
    final current = tokens[c['currentTokenIndex']],
        prior = tokens[c['comparativeTokenIndex']];
    return {
      ...Map<String, dynamic>.from(c),
      'rawLine': line,
      'rawGlyphLine': _line(raw, c),
      'labelRawLines': (c['labelCoordinates'] as List)
          .map((v) => _line(pages, v))
          .toList(),
      'printedAmount': current,
      'comparativePrintedAmount': prior,
      'amountInteger': FundFinancialsText.integer(current)?.toString(),
      'currency': 'KRW',
      'printedUnit': '원',
      'precisionUnit': '1',
    };
  }

  static Map<String, dynamic> parseRaw(Map metadata, List<int> bytes) {
    final p = profile(metadata);
    if (p == null ||
        bytes.length > 4 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != p['rawTextSha256']) {
      throw const FormatException(
        'Exact full raw infrastructure extraction required',
      );
    }
    final raw = utf8.decode(bytes), decoded = decode(raw, p['decodedPages']);
    if (sha256.convert(utf8.encode(decoded)).toString() !=
        p['decodedTextSha256']) {
      throw const FormatException(
        'Exact bound finance glyph transform required',
      );
    }
    final pages = decoded
            .split('\f')
            .map((p) => const LineSplitter().convert(p))
            .toList(),
        rawPages = raw
            .split('\f')
            .map((p) => const LineSplitter().convert(p))
            .toList();
    final cells = {
      for (final e in (p['cells'] as Map).entries)
        e.key: _cell(pages, rawPages, e.value),
    };
    final equity = <Map<String, dynamic>>[];
    for (final c in p['equityWitnesses'] as List) {
      final line = _line(pages, c), tokens = _tokens(line);
      if (tokens.length != c['tokenCount']) {
        throw const FormatException(
          'Infrastructure CE exact token coordinates required',
        );
      }
      final parts = (c['componentTokenIndices'] as List)
          .map((i) => tokens[i])
          .toList();
      equity.add({
        ...Map<String, dynamic>.from(c),
        'printedComponents': parts,
        'rawLine': line,
        'rawGlyphLine': _line(rawPages, c),
      });
    }
    final accounts = <Map<String, dynamic>>[];
    for (final a in p['observations'] as List) {
      final c = cells[a['cellKey']]!;
      if (c['amountInteger'] == null) {
        throw const FormatException(
          'No replacement for missing infrastructure category',
        );
      }
      accounts.add({
        ...c,
        ...Map<String, dynamic>.from(a),
        'periodStart': a['amountScope'] == 'stockAtPeriodEnd'
            ? metadata['periodEnd']
            : metadata['periodStart'],
        'periodEnd': metadata['periodEnd'],
      });
    }
    final headers = (p['headers'] as List)
        .map(
          (h) => {
            ...Map<String, dynamic>.from(h),
            'printedHeader': pages[(h['pageOrdinal'] as int) - 1]
                .take(8)
                .join('\n'),
          },
        )
        .toList();
    final validation = _validateProof(p, cells, equity, accounts);
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
      'numericState': 'partialPrintedInfrastructureFundCategories',
      'publicContent': 'sourceLinkAndValues',
      'extractedBy': 'fixedPdfFontRule',
      'parserVersion': version,
      'rawTextSha256': p['rawTextSha256'],
      'decodedTextSha256': p['decodedTextSha256'],
      'decodedPages': p['decodedPages'],
      'textTransformation': p['textTransformation'],
      'extractionTool': p['extractionTool'],
      'regularReportCode': null,
      'xbrlAccountId': null,
      'fullStatementCollected': false,
      'wholeFontMapVerified': false,
      'notesDecodedOrVerified': false,
      'accounts': accounts,
      'statementHeaders': headers,
      'validation': validation,
      'completenessNote': '인프라 펀드 인쇄 계정 일부 · 고정 재무 페이지 글꼴 복원 · 주석·전체 글꼴·비교기간 미수집 · 정기 API·산업 지표·TTM과 분리',
    };
  }

  static Map<String, dynamic> _validateProof(
    Map p,
    Map cells,
    List equity,
    List accounts,
  ) {
    final expected = p['cells'] as Map;
    if (cells.keys.toSet().difference(expected.keys.toSet()).isNotEmpty ||
        expected.keys.toSet().difference(cells.keys.toSet()).isNotEmpty) {
      throw const FormatException('Infrastructure source witness set mismatch');
    }
    for (final e in expected.entries) {
      final c = cells[e.key], bound = e.value as Map;
      if (c is! Map ||
          bound.entries.any(
            (e) => jsonEncode(c[e.key]) != jsonEncode(e.value),
          ) ||
          c['rawLine'] is! String ||
          !_glyphProof(p, c) ||
          c['labelRawLines'] is! List ||
          _tokens(c['rawLine']).length != bound['tokenCount'] ||
          _tokens(c['rawLine'])[bound['currentTokenIndex']] !=
              c['printedAmount'] ||
          _tokens(c['rawLine'])[bound['comparativeTokenIndex']] !=
              c['comparativePrintedAmount'] ||
          FundFinancialsText.integer(c['printedAmount'])?.toString() !=
              c['amountInteger'] ||
          c['currency'] != 'KRW' ||
          c['printedUnit'] != '원' ||
          c['precisionUnit'] != '1') {
        throw const FormatException(
          'Infrastructure source-cell proof mismatch',
        );
      }
    }
    final checks = <Map<String, dynamic>>[];
    for (final check in p['checks'] as List) {
      final left = FundFinancialsText.integer(
        cells[check['left']]['printedAmount'],
      );
      if (left == null) {
        throw const FormatException('Printed check subtotal required');
      }
      var sum = BigInt.zero, missing = 0;
      for (final t in check['terms'] as List) {
        final amount = FundFinancialsText.integer(
          cells[t['cellKey']]['printedAmount'],
        );
        if (amount == null) {
          missing++;
          continue;
        }
        sum += amount * BigInt.from(t['coefficient']);
      }
      if (left != sum) {
        throw const FormatException('Infrastructure source hierarchy mismatch');
      }
      checks.add({
        'name': check['name'],
        'difference': '0',
        'unprintedTermCount': missing,
      });
    }
    if (equity.length != (p['equityWitnesses'] as List).length) {
      throw const FormatException('Infrastructure own CE witness set mismatch');
    }
    final totals = <BigInt>[];
    for (var i = 0; i < equity.length; i++) {
      final c = equity[i], bound = (p['equityWitnesses'] as List)[i] as Map;
      if (c is! Map ||
          bound.entries.any(
            (e) => jsonEncode(c[e.key]) != jsonEncode(e.value),
          ) ||
          c['rawLine'] is! String ||
          !_glyphProof(p, c) ||
          c['printedComponents'] is! List ||
          _tokens(c['rawLine']).length != bound['tokenCount'] ||
          jsonEncode(
                (bound['componentTokenIndices'] as List)
                    .map((i) => _tokens(c['rawLine'])[i])
                    .toList(),
              ) !=
              jsonEncode(c['printedComponents'])) {
        throw const FormatException(
          'Infrastructure original CE component proof mismatch',
        );
      }
      final parts = (c['printedComponents'] as List)
          .map((v) => FundFinancialsText.integer(v))
          .toList();
      if (parts.length != 3 ||
          parts.last == null ||
          parts
                  .take(2)
                  .whereType<BigInt>()
                  .fold(BigInt.zero, (a, b) => a + b) !=
              parts.last ||
          (i == 0 || i == equity.length - 1) && parts.any((v) => v == null)) {
        throw const FormatException(
          'Infrastructure source CE component sum mismatch',
        );
      }
      totals.add(parts.last!);
    }
    final obs = p['observations'] as List;
    if (accounts.length != 8) {
      throw const FormatException(
        'Infrastructure eight current source categories required',
      );
    }
    for (var i = 0; i < accounts.length; i++) {
      final a = accounts[i],
          bound = obs[i] as Map,
          cell = cells[bound['cellKey']];
      if (a is! Map ||
          bound.entries.any((e) => a[e.key] != e.value) ||
          cell.entries.any(
            (e) => jsonEncode(a[e.key]) != jsonEncode(e.value),
          ) ||
          a['periodStart'] !=
              (bound['amountScope'] == 'stockAtPeriodEnd'
                  ? p['metadata']['periodEnd']
                  : p['metadata']['periodStart']) ||
          a['periodEnd'] != p['metadata']['periodEnd']) {
        throw const FormatException(
          'Infrastructure category/current scope mismatch',
        );
      }
      final amount = FundFinancialsText.integer(a['printedAmount']);
      if (amount == null ||
          a['printedSign'] !=
              (amount.isNegative
                  ? 'negative'
                  : amount == BigInt.zero
                  ? 'zero'
                  : 'positive')) {
        throw const FormatException(
          'Infrastructure printed category sign mismatch',
        );
      }
    }
    BigInt account(String metric) => BigInt.parse(
      accounts.singleWhere((a) => a['metric'] == metric)['amountInteger'],
    );
    final movement =
        totals.first +
        totals
            .sublist(1, totals.length - 1)
            .fold(BigInt.zero, (a, b) => a + b) -
        totals.last;
    final currentProfit = equity
        .sublist(1, equity.length - 1)
        .where(
          (c) => (c['rawLine'] as String)
              .replaceAll(RegExp(r'\s+'), '')
              .startsWith('당기순이익'),
        )
        .toList();
    if (movement != BigInt.zero ||
        totals.last != account('equity') ||
        currentProfit.length != 1 ||
        FundFinancialsText.integer(
              (currentProfit.single['printedComponents'] as List).last,
            ) !=
            account('netProfit')) {
      throw const FormatException(
        'Infrastructure own CE/BS/PL reconciliation mismatch',
      );
    }
    return {
      'checks': checks,
      'equityMovementDifference': '0',
      'equityCloseDifference': '0',
      'wholeProfitDifference': '0',
      'cashScope': p['cashScope'],
      'cells': cells,
      'equityWitnesses': equity,
    };
  }

  static List<Map<String, dynamic>> validateRows(dynamic raw) {
    if (raw is! List || raw.isEmpty || raw.length > 3) {
      throw const FormatException(
        'Bounded own infrastructure periods required',
      );
    }
    final seen = <String>{};
    String? issuer;
    return raw.map((v) {
      if (v is! Map) throw const FormatException('Infrastructure row required');
      final row = Map<String, dynamic>.from(v),
          matches = InfrastructureFundProfiles.rows.where(
            (p) => p['metadata']['officialUrl'] == row['officialUrl'],
          );
      if (matches.length != 1) {
        throw const FormatException('Unreviewed infrastructure source');
      }
      final p = matches.single, m = p['metadata'] as Map;
      issuer ??= m['corpCode'];
      if (issuer != m['corpCode'] ||
          !seen.add(row['officialUrl']) ||
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
          row['numericState'] != 'partialPrintedInfrastructureFundCategories' ||
          row['publicContent'] != 'sourceLinkAndValues' ||
          row['extractedBy'] != 'fixedPdfFontRule' ||
          row['parserVersion'] != version ||
          row['rawTextSha256'] != p['rawTextSha256'] ||
          row['decodedTextSha256'] != p['decodedTextSha256'] ||
          jsonEncode(row['decodedPages']) != jsonEncode(p['decodedPages']) ||
          row['textTransformation'] != p['textTransformation'] ||
          row['extractionTool'] != p['extractionTool'] ||
          row['regularReportCode'] != null ||
          row['xbrlAccountId'] != null ||
          row['fullStatementCollected'] != false ||
          row['wholeFontMapVerified'] != false ||
          row['notesDecodedOrVerified'] != false ||
          row['accounts'] is! List ||
          row['validation'] is! Map ||
          row['statementHeaders'] is! List) {
        throw const FormatException(
          'Infrastructure source/fiscal/transform contract mismatch',
        );
      }
      const keys = {
        'completenessNote',
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
        'rawTextSha256',
        'decodedTextSha256',
        'decodedPages',
        'textTransformation',
        'extractionTool',
        'regularReportCode',
        'xbrlAccountId',
        'fullStatementCollected',
        'wholeFontMapVerified',
        'notesDecodedOrVerified',
        'accounts',
        'statementHeaders',
        'validation',
      };
      if (row.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(row.keys.toSet()).isNotEmpty) {
        throw const FormatException('Unexpected infrastructure fields');
      }
      final headers = row['statementHeaders'] as List;
      if (headers.length != (p['headers'] as List).length) {
        throw const FormatException('Four bound statement headers required');
      }
      for (var i = 0; i < headers.length; i++) {
        final h = headers[i], pin = (p['headers'] as List)[i];
        if (h is! Map ||
            pin.entries.any((e) => h[e.key] != e.value) ||
            h['printedHeader'] is! String) {
          throw const FormatException('Bound statement header required');
        }
        final text = (h['printedHeader'] as String).replaceAll(
          RegExp(r'\s'),
          '',
        );
        if (!text.contains(
              (m['issuerQuote'] as String).replaceAll(RegExp(r'\s'), ''),
            ) ||
            !text.contains('(단위:원)') ||
            !text.contains('${(m['periodEnd'] as String).substring(0, 4)}년')) {
          throw const FormatException(
            'Statement issuer/year/unit header mismatch',
          );
        }
      }
      final validation = row['validation'] as Map;
      if (validation['cells'] is! Map ||
          validation['equityWitnesses'] is! List ||
          jsonEncode(
                _validateProof(
                  p,
                  validation['cells'],
                  validation['equityWitnesses'],
                  row['accounts'],
                ),
              ) !=
              jsonEncode(validation)) {
        throw const FormatException(
          'Infrastructure stored hierarchy proof mismatch',
        );
      }
      return row;
    }).toList();
  }
}
