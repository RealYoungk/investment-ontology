import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/primary_historical_issuer.dart';

void main() {
  final cases = jsonDecode(
    File('test/fixtures/financial_html/primary-historical-issuer/cases.json')
        .readAsStringSync(),
  ) as List;
  for (final c in cases) {
    final d =
        'test/fixtures/financial_html/primary-historical-issuer/${c['receipt']}';
    String raw(String l) => File('$d/$l.html').readAsStringSync();
    Uri url(String l) => Uri.parse(c['urls'][l]);
    List<Map<String, dynamic>> parse({
      String? shell,
      String? body,
      String? corp,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: raw('cover'),
      statementHtml: body ?? raw('ofs'),
      coverSource: url('cover'),
      statementSource: url('ofs'),
      receipt: c['receipt'],
      corpCode: corp ?? c['corp'],
      companyName: c['name'],
      periodStart: DateTime.utc(c['year']),
      periodEnd: DateTime.utc(c['year'], 12, 31),
      consolidated: false,
      primaryIssuerProof: PrimaryHistoricalIssuer(
        shell: shell ?? raw('shell'),
        shellSource: url('shell'),
      ),
    );
    if (c['corp'] != '01429220') {
      test('normal exact transport ${c['receipt']}', () async {
        final fetched = <String>[];
        final f = PublicFinancialHtmlFetcher(
          MockClient((r) async {
            fetched.add(r.url.toString());
            final label = [
              'shell',
              'cover',
              'ofs',
            ].where((l) => url(l) == r.url).toList();
            if (label.length != 1) throw StateError('Unbound URL');
            return http.Response.bytes(
              utf8.encode(raw(label.single)),
              200,
              request: r,
            );
          }),
        );
        final result = await f.fetchAnnual(
          c['receipt'],
          reportName: '사업보고서 (${c['year']}.12)',
          corpCode: c['corp'],
          companyName: c['name'],
          bsnsYear: c['year'],
          periodEnd: DateTime.utc(c['year'], 12, 31),
          consolidated: false,
        );
        expect(result.rows.length, greaterThanOrEqualTo(7));
        expect(fetched.length, 3);
      });
    }
    test('actual ${c['receipt']}', () {
      if (c['corp'] == '01429220') {
        expect(parse, throwsFormatException);
      } else {
        final rows = parse();
        expect(rows, hasLength(7));
        expect(
          rows.map((r) => [r["account_nm"], r["thstrm_amount"]]).toList(),
          c["expectedRows"],
        );
        expect(rows.every((r) => r["account_id"] == null), isTrue);
        expect(
          rows.every(
            (r) =>
                (r['html_provenance'] as Map)['primaryHistoricalIssuer'] !=
                null,
          ),
          isTrue,
        );
      }
    });
    test('wrong owner ${c['receipt']}', () {
      expect(() => parse(corp: '99999999'), throwsFormatException);
    });
    test('different printed primary issuer ${c['receipt']}', () {
      expect(
        () => parse(
          body: raw('ofs')
              .replaceAll(c['corp'] == '00321204' ? '관악산업' : '휴벡셀', '다른회사'),
        ),
        throwsFormatException,
      );
    });
  }
}
