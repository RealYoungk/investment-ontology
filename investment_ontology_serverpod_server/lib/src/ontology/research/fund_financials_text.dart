import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'fund_financial_profiles.dart';

/// Reads only a locally prepared, byte-pinned complete extraction. No PDF runtime.
abstract final class FundFinancialsText {
  static const corp = '00600013';
  static const version = 'mapps-printed-fund-current-v1';
  static const category = 'printedFundCategories';
  static bool supportsCorp(String code) => code == corp;
  static Map<String, dynamic>? profile(Map metadata) {
    final matches = FundFinancialProfiles.rows.where(
      (p) {
        final expected = p['metadata'] as Map;
        return metadata.length == expected.length &&
            expected.entries.every(
              (e) => jsonEncode(metadata[e.key]) == jsonEncode(e.value),
            );
      },
    );
    return matches.length == 1 ? matches.single : null;
  }

  static bool supports(Map document) =>
      document['metadata'] is Map &&
      profile(document['metadata'] as Map) != null;
  static void verifyPdf(Map metadata, List<int> bytes) {
    if (profile(metadata) == null ||
        bytes.length > 20 * 1024 * 1024 ||
        bytes.length < 5 ||
        utf8.decode(bytes.take(5).toList()) != '%PDF-' ||
        sha256.convert(bytes).toString() != metadata['sha256']) {
      throw const FormatException('Exact own fund PDF bytes required');
    }
  }

  static BigInt? integer(String s) {
    if (s == '-' || s == '–') return null;
    if (!RegExp(
      r'^(?:-?\d{1,3}(?:,\d{3})*|-?\d+|\(\d{1,3}(?:,\d{3})*\)|\(\d+\))$',
    ).hasMatch(s)) {
      throw const FormatException('Direct printed fund integer required');
    }
    return BigInt.parse(
      s.startsWith('(')
          ? '-${s.substring(1, s.length - 1).replaceAll(',', '')}'
          : s.replaceAll(',', ''),
    );
  }

  static final _number = RegExp(
    r'(?<![\w\d가-힣])(?:\(?-?\d{1,3}(?:,\d{3})+\)?|\(?-?\d+\)?|[-–])(?![\d\w.가-힣])',
  );
  static List<String> _tokens(String line) =>
      _number.allMatches(line).map((m) => m[0]!).toList();
  static String _line(List<List<String>> pages, Map c) =>
      pages[(c['pageOrdinal'] as int) - 1][(c['lineOrdinal'] as int) - 1];
  static Map<String, dynamic> _cell(List<List<String>> pages, Map c) {
    final line = _line(pages, c), tokens = _tokens(line);
    if (tokens.length < 2 ||
        !line.trimLeft().startsWith(c['accountLabel'] as String)) {
      throw const FormatException('Fund category coordinates mismatch');
    }
    final current = tokens[tokens.length - 2], prior = tokens.last;
    return {
      ...Map<String, dynamic>.from(c),
      'printedAmount': current,
      'amountInteger': integer(current)?.toString(),
      'comparativePrintedAmount': prior,
      'rawLine': line,
      'currentColumn': 0,
      'currency': 'KRW',
      'printedUnit': '원',
      'precisionUnit': '1',
    };
  }

  static Map<String, dynamic> parseText(Map metadata, List<int> bytes) {
    final p = profile(metadata);
    if (p == null ||
        bytes.length > 4 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != p['extractedTextSha256']) {
      throw const FormatException('Exact complete private fund text required');
    }
    final text = utf8.decode(bytes),
        pages = text
            .split('\f')
            .map((p) => const LineSplitter().convert(p))
            .toList();
    final accounts = (p['observations'] as List)
        .map((c) => _cell(pages, c))
        .toList();
    if (accounts.any((c) => c['amountInteger'] == null)) {
      throw const FormatException('Missing fund category stays missing');
    }
    final values = {
      for (final a in accounts) a['metric']: BigInt.parse(a['amountInteger']),
    };
    final cash = (p['cashWitnesses'] as List)
        .map((c) => _cell(pages, c))
        .toList();
    BigInt cv(int i) => BigInt.parse(cash[i]['amountInteger']);
    BigInt cp(int i) {
      final n = integer(cash[i]['comparativePrintedAmount']);
      if (n == null) throw const FormatException('Missing cash witness');
      return n;
    }

    final equity = <Map<String, dynamic>>[];
    final totals = <BigInt>[];
    for (final c in p['equityWitnesses'] as List) {
      final line = _line(pages, c), tokens = _tokens(line);
      if (tokens.length != 3) {
        throw const FormatException('Fund CE exact components required');
      }
      final components = tokens.map(integer).toList();
      if (components.last == null ||
          components
                  .take(2)
                  .whereType<BigInt>()
                  .fold(BigInt.zero, (a, b) => a + b) !=
              components.last ||
          (c['markerLabel'] != null && components.any((a) => a == null))) {
        throw const FormatException('Fund CE component reconciliation failed');
      }
      totals.add(components.last!);
      equity.add({
        ...Map<String, dynamic>.from(c),
        'rawAmountLine': line,
        if (c['markerLabel'] != null)
          'markerRawLine':
              pages[(c['markerPageOrdinal'] as int) -
                  1][(c['markerLineOrdinal'] as int) - 1],
        'printedComponents': tokens,
        'totalPrintedAmount': tokens.last,
        'unprintedComponentCount': components
            .take(2)
            .where((v) => v == null)
            .length,
      });
    }
    final checks = <String, BigInt>{
      'balanceDifference':
          values['assets']! - values['liabilities']! - values['equity']!,
      'cashRollDifference': cv(2) + cv(3) - cv(4),
      'cashActivityDifference':
          values['assetManagementCashFlow']! + cv(5) + cv(6) - cv(3),
      'equityCloseDifference': totals[3] - values['equity']!,
      'equityMovementDifference': totals[0] + totals[1] + totals[2] - totals[3],
      'wholeProfitDifference': totals[1] - values['netProfit']!,
    };
    if (checks.values.any((v) => v != BigInt.zero)) {
      throw const FormatException('Fund exact equations mismatch');
    }
    final currentGap = cv(0) - cv(4), priorGap = cp(0) - cp(4);
    final quarantined = currentGap != BigInt.zero || priorGap != BigInt.zero;
    final note = const LineSplitter()
        .convert(text)
        .where(
          (l) => l
              .replaceAll(RegExp(r'\s+'), '')
              .contains('현금흐름표의현금은재무상태표상의현금및현금성자산입니다.'),
        )
        .firstOrNull;
    final headers = <Map<String, dynamic>>[];
    for (var i = 0; i < pages.length; i++) {
      final lines = pages[i],
          first = lines
              .where((l) => l.trim().isNotEmpty)
              .firstOrNull
              ?.replaceAll(RegExp(r'\s+'), '');
      if ({'재무상태표', '손익계산서', '자본변동표', '현금흐름표'}.contains(first)) {
        headers.add({
          'pageOrdinal': i + 1,
          'statement': first,
          'printedHeader': lines.take(12).join('\n'),
        });
      }
    }
    final validation = {
      for (final e in checks.entries) e.key: e.value.toString(),
      'currentBSCashMinusCF': currentGap.toString(),
      'comparativeBSCashMinusCF': priorGap.toString(),
      'currentBSCashAndDepositsMinusCF': (cv(1) - cv(4)).toString(),
      'comparativeBSCashAndDepositsMinusCF': (cp(1) - cp(4)).toString(),
      'notesCashDefinitionQuote': note,
      'notesCashDefinitionContradiction': note != null && quarantined,
      'cashWitnesses': cash,
      'equityWitnesses': equity,
    };
    return {
      'corpCode': metadata['corpCode'],
      'categorySchema': category,
      'documentType': metadata['documentType'],
      'provider': 'officialIR',
      'providerReceipt': null,
      'officialUrl': metadata['officialUrl'],
      'sha256': metadata['sha256'],
      'periodStart': metadata['periodStart'],
      'periodEnd': metadata['periodEnd'],
      'basis': 'singleFundEntity',
      'periodKind': metadata['periodEnd'] == '2026-06-30'
          ? 'ownSixMonthFiscalYear'
          : 'ownTwelveMonthFiscalYear',
      'auditStatus': 'opinionNotExtracted',
      'observationRole': 'currentOwn',
      'currency': 'KRW',
      'printedUnit': '원',
      'precisionUnit': '1',
      'numericState': quarantined
          ? 'pendingCashScope'
          : 'partialPrintedFundCategories',
      'publicContent': 'sourceLinkAndValues',
      'extractedBy': 'fixedPdfTextRule',
      'parserVersion': version,
      'extractedTextSha256': p['extractedTextSha256'],
      'extractionTool': p['extractionTool'],
      'regularReportCode': null,
      'xbrlAccountId': null,
      'fullStatementCollected': false,
      'accounts': quarantined ? <Map<String, dynamic>>[] : accounts,
      'quarantinedAccounts': quarantined ? accounts : <Map<String, dynamic>>[],
      'statementHeaders': headers,
      'validation': validation,
      'completenessNote':
          '인쇄된 펀드 계정 일부 · 정기 API·산업 재무지표·TTM과 분리 · 전체 재무제표 및 비교기간 미수집',
    };
  }

  /// Stored payload checks. Original bytes are checked by the normal worker.
  static List<Map<String, dynamic>> validateRows(dynamic raw) {
    if (raw is! List || raw.isEmpty || raw.length > 6) {
      throw const FormatException('Bounded fund rows required');
    }
    final seen = <String>{};
    return raw.map((v) {
      if (v is! Map) throw const FormatException('Fund row object required');
      final row = Map<String, dynamic>.from(v);
      final matches = FundFinancialProfiles.rows.where(
        (p) => (p['metadata'] as Map)['officialUrl'] == row['officialUrl'],
      );
      if (matches.length != 1) {
        throw const FormatException('Unreviewed fund source');
      }
      final p = matches.single, m = p['metadata'] as Map;
      final quarantine = row['numericState'] == 'pendingCashScope';
      if (quarantine != {'2021-12-31', '2022-12-31'}.contains(m['periodEnd'])) {
        throw const FormatException('Bound source cash quarantine required');
      }
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
          row['periodKind'] !=
              (m['periodEnd'] == '2026-06-30'
                  ? 'ownSixMonthFiscalYear'
                  : 'ownTwelveMonthFiscalYear') ||
          row['auditStatus'] != 'opinionNotExtracted' ||
          row['observationRole'] != 'currentOwn' ||
          row['currency'] != 'KRW' ||
          row['printedUnit'] != '원' ||
          row['precisionUnit'] != '1' ||
          !{
            'pendingCashScope',
            'partialPrintedFundCategories',
          }.contains(row['numericState']) ||
          row['publicContent'] != 'sourceLinkAndValues' ||
          row['extractedBy'] != 'fixedPdfTextRule' ||
          row['parserVersion'] != version ||
          row['extractedTextSha256'] != p['extractedTextSha256'] ||
          row['extractionTool'] != p['extractionTool'] ||
          row['regularReportCode'] != null ||
          row['xbrlAccountId'] != null ||
          row['fullStatementCollected'] != false ||
          row['accounts'] is! List ||
          row['quarantinedAccounts'] is! List ||
          (row['accounts'] as List).length != (quarantine ? 0 : 7) ||
          (row['quarantinedAccounts'] as List).length != (quarantine ? 7 : 0) ||
          row['validation'] is! Map ||
          row['statementHeaders'] is! List) {
        throw const FormatException('Fund source/scope contract mismatch');
      }
      const rowKeys = {
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
        'extractedTextSha256',
        'extractionTool',
        'regularReportCode',
        'xbrlAccountId',
        'fullStatementCollected',
        'accounts',
        'quarantinedAccounts',
        'statementHeaders',
        'validation',
        'completenessNote',
      };
      if (row.keys.toSet().difference(rowKeys).isNotEmpty ||
          rowKeys.difference(row.keys.toSet()).isNotEmpty) {
        throw const FormatException('Fund unknown fields rejected');
      }
      final accounts =
          (quarantine ? row['quarantinedAccounts'] : row['accounts']) as List;
      final profiles = p['observations'] as List;
      for (var i = 0; i < accounts.length; i++) {
        final a = accounts[i];
        if (a is! Map ||
            profiles[i].entries.any((e) => a[e.key] != e.value) ||
            a['printedAmount'] is! String ||
            integer(a['printedAmount'])?.toString() != a['amountInteger'] ||
            a['rawLine'] is! String ||
            (_tokens(a['rawLine']).length < 2 ||
                _tokens(a['rawLine'])[_tokens(a['rawLine']).length - 2] !=
                    a['printedAmount'] ||
                _tokens(a['rawLine']).last != a['comparativePrintedAmount']) ||
            a['currency'] != 'KRW' ||
            a['printedUnit'] != '원' ||
            a['precisionUnit'] != '1') {
          throw const FormatException('Fund printed coordinate mismatch');
        }
      }
      for (final a in accounts) {
        final amount = BigInt.parse(a['amountInteger']);
        final sign = amount.isNegative
            ? 'negative'
            : amount == BigInt.zero
            ? 'zero'
            : 'positive';
        if (a['printedSign'] != sign) {
          throw const FormatException('Exact source printed sign mismatch');
        }
      }
      final validation = row['validation'] as Map;
      for (final k in [
        'balanceDifference',
        'cashRollDifference',
        'cashActivityDifference',
        'equityCloseDifference',
        'equityMovementDifference',
        'wholeProfitDifference',
      ]) {
        if (validation[k] != '0') {
          throw const FormatException('Fund exact checks required');
        }
      }
      final cash = validation['cashWitnesses'],
          ce = validation['equityWitnesses'];
      if (cash is! List || cash.length != 7 || ce is! List || ce.length != 4) {
        throw const FormatException('Fund full validation witnesses required');
      }
      for (var i = 0; i < cash.length; i++) {
        final c = cash[i], bound = (p['cashWitnesses'] as List)[i] as Map;
        if (c is! Map ||
            bound.entries.any((e) => c[e.key] != e.value) ||
            c['rawLine'] is! String ||
            _tokens(c['rawLine']).length < 2 ||
            _tokens(c['rawLine'])[_tokens(c['rawLine']).length - 2] !=
                c['printedAmount'] ||
            _tokens(c['rawLine']).last != c['comparativePrintedAmount'] ||
            integer(c['printedAmount'])?.toString() != c['amountInteger']) {
          throw const FormatException('Fund cash witness coordinate mismatch');
        }
      }
      final totals = <BigInt>[];
      for (var i = 0; i < ce.length; i++) {
        final c = ce[i], bound = (p['equityWitnesses'] as List)[i] as Map;
        if (c is! Map ||
            bound.entries.any((e) => c[e.key] != e.value) ||
            c['rawAmountLine'] is! String ||
            c['printedComponents'] is! List ||
            jsonEncode(_tokens(c['rawAmountLine'])) !=
                jsonEncode(c['printedComponents']) ||
            (c['printedComponents'] as List).length != 3) {
          throw const FormatException(
            'Fund equity witness coordinate mismatch',
          );
        }
        if (bound['markerLabel'] != null &&
            (c['markerRawLine'] is! String ||
                !(c['markerRawLine'] as String).trimLeft().startsWith(
                  bound['markerLabel'] as String,
                ))) {
          throw const FormatException('Fund actual CE date marker required');
        }
        final parts = (c['printedComponents'] as List)
            .map((v) => integer(v as String))
            .toList();
        if (parts.last == null ||
            parts
                    .take(2)
                    .whereType<BigInt>()
                    .fold(BigInt.zero, (a, b) => a + b) !=
                parts.last ||
            (i == 0 || i == 3) && parts.any((v) => v == null)) {
          throw const FormatException(
            'Fund equity witness components mismatch',
          );
        }
        totals.add(parts.last!);
      }
      BigInt cv(int i) => BigInt.parse(cash[i]['amountInteger']);
      BigInt cp(int i) {
        final value = integer(cash[i]['comparativePrintedAmount']);
        if (value == null) {
          throw const FormatException('Fund missing comparison witness');
        }
        return value;
      }

      final values = {
        for (final a in accounts) a['metric']: BigInt.parse(a['amountInteger']),
      };
      final recomputed = {
        'balanceDifference':
            values['assets']! - values['liabilities']! - values['equity']!,
        'cashRollDifference': cv(2) + cv(3) - cv(4),
        'cashActivityDifference':
            values['assetManagementCashFlow']! + cv(5) + cv(6) - cv(3),
        'equityCloseDifference': totals[3] - values['equity']!,
        'equityMovementDifference':
            totals[0] + totals[1] + totals[2] - totals[3],
        'wholeProfitDifference': totals[1] - values['netProfit']!,
      };
      if (recomputed.entries.any(
            (e) =>
                e.value != BigInt.zero ||
                validation[e.key] != e.value.toString(),
          ) ||
          validation['currentBSCashMinusCF'] != (cv(0) - cv(4)).toString() ||
          validation['comparativeBSCashMinusCF'] !=
              (cp(0) - cp(4)).toString() ||
          validation['currentBSCashAndDepositsMinusCF'] !=
              (cv(1) - cv(4)).toString() ||
          validation['comparativeBSCashAndDepositsMinusCF'] !=
              (cp(1) - cp(4)).toString()) {
        throw const FormatException('Fund stored proof equations mismatch');
      }
      final gap = validation['currentBSCashMinusCF'],
          prior = validation['comparativeBSCashMinusCF'];
      if (gap is! String ||
          prior is! String ||
          BigInt.tryParse(gap) == null ||
          BigInt.tryParse(prior) == null ||
          quarantine != (gap != '0' || prior != '0')) {
        throw const FormatException('Fund cash quarantine mismatch');
      }
      return row;
    }).toList();
  }
}
