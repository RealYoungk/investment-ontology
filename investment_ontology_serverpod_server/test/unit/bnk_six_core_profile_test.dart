import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/bnk_six_core_profile.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  final cover = File('test/fixtures/financial_html/bnk-six-core/cover.html')
      .readAsStringSync();
  final statement = File('test/fixtures/financial_html/bnk-six-core/OFS.html')
      .readAsStringSync();
  List<Map<String, dynamic>> parse({
    String corp = '00858364',
    String receipt = '20230309000759',
    bool cfs = false,
    String? raw,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover,
    statementHtml: raw ?? statement,
    coverSource: Uri.parse(BnkSixCoreProfile.coverUri),
    statementSource: Uri.parse(BnkSixCoreProfile.statementUri),
    receipt: receipt,
    corpCode: corp,
    companyName: '(주)BNK금융지주',
    periodStart: DateTime.utc(2022, 1, 1),
    periodEnd: DateTime.utc(2022, 12, 31),
    consolidated: cfs,
  );
  bool proof(dynamic rows) => BnkSixCoreProfile.storedProof(
    rows,
    sourceDigest: BnkSixCoreProfile.digest,
    sourceUrl: BnkSixCoreProfile.statementUri,
    companyCode: '00858364',
    targetReceipt: '20230309000759',
    basis: 'separate',
    year: 2022,
    reportName: '사업보고서 (2022.12)',
  );
  test(
    'official shell exact corp/receipt/dcm yields the same six profile',
    () async {
      final client = MockClient((r) async {
        final file = r.url.path == '/dsaf001/main.do'
            ? 'shell.html'
            : r.url.toString() == BnkSixCoreProfile.coverUri
            ? 'cover.html'
            : r.url.toString() == BnkSixCoreProfile.statementUri
            ? 'OFS.html'
            : null;
        if (file == null) throw StateError('Unexpected URL');
        return http.Response.bytes(
          File('test/fixtures/financial_html/bnk-six-core/$file')
              .readAsBytesSync(),
          200,
          request: r,
        );
      });
      final result = await PublicFinancialHtmlFetcher(client).fetchAnnual(
        BnkSixCoreProfile.receipt,
        reportName: '사업보고서 (2022.12)',
        corpCode: BnkSixCoreProfile.corpCode,
        companyName: '(주)BNK금융지주',
        bsnsYear: 2022,
        periodEnd: DateTime.utc(2022, 12, 31),
        consolidated: false,
      );
      expect(result.sourceDigest, BnkSixCoreProfile.digest);
      expect(proof(result.rows), isTrue);
      client.close();
    },
  );
  for (final field in [
    'currency',
    'label',
    'CE',
    'revenue',
    'capex',
    'column',
    'SHA',
    'duplicate',
  ]) {
    test('independent audit rejects forged $field', () {
      final rows = (jsonDecode(jsonEncode(parse())) as List)
          .cast<Map<String, dynamic>>();
      final p = rows.first['html_provenance'] as Map;
      final b = p['bnkSixCore'] as Map;
      switch (field) {
        case 'currency':
          rows.first['currency'] = 'USD';
        case 'label':
          rows.first['account_nm'] = '주주귀속자본';
          p['printedAccount'] = '주주귀속자본';
        case 'CE':
          b['ceWholeProfit'] = '0';
        case 'revenue':
          b['missingRequiredAccounts'] = [];
        case 'capex':
          b['uncollectedOptionalAccounts'] = [];
        case 'column':
          p['printedCurrentCells'] = ['0'];
        case 'SHA':
          b['coverSha256'] = '0' * 64;
        case 'duplicate':
          rows[1] = rows.first;
      }
      expect(proof(rows), isFalse);
    });
  }
  test(
    'actual whole six preserves printed rows and verifies current CE totals',
    () {
      final rows = parse();
      expect(rows, hasLength(6));
      expect(proof(rows), isTrue);
      expect(
        rows.map((r) => r['thstrm_amount']),
        BnkSixCoreProfile.amounts.values,
      );
      expect(rows.every((r) => r['account_id'] == null), isTrue);
      expect(
        rows.any((r) => r['account_nm'].toString().contains('매출')),
        isFalse,
      );
    },
  );
  for (final mutation in ['corp', 'receipt', 'basis', 'unit', 'amount', 'CE']) {
    test('reject $mutation source variation', () {
      expect(
        () => parse(
          corp: mutation == 'corp' ? '00858365' : '00858364',
          receipt: mutation == 'receipt' ? '20230309000758' : '20230309000759',
          cfs: mutation == 'basis',
          raw: mutation == 'unit'
              ? statement.replaceAll('단위 : 원', '단위 : 천원')
              : mutation == 'amount'
              ? statement.replaceAll('305,256,302,474', '305,256,302,475')
              : mutation == 'CE'
              ? statement.replaceAll('5,251,713,667,367', '5,251,713,667,368')
              : null,
        ),
        throwsFormatException,
      );
    });
  }
  test('audit cannot admit five rows or an invented required account', () {
    final rows = parse();
    expect(proof(rows.sublist(1)), isFalse);
    rows.first['thstrm_amount'] = '0';
    expect(proof(rows), isFalse);
  });
}
