import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

void main() {
  final root = Platform.environment['GROWTH_AUDIT_DIR'];
  test(
    'public screen and detail share financial basis and metric arithmetic',
    () {
      final rows =
          (jsonDecode(File('$root/screen.json').readAsStringSync())
                  as Map)['items']
              as List;
      final failures = <Map<String, dynamic>>[];
      var checked = 0;
      for (final raw in rows) {
        final row = ScreenRow.fromJson(raw);
        final data = CompanyFinancials.fromJson(
          jsonDecode(
            File('$root/api/${row.company.corpCode}.json').readAsStringSync(),
          ),
        );
        expect(data.fsDiv, row.fsDiv, reason: row.company.name);
        final metrics = {
          for (final m in FinancialView(data).metrics()) m.key: m.derived.value,
        };
        final expected = {
          'per': row.per,
          'pbr': row.pbr,
          'roe': row.roe,
          'operatingMargin': row.operatingMargin,
          'debtRatio': row.debtRatio,
          'fcfYield': row.fcfYield,
          'revenueGrowth': row.revenueGrowth,
        };
        for (final entry in expected.entries) {
          final actual = metrics[entry.key];
          final percentage = !{'per', 'pbr'}.contains(entry.key);
          final server = entry.value == null
              ? null
              : entry.value! / (percentage ? 100 : 1);
          if ((actual == null) != (server == null) ||
              actual != null &&
                  server != null &&
                  (actual - server).abs() > 1e-8 * (1 + server.abs())) {
            failures.add({
              'company': row.company.name,
              'metric': entry.key,
              'detail': actual,
              'screen': server,
            });
          }
          checked++;
        }
      }
      File('$root/parity.json').writeAsStringSync(
        jsonEncode({'checked': checked, 'failures': failures}),
      );
      expect(failures, isEmpty);
    },
    skip: root == null
        ? 'Set GROWTH_AUDIT_DIR to an explicit current public snapshot'
        : false,
  );
}
