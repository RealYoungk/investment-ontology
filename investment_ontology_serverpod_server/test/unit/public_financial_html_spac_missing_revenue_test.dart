import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/imgt_explicit_revenue_missing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

const root = 'test/fixtures/financial_html/spac-explicit-revenue-null';
Map<String, dynamic> proof(String r) =>
    jsonDecode(File('$root/$r/proof.json').readAsStringSync())
        as Map<String, dynamic>;
String raw(String r, String name) =>
    File('$root/$r/$name.html').readAsStringSync();
Uri uri(String r, String n) => Uri.parse(
  (proof(r)['sources'] as List).singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse(
  String r, {
  String? body,
  String? cover,
  String? overview,
  String? shell,
  String? corp,
  String? target,
  Uri? source,
  bool cfs = false,
  int year = 2022,
  bool declaration = true,
}) {
  final p = proof(r);
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover ?? raw(r, 'cover'),
    statementHtml: body ?? raw(r, 'ofs'),
    coverSource: uri(r, 'cover'),
    statementSource: source ?? uri(r, 'ofs'),
    receipt: target ?? r,
    corpCode: corp ?? p['corpCode'],
    companyName: p['companyName'],
    periodStart: DateTime.utc(year),
    periodEnd: DateTime.utc(year, 12, 31),
    consolidated: cfs,
    issuerProof: declaration
        ? PublicIssuerLegalName(
            shellHtml: shell ?? raw(r, 'shell'),
            shellSource: uri(r, 'shell'),
            overviewHtml: overview ?? raw(r, 'overview'),
            overviewSource: uri(r, 'overview'),
          )
        : null,
  );
}

void main() {
  for (final r in ['20230315000997', '20230308000311']) {
    final cp = r == '20230315000997';
    test('official exact bytes and six numeric plus null source $r', () {
      for (final s in proof(r)['sources'] as List) {
        expect(
          sha256
              .convert(File('$root/$r/${s['label']}.html').readAsBytesSync())
              .toString(),
          s['sha256'],
        );
      }
      final rows = parse(r);
      expect(rows.length, 7);
      expect(rows.where((v) => v['thstrm_amount'] != null).length, 6);
      final missing = rows.singleWhere((v) => v['thstrm_amount'] == null);
      expect(missing['html_provenance']['printedCurrentCells'], ['', '-']);
      expect(missing['account_id'], isNull);
      expect(
        ImgtExplicitRevenueMissing.rowsProof(
          rows,
          proof(r)['corpCode'],
          r,
          FsDiv.separate,
          uri(r, 'ofs'),
        ),
        isTrue,
      );
      expect(
        rows.map((v) => v['thstrm_amount']),
        containsAll(
          cp
              ? [
                  '12427859404',
                  '1408433174',
                  '11019426230',
                  '-55315450',
                  '57682077',
                  '-37153280',
                ]
              : [
                  '9895742901',
                  '903428428',
                  '8992314473',
                  '-65684830',
                  '44097065',
                  '11508090',
                ],
        ),
      );
    });
    test(
      'normal fetch verifies shell and independent declaration $r',
      () async {
        final calls = <String>[];
        final client = MockClient((q) async {
          calls.add(q.url.toString());
          final s = (proof(r)['sources'] as List).singleWhere(
            (s) => s['url'] == q.url.toString(),
          );
          return http.Response.bytes(
            File('$root/$r/${s['label']}.html').readAsBytesSync(),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        });
        final p = proof(r);
        final result = await fastFinancialHtmlFetcher(client).fetchAnnual(
          r,
          reportName: '사업보고서 (2022.12)',
          corpCode: p['corpCode'],
          companyName: p['companyName'],
          bsnsYear: 2022,
          periodEnd: DateTime.utc(2022, 12, 31),
          consolidated: false,
        );
        client.close();
        expect(result.rows.length, 7);
        expect(calls.toSet(), {for (final s in p['sources'] as List) s['url']});
      },
    );
    for (final mutation in [
      'corp',
      'receipt',
      'year',
      'basis',
      'source',
      'no-declaration',
      'subsidiary',
      'ambiguous-declaration',
      'wrong-declared-name',
      'USD',
      'term',
      'end-date',
      'blank-revenue',
      'zero-revenue',
      'ambiguous-money',
      'CE-profit',
      'CE-equity',
      'CE-current-date',
    ]) {
      test('reject $mutation $r', () {
        var body = raw(r, 'ofs'),
            overview = raw(r, 'overview'),
            cover = raw(r, 'cover');
        String changed(String from, String to) {
          expect(body, contains(from));
          return body.replaceAll(from, to);
        }

        switch (mutation) {
          case 'subsidiary':
            overview = overview.replaceAll('당사의 명칭은', '자회사의 명칭은');
          case 'ambiguous-declaration':
            overview = overview.replaceAll(
              "'입니다.",
              "'입니다. 당사의 명칭은 '다른주식회사'입니다.",
            );
          case 'wrong-declared-name':
            overview = overview.replaceAll(
              cp ? '유진기업인수목적8호 주식회사' : '교보10호기업인수목적 주식회사',
              '다른주식회사',
            );
          case 'USD':
            body = changed('(단위 : 원)', '(단위 : USD)');
          case 'term':
            body = changed(cp ? '제 2(당)' : '제 3(당)', cp ? '제 3(당)' : '제 4(당)');
          case 'end-date':
            body = changed('2022년 12월 31일', '2021년 12월 31일');
          case 'blank-revenue':
          case 'zero-revenue':
            final label = cp ? 'I. 영업수익' : '영업수익';
            final pattern = RegExp(
              '(${RegExp.escape(label)}'
              r'</TD>.*?<TD[^>]*>.*?</TD>.*?<TD[^>]*>.*?</TD>.*?<TD[^>]*>)-',
              dotAll: true,
            );
            final before = body;
            body = body.replaceFirstMapped(
              pattern,
              (m) => '${m[1]}${mutation == 'zero-revenue' ? '0' : ''}',
            );
            expect(body, isNot(before));
          case 'ambiguous-money':
            body = changed(
              cp ? '12,427,859,404' : '9,895,742,901',
              cp ? '12,427,859,404 1' : '9,895,742,901 1',
            );
          case 'CE-profit':
            final table =
                RegExp(
                      r'<TABLE\b[^>]*>.*?</TABLE>',
                      caseSensitive: false,
                      dotAll: true,
                    )
                    .allMatches(body)
                    .singleWhere((m) => m.group(0)!.contains('당기초'))
                    .group(0)!;
            final value = cp ? '57,682,077' : '44,097,065';
            final altered = table.replaceAll(
              value,
              cp ? '57,682,078' : '44,097,066',
            );
            expect(altered, isNot(table));
            body = body.replaceFirst(table, altered);
          case 'CE-equity':
            final value = cp ? '11,019,426,230' : '8,992,314,473';
            final at = body.lastIndexOf(value);
            body =
                body.substring(0, at) +
                (cp ? '11,019,426,231' : '8,992,314,474') +
                body.substring(at + value.length);
          case 'CE-current-date':
            body = changed(
              cp ? '2022.12.31(당기말)' : '2022년 12월 31일(당기말)',
              cp ? '2021.12.31(당기말)' : '2021년 12월 31일(당기말)',
            );
        }
        expect(
          () => parse(
            r,
            body: body,
            overview: overview,
            cover: cover,
            corp: mutation == 'corp' ? '00000001' : null,
            target: mutation == 'receipt' ? '20230315000998' : null,
            year: mutation == 'year' ? 2021 : 2022,
            cfs: mutation == 'basis',
            declaration: mutation != 'no-declaration',
            source: mutation == 'source'
                ? uri(r, 'ofs').replace(
                    queryParameters: {
                      ...uri(r, 'ofs').queryParameters,
                      'offset': '1',
                    },
                  )
                : null,
          ),
          throwsFormatException,
        );
      });
    }
  }
}
