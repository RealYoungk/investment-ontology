import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/same_receipt_audit_source.dart';

void main() {
  for (final profile in [
    (
      '20250318000507',
      'ofs',
      '(주)에피바이오텍',
      <String>[
        '2805954461',
        '1911007227',
        '894947234',
        '746739428',
        '-2965064683',
        '-1726142112',
        '-1802047582',
      ],
    ),
    (
      '20250321001749',
      'ofs',
      '(주)케이씨산업',
      <String>[
        '166709771805',
        '130201457637',
        '36508314168',
        '84322250768',
        '9453558272',
        '464212358',
        '1293932277',
      ],
    ),
    (
      '20250407004206',
      'ofs',
      '대주이엔티(주)',
      <String>[
        '83427501316',
        '41216530499',
        '42210970817',
        '85566276888',
        '8982253414',
        '2789517048',
        '11833007565',
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
      expect(rows.length, greaterThanOrEqualTo(7));
      for (final row in rows) {
        final proof = row['html_provenance']['supportingWholeEquityEvidence'];
        expect(proof['currentProfit'], profile.$4[5]);
        expect(proof['closingEquity'], profile.$4[2]);
      }
      if (r == '20250318000507') {
        final net = rows.singleWhere(
          (row) => row['account_nm'].toString().contains('당기순손실'),
        );
        expect(
          net['html_provenance']['printedAmountBeforeSignRule'],
          '1726142112',
        );
        expect(
          net['html_provenance']['signRule'],
          'printed-loss-label-negative-absolute',
        );
        expect(
          net['html_provenance']['supportingWholeEquityEvidence']['printedCurrentProfit'],
          '(1,726,142,112)',
        );
      }
      expect(
        () => SameReceiptAuditSource.verifiedWholeEquity(
          r,
          raw(basis),
          BigInt.parse(profile.$4[2]),
          BigInt.one,
        ),
        throwsFormatException,
      );

      expect(rows.take(7).map((r) => r['thstrm_amount']).toList(), profile.$4);
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
            profile.$4.first.replaceAllMapped(
              RegExp(r'(?<=\d)(?=(\d{3})+$)'),
              (_) => ',',
            ),
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
      expect(
        source.rows.take(7).map((r) => r['thstrm_amount']).toList(),
        profile.$4,
      );
      expect(requested, hasLength(4));
      expect(source.sourceReceipt, r);
      expect(source.statementSource, uri(basis));
    });
  }
  for (final r in ['20250318000507', '20250321001749']) {
    test('$r actual same-receipt CFS explicit nonpreparer', () async {
      final dir = 'test/fixtures/financial_html/three-audit-cfs-proof/$r';
      final p = jsonDecode(File('$dir/proof.json').readAsStringSync());
      final cfs = jsonDecode(File('$dir/cfs-proof.json').readAsStringSync());
      final sources = p['sources'] as List;
      final docs = <String, List<int>>{
        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$r': File(
          '$dir/shell.html',
        ).readAsBytesSync(),
        sources.singleWhere((x) => x['label'] == 'cover')['url']: File(
          '$dir/cover.html',
        ).readAsBytesSync(),
        cfs['url']: File('$dir/cfs.html').readAsBytesSync(),
      };
      expect(
        () =>
            fastFinancialHtmlFetcher(
              MockClient(
                (req) async => http.Response.bytes(
                  docs[req.url.toString()]!,
                  200,
                  request: req,
                ),
              ),
            ).fetchAnnual(
              r,
              reportName: '사업보고서 (2024.12)',
              corpCode: p['corpCode'],
              companyName: p['name'],
              bsnsYear: 2024,
              periodEnd: DateTime.utc(2024, 12, 31),
              consolidated: true,
            ),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>().having(
            (x) => x.evidence,
            'exact literal',
            r == '20250318000507'
                ? '당사는 연결재무제표 작성대상 법인이 아니므로 해당사항이 없습니다.'
                : '- 당사는 사업보고서 작성기준일 현재 해당사항 없습니다.',
          ),
        ),
      );
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
