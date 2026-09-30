import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/metric_profile.dart';

void main() {
  final path = Platform.environment['METRIC_AUDIT_DIR'];
  test(
    'stored universe: every metric is finite or has an explicit reason',
    () {
      final dir = Directory(path!);
      final companies = jsonDecode(
        File('${dir.path}/companies.json').readAsStringSync(),
      ) as List;
      final counts = <String, Map<String, int>>{};
      final missing = <Map<String, dynamic>>[];
      for (final c in companies) {
        final data = CompanyFinancials.fromJson(
          jsonDecode(
            File('${dir.path}/${c['corpCode']}.json').readAsStringSync(),
          ),
        );
        final metrics = FinancialView(data).metrics();
        final selected = MetricProfile.forCompany(
          c['industryCode'],
          c['name'],
          metrics,
        ).select(metrics);
        expect(selected.length, 6, reason: c['name']);
        for (final m in metrics) {
          final v = m.derived;
          expect(
            v.value == null
                ? v.missing?.isNotEmpty == true
                : v.value!.isFinite && v.missing == null,
            isTrue,
            reason: '${c['name']} ${m.key}',
          );
          final tally = counts.putIfAbsent(
            m.key,
            () => {'available': 0, 'missing': 0},
          );
          final status = v.value == null ? 'missing' : 'available';
          tally[status] = tally[status]! + 1;
        }
        final absent = selected.where((m) => m.derived.value == null).toList();
        if (absent.isNotEmpty) {
          missing.add({
            'corpCode': c['corpCode'],
            'name': c['name'],
            'basis': data.fsDiv?.name,
            'missing': {for (final m in absent) m.key: m.derived.missing},
          });
        }
      }
      File('${dir.path}/audit.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'companies': companies.length,
          'metrics': counts,
          'headlineMissing': missing,
        }),
      );
    },
    skip: path == null
        ? 'Set METRIC_AUDIT_DIR to an explicit API snapshot directory'
        : false,
  );
}
