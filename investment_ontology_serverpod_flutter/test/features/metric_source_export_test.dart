import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

void main() {
  final root = Platform.environment['METRIC_SOURCE_DIR'];
  test('export actual metrics for independent arithmetic verification', () {
    final output = <String, dynamic>{};
    for (final file in Directory('$root/api').listSync().whereType<File>()) {
      if (!RegExp(r'^\d+(_(consolidated|separate))?\.json$')
          .hasMatch(file.uri.pathSegments.last)) {
        continue;
      }
      final data = CompanyFinancials.fromJson(
        jsonDecode(file.readAsStringSync()),
      );
      output[file.uri.pathSegments.last] = {
        for (final m in FinancialView(data).metrics())
          m.key: {
            'value': m.derived.value,
            'missing': m.derived.missing,
            'display': m.display,
          },
      };
    }
    File('$root/derived.json').writeAsStringSync(jsonEncode(output));
  }, skip: root == null ? 'Explicit source snapshot required' : false);
}
