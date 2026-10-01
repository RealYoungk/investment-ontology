import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

List<Map<String, dynamic>> parseTilde({
  String? statement,
  String? cover,
  String corp = '00832700',
  String receipt = '20260318000509',
  String name = '에이펙스인텍(주)',
  bool cfs = false,
  Uri? source,
  DateTime? start,
  DateTime? end,
}) {
  const base = 'test/fixtures/financial_html/tilde-annual';
  final m = jsonDecode(File('$base/metadata.json').readAsStringSync());
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover ?? File('$base/cover.html').readAsStringSync(),
    statementHtml: statement ?? File('$base/OFS.html').readAsStringSync(),
    coverSource: Uri.parse(m['coverUrl']),
    statementSource: source ?? Uri.parse(m['OFSSource']),
    receipt: receipt,
    corpCode: corp,
    companyName: name,
    periodStart: start ?? DateTime.utc(2025),
    periodEnd: end ?? DateTime.utc(2025, 12, 31),
    consolidated: cfs,
  );
}

void main() {
  test('actual tilde annual whole8 rows retain labels, current values, units and source dates', () {
    final r = parseTilde();
    expect(r.length, 8);
    final amounts = {
      for (final row in r) row['account_nm']: row['thstrm_amount'],
    };
    expect(
      amounts.values,
      containsAll([
        '31486896644',
        '22767608491',
        '8719288153',
        '20015837872',
        '-522428137',
        '-441935211',
        '-174395793',
      ]),
    );
    expect(
      r.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
      isTrue,
    );
    expect(
      r.every(
        (r) =>
            (r['html_provenance'] as Map)['periodStart'] == '2025-01-01' &&
            (r['html_provenance'] as Map)['periodEnd'] == '2025-12-31',
      ),
      isTrue,
    );
  });
  for (final kind in [
    'quarter',
    'cumulative',
    'partialdate',
    'reversed',
    'balance',
    'unit',
    'receipt',
    'company',
    'source',
    'basis',
    'fromMissingUntil',
  ]) {
    test('reject tilde $kind', () {
      var s = File('test/fixtures/financial_html/tilde-annual/OFS.html')
          .readAsStringSync();
      if (kind == 'quarter') s = s.replaceAll('2025년 01월 01일', '2025년 10월 01일');
      if (kind == 'cumulative') {
        s = s.replaceAll('2025년 12월 31일', '2025년 06월 30일');
      }
      if (kind == 'partialdate') s = s.replaceAll('2025년 01월 01일', '01월 01일');
      if (kind == 'reversed') {
        s = s.replaceAll('2025년 01월 01일', '2026년 01월 01일');
      }
      if (kind == 'balance') {
        s = s.replaceAll('31,486,896,644', '31,486,896,645');
      }
      if (kind == 'unit') s = s.replaceAll('단위: 원', '단위: USD');
      if (kind == 'fromMissingUntil') s = s.replaceAll('~', '부터');
      expect(
        () => parseTilde(
          statement: s,
          receipt: kind == 'receipt' ? '20260318000510' : '20260318000509',
          name: kind == 'company' ? '다른회사' : '에이펙스인텍(주)',
          cfs: kind == 'basis',
          source: kind == 'source'
              ? Uri.parse('https://other.example/report')
              : null,
        ),
        throwsFormatException,
      );
    });
  }
}
