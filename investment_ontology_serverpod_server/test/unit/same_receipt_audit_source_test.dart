import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/same_receipt_audit_source.dart';

void main() {
  for (final r in ['20240401000698', '20220315000038']) {
    final dir = 'test/fixtures/financial_html/same-receipt-audit/$r';
    final p = jsonDecode(File('$dir/proof.json').readAsStringSync()) as Map;
    final c = p['basis'] == 'CFS';
    final y = p['year'] as int;
    final name = c ? '메디안디노스틱' : '가이아코퍼레이션';
    String raw(String n) => File('$dir/$n.html').readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? cover,
      String? body,
      String? corp,
      String? receipt,
      Uri? source,
      bool? basis,
      DateTime? start,
      DateTime? end,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover ?? raw('cover'),
      statementHtml: body ?? raw('audit-statements'),
      coverSource: Uri.parse(p['cover']['url']),
      statementSource: source ?? Uri.parse(p['statement']['url']),
      receipt: receipt ?? r,
      corpCode: corp ?? p['corp'],
      companyName: name,
      periodStart: start ?? DateTime.utc(y),
      periodEnd: end ?? DateTime.utc(y, 12, 31),
      consolidated: basis ?? c,
    );
    test('$r actual raw audit core and independent provenance', () {
      final rows = parse();
      expect(rows.length, 8);
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(row['currency'], 'KRW');
        final meta = row['html_provenance'] as Map;
        expect(
          meta['sameReceiptAuditSource'],
          SameReceiptAuditSource.evidence(r),
        );
        expect(meta['source'], p['statement']['url']);
        expect(meta['periodEnd'], '$y-12-31');
      }
      final byName = {
        for (final row in rows)
          (row['account_nm'] as String).replaceAll(RegExp(r'\s+'), ''):
              row['thstrm_amount'],
      };
      expect(byName['자산총계'], c ? '21894642181' : '15522761887');
      expect(byName['부채총계'], c ? '1829620619' : '8783187118');
      expect(byName['자본총계'], c ? '20065021562' : '6739574769');
      expect(rows.where((e) => e['sj_div'] == 'CF'), isNotEmpty);
    });
    test('$r no inferred company receipt basis date or altered raw', () {
      for (final f in [
        () => parse(corp: '00000000'),
        () => parse(receipt: '20240101000000'),
        () => parse(basis: !c),
        () => parse(start: DateTime.utc(y - 1)),
        () => parse(end: DateTime.utc(y, 11, 30)),
        () => parse(body: '${raw('audit-statements')} '),
        () => parse(cover: '${raw('cover')} '),
        () => parse(
          source: Uri.parse(
            p['statement']['url'].replaceFirst('eleId=3', 'eleId=4'),
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
        () => SameReceiptAuditSource.statement(r, '${raw('audit-shell')} '),
        throwsFormatException,
      );
    });
    test(
      '$r actual official attachment transport preserves dcm and actual raw',
      () async {
        final files = <String, List<int>>{
          p['shell']['url']: File('$dir/shell.html').readAsBytesSync(),
          p['cover']['url']: File('$dir/cover.html').readAsBytesSync(),
          p['auditShell']['url']: File('$dir/audit-shell.html')
              .readAsBytesSync(),
          p['statement']['url']: File('$dir/audit-statements.html')
              .readAsBytesSync(),
        };
        final read = <String>[];
        final x =
            await PublicFinancialHtmlFetcher(
              MockClient((req) async {
                read.add(req.url.toString());
                final bytes = files[req.url.toString()];
                if (bytes == null) {
                  throw const FormatException('Unexpected source request');
                }
                return http.Response.bytes(bytes, 200, request: req);
              }),
            ).fetchAnnual(
              r,
              reportName: '사업보고서 ($y.12)',
              corpCode: p['corp'],
              companyName: name,
              bsnsYear: y,
              periodEnd: DateTime.utc(y, 12, 31),
              consolidated: c,
            );
        expect(x.sourceReceipt, r);
        expect(x.correctionReceipt, isNull);
        expect(x.statementSource.toString(), p['statement']['url']);
        expect(x.coverSource.toString(), p['cover']['url']);
        expect(x.rows.length, 8);
        expect(read, files.keys.toList());
      },
    );
  }
}
