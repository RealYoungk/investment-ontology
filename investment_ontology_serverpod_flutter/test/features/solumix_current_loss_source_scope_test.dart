import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  test('Solumix24 actual current8 audit projection exposes signed raw losses and finite identity', () {
    final m = jsonDecode(
      File(
        '../investment_ontology_serverpod_server/assets/financial_source_cache/20250407004339-ofs-located-own-loss-eight/manifest.json',
      ).readAsStringSync(),
    ) as Map;
    final body = (m['sources'] as List).singleWhere((x) => x['label'] == 'ofs');
    final rows = [
      for (final c in m['core'])
        {
          'account_nm': c['label'],
          'account_id': null,
          'currency': 'KRW',
          'xbrl_provenance': null,
          'thstrm_amount':
              (c['signNormalization'] ==
                      'explicitPrintedLossMagnitudeCorroborated'
                  ? '-'
                  : '') +
              (c['literal'] as String)
                  .replaceAll(',', '')
                  .replaceAll('(', '-')
                  .replaceAll(')', ''),
          'html_provenance': {
            'ruleVersion': m['ruleVersion'],
            'source': body['url'],
            'sourceSha256': body['sha256'],
            'sourceReceipt': m['sourceReceipt'],
            'targetReceipt': m['receipt'],
            'tableIndex': c['table'],
            'rowIndex': c['row'],
            'currentColumn': c['column'],
            'printedLabel': c['label'],
            'printedAmount': c['literal'],
            'unit': '원',
            'unitMultiplier': '1',
            'periodStart': m['periodStart'],
            'periodEnd': m['periodEnd'],
            'currentCore8': true,
            'fullStatementVerified': false,
            'notesVerified': false,
            'detailEnrichmentApproved': false,
            'sourceCellRewritten': false,
            'printedLossSourceOwnOnly': true,
            'signNormalization': c['signNormalization'],
            'derivedSignedAmount':
                (c['signNormalization'] ==
                        'explicitPrintedLossMagnitudeCorroborated'
                    ? '-'
                    : '') +
                (c['literal'] as String)
                    .replaceAll(',', '')
                    .replaceAll('(', '-')
                    .replaceAll(')', ''),
            'sourceMainEquationCount': 18,
            'printedFxDashIsNumericZero': false,
            'ownIssuerFilingSeriesEvidence': m['ownIssuerFilingSeriesEvidence'],
          },
        },
    ];
    final v = <String, dynamic>{
      'action': 'verified-keyless-annual-source-after-api-noData',
      'targetReceipt': m['receipt'],
      'sourceReceipt': m['sourceReceipt'],
      'corpCode': m['corpCode'],
      'fsDiv': 'separate',
      'coreRows': 8,
      'coreRowProvenance': rows,
    };
    final notice = FinancialSourceScopeNotice.messageFor(jsonEncode(v));
    expect(notice, contains('당기 핵심 8개'));
    expect(notice, contains('원문 셀은 보존'));
    expect(notice, contains('연속성을 주장하지'));
    expect(notice, contains('전체 상세 계정·주석 검증은 완료하지'));
    expect(
      FinancialSourceScopeNotice.messageFor(
        jsonEncode({...v, 'fsDiv': 'consolidated'}),
      ),
      isNull,
    );
    expect(
      FinancialSourceScopeNotice.messageFor(
        jsonEncode({...v, 'sourceReceipt': m['receipt']}),
      ),
      isNull,
    );
    expect(
      FinancialSourceScopeNotice.messageFor(
        jsonEncode({...v, 'corpCode': '00000000'}),
      ),
      isNull,
    );
    rows[4]['thstrm_amount'] = '1541424780';
    expect(FinancialSourceScopeNotice.messageFor(jsonEncode(v)), isNull);
  });
}
