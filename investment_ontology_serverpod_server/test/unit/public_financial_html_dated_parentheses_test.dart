import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/dated-parentheses';
String actual(String label) => File('$root/$label.html').readAsStringSync();
Uri source(String label) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((x) => x['label'] == label)['url'],
);
List<Map<String, dynamic>> actualDatedRows({
  String? body,
  String? cover,
  String corp = '00442631',
  bool consolidated = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? actual('cover'),
  statementHtml: body ?? actual('ofs'),
  coverSource: source('cover'),
  statementSource: source('ofs'),
  receipt: '20250320001616',
  corpCode: corp,
  companyName: '태양기계(주)',
  periodStart: DateTime.utc(2024, 1, 1),
  periodEnd: DateTime.utc(2024, 12, 31),
  consolidated: consolidated,
);
PublicFinancialHtmlSource actualSource() => PublicFinancialHtmlSource(
  sourceReceipt: '20250320001616',
  correctionReceipt: null,
  correctionSource: null,
  coverHtml: actual('cover'),
  coverSource: source('cover'),
  statementHtml: actual('ofs'),
  statementSource: source('ofs'),
  periodStart: DateTime.utc(2024),
  periodEnd: DateTime.utc(2024, 12, 31),
  rows: actualDatedRows(),
);
void main() {
  test('actual fully dated parentheses retain seven whole source values and CE proof', () {
    final rows = actualDatedRows();
    final amounts = {
      for (final row in rows) row['account_nm']: row['thstrm_amount'],
    };
    expect(
      amounts.values,
      containsAll([
        '45196505945',
        '28155449143',
        '17041056802',
        '35139145847',
        '2077871656',
        '788713757',
        '2757334697',
      ]),
    );
    expect(rows.every((r) => r['account_id'] == null), isTrue);
    final p =
        (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
            as Map;
    expect(p['mode'], 'fully-dated-parentheses-equity-corroboration');
    expect(p['closingEquity'], '17041056802');
    expect(p['currentProfit'], '788713757');
  });
  test(
    'wrong current duration rejects',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceAll('2024. 01. 01부터', '2023. 01. 01부터'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong cover term rejects',
    () => expect(
      () => actualDatedRows(
        cover: actual('cover').replaceAll('제 35 기', '제 34 기'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'year-only title never gains support',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs')
            .replaceAll('2024. 01. 01부터 2024. 12. 31까지', '2024년도'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'unbalanced parenthesis rejects',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceAll('(2024. 01. 01부터', '2024. 01. 01부터'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'foreign cover rejects',
    () => expect(
      () => actualDatedRows(cover: actual('cover').replaceAll('태양기계', '다른기업')),
      throwsFormatException,
    ),
  );
  test(
    'wrong basis rejects',
    () => expect(
      () => actualDatedRows(consolidated: true),
      throwsFormatException,
    ),
  );
  test(
    'CE current date must be unique',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceAll('2023. 1. 1(보고금액)', '2024. 1. 1(보고금액)'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'CE closing equity crosscheck rejects conflict',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceRange(
          actual('ofs').lastIndexOf('17,041,056,802'),
          actual('ofs').lastIndexOf('17,041,056,802') + '17,041,056,802'.length,
          '17,041,056,803',
        ),
      ),
      throwsFormatException,
    ),
  );
  test(
    'CE current profit crosscheck rejects conflict',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceFirst('788,713,757', '788,713,758'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'current required revenue dash remains reject',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceFirst('35,139,145,847', '-'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'mixed primary money units reject equality',
    () => expect(
      () => actualDatedRows(
        body: actual('ofs').replaceFirst('(단위:원)', '(단위:천원)'),
      ),
      throwsFormatException,
    ),
  );
}
