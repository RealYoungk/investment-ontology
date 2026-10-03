import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/split_plan_documents.dart';

void main() {
  for (final row in SplitPlanDocuments.rows) {
    final code = row['corpCode'];
    test('$code exact whole delegated source bytes and numeric exclusion', () {
      final bytes = gzip.decode(
        File('test/fixtures/issuer_documents/split/$code.html.gz')
            .readAsBytesSync(),
      );
      SplitPlanDocuments.verifyBytes(row, bytes);
      expect(row['financialValues'], isNull);
      expect(row['annualPeriodCount'], 0);
      expect(row['wholeFinancialStatementsComplete'], false);
      expect(row['corpCode'], isNot(row['filingActorCorpCode']));
    });
    test('$code changed original rejects', () {
      final bytes = gzip.decode(
        File('test/fixtures/issuer_documents/split/$code.html.gz')
            .readAsBytesSync(),
      );
      bytes[100] ^= 1;
      expect(
        () => SplitPlanDocuments.verifyBytes(row, bytes),
        throwsFormatException,
      );
    });
    test('$code every compiled metadata field is exact', () {
      for (final key in row.keys) {
        final bad = Map<String, dynamic>.from(row)..[key] = 'changed';
        expect(
          () => SplitPlanDocuments.validate([bad]),
          throwsFormatException,
          reason: key,
        );
      }
      expect(
        () => SplitPlanDocuments.validate([row, row]),
        throwsFormatException,
      );
      expect(
        SplitPlanDocuments.validate(jsonDecode(jsonEncode([row]))),
        hasLength(1),
      );
    });
  }
}
