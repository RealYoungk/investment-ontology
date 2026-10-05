import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const root = 'test/fixtures/financial_html/txr-blank-header';
String fixture(String label) => File('$root/$label.html').readAsStringSync();
Uri source(String label) => Uri.parse(
  ((jsonDecode(File('$root/sources.json').readAsStringSync())['sources'])
          as List)
      .singleWhere((x) => x['label'] == label)['url'],
);
Future<PublicFinancialHtmlSource> fetch({
  bool cfs = false,
  String? body,
  String? cover,
}) =>
    fastFinancialHtmlFetcher(
      MockClient((r) async {
        final label = r.url.path == '/dsaf001/main.do'
            ? 'shell'
            : r.url.queryParameters['eleId'] == '3'
            ? 'cover'
            : cfs
            ? 'cfs'
            : 'ofs';
        return http.Response.bytes(
          utf8.encode(
            label == 'cover'
                ? cover ?? fixture(label)
                : label == 'shell'
                ? fixture(label)
                : body ?? fixture(label),
          ),
          200,
          request: r,
        );
      }),
    ).fetchAnnual(
      '20250526000504',
      reportName: '사업보고서 (2024.12)',
      corpCode: '01458161',
      companyName: '(주)티엑스알로보틱스',
      bsnsYear: 2024,
      periodEnd: DateTime.utc(2024, 12, 31),
      consolidated: cfs,
    );
List<Map<String, dynamic>> parse({
  String? body,
  String receipt = '20250526000504',
  bool cfs = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: fixture('cover'),
  statementHtml: body ?? fixture('ofs'),
  coverSource: source('cover'),
  statementSource: source('ofs'),
  receipt: receipt,
  corpCode: '01458161',
  companyName: '(주)티엑스알로보틱스',
  periodStart: DateTime.utc(2024),
  periodEnd: DateTime.utc(2024, 12, 31),
  consolidated: cfs,
);
void main() {
  test(
    'actual TXR OFS current blank header preserves seven printed source values',
    () async {
      final x = await fetch();
      final proof = jsonDecode(
        File('$root/reviewed-evidence.json').readAsStringSync(),
      );
      for (final expected in proof['ofs']['rows']) {
        final row = x.rows.singleWhere(
          (r) => r['account_nm'] == expected['printedLabel'],
        );
        expect(row['thstrm_amount'], expected['observedAmountWon']);
        expect(row['account_id'], isNull);
        expect(row['html_provenance']['currentColumn'], 1);
      }
      expect(x.sourceReceipt, '20250526000504');
      expect(x.statementSource, source('ofs'));
    },
  );
  test(
    'actual TXR CFS pure literal emits source-bound not-applicable proof',
    () async {
      await expectLater(
        fetch(cfs: true),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((x) => x.sourceReceipt, 'receipt', '20250526000504')
              .having((x) => x.statementSource, 'source', source('cfs'))
              .having((x) => x.evidence, 'literal', '- 해당사항이 없습니다.'),
        ),
      );
    },
  );
  test('CFS literal with numeric table is not absence', () async {
    await expectLater(
      fetch(
        cfs: true,
        body: fixture('cfs').replaceFirst(
          '</BODY>',
          '<TABLE><TR><TD>100</TD></TR></TABLE></BODY>',
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (x) => x is PublicFinancialHtmlBasisNotApplicable,
          'typed absence',
          false,
        ),
      ),
    );
  });
  test('CFS literal with conditional continuation is not absence', () async {
    await expectLater(
      fetch(
        cfs: true,
        body: fixture('cfs')
            .replaceFirst('해당사항이 없습니다.', '해당사항이 없습니다. 단, 종속회사를 취득하였습니다.'),
      ),
      throwsA(
        isA<FormatException>().having(
          (x) => x is PublicFinancialHtmlBasisNotApplicable,
          'typed absence',
          false,
        ),
      ),
    );
  });
  test('wrong cover period cannot emit absence', () async {
    await expectLater(
      fetch(cfs: true, cover: fixture('cover').replaceAll('2024년', '2023년')),
      throwsFormatException,
    );
  });
  test('wrong receipt cannot use blank profile', () {
    expect(() => parse(receipt: '20250526000505'), throwsFormatException);
  });
  test('OFS cannot be relabeled CFS', () {
    expect(() => parse(cfs: true), throwsFormatException);
  });
  test('duplicate current term rejected', () {
    expect(
      () => parse(body: fixture('ofs').replaceAll('제 7 기', '제 8 기')),
      throwsFormatException,
    );
  });
  test('actual BS contradictory total is rejected', () {
    expect(
      () => parse(
        body: fixture('ofs').replaceAll('73,247,389,526', '73,247,389,527'),
      ),
      throwsFormatException,
    );
  });
}
