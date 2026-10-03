import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/charter_comparison_rules.dart';

/// Uses the very same Dart parser as the public endpoint, never AI/manual rows.
void main(List<String> args) {
  final input = Directory(args[0]);
  final output = Directory(args[1])..createSync(recursive: true);
  final manifest = jsonDecode(
    File('${input.path}/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final companies = jsonDecode(
    File('${input.path}/companies.json').readAsStringSync(),
  ) as List;
  final byCompany = <String, List<Map<String, dynamic>>>{};
  var parsed = 0, changes = 0;
  for (final file in Directory(
    '${input.path}/bodies',
  ).listSync().whereType<File>()) {
    final raw = jsonDecode(
      utf8.decode(gzip.decode(file.readAsBytesSync())),
    ) as Map<String, dynamic>;
    final html = raw['body'] as String;
    final result = CharterComparisonRules.parse(html);
    final receipt = raw['receipt'] as String;
    final notice = <String, dynamic>{
      ...result,
      'receipt': receipt,
      'reportName': raw['reportName'],
      'stage': 'proposal',
      'filingDate':
          '${receipt.substring(0, 4)}-${receipt.substring(4, 6)}-${receipt.substring(6, 8)}',
      'sourceUrl': raw['sourceUrl'],
      'retrievedAt': raw['retrievedAt'],
      'sha256': sha256.convert(utf8.encode(html)).toString(),
      'source': {
        'kind': 'dartReport',
        'title': 'DART 주주총회소집공고 정관 대비표',
        'reference': receipt,
        'url': raw['sourceUrl'],
        'retrievedAt': raw['retrievedAt'],
      },
    };
    byCompany.putIfAbsent(raw['corpCode'] as String, () => []).add(notice);
    parsed++;
    if ((result['changes'] as List).isNotEmpty) changes++;
  }
  var covered = 0, unavailable = 0, noNotice = 0, withChanges = 0;
  for (final c in companies.cast<Map<String, dynamic>>()) {
    final code = c['corpCode'] as String;
    final notices = byCompany[code] ?? [];
    notices.sort(
      (a, b) => (b['receipt'] as String).compareTo(a['receipt'] as String),
    );
    final count = (manifest['notices'] as List)
        .where((n) => n['corpCode'] == code)
        .length;
    final state = count == 0
        ? 'noNotice'
        : notices.length < count
        ? 'partial'
        : 'ready';
    if (count == 0) {
      noNotice++;
    } else if (notices.isEmpty) {
      unavailable++;
    } else {
      covered++;
    }
    if (notices.any((n) => (n['changes'] as List).isNotEmpty)) withChanges++;
    File('${output.path}/$code.json').writeAsStringSync(
      jsonEncode({
        'corpCode': code,
        'fromDate': manifest['fromDate'],
        'toDate': manifest['toDate'],
        'noticeState': state,
        'noticeCount': count,
        'inspectedCount': notices.length,
        'failedCount': count - notices.length,
        'notices': notices,
      }),
    );
  }
  final stats = {
    'companies': companies.length,
    'parsedNotices': parsed,
    'comparisonNotices': changes,
    'withNotices': covered,
    'withComparisons': withChanges,
    'noNotice': noNotice,
    'unavailable': unavailable,
    'fromDate': manifest['fromDate'],
    'toDate': manifest['toDate'],
  };
  File('${input.path}/coverage.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(stats));
  stdout.writeln(jsonEncode(stats));
}
