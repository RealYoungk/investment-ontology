// Run explicitly against captured public API data; not part of routine tests.
// BUSINESS_AUDIT_CONTENT_DIR=/absolute/path flutter test tool/audit/business_universe_render_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_insights_panel.dart';

import '../../test/support/shad_test_host.dart';

void main() {
  testWidgets('captured company source tables render including expanded rows', (
    tester,
  ) async {
    final directory = Platform.environment['BUSINESS_AUDIT_CONTENT_DIR'];
    if (directory == null) {
      throw StateError(
        'BUSINESS_AUDIT_CONTENT_DIR must name captured API data',
      );
    }
    final output = File(
      Platform.environment['BUSINESS_AUDIT_RENDER_LEDGER'] ??
          '$directory/render-ledger.jsonl',
    );
    final shard = int.parse(
      Platform.environment['BUSINESS_AUDIT_RENDER_SHARD'] ?? '0',
    );
    final shards = int.parse(
      Platform.environment['BUSINESS_AUDIT_RENDER_SHARDS'] ?? '1',
    );
    final widths =
        (Platform.environment['BUSINESS_AUDIT_RENDER_WIDTHS'] ?? '1440,390')
            .split(',')
            .map(double.parse)
            .toList();
    final resume = Platform.environment['BUSINESS_AUDIT_RENDER_RESUME'] == '1';
    final completed = <String>{};
    final onlyCodes =
        (Platform.environment['BUSINESS_AUDIT_RENDER_ONLY_CODES'] ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toSet();
    final trace = Platform.environment['BUSINESS_AUDIT_RENDER_TRACE'] == '1';
    if (resume && output.existsSync()) {
      for (final line in output.readAsLinesSync()) {
        final entry = jsonDecode(line) as Map<String, dynamic>;
        if (entry['status'] == 'pass') completed.add(entry['file'] as String);
      }
    }
    output.parent.createSync(recursive: true);
    final files =
        Directory(directory)
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('businessContent.json') ||
                  RegExp(r'/api-\d+\.json$').hasMatch(f.path),
            )
            .where((f) {
              final code = RegExp(r'(?:/|api-)(\d{8})(?:/|\.json)')
                  .firstMatch(f.path)
                  ?.group(1);
              return code != null &&
                  (onlyCodes.isEmpty || onlyCodes.contains(code)) &&
                  int.parse(code) % shards == shard &&
                  !completed.contains(f.path);
            })
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty);
    if (!resume) output.writeAsStringSync('');
    var failures = 0;
    var tables = 0;
    for (final (index, file) in files.indexed) {
      final data = jsonDecode(file.readAsStringSync());
      if (data == null) continue;
      final report = BusinessContent.fromJson(data as Map<String, dynamic>);
      final errors = <String>[];
      final handler = FlutterError.onError;
      FlutterError.onError = (details) =>
          errors.add(details.exceptionAsString());
      try {
        for (final width in widths) {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          // Render one literal source table at a time so every expanded row is
          // actually laid out, including tables below a long issuer page.
          for (final (tableIndex, table)
              in (report.tableInsights ?? <BusinessTableInsight>[]).indexed) {
            if (trace) {
              // ignore: avoid_print
              print(
                'TABLE ${file.path} $tableIndex ${table.topic} ${table.title}',
              );
            }
            await tester.pumpWidget(
              shadTestHost(
                MaterialApp(
                  theme: buildAppTheme(ledgerBrand),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: BusinessTableInsightsPanel(
                        key: ValueKey('${file.path}-$width-$tableIndex'),
                        insights: [table],
                        rceptNo: report.rceptNo,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle(
              const Duration(milliseconds: 100),
              EnginePhase.sendSemanticsUpdate,
              const Duration(seconds: 5),
            );
            final risk = find.text('파생상품·위험관리 펼치기');
            if (risk.evaluate().isNotEmpty) {
              await tester.ensureVisible(risk);
              await tester.tap(risk);
              await tester.pumpAndSettle(
                const Duration(milliseconds: 100),
                EnginePhase.sendSemanticsUpdate,
                const Duration(seconds: 5),
              );
            }
            final expand = find.text('항목별 정보 ${table.rows.length}개');
            if (expand.evaluate().isNotEmpty) {
              await tester.ensureVisible(expand);
              await tester.tap(expand);
              await tester.pumpAndSettle(
                const Duration(milliseconds: 100),
                EnginePhase.sendSemanticsUpdate,
                const Duration(seconds: 5),
              );
            }
            tables++;
          }
        }
      } catch (error) {
        errors.add(error.toString());
      } finally {
        FlutterError.onError = handler;
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
      final bindingError = tester.takeException();
      if (bindingError != null) errors.add(bindingError.toString());
      if (errors.isNotEmpty) failures++;
      output.writeAsStringSync(
        '${jsonEncode({
          'file': file.path,
          'receipt': report.rceptNo,
          'tables': report.tableInsights?.length ?? 0,
          'widths': widths,
          'errors': errors.toSet().toList(),
          'status': errors.isEmpty ? 'pass' : 'fail',
        })}\n',
        mode: FileMode.append,
      );
      if ((index + 1) % 50 == 0) {
        // ignore: avoid_print
        print(
          'RENDER ${index + 1}/${files.length} tables=$tables failures=$failures',
        );
      }
    }
    expect(failures, 0, reason: 'See ${output.path}');
  }, timeout: const Timeout(Duration(hours: 2)));
}
