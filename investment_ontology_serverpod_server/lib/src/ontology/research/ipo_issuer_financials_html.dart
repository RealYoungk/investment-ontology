import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'ipo_financials_profiles.dart';
import 'issuer_financials_html.dart';
import 'reviewed_dart_issuer_sources.dart';

/// Eight individually read IPO chapters; detailed current cells, never summaries.
abstract final class IpoIssuerFinancialsHtml {
  static const version = 'ipo-eight-current-statements-v1';
  static bool supportsCorp(String code) =>
      IpoFinancialsProfiles.rows.any((p) => p['corpCode'] == code);
  static bool supports(Map<String, dynamic> d) =>
      supportsCorp('${(d['metadata'] as Map?)?['corpCode']}') &&
      (d['metadata'] as Map?)?['documentType'] ==
          'securitiesRegistrationStatement';
  static List<Map<String, dynamic>> _profiles(String code) =>
      IpoFinancialsProfiles.rows.where((p) => p['corpCode'] == code).toList();
  static String _dateText(String s) =>
      IssuerFinancialsHtml.compact(s)
          .replaceAllMapped(RegExp(r'0(\d)([월일])'), (m) => '${m[1]}${m[2]}');

  static Map<String, dynamic> _base(Map m, Map p) => {
    for (final k in [
      'corpCode',
      'documentType',
      'provider',
      'providerReceipt',
      'officialUrl',
      'sha256',
      'periodStart',
      'periodEnd',
    ])
      k: m[k],
    'basis': p['basis'],
    'periodKind': p['periodKind'],
    'auditStatus': p['auditStatus'],
    'auditProof': p['auditProof'],
    'observationRole': 'currentOwn',
    'currency': 'KRW',
    'printedUnit': '원',
    'precisionUnit': '1',
    'numericState': 'partialCore',
    'publicContent': 'sourceLinkAndValues',
    'extractedBy': 'fixedHtmlRule',
    'parserVersion': version,
    'regularReportCode': null,
    'xbrlAccountId': null,
    'unextractedMetrics': p['unextractedMetrics'],
    'completenessNote': '대체 공식 원문 현재기간 핵심계정 일부 · 정기 API 집계와 분리 · 비교기간 미추출',
  };

  static List<Map<String, dynamic>> parse({
    required Map<String, dynamic> document,
    required List<int> shellBytes,
    required List<int> statementBytes,
  }) {
    ReviewedDartIssuerSources.validateDocument(document);
    final m = document['metadata'] as Map, proof = document['proof'] as Map;
    if (!supports(document) ||
        sha256.convert(shellBytes).toString() != proof['shellSha256'] ||
        sha256.convert(statementBytes).toString() != m['sha256']) {
      throw const FormatException('IPO financial exact source bytes mismatch');
    }
    final actors = RegExp(r"openCorpInfo(?:New)?\('(\d{8})'")
        .allMatches(utf8.decode(shellBytes))
        .map((m) => m[1]!)
        .toSet();
    if (actors.length != 1 || actors.single != m['corpCode']) {
      throw const FormatException('IPO financial shell issuer mismatch');
    }
    final html = utf8.decode(statementBytes);
    if (!_dateText(IssuerFinancialsHtml.text(html))
        .contains(_dateText(m['periodQuote']))) {
      throw const FormatException('IPO printed current period mismatch');
    }
    final tables =
        RegExp(
              r'<TABLE\b[^>]*>(.*?)</TABLE>',
              caseSensitive: false,
              dotAll: true,
            )
            .allMatches(html)
            .map(
              (t) =>
                  RegExp(
                        r'<TR\b[^>]*>(.*?)</TR>',
                        caseSensitive: false,
                        dotAll: true,
                      )
                      .allMatches(t[1]!)
                      .map(
                        (r) =>
                            RegExp(
                                  r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
                                  caseSensitive: false,
                                  dotAll: true,
                                )
                                .allMatches(r[1]!)
                                .map((c) => IssuerFinancialsHtml.text(c[1]!))
                                .toList(),
                      )
                      .toList(),
            )
            .toList();
    final rows = <Map<String, dynamic>>[];
    for (final p in _profiles(m['corpCode'])) {
      for (final context in p['contextTables'] as List) {
        if (jsonEncode(tables[context['tableOrdinal']]) !=
            jsonEncode(context['rows'])) {
          throw const FormatException(
            'IPO printed issuer/basis/unit/current context mismatch',
          );
        }
      }
      final auditCell = p['auditCell'];
      if (auditCell != null &&
          tables[auditCell['tableOrdinal']][auditCell['rowOrdinal']][auditCell['cellOrdinal']] !=
              auditCell['printedText']) {
        throw const FormatException('IPO current auditor cell mismatch');
      }
      final accounts = <Map<String, dynamic>>[];
      for (final a in p['accounts'] as List) {
        final table = tables[a['tableOrdinal']],
            cells = table[a['rowOrdinal']],
            printed = cells[a['cellOrdinal']];
        if (cells.length != a['rowLength'] ||
            cells.first != a['accountLabel'] ||
            jsonEncode(table.first) != jsonEncode(a['headerCells'])) {
          throw const FormatException('IPO primary current cell mismatch');
        }
        final amount = IssuerFinancialsHtml.integer(printed);
        if (a['cashDirection'] == 'outflow' && !amount.startsWith('-')) {
          throw const FormatException(
            'IPO acquisition printed outflow sign mismatch',
          );
        }
        accounts.add({
          for (final k in [
            'metric',
            'statement',
            'amountScope',
            'cashDirection',
            'incomeDirection',
            'tableOrdinal',
            'rowOrdinal',
            'cellOrdinal',
            'accountLabel',
            'headerCells',
          ])
            k: a[k],
          'printedAmount': printed,
          'amountInteger': amount,
          'rowCells': cells,
        });
      }
      rows.add({..._base(m, p), 'accounts': accounts});
    }
    return validateRows(rows);
  }

  static List<Map<String, dynamic>> validateRows(dynamic raw) {
    if (raw is! List || raw.isEmpty || raw.length > 2) {
      throw const FormatException('IPO own current groups required');
    }
    final seen = <String>{};
    String? issuer;
    return raw.map((value) {
      if (value is! Map) throw const FormatException('IPO row object required');
      final row = Map<String, dynamic>.from(value),
          d = ReviewedDartIssuerSources.findUrl(
            '${value['officialUrl']}',
            '${value['corpCode']}',
          );
      if (d == null ||
          !supports(d) ||
          issuer != null && issuer != row['corpCode']) {
        throw const FormatException('Unreviewed/mixed IPO financial source');
      }
      issuer = row['corpCode'];
      final profiles = _profiles(issuer!),
          matches = profiles.where((p) => p['basis'] == row['basis']);
      if (matches.length != 1 ||
          !seen.add('${row['officialUrl']}|${row['basis']}')) {
        throw const FormatException('IPO current basis mismatch');
      }
      final p = matches.single,
          base = _base(d['metadata'] as Map, p),
          keys = {...base.keys, 'accounts'};
      if (row.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(row.keys.toSet()).isNotEmpty ||
          base.entries.any(
            (e) => jsonEncode(row[e.key]) != jsonEncode(e.value),
          ) ||
          row['accounts'] is! List ||
          (row['accounts'] as List).length != (p['accounts'] as List).length) {
        throw const FormatException('IPO current numeric metadata mismatch');
      }
      final values = <String, BigInt>{}, accounts = row['accounts'] as List;
      for (var i = 0; i < accounts.length; i++) {
        final a = accounts[i], expected = (p['accounts'] as List)[i] as Map;
        final keys = {
          ...expected.keys.where((k) => k != 'rowLength'),
          'printedAmount',
          'amountInteger',
          'rowCells',
        };
        if (a is! Map ||
            a.keys.toSet().difference(keys).isNotEmpty ||
            keys.difference(a.keys.toSet()).isNotEmpty ||
            expected.entries
                .where((e) => e.key != 'rowLength')
                .any((e) => jsonEncode(a[e.key]) != jsonEncode(e.value)) ||
            a['rowCells'] is! List ||
            (a['rowCells'] as List).length != expected['rowLength'] ||
            (a['rowCells'] as List).first != expected['accountLabel'] ||
            (a['rowCells'] as List)[expected['cellOrdinal']] !=
                a['printedAmount'] ||
            a['printedAmount'] is! String ||
            IssuerFinancialsHtml.integer(a['printedAmount']) !=
                a['amountInteger']) {
          throw const FormatException(
            'IPO detailed printed cell proof mismatch',
          );
        }
        final amount = BigInt.parse(a['amountInteger']);
        if (a['cashDirection'] == 'outflow' && !amount.isNegative ||
            a['incomeDirection'] == 'lossMagnitude' && amount.isNegative) {
          throw const FormatException('IPO printed sign/direction mismatch');
        }
        values[a['metric']] = amount;
      }
      if (values['assets'] != values['liabilities']! + values['equity']!) {
        throw const FormatException('IPO current balance equation mismatch');
      }
      return row;
    }).toList();
  }
}
