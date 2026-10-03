import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'filing_series_current_eight_profiles.dart';

/// Two exact own annual filing-series core8 contracts; no general legal alias.
abstract final class FilingSeriesCurrentEightSource {
  static const rule = 'exact-numeric-filing-series-current-eight-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(filingSeriesCurrentEightProfilesJson) as List)
          .cast<Map<String, dynamic>>();
  static String compact(String s) => s
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), '');
  static List<Map<String, dynamic>> parse({
    required String receipt,
    required String corpCode,
    required String companyName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Map<String, String> raw,
    required Map<String, Uri> uris,
  }) {
    void guard(bool ok, String why) {
      if (!ok) {
        throw FormatException('Exact historical filing-series current: $why');
      }
    }

    final choices = profiles.where((p) => p['receipt'] == receipt).toList();
    guard(choices.length == 1, 'unknown receipt/basis');
    final p = choices.single, year = p['year'] as int;
    final statement = p['statement'] as String;
    guard(
      consolidated == (p['basis'] == 'consolidated'),
      'exact basis mismatch',
    );
    guard(
      corpCode == p['corp'] &&
          companyName == p['name'] &&
          start == DateTime.utc(year) &&
          end == DateTime.utc(year, 12, 31),
      'issuer/period mismatch',
    );
    final sources = p['sources'] as List;
    guard(
      raw.length == sources.length && uris.length == sources.length,
      'source set mismatch',
    );
    for (final s in sources) {
      guard(
        raw[s['label']] != null &&
            uris[s['label']].toString() == s['url'] &&
            sha256.convert(utf8.encode(raw[s['label']]!)).toString() ==
                s['sha256'],
        'source URI/SHA mismatch',
      );
    }
    final ids = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    guard(
      ids.length == 1 &&
          ids.single == corpCode &&
          raw['shell']!.contains('<title>${p['currentShellName']}/사업보고서/'),
      'own shell corp mismatch',
    );
    guard(
      compact(raw['cover']!).contains(p['coverName'] as String) &&
          compact(raw['cover']!).contains('$year년01월01일부터$year년12월31일까지'),
      'own cover issuer/period mismatch',
    );
    guard(
      sha256
              .convert(utf8.encode('${raw['cover']}\n${raw[statement]}'))
              .toString() ==
          p['compoundDigest'],
      'compound cover/body digest mismatch',
    );
    final tables =
        RegExp(r'<table\b[^>]*>([\s\S]*?)</table>', caseSensitive: false)
            .allMatches(raw[statement]!)
            .map(
              (t) => RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
                  .allMatches(t[1]!)
                  .map(
                    (r) => RegExp(
                      r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                      caseSensitive: false,
                    ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
                  )
                  .toList(),
            )
            .toList();
    for (final h in p['headers'] as List) {
      guard(
        jsonEncode(tables[h['table'] as int]) == jsonEncode(h['rows']),
        'printed current header/unit mismatch',
      );
    }
    BigInt money(String s) {
      guard(
        RegExp(
          r'^(?:-?(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)|\((?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\))$',
        ).hasMatch(s),
        'missing or malformed amount',
      );
      return BigInt.parse(
        s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    BigInt current(Map c) {
      final r = tables[c['table'] as int][c['row'] as int];
      guard(
        jsonEncode(r) == jsonEncode(c['expected']),
        'exact row/coordinate mismatch',
      );
      final v = money(r[c['column'] as int]);
      guard(v.toString() == c['amount'], 'current sign/value mismatch');
      return v;
    }

    for (final check in p['checks'] as List) {
      guard(
        (check['terms'] as List)
                .map((c) => current(c) * BigInt.from(c['sign'] as int))
                .fold(BigInt.zero, (a, b) => a + b) ==
            BigInt.zero,
        'own current equation ${check['name']} contradiction',
      );
    }
    for (final c in p['core'] as List) {
      current(c as Map);
    }
    final missing = p['printedMissingTermScope'];
    if (missing is Map) {
      guard(
        tables[missing['table'] as int][missing['row'] as int][missing['column']
                    as int] ==
                '-' &&
            missing['numericValue'] == null &&
            missing['storedAsZero'] == false,
        'printed FX dash changed',
      );
      final direction = p['outflowMagnitudeEvidence'] as Map;
      final row = tables[direction['table'] as int][direction['row'] as int];
      guard(
        jsonEncode(row) == jsonEncode(direction['expected']) &&
            money(row[direction['column'] as int]).toString() ==
                direction['signedTotal'],
        'own negative investing outflow context changed',
      );
      final total = (direction['componentRows'] as List)
          .map((i) => money(tables[10][i as int][2]))
          .fold(BigInt.zero, (a, b) => a + b);
      guard(
        total.toString() == direction['printedMagnitudeComponentSum'] &&
            total == -money(row[direction['column'] as int]),
        'own investing magnitude component equation changed',
      );
    }
    return expectedRows(p);
  }

  /// Canonical verified rows used only after parsing or for exact Source proof comparison.
  static List<Map<String, dynamic>> expectedRows(Map<String, dynamic> p) {
    final year = p['year'] as int,
        receipt = p['receipt'] as String,
        corpCode = p['corp'] as String,
        companyName = p['name'] as String;
    final consolidated = p['basis'] == 'consolidated',
        statement = p['statement'] as String;
    final sources = p['sources'] as List;
    final uris = {
      for (final s in sources)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    BigInt current(Map c) => BigInt.parse(c['amount'] as String);
    final multiplier = BigInt.parse(p['multiplier'] as String),
        from = '$year-01-01',
        to = '$year-12-31';
    return [
      for (final c in p['core'] as List)
        {
          'rcept_no': receipt,
          'corp_code': corpCode,
          'bsns_year': '$year',
          'reprt_code': '11011',
          'fs_div': consolidated ? 'CFS' : 'OFS',
          'sj_div': c['kind'],
          'account_id': null,
          'account_nm': c['printedLabel'],
          'account_detail': '-',
          'thstrm_nm': c['kind'] == 'BS' ? to : '$from~$to',
          'thstrm_amount':
              ((c['role'] == 'ppePurchaseSigned'
                          ? current(c).abs()
                          : current(c)) *
                      multiplier)
                  .toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': uris[statement].toString(),
            'sourceReceipt': receipt,
            'ruleVersion': rule,
            'sourceSha256': sources.singleWhere(
              (s) => s['label'] == statement,
            )['sha256'],
            'tableIndex': c['table'],
            'rowIndex': c['row'],
            'column': c['column'],
            'printedLabel': c['printedLabel'],
            'currentCell': c['raw'],
            'printedUnit': p['unit'],
            'unitMultiplier': p['multiplier'],
            'precisionUnit': p['multiplier'],
            'basis': consolidated ? 'CFS' : 'OFS',
            'periodStart': from,
            'periodEnd': to,
            'cashDirection': c['role'] == 'ppePurchaseSigned'
                ? 'outflow'
                : null,
            'printedSign': current(c).isNegative ? 'negative' : 'positive',
            'fullStatementCollected': false,
            'notesVerified': false,
            'detailHierarchyComplete': false,
            if (p['printedMissingTermScope'] != null)
              'printedMissingTermScope': p['printedMissingTermScope'],
            if (p['outflowMagnitudeEvidence'] != null)
              'outflowMagnitudeEvidence': p['outflowMagnitudeEvidence'],
            'sourceScopeNotice':
                '원문 제출주체 ${p['printedFilingActor']}, 현재 표시명 $companyName. 해당 DART 공시의 법인코드·제출주체·기간만 검증했으며 과거 영업 이력·법인등록번호 연속성이나 전체 계정·주석 완료를 뜻하지 않습니다.',
            'filingSeriesIdentity': {
              'identityScope': 'official-DART-filing-series-only',
              'corpCode': corpCode,
              'currentMasterName': companyName,
              'printedFilingActor': p['printedFilingActor'],
              'shellSource': uris['shell'].toString(),
              'jurirContinuityVerified': false,
              'operatingHistoryContinuityVerified': false,
              'sourceNotice': '해당 공시의 법인코드·현재 표시명과 과거 제출주체로 공시를 식별했습니다. 현재 회사의 과거 영업 이력이나 법인등록번호 연속성 검증은 아닙니다.',
            },
            'supportingPeriodEvidence': {
              'policy': rule,
              'periodStart': from,
              'periodEnd': to,
              'flowCaptionPrintedStart': true,
              'currentEquationWitnesses': p['checks'],
              'readScope': p['readScope'],
            },
          },
        },
    ];
  }
}
