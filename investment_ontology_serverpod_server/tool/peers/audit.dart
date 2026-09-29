import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/peer_rules.dart';

/// Usage: dart run tool/peers/audit.dart snapshot.json report.json
/// Snapshot: latest eligible profiles, with corpCode/name/industryCode/signals.
void main(List<String> args) {
  if (args.length != 2) throw ArgumentError('snapshot.json report.json');
  final rows = (jsonDecode(File(args[0]).readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final signals = {
    for (final r in rows)
      r['corpCode'] as String: (r['signals'] as List)
          .map((v) => PeerSignal.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
  };
  final counts = <String, int>{};
  final matches = <Map<String, dynamic>>[];
  for (final a in rows) {
    for (final s in signals[a['corpCode']]!) {
      counts.update(s.label, (n) => n + 1, ifAbsent: () => 1);
    }
    final candidates = <Map<String, dynamic>>[];
    for (final b in rows) {
      if (a['corpCode'] == b['corpCode']) continue;
      final focus = PeerRules.focuses(signals[a['corpCode']]!).firstOrNull;
      if (focus == null ||
          !signals[b['corpCode']]!.any((s) => s.key == focus.key)) {
        continue;
      }
      final match = PeerRules.match(
        signals[a['corpCode']]!,
        signals[b['corpCode']]!,
        anchorIndustry: a['industryCode'] as String?,
        candidateIndustry: b['industryCode'] as String?,
      );
      if (match != null) {
        candidates.add({
          'corpCode': b['corpCode'],
          'name': b['name'],
          'score': match.score,
          'reasons': match.reasons,
        });
      }
    }
    candidates.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    if (candidates.isNotEmpty) {
      matches.add({
        'corpCode': a['corpCode'],
        'name': a['name'],
        'candidates': candidates.take(5).toList(),
      });
    }
  }
  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'ruleVersion': PeerRules.version,
      'profiles': rows.length,
      'companiesWithCandidates': matches.length,
      'productCoverage': counts,
      'matches': matches,
    }),
  );
  stdout.writeln(
    'Profiles ${rows.length}; companies with candidates ${matches.length}',
  );
}
