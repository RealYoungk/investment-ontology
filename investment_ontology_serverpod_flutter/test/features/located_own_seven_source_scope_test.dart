import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  for (final pair in [
    ('20220322000802', 'ofs'),
    ('20240424000570', 'cfs'),
    ('20250429000919', 'ofs'),
  ]) {
    test('${pair.$1} real source partial7 explains absent whole capex and no FCF', () {
      final m = jsonDecode(
        File(
          '../investment_ontology_serverpod_server/assets/financial_source_cache/${pair.$1}-${pair.$2}-located-own-seven/manifest.json',
        ).readAsStringSync(),
      ) as Map;
      final source = (m['sources'] as List).singleWhere(
        (s) => s['label'] == pair.$2,
      );
      final rows = [
        for (final c in m['core'])
          {
            'account_nm': c['label'],
            'account_id': null,
            'thstrm_amount': (c['literal'] as String)
                .replaceAll(',', '')
                .replaceAll('(', '-')
                .replaceAll(')', ''),
            'html_provenance': {
              'ruleVersion': m['ruleVersion'],
              'sourceReceipt': m['receipt'],
              'targetReceipt': m['receipt'],
              'source': source['url'],
              'sourceSha256': source['sha256'],
              'tableIndex': c['table'],
              'rowIndex': c['row'],
              'currentColumn': c['column'],
              'printedLabel': c['label'],
              'printedAmount': c['literal'],
              'unit': '원',
              'unitMultiplier': '1',
              'periodStart': m['periodStart'],
              'periodEnd': m['periodEnd'],
              'partialCore7': true,
              'currentCore8': false,
              'coreAccountsProvided': 7,
              'fullStatementVerified': false,
              'notesVerified': false,
              'detailEnrichmentApproved': false,
              'syntheticCapex': false,
              'missingAccountReasons': m['missingAccountReasons'],
            },
          },
      ];
      final p = <String, dynamic>{
        'action': 'verified-keyless-annual-source-after-api-noData',
        'targetReceipt': m['receipt'],
        'sourceReceipt': m['receipt'],
        'corpCode': m['corpCode'],
        'fsDiv': m['basis'],
        'coreRows': 7,
        'coreRowProvenance': rows,
      };
      final msg = FinancialSourceScopeNotice.messageFor(jsonEncode(p));
      expect(msg, contains('유형자산 취득 총액은 미확보'));
      expect(msg, contains('FCF와 FCF 수익률은 계산하지 않습니다'));
      expect(msg, contains('주석은 검증을 마치지'));
      expect(
        FinancialSourceScopeNotice.messageFor(
          jsonEncode({...p, 'corpCode': '00000000'}),
        ),
        isNull,
      );
      expect(
        FinancialSourceScopeNotice.messageFor(
          jsonEncode({
            ...p,
            'fsDiv': m['basis'] == 'consolidated' ? 'separate' : 'consolidated',
          }),
        ),
        isNull,
      );
      rows[0]['html_provenance']['currentColumn'] = 99;
      expect(FinancialSourceScopeNotice.messageFor(jsonEncode(p)), isNull);
    });
  }
}
