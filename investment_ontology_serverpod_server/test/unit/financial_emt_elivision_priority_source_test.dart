import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const root = 'test/fixtures/financial_html/emt-elivision-priority';
void main() {
  for (final (receipt, corp, name, basis) in [
    ('20250409000365', '00925967', '(주)이엠티', 'ofs'),
    ('20250407003814', '01119651', '(주)엘리비젼', 'cfs'),
  ]) {
    test(
      'exact official source supports verified queue basis $receipt:$basis',
      () async {
        final dir = '$root/$receipt';
        final proof = jsonDecode(File('$dir/proof.json').readAsStringSync());
        final sources = proof['sources'] as List;
        for (final s in sources) {
          expect(
            sha256
                .convert(File('$dir/${s['label']}.html').readAsBytesSync())
                .toString(),
            s['sha256'],
          );
        }
        final requested = <String>[];
        final client = MockClient((request) async {
          final source = sources.singleWhere(
            (s) => s['url'] == request.url.toString(),
          );
          requested.add(source['label']);
          return http.Response.bytes(
            File('$dir/${source['label']}.html').readAsBytesSync(),
            200,
            request: request,
          );
        });
        final fetch = PublicFinancialHtmlFetcher(client).fetchAnnual(
          receipt,
          reportName: '사업보고서 (2024.12)',
          corpCode: corp,
          companyName: name,
          bsnsYear: 2024,
          periodEnd: DateTime.utc(2024, 12, 31),
          consolidated: basis == 'cfs',
        );
        if (basis == 'cfs') {
          await expectLater(
            fetch,
            throwsA(
              isA<PublicFinancialHtmlBasisNotApplicable>()
                  .having((e) => e.sourceReceipt, 'receipt', receipt)
                  .having(
                    (e) => e.statementSource.toString(),
                    'exactCFS',
                    sources.singleWhere((s) => s['label'] == 'cfs')['url'],
                  )
                  .having((e) => e.evidence, 'literal', '해당 사항 없음'),
            ),
          );
        } else {
          final result = await fetch;
          expect(result.rows, hasLength(8));
          expect(result.rows.map((r) => r['thstrm_amount']).toList(), [
            '70673967537',
            '71940155852',
            '-1266188315',
            '9847033191',
            '-960908575',
            '-1947551121',
            '-30428497587',
            '-13406917706',
          ]);
          for (final row in result.rows) {
            expect(row['account_id'], isNull);
            expect(row['currency'], 'KRW');
            final p = row['html_provenance'] as Map;
            expect(p['source'], result.statementSource.toString());
            expect(p['basis'], 'OFS');
            expect(p['periodStart'], '2024-01-01');
            expect(p['periodEnd'], '2024-12-31');
            expect(p['printedLabel'], row['account_nm']);
            expect(p['supportingPeriodEvidence']['currentTerm'], '15');
          }
        }
        expect(requested, ['shell', 'cover', basis]);
      },
    );
  }
}
