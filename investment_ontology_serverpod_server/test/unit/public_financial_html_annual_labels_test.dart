import '../support/financial_html_test_clock.dart';

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

void main() {
  const dir = 'test/fixtures/financial_html/annual-labels';
  final evidence =
      jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
  final values = jsonDecode(
    File('$dir/reviewed-current-values.json').readAsStringSync(),
  ) as Map;
  String body(String rec, String type) =>
      File('$dir/$rec/$type.html').readAsStringSync();
  Map item(String rec) =>
      evidence.singleWhere((m) => m['receipt'] == rec) as Map;
  List<Map<String, dynamic>> parse(
    String rec,
    String basis, {
    String? statement,
  }) {
    final e = item(rec);
    final type = basis == 'CFS' ? 'consolidated' : 'separate';
    return PublicFinancialHtml.parseStandardAnnual(
      coverHtml: body(rec, 'cover'),
      statementHtml: statement ?? body(rec, type),
      coverSource: Uri.parse(e['urls']['cover']),
      statementSource: Uri.parse(e['urls'][type]),
      receipt: rec,
      corpCode: e['corpCode'],
      companyName: e['name'],
      periodStart: DateTime.parse('${e['start']}T00:00:00Z'),
      periodEnd: DateTime.parse('${e['end']}T00:00:00Z'),
      consolidated: basis == 'CFS',
    );
  }

  for (final (receipt, amount, label) in [
    ('20260430001951', '-5291588269', '연결당기순손실'),
    ('20260430001147', '698299790', '연결당기순이익'),
  ]) {
    test('actual whole connected net income $receipt', () {
      final rows = parse(receipt, 'CFS');
      final profit = rows.singleWhere(
        (r) => (r['account_nm'] as String).contains(label),
      );
      expect(profit['thstrm_amount'], amount);
      expect(profit['account_id'], isNull);
      expect(profit['sj_div'], 'CIS');
      final provenance = profit['html_provenance'] as Map;
      expect(provenance['printedLabel'], contains(label));
      if (label.contains('손실')) {
        expect(provenance['printedAmountBeforeSignRule'], '5291588269');
        expect(provenance['signRule'], 'printed-loss-label-negative-absolute');
      }
    });
  }
  for (final key in values.keys) {
    final parts = key.toString().split(':');
    test('actual printed labels/periods/core values $key', () {
      final rows = parse(parts[0], parts[1]);
      expect(
        rows.map((r) => r['thstrm_amount']).toList(),
        (values[key] as List).map((n) => n.toString()).toList(),
      );
      expect(
        rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
        true,
      );
      for (final row in rows) {
        final p = row['html_provenance'] as Map;
        expect(
          body(parts[0], parts[1] == 'CFS' ? 'consolidated' : 'separate'),
          contains((p['printedLabel'] as String).split(' ').first),
        );
        expect(p['printedCurrentCells'], isNotEmpty);
      }
    });
  }
  test('Loss-only label has explicit negative-absolute rule and preserves the positive printed amount', () {
    final rows = parse('20260629000311', 'OFS');
    final loss = rows.singleWhere(
      (r) => (r['account_nm'] as String).contains('당기순손실'),
    );
    expect(loss['thstrm_amount'], '-1858500784');
    expect(
      loss['html_provenance']['printedAmountBeforeSignRule'],
      '1858500784',
    );
    expect(loss['html_provenance']['printedAmount'], '1858500784');
    expect(
      loss['html_provenance']['signRule'],
      'printed-loss-label-negative-absolute',
    );
  });
  test('Unknown whole-profit alias does not fall back to an EPS or equity movement row', () {
    final raw = body('20260629000311', 'separate');
    expect(
      () => parse(
        '20260629000311',
        'OFS',
        statement: raw.replaceAll('당기순손실', '미확인손익'),
      ),
      throwsFormatException,
    );
  });
  test(
    'Cronex exact OFS has seven whole-period core accounts and dated CE proof',
    () {
      const receipt = '20260709000504';
      final rows = parse(receipt, 'OFS');
      final amounts = rows.map((r) => r['thstrm_amount']).toList();
      for (final amount in [
        '14237907303',
        '12371090488',
        '1866816815',
        '5534042425',
        '641909126',
        '-2569130760',
        '461278058',
      ]) {
        expect(amounts.where((v) => v == amount), hasLength(1));
      }
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(row['currency'], 'KRW');
        final provenance = row['html_provenance'] as Map;
        expect(provenance['currentColumn'], 1);
        expect(provenance['currentColumnSpan'], 2);
        final proof = provenance['supportingPeriodEvidence'] as Map;
        expect(
          proof['mode'],
          'exact-cronex-undated-title-equity-period-corroboration',
        );
        expect(proof['periodStart'], '2025-01-01');
        expect(proof['periodEnd'], '2025-12-31');
        expect(proof['currentProfit'], '-2569130760');
        expect(proof['closingEquity'], '1866816815');
        expect(proof['source'], item(receipt)['urls']['separate']);
        expect(provenance['printedCurrentCells'], isNotEmpty);
      }
    },
  );
  for (final key in [
    '20260804000177:OFS',
    '20260630000259:CFS',
    '20260630000259:OFS',
  ]) {
    test(
      'Incomplete/contradictory actual period proof remains rejected $key',
      () {
        final p = key.split(':');
        expect(() => parse(p[0], p[1]), throwsFormatException);
      },
    );
  }
  for (final rec in [
    '20260617000188',
    '20260731000744',
    '20260708000510',
    '20260804000177',
    '20260728000338',
    '20260629000311',
    '20260407000793',
    '20260619000106',
  ]) {
    test(
      'actual receipt-bound CFS explicit-only body is source-proven non-applicability $rec',
      () async {
        final e = item(rec);
        final urls = e['urls'] as Map;
        final client = MockClient((request) async {
          if (request.url.path == '/dsaf001/main.do') {
            return http.Response(
              body(rec, 'shell'),
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          }
          final key = urls.keys.cast<String>().singleWhere(
            (k) => urls[k] == request.url.toString(),
          );
          return http.Response(
            body(rec, key),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        });
        await expectLater(
          fastFinancialHtmlFetcher(client).fetchAnnual(
            rec,
            reportName: e['reportName'],
            corpCode: e['corpCode'],
            companyName: e['name'],
            bsnsYear: DateTime.parse('${e['end']}T00:00:00Z').year,
            periodEnd: DateTime.parse('${e['end']}T00:00:00Z'),
            consolidated: true,
          ),
          throwsA(
            isA<PublicFinancialHtmlBasisNotApplicable>()
                .having((x) => x.sourceReceipt, 'exactreceipt', rec)
                .having(
                  (x) => x.statementSource.toString(),
                  'actualbody',
                  urls['consolidated'],
                ),
          ),
        );
      },
    );
  }
}
