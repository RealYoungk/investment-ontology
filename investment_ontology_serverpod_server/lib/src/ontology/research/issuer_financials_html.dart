import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'reviewed_dart_issuer_sources.dart';

/// A source-bound current-period subset, never financial API/XBRL records.
abstract final class IssuerFinancialsHtml {
  static const corp = '01801026';
  static const version = 'brils-primary-statements-v1';
  static const metrics = [
    'assets',
    'liabilities',
    'equity',
    'revenue',
    'operatingProfit',
    'netProfit',
    'operatingCashFlow',
    'propertyPlantEquipmentAcquisitions',
  ];
  static bool supports(Map doc) => (doc['metadata'] as Map)['corpCode'] == corp;
  static String text(String html) => html
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String compact(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static String dates(String s) => compact(s).replaceAllMapped(
    RegExp(r'(\d{4})년(\d{1,2})월(\d{1,2})일'),
    (m) => '${m[1]}년${int.parse(m[2]!)}월${int.parse(m[3]!)}일',
  );
  static String integer(String printed) {
    if (!RegExp(
      r'^(?:-?\d{1,3}(?:,\d{3})*|-?\d+|\(\d{1,3}(?:,\d{3})*\)|\(\d+\))$',
    ).hasMatch(printed)) {
      throw const FormatException(
        'Only directly printed signed integer amounts',
      );
    }
    final s = printed.replaceAll(',', '');
    return BigInt.parse(
      s.startsWith('(') ? '-${s.substring(1, s.length - 1)}' : s,
    ).toString();
  }

  static List<Map<String, dynamic>> parse({
    required Map<String, dynamic> document,
    required List<int> shellBytes,
    required List<int> statementBytes,
  }) {
    ReviewedDartIssuerSources.validateDocument(document);
    final m = document['metadata'] as Map, p = document['proof'] as Map;
    if (!supports(document) ||
        sha256.convert(shellBytes).toString() != p['shellSha256'] ||
        sha256.convert(statementBytes).toString() != m['sha256']) {
      throw const FormatException('Financial issuer/exact bytes mismatch');
    }
    final actors = RegExp(r"openCorpInfo(?:New)?\('(\d{8})'")
        .allMatches(utf8.decode(shellBytes))
        .map((m) => m[1]!)
        .toSet();
    if (actors.length != 1 || actors.single != corp) {
      throw const FormatException('Financial shell issuer mismatch');
    }
    final html = utf8.decode(statementBytes);
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
                        (r) => RegExp(
                          r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
                          caseSensitive: false,
                          dotAll: true,
                        ).allMatches(r[1]!).map((c) => text(c[1]!)).toList(),
                      )
                      .toList(),
            )
            .toList();
    final annual = m['documentType'] == 'auditReport',
        year = DateTime.parse(m['periodEnd'] as String).year,
        term = DateTime.parse(m['periodEnd'] as String).year - 2014;
    final result = <Map<String, dynamic>>[];
    for (final basis in annual ? ['OFS'] : ['CFS', 'OFS']) {
      final bs = annual
              ? 6
              : basis == 'CFS'
              ? 5
              : 163,
          income = annual
              ? 9
              : basis == 'CFS'
              ? 9
              : 167,
          cash = annual
              ? 15
              : basis == 'CFS'
              ? 15
              : 173;
      final captions = annual
              ? [5, 8, 14]
              : basis == 'CFS'
              ? [4, 7, 14]
              : [162, 165, 172],
          prefix = basis == 'CFS' ? '연결' : '';
      if (!compact(tables[captions[0]][0][0]).startsWith('$prefix재무상태표') ||
          !compact(tables[captions[1]][0][0]).startsWith('$prefix포괄손익계산서') ||
          !compact(tables[captions[2]][0][0]).startsWith('$prefix현금흐름표')) {
        throw const FormatException('Explicit primary basis mismatch');
      }
      final end = '$year년${annual ? 12 : 6}월${annual ? 31 : 30}일';
      for (final i in captions) {
        final current = dates(tables[i][1].join());
        if (!current.contains('제$term') ||
            !current.contains(end) ||
            i != captions[0] && !current.contains('$year년1월1일부터')) {
          throw const FormatException('Printed current period mismatch');
        }
      }
      final owner = annual
          ? tables[0][0][0]
          : tables[basis == 'CFS' ? 8 : 166][0][0];
      if (compact(owner) != (basis == 'CFS' ? '주식회사브릴스와그종속기업' : '주식회사브릴스') ||
          !compact(text(html)).contains('(단위:원)')) {
        throw const FormatException('Printed entity/unit mismatch');
      }
      final col = annual ? 2 : 1;
      if (annual) {
        if (!compact(tables[bs][0][col]).startsWith('제$term(당)기말') ||
            [
              income,
              cash,
            ].any((i) => compact(tables[i][0][col]) != '제$term(당)기')) {
          throw const FormatException('Annual current column mismatch');
        }
      } else if (tables[bs][0][1] != '2026연도 반기 (제12기)' ||
          [income, cash].any((i) => tables[i][0][1] != '2026연도 반기 (제12기)') ||
          tables[income][1].join('|') != '3개월|누적|3개월|누적') {
        throw const FormatException('Half cumulative header mismatch');
      }
      final accounts = <Map<String, dynamic>>[];
      for (final metric in metrics) {
        final st = metrics.indexOf(metric) < 3
                ? 'BS'
                : metrics.indexOf(metric) < 6
                ? 'IS'
                : 'CF',
            id = metrics.indexOf(metric) < 3
                ? bs
                : metrics.indexOf(metric) < 6
                ? income
                : cash,
            column =
                !annual &&
                    metrics.indexOf(metric) >= 3 &&
                    metrics.indexOf(metric) < 6
                ? 2
                : col;
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
        final matches = [
          for (var r = 0; r < tables[id].length; r++)
            if (tables[id][r].isNotEmpty &&
                compact(tables[id][r][0]).startsWith(labels[metric]!))
              r,
        ];
        if (matches.length != 1) {
          throw FormatException('Missing/duplicate primary row: $metric');
        }
        final ri = matches.single, row = tables[id][ri];
        if (row.length !=
            (annual
                ? (st == 'BS' && year == 2023 ? 5 : 4)
                : st == 'IS'
                ? 8
                : st == 'BS'
                ? 5
                : 6)) {
          throw FormatException('Unsupported primary monetary shape: $metric');
        }
        if (metric == 'propertyPlantEquipmentAcquisitions') {
          final prior = tables[id].take(ri);
          final investing = prior.any(
            (r) => r.isNotEmpty && compact(r.first).contains('투자활동으로인한현금흐름'),
          );
          final explicitOutflow = prior.any(
            (r) => r.isNotEmpty && compact(r.first).contains('투자활동으로인한현금유출액'),
          );
          if (!investing ||
              (!explicitOutflow && !integer(row[column]).startsWith('-'))) {
            throw const FormatException('Acquisition cash direction unbound');
          }
        }
        accounts.add({
          'metric': metric,
          'accountLabel': row[0],
          'printedAmount': row[column],
          'amountInteger': integer(row[column]),
          'statement': st,
          'amountScope': st == 'BS' ? 'instant' : 'cumulative',
          'cashDirection': metric == 'propertyPlantEquipmentAcquisitions'
              ? 'outflow'
              : null,
          'tableOrdinal': id,
          'rowOrdinal': ri,
          'cellOrdinal': column,
          'headerCells': tables[id][0],
          'rowCells': row,
        });
      }
      final amounts = {
        for (final a in accounts)
          a['metric'] as String: BigInt.parse(a['amountInteger'] as String),
      };
      if (amounts['assets'] != amounts['liabilities']! + amounts['equity']!) {
        throw const FormatException('Balance equation mismatch');
      }
      if (!annual) {
        final summary = tables[basis == 'CFS' ? 1 : 3];
        for (final a in accounts.take(6)) {
          final names = {
            'assets': '자산총계',
            'liabilities': '부채총계',
            'equity': '자본총계',
            'revenue': '매출액',
            'operatingProfit': '영업이익',
            'netProfit': '당기순이익',
          };
          final rows = summary
              .where(
                (r) =>
                    r.isNotEmpty &&
                    compact(r.first).startsWith(names[a['metric']]!),
              )
              .toList();
          if (rows.length != 1 ||
              integer(rows.single[1]) != a['amountInteger']) {
            throw const FormatException('Summary/detailed discrepancy');
          }
        }
      }
      result.add({
        'corpCode': corp,
        'documentType': m['documentType'],
        'provider': 'DART',
        'providerReceipt': m['providerReceipt'],
        'officialUrl': m['officialUrl'],
        'sha256': m['sha256'],
        'basis': basis,
        'periodStart': m['periodStart'],
        'periodEnd': m['periodEnd'],
        'periodKind': annual ? 'ownAnnual' : 'halfYear',
        'auditStatus': annual ? 'audited' : 'reviewed',
        'observationRole': 'currentOwn',
        'currency': 'KRW',
        'printedUnit': '원',
        'precisionUnit': '1',
        'numericState': 'partialCore',
        'publicContent': 'sourceLinkAndValues',
        'extractedBy': 'fixedHtmlRule',
        'parserVersion': version,
        'accounts': accounts,
        'regularReportCode': null,
        'xbrlAccountId': null,
        'completenessNote': '대체 공식 원문 현재기간 핵심 8계정 · 정기 API 집계와 분리 · 비교기간 미추출',
      });
    }
    return result;
  }
}
