import '../support/shad_test_host.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

Map<String, dynamic> _payload(Map m, String statementLabel) {
  final source = (m['sources'] as List).singleWhere(
    (s) => s['label'] == statementLabel,
  );
  final rows = [
    for (final c in m['core'])
      {
        'account_nm': c['label'],
        'account_id': null,
        'currency': 'KRW',
        'xbrl_provenance': null,
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
          if (m['unresolvedOwnNoteDetailConflict'] == true) ...{
            'supportingUnverifiedNoteSource': (m['sources'] as List)
                .singleWhere((s) => s['label'] == 'notes')['url'],
            'supportingUnverifiedNoteSha256': (m['sources'] as List)
                .singleWhere((s) => s['label'] == 'notes')['sha256'],
            'ownNoteDisagreements': m['ownNoteDisagreements'],
            'ownNoteCrossPrecisionResiduals':
                m['ownNoteCrossPrecisionResiduals'],
            'independentCFNetIncomePrinted': false,
            'independentCFNetIncomeExact': false,
            'mainNetIncomePLCEExact': true,
            'unresolvedOwnNoteDetailConflict': true,
          },
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
  return p;
}

void main() {
  for (final pair in [
    ('20220322000802', 'ofs'),
    ('20240424000570', 'cfs'),
    ('20250429000919', 'ofs'),
    ('20260323001293', 'ofs'),
  ]) {
    test('${pair.$1} real source partial7 explains absent whole capex and no FCF', () {
      final m = jsonDecode(
        File(
          '../investment_ontology_serverpod_server/assets/financial_source_cache/${pair.$1}-${pair.$2}-located-own-seven/manifest.json',
        ).readAsStringSync(),
      ) as Map;
      final p = _payload(m, pair.$2);
      final rows = p['coreRowProvenance'] as List;
      final msg = FinancialSourceScopeNotice.messageFor(jsonEncode(p));
      expect(msg, contains('유형자산 취득 총액은 미확보'));
      if (m['unresolvedOwnNoteDetailConflict'] == true) {
        expect(msg, contains('주석34 당기 현금창출 −1천원·운전자본 +1천원'));
        expect(msg, contains('전기 조정 −1천원·운전자본 +2천원'));
        expect(msg, contains('순손익 −169원·현금창출 −92원'));
        expect(msg, contains('독립 순손익은 미인쇄·미검증'));
        final altered = jsonDecode(jsonEncode(p)) as Map;
        altered['coreRowProvenance'][0]['html_provenance']['independentCFNetIncomeExact'] =
            true;
        expect(
          FinancialSourceScopeNotice.messageFor(jsonEncode(altered)),
          isNull,
        );
      }
      expect(msg, contains('FCF와 FCF 수익률은 계산하지 않습니다'));
      expect(
        msg,
        contains(
          m['unresolvedOwnNoteDetailConflict'] == true
              ? '주석 검증은 완료하지'
              : '주석은 검증을 마치지',
        ),
      );
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
  testWidgets(
    'Pandora selected unresolved note differences remain visible at 320px',
    (tester) async {
      final m = jsonDecode(
        File(
          '../investment_ontology_serverpod_server/assets/financial_source_cache/20260323001293-ofs-located-own-seven/manifest.json',
        ).readAsStringSync(),
      ) as Map;
      final pandoraPayload = jsonEncode(_payload(m, 'ofs'));
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FinancialSourceScopeNotice(
                    sourceTitle: pandoraPayload,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('주석34 당기 현금창출 −1천원·운전자본 +1천원'),
        findsOneWidget,
      );
      expect(find.textContaining('전기 조정 −1천원·운전자본 +2천원'), findsOneWidget);
      expect(find.textContaining('순손익 −169원·현금창출 −92원'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
