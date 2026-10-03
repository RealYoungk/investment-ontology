import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'filing_series_cfs_absence_profiles.dart';
import 'public_financial_html_fetch.dart';

/// Finite filing-level identity only. No legal successor/business-history alias.
abstract final class FilingSeriesCfsAbsence {
  static const rule = 'exact-own-filing-series-cfs-none-v1';
  static List<Map<String, dynamic>> get profiles =>
      (jsonDecode(filingSeriesCfsAbsenceProfilesJson) as List)
          .cast<Map<String, dynamic>>();
  static String compact(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>|&nbsp;|\s'), '');
  static PublicFinancialHtmlBasisNotApplicable verify({
    required String receipt,
    required String corp,
    required String currentName,
    required String reportName,
    required DateTime start,
    required DateTime end,
    required Map<String, String> raw,
    required Map<String, Uri> uris,
  }) {
    void guard(bool b, String why) {
      if (!b) {
        throw FormatException('Exact own filing-series CFS absence: $why');
      }
    }

    final selected = profiles.where((p) => p['receipt'] == receipt).toList();
    guard(selected.length == 1, 'unregistered receipt');
    final p = selected.single, y = p['year'] as int;
    guard(
      corp == p['corp'] &&
          currentName == p['name'] &&
          start == DateTime.utc(y) &&
          end == DateTime.utc(y, 12, 31),
      'own current issuer/full fiscal period mismatch',
    );
    final sources = p['sources'] as List;
    guard(
      raw.length == 3 && uris.length == 3,
      'exact original source set required',
    );
    for (final s in sources) {
      guard(
        raw[s['label']] != null &&
            uris[s['label']]?.toString() == s['url'] &&
            sha256.convert(utf8.encode(raw[s['label']]!)).toString() ==
                s['sha256'],
        'exact source URI/SHA mismatch',
      );
    }
    final shell = raw['shell']!;
    final ids = RegExp(r"openCorpInfoNew\('(\d{8})'")
        .allMatches(shell)
        .map((m) => m[1])
        .toSet();
    guard(
      ids.length == 1 &&
          ids.single == corp &&
          shell.contains(p['shellNameQuote'] as String),
      'own shell selfCode/current-name literal missing',
    );
    bool node(String title, Uri uri) {
      final matches = <Map<String, String>>[];
      for (final b in RegExp(
        r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
        dotAll: true,
      ).allMatches(shell)) {
        if (b[2]!.replaceAll(RegExp(r'\s+'), '') != title) continue;
        final coords = <String, String>{};
        for (final m in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(b[3]!)) {
          if (coords.containsKey(m[1])) return false;
          coords[m[1]!] = m[2]!;
        }
        matches.add(coords);
      }
      return matches.length == 1 &&
          matches.single.length == 6 &&
          matches.single['rcpNo'] == receipt &&
          uri.queryParametersAll.length == 6 &&
          matches.single.entries.every(
            (e) =>
                uri.queryParametersAll[e.key]?.length == 1 &&
                uri.queryParameters[e.key] == e.value,
          );
    }

    guard(
      node('사업보고서', uris['cover']!) && node('2.연결재무제표', uris['cfs']!),
      'unique own cover/CFS nodes missing',
    );

    guard(
      uris['cover']!.queryParameters['dcmNo'] ==
          uris['cfs']!.queryParameters['dcmNo'],
      'original document family mismatch',
    );
    final coverRows =
        RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
            .allMatches(raw['cover']!)
            .map(
              (r) => RegExp(
                r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                caseSensitive: false,
              ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
            )
            .toList();
    for (final r in p['coverPeriodRows'] as List) {
      guard(
        jsonEncode(coverRows[r['index'] as int]) ==
            jsonEncode(
              (r['cells'] as List).map((s) => compact(s as String)).toList(),
            ),
        'actual declared cover period changed',
      );
    }
    guard(
      coverRows.length > 9 &&
          coverRows[9].length == 2 &&
          coverRows[9][0] == '회사명:' &&
          coverRows[9][1] == compact(p['actor'] as String),
      'exact original filing actor mismatch',
    );
    guard(
      compact(raw['cfs']!) == p['bodyCompact'],
      'complete own CFS paragraph mismatch',
    );
    final historical = p['historicalSpac'] == true;
    final identity = <String, String>{
      'policy': rule,
      'identityScope': 'official-DART-filing-series-only',
      'corpCode': corp,
      'currentMasterName': currentName,
      'printedCurrentShellName': RegExp(r'>([^<]+)</span>')
          .firstMatch(p['shellNameQuote'] as String)!
          .group(1)!,
      'printedFilingActor': p['actor'] as String,
      'sourceReceipt': receipt,
      'shellSource': uris['shell'].toString(),
      'shellSha256': sources.singleWhere(
        (s) => s['label'] == 'shell',
      )['sha256'],
      'coverSource': uris['cover'].toString(),
      'coverSha256': sources.singleWhere(
        (s) => s['label'] == 'cover',
      )['sha256'],
      'statementSource': uris['cfs'].toString(),
      'statementSha256': sources.singleWhere(
        (s) => s['label'] == 'cfs',
      )['sha256'],
      'jurirContinuityVerified': 'false',
      'operatingHistoryContinuityVerified': 'false',
      'numericFactsCollected': '0',
      'coreFinancialsVerified': 'false',
      'fullFinancialsVerified': 'false',
      'numericOperatingHistoryCollected': 'false',
      'sourceNotice': historical
          ? '과거 SPAC 공시기준: 원문 제출주체 ${p['actor']}. 현재 회사와의 연결은 해당 DART 공시의 법인코드·현재 표시명에 한정하며, 현재 사업의 과거 재무 이력이나 법인등록번호 연속성을 검증한 것이 아닙니다.'
          : '원문 제출주체 ${p['actor']}; DART 해당 공시의 법인코드·현재 표시명으로 공시를 식별했습니다. 회사명 차이를 일반 별칭으로 처리하지 않습니다.',
    };
    final result = _ExactFilingSeriesAbsence(
      identity: identity,
      sourceReceipt: receipt,
      corpCode: corp,
      companyName: currentName,
      reportName: reportName,
      periodStart: start,
      periodEnd: end,
      coverSource: uris['cover']!,
      statementSource: uris['cfs']!,
      coverHtml: raw['cover']!,
      statementHtml: raw['cfs']!,
      evidence: p['literal'] as String,
    );
    guard(
      result.sourceDigest == p['sourceDigest'],
      'actual compound cover+body digest mismatch',
    );
    return result;
  }
}

class _ExactFilingSeriesAbsence extends PublicFinancialHtmlBasisNotApplicable {
  _ExactFilingSeriesAbsence({
    required this.identity,
    required super.sourceReceipt,
    required super.corpCode,
    required super.companyName,
    required super.reportName,
    required super.periodStart,
    required super.periodEnd,
    required super.coverSource,
    required super.statementSource,
    required super.coverHtml,
    required super.statementHtml,
    required super.evidence,
  });
  final Map<String, String> identity;
  @override
  Map<String, String> get issuerIdentityEvidence => Map.unmodifiable(identity);
}
