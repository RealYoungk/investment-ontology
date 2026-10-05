import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_conflict.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const fixture = 'test/fixtures/financial_html/known-conflicts';
final conflictCases = (jsonDecode(
  File('$fixture/evidence.json').readAsStringSync(),
) as List).cast<Map>();
String sourceHtml(Map e, String label) =>
    File('$fixture/${e['receipt']}/$label.html').readAsStringSync();
Uri sourceUri(Map e, String label) => Uri.parse(
  (e['sources'] as List).firstWhere((s) => s['label'] == label)['url'],
);
int year(Map e) =>
    int.parse((e['reportName'] as String).split('(')[1].substring(0, 4));
Future<PublicFinancialHtmlSource> fetchConflict(
  Map e, {
  String? corp,
  bool? cfs,
}) {
  return fastFinancialHtmlFetcher(
    MockClient((r) async {
      if (r.url.toString() ==
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${e['receipt']}') {
        return http.Response.bytes(
          File('$fixture/${e['receipt']}/shell.html').readAsBytesSync(),
          200,
          request: r,
        );
      }
      final label = r.url == sourceUri(e, 'cover')
          ? 'cover'
          : e['basis'] as String;
      if (r.url != sourceUri(e, label)) {
        throw const FormatException('Unknown fixture URL');
      }
      return http.Response.bytes(
        File('$fixture/${e['receipt']}/$label.html').readAsBytesSync(),
        200,
        request: r,
      );
    }),
  ).fetchAnnual(
    e['receipt'],
    reportName: e['reportName'],
    corpCode: corp ?? e['corpCode'],
    companyName: e['name'],
    bsnsYear: year(e),
    periodEnd: DateTime.utc(year(e), 12, 31),
    consolidated: cfs ?? e['basis'] == 'cfs',
  );
}

void main() {
  test(
    'actual conflict witness retains exact BS/CE values and malformed year',
    () {
      for (final e in conflictCases) {
        try {
          KnownAnnualSourceConflicts.verify(
            receipt: e['receipt'],
            corpCode: e['corpCode'],
            consolidated: e['basis'] == 'cfs',
            start: DateTime.utc(year(e), 1, 1),
            end: DateTime.utc(year(e), 12, 31),
            coverSource: sourceUri(e, 'cover'),
            statementSource: sourceUri(e, e['basis']),
            coverHtml: sourceHtml(e, 'cover'),
            statementHtml: sourceHtml(e, e['basis']),
          );
          fail('Exact conflict was not found');
        } on KnownAnnualSourceConflict catch (x) {
          if (e['basis'] == 'ofs') {
            expect(x.evidence['balanceEquity'], '834482799');
            expect(x.evidence['equityStatementClosing'], '834482800');
            expect(x.evidence['equityWholeColumn'], 5);
          } else if (e['receipt'] == '20240320001438') {
            expect(x.evidence['rawWholeEquityRollDifference'], '-50000000');
            expect(x.evidence['ceUnitPrinted'], false);
          } else {
            expect(x.evidence['printedClosingLabel'], '202.12.31 (당기말)');
            expect(x.evidence['wholeEquity'], '7,178,098,852');
            expect(x.evidence['wholeColumn'], 7);
          }
          if (e['receipt'] != '20240320001438') expect(x.evidence['unit'], '원');
        }
      }
    },
  );
  for (final e in conflictCases) {
    test(
      '${e['receipt']} actual normal fetch rejects independently printed contradiction',
      () async {
        await expectLater(
          fetchConflict(e),
          throwsA(
            isA<KnownAnnualSourceConflict>().having(
              (x) => x.evidence['financialFactsStored'],
              'no facts',
              false,
            ),
          ),
        );
      },
    );
    test(
      '${e['receipt']} parser detects exact source conflict with unchanged raw values',
      () {
        expect(
          () => PublicFinancialHtml.parseStandardAnnual(
            coverHtml: sourceHtml(e, 'cover'),
            statementHtml: sourceHtml(e, e['basis']),
            coverSource: sourceUri(e, 'cover'),
            statementSource: sourceUri(e, e['basis']),
            receipt: e['receipt'],
            corpCode: e['corpCode'],
            companyName: e['name'],
            periodStart: DateTime.utc(year(e), 1, 1),
            periodEnd: DateTime.utc(year(e), 12, 31),
            consolidated: e['basis'] == 'cfs',
          ),
          throwsA(
            isA<KnownAnnualSourceConflict>().having(
              (x) => x.evidence['reason'],
              'source reason',
              contains(e['basis'] == 'ofs' ? '불일치' : '202'),
            ),
          ),
        );
      },
    );
    test(
      '${e['receipt']} finite guard never aliases another source owner/basis/date/bytes',
      () {
        void verify({
          String? corp,
          bool? cfs,
          String? body,
          Uri? uri,
          DateTime? end,
        }) => KnownAnnualSourceConflicts.verify(
          receipt: e['receipt'],
          corpCode: corp ?? e['corpCode'],
          consolidated: cfs ?? e['basis'] == 'cfs',
          start: DateTime.utc(year(e), 1, 1),
          end: end ?? DateTime.utc(year(e), 12, 31),
          coverSource: sourceUri(e, 'cover'),
          statementSource: uri ?? sourceUri(e, e['basis']),
          coverHtml: sourceHtml(e, 'cover'),
          statementHtml: body ?? sourceHtml(e, e['basis']),
        );
        expect(() => verify(corp: '99999999'), returnsNormally);
        expect(() => verify(cfs: e['basis'] != 'cfs'), returnsNormally);
        expect(
          () => verify(end: DateTime.utc(year(e), 6, 30)),
          returnsNormally,
        );
        expect(
          () => verify(body: '${sourceHtml(e, e['basis'])} '),
          returnsNormally,
        );
        expect(
          () => verify(
            uri: sourceUri(
              e,
              e['basis'],
            ).replace(query: 'rcpNo=20260101000001'),
          ),
          returnsNormally,
        );
      },
    );
  }
}
