// Bounded, read-only DART fixture capture. Never imports into an application DB.
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/dart_research.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3 ||
      !RegExp(r'^\d{8}$').hasMatch(args[0]) ||
      !DartResearch.apis.containsKey(args[1])) {
    stderr.writeln(
      'Usage: dart run tool/research_sample.dart CORP KIND OUTPUT.json',
    );
    exitCode = 2;
    return;
  }
  final output = File(args[2]);
  if (output.existsSync()) throw StateError('Refusing to overwrite sample');
  final passwords = loadYaml(File('config/passwords.yaml').readAsStringSync());
  final key =
      Platform.environment['DART_API_KEY'] ??
      passwords['development']?['dartApiKey'] ??
      passwords['shared']?['dartApiKey'];
  if (key is! String || key.isEmpty) {
    throw StateError('DART key not configured');
  }
  final client = DartClient(key);
  final now = DateTime.now().toUtc();
  final from = DateTime.utc(now.year - 5, now.month, now.day);
  try {
    final rows = <Map<String, dynamic>>[];
    for (final api in DartResearch.apis[args[1]]!) {
      final raw = await client.fetchResearchDisclosure(
        api,
        args[0],
        from: from,
        to: now,
      );
      for (final row in raw) {
        if (row['corp_code'] != args[0]) throw StateError('Company mismatch');
        final normalized = DartResearch.normalize(api, row);
        if (!DateTime.parse(normalized['date']).isBefore(from)) {
          rows.add(normalized);
        }
      }
    }
    await output.parent.create(recursive: true);
    await output.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'corpCode': args[0],
        'kind': args[1],
        'capturedAt': now.toIso8601String(),
        'from': from.toIso8601String(),
        'to': now.toIso8601String(),
        'calls': client.calls,
        'rows': rows,
      }),
    );
    stdout.writeln(
      'Captured ${rows.length} rows; ${client.calls} DART calls. No DB writes.',
    );
  } on DartApiException catch (e) {
    stderr.writeln('DART ${e.status}: ${e.message}');
    exitCode = 1;
  } catch (_) {
    // Network exception URIs may contain the key; do not print them.
    stderr.writeln(
      'Capture failed; details omitted to protect API credentials.',
    );
    exitCode = 1;
  } finally {
    client.close();
  }
}
