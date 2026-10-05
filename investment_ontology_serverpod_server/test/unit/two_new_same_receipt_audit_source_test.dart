import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/same_receipt_audit_source.dart';

void main() {
  for (final profile in [
    (
      '20260309001820',
      'ofs',
      '(주)큐라켐',
      <String>[
        '14887067433',
        '8239503612',
        '6647563821',
        '7437486538',
        '1736340108',
        '1346087986',
        '359652695',
      ],
    ),
    (
      '20240321000933',
      'cfs',
      '(주)마이크로엔엑스',
      <String>[
        '25242555810',
        '14989803947',
        '10252751863',
        '8394493843',
        '569252425',
        '144953125',
        '-527661963',
      ],
    ),
  ]) {
    final r = profile.$1,
        basis = profile.$2,
        cfs = basis == 'cfs',
        dir = 'assets/financial_source_cache/$r-$basis-audit';
    final p = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    String raw(String label) => File('$dir/$label.html').readAsStringSync();
    Uri uri(String label) => Uri.parse(
      (p['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    List<Map<String, dynamic>> parse({
      String? body,
      String? cover,
      String? corp,
      bool? consolidated,
      Uri? source,
      DateTime? end,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover ?? raw('cover'),
      statementHtml: body ?? raw(basis),
      coverSource: uri('cover'),
      statementSource: source ?? uri(basis),
      receipt: r,
      corpCode: corp ?? p['corpCode'],
      companyName: profile.$3,
      periodStart: DateTime.utc(p['year']),
      periodEnd: end ?? DateTime.utc(p['year'], 12, 31),
      consolidated: consolidated ?? cfs,
    );
    test('$r actual whole seven values and raw audit period source', () {
      final rows = parse();
      expect(rows, hasLength(7));
      expect(rows.map((r) => r['thstrm_amount']).toList(), profile.$4);
      for (final row in rows) {
        expect(row['currency'], 'KRW');
        expect(row['account_id'], isNull);
        expect(row['html_provenance']['source'], uri(basis).toString());
        expect(
          row['html_provenance']['sameReceiptAuditSource'],
          SameReceiptAuditSource.evidence(r),
        );
        expect(row['html_provenance']['periodStart'], '${p['year']}-01-01');
        expect(row['html_provenance']['periodEnd'], '${p['year']}-12-31');
      }
    });
    test('$r strict company basis period raw and document failures', () {
      for (final f in [
        () => parse(corp: '00000000'),
        () => parse(consolidated: !cfs),
        () => parse(end: DateTime.utc(p['year'] - 1, 12, 31)),
        () => parse(body: '${raw(basis)} '),
        () => parse(cover: '${raw('cover')} '),
        () => parse(
          body: raw(basis).replaceFirst(
            r == '20260309001820' ? '14,887,067,433' : '25,242,555,810',
            '1',
          ),
        ),
        () => parse(
          source: uri(basis).replace(
            query: uri(basis).query.replaceFirst('eleId=3', 'eleId=999'),
          ),
        ),
      ]) {
        expect(f, throwsFormatException);
      }
      expect(
        () => SameReceiptAuditSource.auditShell(r, '${raw('shell')} '),
        throwsFormatException,
      );
      expect(
        () => SameReceiptAuditSource.statement(r, '${raw('auditShell')} '),
        throwsFormatException,
      );
    });
    test('$r actual same-receipt four raw transport', () async {
      final requested = <String>[];
      final docs = {
        for (final s in p['sources'])
          s['url']: File('$dir/${s['file']}').readAsBytesSync(),
      };
      final source =
          await fastFinancialHtmlFetcher(
            MockClient((req) async {
              requested.add(req.url.toString());
              final bytes = docs[req.url.toString()];
              if (bytes == null) throw const FormatException('Unbound source');
              return http.Response.bytes(bytes, 200, request: req);
            }),
          ).fetchAnnual(
            r,
            reportName: '사업보고서 (${p['year']}.12)',
            corpCode: p['corpCode'],
            companyName: profile.$3,
            bsnsYear: p['year'],
            periodEnd: DateTime.utc(p['year'], 12, 31),
            consolidated: cfs,
          );
      expect(source.rows.map((r) => r['thstrm_amount']).toList(), profile.$4);
      expect(requested, hasLength(4));
      expect(source.sourceReceipt, r);
      expect(source.statementSource, uri(basis));
    });
  }
  test('Logismon remains unsupported and MicroNX OFS excluded', () {
    expect(
      SameReceiptAuditSource.eligible(
        receipt: '20250318000780',
        corpCode: '01060735',
        consolidated: false,
        start: DateTime.utc(2024),
        end: DateTime.utc(2024, 12, 31),
      ),
      false,
    );
    expect(
      SameReceiptAuditSource.eligible(
        receipt: '20240321000933',
        corpCode: '01206717',
        consolidated: false,
        start: DateTime.utc(2023),
        end: DateTime.utc(2023, 12, 31),
      ),
      false,
    );
  });
}
