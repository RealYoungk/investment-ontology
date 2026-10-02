import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/innovex-crfood';
String raw(String receipt, String name) =>
    File('$root/$receipt/$name.html').readAsStringSync();
Map proof(String receipt) =>
    jsonDecode(File('$root/$receipt/proof.json').readAsStringSync()) as Map;
Uri uri(String receipt, String name) => Uri.parse(
  (proof(receipt)['sources'] as List).singleWhere(
    (s) => s['label'] == name,
  )['url'],
);
List<Map<String, dynamic>> parse({
  String receipt = '20250320001369',
  String? body,
  String? corp,
  bool cfs = false,
  Uri? source,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw(receipt, 'cover'),
  statementHtml: body ?? raw(receipt, 'ofs'),
  coverSource: uri(receipt, 'cover'),
  statementSource: source ?? uri(receipt, 'ofs'),
  receipt: receipt,
  corpCode: corp ?? proof(receipt)['corpCode'],
  companyName: receipt == '20250320001369' ? '이노벡스' : '씨알푸드',
  periodStart: DateTime.utc(2024),
  periodEnd: DateTime.utc(2024, 12, 31),
  consolidated: cfs,
);
String ce(String from, String to) {
  final s = raw('20250320001369', 'ofs');
  final a = s.indexOf('다. 자본변동표');
  final z = s.indexOf('라. 현금흐름표', a);
  expect(a, greaterThan(0));
  expect(z, greaterThan(a));
  return s.substring(0, a) +
      s.substring(a, z).replaceAll(from, to) +
      s.substring(z);
}

void main() {
  for (final receipt in ['20250320001369', '20250326000875']) {
    test('actual official source SHA and whole seven $receipt', () {
      for (final name in ['cover', 'ofs']) {
        expect(
          sha256
              .convert(File('$root/$receipt/$name.html').readAsBytesSync())
              .toString(),
          (proof(receipt)['sources'] as List).singleWhere(
            (s) => s['label'] == name,
          )['sha256'],
        );
      }
      final rows = parse(receipt: receipt);
      expect(
        rows.take(7).map((r) => r['thstrm_amount']).toList(),
        receipt == '20250320001369'
            ? [
                '14915658250',
                '17566270041',
                '-2650611791',
                '6241633266',
                '-2661004028',
                '-2687128733',
                '-183224746',
              ]
            : [
                '14747358125',
                '14128613307',
                '618744818',
                '17844149697',
                '-621835340',
                '-1116094946',
                '1145042041',
              ],
      );
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(row['currency'], 'KRW');
        final p = row['html_provenance'] as Map;
        expect(p['source'], uri(receipt, 'ofs').toString());
        expect(p['printedLabel'], row['account_nm']);
        expect(p['periodStart'], '2024-01-01');
        expect(p['periodEnd'], '2024-12-31');
      }
      if (receipt == '20250320001369') {
        final e =
            (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
                as Map;
        expect(e['mode'], 'exact-innovex-ofs-whole-equity-corroboration');
        expect(e['wholeTotalColumn'], 6);
        expect(e['closingEquity'], '-2650611791');
        expect(e['currentProfit'], '-2687128733');
      }
    });
  }
  for (final mutation in [
    ('duplicate separator span', "colspan='7'", "colspan='7' colspan='6'"),
    ('wrong separator span', "colspan='7'", "colspan='8'"),
    ('numeric separator', '총포괄손익 :', '총포괄손익 : 123'),
    ('whole missing', '합계', ''),
    ('subtotal', '합계', '지배기업소유주지분'),
    ('NCI', '기타자본', '비지배지분'),
    ('header span', "colspan='6'", "colspan='5'"),
    ('current end', '2024.12.31', '2023.12.31'),
    ('current term', '제 12 기', '제 11 기'),
    ('unit', '단위 : 원', '단위 : 천원'),
    ('whole equity', '(2,650,611,791)', '(2,650,611,792)'),
    ('whole profit', '(2,687,128,733)', '(2,687,128,734)'),
    ('Roman other', 'Ⅲ. 2024.12.31', 'Ⅱ. 2024.12.31'),
  ]) {
    test(
      'reject CE ${mutation.$1}',
      () => expect(
        () => parse(body: ce(mutation.$2, mutation.$3)),
        throwsFormatException,
      ),
    );
  }
  test(
    'wrong corporation rejects',
    () => expect(() => parse(corp: '00000000'), throwsFormatException),
  );
  test(
    'CFS reuse rejects',
    () => expect(() => parse(cfs: true), throwsFormatException),
  );
  test(
    'wrong source node rejects',
    () => expect(
      () => parse(
        source: uri('20250320001369', 'ofs').replace(
          queryParameters: {
            ...uri('20250320001369', 'ofs').queryParameters,
            'eleId': '22',
          },
        ),
      ),
      throwsFormatException,
    ),
  );
}
