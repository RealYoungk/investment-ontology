import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

void main() {
  const dir = 'test/fixtures/financial_html';
  final ledger = jsonDecode(
    File('$dir/financial-html-source-ledger.json').readAsStringSync(),
  ) as List;
  String html(String part) =>
      File('$dir/20240701000635-$part.html').readAsStringSync();
  Uri source(String part) => Uri.parse(
    (ledger.firstWhere((r) => r['basis'] == part) as Map)['url'] as String,
  );
  List<Map<String, dynamic>> parse({
    bool cfs = true,
    String? statements,
    Uri? uri,
    String name = '아하',
    String? cover,
    DateTime? end,
  }) => PublicFinancialHtml.parse(
    coverHtml: cover ?? html('cover'),
    statementHtml: statements ?? html(cfs ? 'cfs' : 'ofs'),
    coverSource: source('cover'),
    statementSource: uri ?? source(cfs ? 'cfs' : 'ofs'),
    receipt: '20240701000635',
    corpCode: '00677334',
    companyName: name,
    periodStart: DateTime.utc(2023, 4, 1),
    periodEnd: end ?? DateTime.utc(2024, 3, 31),
    consolidated: cfs,
  );
  for (final cfs in [true, false]) {
    test(
      'actual ${cfs ? 'CFS' : 'OFS'} seven core rows retain printed labels, missing capex and null IDs',
      () {
        final rows = parse(cfs: cfs);
        expect(rows.length, 7);
        final expected = cfs
            ? [
                '101131149053',
                '62690969504',
                '38440179549',
                '78305621279',
                '3006702112',
                '1327808656',
                '-7911425271',
              ]
            : [
                '101309722186',
                '62043404550',
                '39266317636',
                '77432069841',
                '3025665889',
                '1934425181',
                '-8609316999',
              ];
        expect(rows.map((r) => r['thstrm_amount']).toList(), expected);
        expect(
          rows.every((r) => r['thstrm_nm'] == '2023-04-01~2024-03-31'),
          isTrue,
        );
        expect(rows.every((r) => !r.containsKey('frmtrm_amount')), isTrue);
        expect(
          rows.every(
            (r) => (r['html_provenance'] as Map)['columnLabel'] == '제26기',
          ),
          isTrue,
        );

        expect(rows.every((r) => r['account_id'] == null), isTrue);
        expect(
          rows.where((r) => r['account_nm'] == '당기순이익').single['thstrm_amount'],
          cfs ? '1327808656' : '1934425181',
        );
        expect(
          rows.where((r) => r['sj_div'] == 'CF').single['thstrm_amount'],
          cfs ? '-7911425271' : '-8609316999',
        );
        expect(rows.any((r) => r['account_nm'] == '유형자산의 취득'), isFalse);
        final converted = FinancialRows.toFacts(
          rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          fsDiv: cfs ? FsDiv.consolidated : FsDiv.separate,
          sourceId: 1,
        );
        expect(converted.facts.length, 7);
        expect(converted.invalidAmounts, 0);
        expect(converted.facts.every((f) => f.accountId == null), isTrue);
      },
    );
  }
  test('receipt/company/basis/unit/identity mismatches reject', () {
    expect(
      () => parse(
        uri: source('cfs').replace(
          queryParameters: {
            ...source('cfs').queryParameters,
            'rcpNo': '20240702000525',
          },
        ),
      ),
      throwsFormatException,
    );
    expect(() => parse(name: '다른기업'), throwsFormatException);
    expect(() => parse(statements: html('ofs')), throwsFormatException);
    expect(
      () => parse(statements: html('cfs').replaceAll('단위 : 원', '단위 : 천원')),
      throwsFormatException,
    );
    expect(
      () => parse(
        statements: html('cfs')
            .replaceAll('101,131,149,053', '101,131,149,054'),
      ),
      throwsFormatException,
    );
  });
  test('wrong cover and current title periods reject', () {
    expect(() => parse(end: DateTime.utc(2024, 4, 30)), throwsFormatException);
    expect(
      () => parse(
        cover: html('cover').replaceAll('2024년 03월 31일', '2024년 02월 29일'),
      ),
      throwsFormatException,
    );
    expect(
      () => parse(
        statements: html('cfs')
            .replaceAll('2023년 04월 01일부터', '2023년 05월 01일부터'),
      ),
      throwsFormatException,
    );
  });
  test('different document binding rejects', () {
    expect(
      () => parse(
        uri: source('cfs').replace(
          queryParameters: {
            ...source('cfs').queryParameters,
            'dcmNo': '10011159',
          },
        ),
      ),
      throwsFormatException,
    );
  });
  test('duplicate current header and conflicting printed core rows reject', () {
    final original = html('cfs');
    final table =
        RegExp(
              r'<TABLE\b[^>]*>(.*?)</TABLE>',
              caseSensitive: false,
              dotAll: true,
            )
            .allMatches(original)
            .firstWhere((m) => m.group(0)!.contains('101,131,149,053'));
    final block = table.group(0)!;
    final header = RegExp(
      r'<TR\b[^>]*>(.*?)</TR>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(block)!.group(0)!;
    expect(
      () => parse(
        statements: original.replaceFirst(
          header,
          header.replaceAll('제25기', '제26기'),
        ),
      ),
      throwsFormatException,
    );
    final income =
        RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
            .allMatches(original)
            .firstWhere((m) => m.group(0)!.contains('78,305,621,279'))
            .group(0)!;
    expect(
      () => parse(
        statements: original.replaceFirst(
          income,
          '$income${income.replaceAll('78,305,621,279', '78,305,621,280')}',
        ),
      ),
      throwsFormatException,
    );
  });
  test('malformed current amount rejects while printed historical typo remains unused', () {
    expect(html('ofs'), contains('4,539,002,02'));
    expect(
      () => parse(
        cfs: false,
        statements: html('ofs').replaceAll('8,609,316,999', '8,609,316,99'),
      ),
      throwsFormatException,
    );
    expect(parse(cfs: false).last['thstrm_amount'], '-8609316999');
  });
  test(
    'spanning or extra numeric cells cannot silently shift the current amount',
    () {
      final original = html('cfs');
      final row =
          RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
              .allMatches(original)
              .firstWhere((m) => m.group(0)!.contains('78,305,621,279'))
              .group(0)!;
      expect(
        () => parse(
          statements: original.replaceFirst(
            row,
            row.replaceFirst('<TD', '<TD colspan="2"'),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => parse(
          statements: original.replaceFirst(
            row,
            row.replaceFirst('</TR>', '<TD>99</TD></TR>'),
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test('explicit ports, repeated source parameters and unknown DTD reject', () {
    final url = source('cfs');
    expect(() => parse(uri: url.replace(port: 8443)), throwsFormatException);
    for (final key in ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd']) {
      expect(
        () => parse(uri: Uri.parse('$url&$key=${url.queryParameters[key]}')),
        throwsFormatException,
      );
    }
    expect(
      () => parse(
        uri: url.replace(
          queryParameters: {...url.queryParameters, 'dtd': 'unknown.xsd'},
        ),
      ),
      throwsFormatException,
    );
  });
}
