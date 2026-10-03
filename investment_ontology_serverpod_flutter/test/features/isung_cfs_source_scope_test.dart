import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  for (final receipt in ['20230323000123', '20240321000294']) {
    Map<String, dynamic> payload() {
      final dir =
          '../investment_ontology_serverpod_server/assets/financial_source_cache/$receipt-cfs-isung-current-seven';
      final evidence = jsonDecode(
        File('$dir/current-evidence.json').readAsStringSync(),
      );
      return {
        'action': 'verified-keyless-annual-source-after-api-noData',
        'targetReceipt': receipt,
        'sourceReceipt': receipt,
        'corpCode': '01365384',
        'fsDiv': 'consolidated',
        'format': 'html',
        'sha256': evidence['sourceDigest'],
        'coreRows': 7,
        'coreRowProvenance': jsonDecode(
          File('$dir/expected-rows.json').readAsStringSync(),
        ),
      };
    }

    test('$receipt transparent source-bounded partial7 scope', () {
      final message = FinancialSourceScopeNotice.messageFor(
        jsonEncode(payload()),
      );
      expect(message, contains('핵심 7개'));
      expect(message, contains('유형자산 취득액은 미확보'));
      expect(message, contains('FCF'));
      expect(message, contains('주석은 검증을 마치지 않았습니다'));
      expect(
        message,
        contains(receipt == '20230323000123' ? '포괄손익계산서' : '부호를 적용'),
      );
    });
    test(
      '$receipt altered basis digest core sign and whole flags rejected',
      () {
        for (final m in <String, dynamic>{
          'fsDiv': 'separate',
          'sha256': 'bad',
          'corpCode': '00000000',
          'coreRows': 8,
          'sourceReceipt': '20260323000000',
        }.entries) {
          final p = payload();
          p[m.key] = m.value;
          expect(
            FinancialSourceScopeNotice.messageFor(jsonEncode(p)),
            isNull,
            reason: m.key,
          );
        }
        for (final m in <String, dynamic>{
          'notesVerified': true,
          'FCFSupported': true,
          'fullStatementCollected': true,
          'sourceSha256': 'bad',
          'signNormalization': 'unboundFlip',
        }.entries) {
          final p = payload();
          p['coreRowProvenance'][5]['html_provenance'][m.key] = m.value;
          expect(
            FinancialSourceScopeNotice.messageFor(jsonEncode(p)),
            isNull,
            reason: m.key,
          );
        }
        final p = payload();
        p['coreRowProvenance'][5]['thstrm_amount'] = '1509318876';
        expect(FinancialSourceScopeNotice.messageFor(jsonEncode(p)), isNull);
      },
    );
  }
}
