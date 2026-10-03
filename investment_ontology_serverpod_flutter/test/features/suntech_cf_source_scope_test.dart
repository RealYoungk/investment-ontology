import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  Map<String, dynamic> payload() {
    final rows = jsonDecode(
      File(
        '../investment_ontology_serverpod_server/assets/financial_source_cache/20250317000968-cfs-suntech-current-eight/expected-rows.json',
      ).readAsStringSync(),
    );
    return {
      'action': 'verified-exact-own-consolidated-cf-net-income-and-ppe',
      'receipt': '20250317000968',
      'corpCode': '00963000',
      'year': 2024,
      'fsDiv': 'consolidated',
      'source': rows[0]['html_provenance']['source'],
      'sha256':
          '1ba5d38ebc216716dfd94b3ecd34a9e2ce4e31010d5c11682ecf79ba24a2a57e',
      'ruleVersion': 'suntech-2024-own-cfs-source-aware-eight-v1',
      'coreRows': 8,
      'coreRowProvenance': rows,
      'netIncomeSourceStatement': 'cashFlow',
      'netIncomeRawLabel': '1.당기순이익',
      'netIncomeAmount': '-1288353219',
      'capexRawLabel': '유형자산의증가',
      'capexAmount': '93377336',
      'storedAccountId': null,
      'wholePLNISynthesized': false,
      'CEUnitPrinted': false,
      'CECurrencyVerified': false,
      'allStatementRowsVerified': false,
      'fullStatementCollected': false,
      'notesVerified': false,
    };
  }

  test('exact eight source explains CF NI selection and CE currency hold', () {
    final m = FinancialSourceScopeNotice.messageFor(jsonEncode(payload()));
    expect(m, contains('핵심 8개'));
    expect(m, contains('현금흐름표'));
    expect(m, contains('자본변동표의 단위는 인쇄되지 않아'));
    expect(m, contains('주석은 검증을 마치지'));
  });
  test(
    'foreign/source/whole flags/raw CF statement drift cannot advertise exact8',
    () {
      for (final e in <String, dynamic>{
        'sha256': 'bad',
        'corpCode': '00000000',
        'fsDiv': 'separate',
        'year': 2023,
        'CECurrencyVerified': true,
        'wholePLNISynthesized': true,
        'notesVerified': true,
        'netIncomeAmount': '-938205085',
      }.entries) {
        final p = payload();
        p[e.key] = e.value;
        expect(
          FinancialSourceScopeNotice.messageFor(jsonEncode(p)),
          isNull,
          reason: e.key,
        );
      }
      for (final k in ['netIncome', 'capex']) {
        final p = payload();
        p['coreRowProvenance'][k == 'netIncome' ? 5 : 7]['sj_div'] = 'IS';
        expect(FinancialSourceScopeNotice.messageFor(jsonEncode(p)), isNull);
      }
    },
  );
}
