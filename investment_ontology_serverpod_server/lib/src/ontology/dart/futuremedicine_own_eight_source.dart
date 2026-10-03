import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'futuremedicine_own_eight_profiles.dart';

/// One exact own annual OFS, eight direct current accounts.
/// Whole NI is corroborated by CE; the CF has no printed NI starting row.
abstract final class FuturemedicineOwnEightSource {
  static const rule = 'futuremedicine-own-2021-eight-independent-ce-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(futuremedicineOwnEightProfilesJson) as List)
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
      if (!ok) throw FormatException('Exact FutureMedicine current: $why');
    }

    final choices = profiles.where((p) => p['receipt'] == receipt).toList();
    guard(choices.length == 1 && !consolidated, 'unknown receipt/basis');
    final p = choices.single, year = p['year'] as int;
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
    guard(ids.length == 1 && ids.single == corpCode, 'own shell corp mismatch');
    guard(
      compact(raw['cover']!).contains(p['coverName'] as String) &&
          compact(raw['cover']!).contains('$year년01월01일부터$year년12월31일까지'),
      'own cover issuer/period mismatch',
    );
    guard(
      sha256
              .convert(utf8.encode('${raw['cover']}\n${raw['ofs']}'))
              .toString() ==
          p['compoundDigest'],
      'compound cover/body digest mismatch',
    );
    final tables =
        RegExp(r'<table\b[^>]*>([\s\S]*?)</table>', caseSensitive: false)
            .allMatches(raw['ofs']!)
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
          'fs_div': 'OFS',
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
            'source': uris['ofs'].toString(),
            'sourceReceipt': receipt,
            'ruleVersion': rule,
            'sourceSha256': sources.singleWhere(
              (s) => s['label'] == 'ofs',
            )['sha256'],
            'tableIndex': c['table'],
            'rowIndex': c['row'],
            'column': c['column'],
            'printedLabel': c['printedLabel'],
            'currentCell': c['raw'],
            'printedUnit': p['unit'],
            'unitMultiplier': p['multiplier'],
            'precisionUnit': p['multiplier'],
            'basis': 'OFS',
            'periodStart': from,
            'periodEnd': to,
            'cashDirection': c['role'] == 'ppePurchaseSigned'
                ? 'outflow'
                : null,
            'printedSign': current(c).isNegative ? 'negative' : 'positive',
            'fullStatementCollected': false,
            'notesVerified': false,
            'detailHierarchyComplete': false,
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
