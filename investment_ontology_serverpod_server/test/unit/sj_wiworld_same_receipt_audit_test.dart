import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/same_receipt_audit_source.dart';

void main() {
  for (final receipt in ['20260326000605', '20240320000531']) {
    final dir = 'assets/financial_source_cache/$receipt-ofs-audit';
    final m = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final docs = {for (final v in m['sources']) v['label']: v};
    final y = m['year'] as int;
    List<Map<String, dynamic>> parse({
      String? body,
      String? corp,
      String? r,
      bool cfs = false,
      DateTime? end,
      Uri? source,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: File('$dir/cover.html').readAsStringSync(),
      statementHtml: body ?? File('$dir/ofs.html').readAsStringSync(),
      coverSource: Uri.parse(docs['cover']['url']),
      statementSource: source ?? Uri.parse(docs['ofs']['url']),
      receipt: r ?? receipt,
      corpCode: corp ?? m['corpCode'],
      companyName: receipt == '20260326000605' ? '주식회사 에스제이켐' : '위월드(주)',
      periodStart: DateTime.utc(y),
      periodEnd: end ?? DateTime.utc(y, 12, 31),
      consolidated: cfs,
    );
    test(
      '$receipt actual CFS section2 strict absence preserves source identity',
      () async {
        final noneDir =
            'test/fixtures/financial_html/sj-wiworld-cfs-none/$receipt';
        final proof = jsonDecode(
          File('$noneDir/proof.json').readAsStringSync(),
        );
        final files = <String, List<int>>{
          docs['shell']['url']: File('$dir/shell.html').readAsBytesSync(),
          docs['cover']['url']: File('$dir/cover.html').readAsBytesSync(),
          proof['url']: File('$noneDir/cfs.html').readAsBytesSync(),
        };
        final reader = fastFinancialHtmlFetcher(
          MockClient((r) async {
            final bytes = files[r.url.toString()];
            if (bytes == null) throw const FormatException('Unbound fixture');
            return http.Response.bytes(bytes, 200, request: r);
          }),
        );
        await expectLater(
          reader.fetchAnnual(
            receipt,
            reportName: '사업보고서 ($y.12)',
            corpCode: m['corpCode'],
            companyName: receipt == '20260326000605' ? '주식회사 에스제이켐' : '위월드(주)',
            bsnsYear: y,
            periodEnd: DateTime.utc(y, 12, 31),
            consolidated: true,
          ),
          throwsA(
            isA<PublicFinancialHtmlBasisNotApplicable>()
                .having((v) => v.sourceReceipt, 'receipt', receipt)
                .having(
                  (v) => v.statementSource.toString(),
                  'URI',
                  proof['url'],
                ),
          ),
        );
      },
    );
    test(
      '$receipt actual independently balanced audit whole current values',
      () {
        final rows = parse();
        expect(rows.length, inInclusiveRange(7, 8));
        final amounts = rows.map((v) => v['thstrm_amount']).toSet();
        expect(
          amounts,
          containsAll(
            receipt == '20260326000605'
                ? [
                    '14364717743',
                    '13446031197',
                    '918686546',
                    '10322963927',
                    '1001880626',
                    '-1679380933',
                    '258924245',
                  ]
                : [
                    '9701598769',
                    '1390939395',
                    '8310659374',
                    '4621610123',
                    '261688928',
                    '283993874',
                    '816238978',
                  ],
          ),
        );
        for (final row in rows) {
          expect(row['account_id'], isNull);
          expect(row['currency'], 'KRW');
          expect(
            row['html_provenance']['sameReceiptAuditSource'],
            SameReceiptAuditSource.evidence(receipt),
          );
        }
      },
    );
    test(
      '$receipt rejects altered bytes money dates basis corp receipt and coords',
      () {
        for (final f in [
          () => parse(body: '${File('$dir/ofs.html').readAsStringSync()} '),
          () => parse(corp: '00000000'),
          () => parse(r: '20240101000000'),
          () => parse(cfs: true),
          () => parse(end: DateTime.utc(y - 1, 12, 31)),
          () => parse(
            source: Uri.parse(
              docs['ofs']['url'].replaceFirst('eleId=3', 'eleId=4'),
            ),
          ),
        ]) {
          expect(f, throwsFormatException);
        }
        expect(
          () => SameReceiptAuditSource.auditShell(
            receipt,
            '${File('$dir/shell.html').readAsStringSync()} ',
          ),
          throwsFormatException,
        );
        expect(
          () => SameReceiptAuditSource.statement(
            receipt,
            '${File('$dir/auditShell.html').readAsStringSync()} ',
          ),
          throwsFormatException,
        );
      },
    );
  }
}
