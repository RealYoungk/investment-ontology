import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  final fixtures = jsonDecode(
    File('test/fixtures/ls_kiwoom_scope_sources.json').readAsStringSync(),
  ) as List;
  for (final source in fixtures) {
    final key = '${source['targetReceipt']}:${source['fsDiv']}';
    Map copy() => jsonDecode(jsonEncode(source)) as Map;
    test('$key finite own source scope and preserved limitations', () {
      final message = FinancialSourceScopeNotice.messageFor(
        jsonEncode(source),
      )!;
      expect(message, contains(source['coreRows'] == 8 ? '8개' : '7개'));
      expect(message, contains('주석'));
      expect(message, contains('검증을 마치지 않았습니다'));
      expect(message, contains(source['coreRows'] == 8 ? '-1천원' : 'FCF'));
    });
    test(
      '$key source-basis/issuer/notes/fullclaim transplant does not obtain finite notice',
      () {
        for (final field in [
          'corpCode',
          'targetReceipt',
          'sourceReceipt',
          'fsDiv',
        ]) {
          final j = copy();
          j[field] = 'wrong';
          expect(FinancialSourceScopeNotice.messageFor(jsonEncode(j)), isNull);
        }
        for (final field in [
          'sourceSha256',
          'ruleVersion',
          'unit',
          'periodEnd',
          'basis',
        ]) {
          final j = copy();
          j['coreRowProvenance'][0]['html_provenance'][field] = 'wrong';
          expect(FinancialSourceScopeNotice.messageFor(jsonEncode(j)), isNull);
        }
        for (final field in [
          'fullStatementVerified',
          'notesVerified',
          'genericRoundingTolerance',
          'priorNumericPeriodsCollected',
        ]) {
          final j = copy();
          j['coreRowProvenance'][0]['html_provenance'][field] = true;
          expect(FinancialSourceScopeNotice.messageFor(jsonEncode(j)), isNull);
        }
        for (final field in [
          'source',
          'sha256',
          'printedUnit',
          'cashDetailResidual',
        ]) {
          final j = copy();
          j['coreRowProvenance'][0]['html_provenance']['cashScopeEvidence'][field] =
              'wrong';
          expect(FinancialSourceScopeNotice.messageFor(jsonEncode(j)), isNull);
        }
        final j = copy();
        j['coreRowProvenance'][0]['html_provenance']['cashScopeEvidence']['crossPrecisionEqualityClaim'] =
            true;
        expect(FinancialSourceScopeNotice.messageFor(jsonEncode(j)), isNull);
      },
    );
  }
}
