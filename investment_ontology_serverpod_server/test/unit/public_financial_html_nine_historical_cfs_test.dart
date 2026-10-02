import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

const directory = 'test/fixtures/financial_html/nine-historical-cfs';
List<Map<String, dynamic>> cases() => List<Map<String, dynamic>>.from(
  jsonDecode(File('$directory/cases.json').readAsStringSync()) as List,
);
String raw(String r, String name) =>
    File('$directory/$r/$name.html').readAsStringSync();
Future<PublicFinancialHtmlSource> actual(
  int index, {
  String? body,
  String? corp,
  int? year,
  bool consolidated = true,
}) {
  final c = cases()[index];
  var viewers = 0;
  return PublicFinancialHtmlFetcher(
    MockClient(
      (r) async => http.Response.bytes(
        utf8.encode(
          r.url.path == '/dsaf001/main.do'
              ? raw(c['rceptNo'], 'shell')
              : viewers++ == 0
              ? raw(c['rceptNo'], 'cover')
              : body ?? raw(c['rceptNo'], 'cfs'),
        ),
        200,
        request: r,
      ),
    ),
  ).fetchAnnual(
    c['rceptNo'],
    reportName: c['reportName'],
    corpCode: corp ?? c['corpCode'],
    companyName: c['name'],
    bsnsYear: year ?? c['bsnsYear'],
    periodEnd: DateTime.utc(year ?? c['bsnsYear'], c['month'] + 1, 0),
    consolidated: consolidated,
  );
}

void main() {
  final all = cases();
  for (var i = 0; i < all.length; i++) {
    final index = i, c = all[i];
    test('official pinned raw URI and SHA ${c['rceptNo']}', () {
      final p = jsonDecode(
        File('$directory/${c['rceptNo']}/proof.json').readAsStringSync(),
      );
      expect(p['shellCorpIds'], [c['corpCode']]);
      for (final source in p['sources'] as List) {
        expect(
          sha256
              .convert(
                File('$directory/${c['rceptNo']}/${source['label']}.html')
                    .readAsBytesSync(),
              )
              .toString(),
          source['sha256'],
        );
        final u = Uri.parse(source['url']);
        expect(u.host, 'dart.fss.or.kr');
        expect(u.queryParameters['rcpNo'], c['rceptNo']);
        if (source['label'] != 'shell')
          expect(u.queryParameters.keys.toSet(), {
            'rcpNo',
            'dcmNo',
            'eleId',
            'offset',
            'length',
            'dtd',
          });
      }
    });
    test('actual nine pure CFS ${c['rceptNo']} sameperiod source-bound', () async {
      await expectLater(
        actual(index),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((e) => e.sourceReceipt, 'receipt', c['rceptNo'])
              .having((e) => e.corpCode, 'corp', c['corpCode'])
              .having(
                (e) => e.periodStart,
                'start',
                c['month'] == 9
                    ? DateTime.utc(c['bsnsYear'] - 1, 10)
                    : DateTime.utc(c['bsnsYear']),
              )
              .having(
                (e) => e.periodEnd,
                'end',
                DateTime.utc(c['bsnsYear'], c['month'] + 1, 0),
              )
              .having(
                (e) => e.sourceDigest,
                'SHA',
                sha256
                    .convert(
                      utf8.encode(
                        '${raw(c['rceptNo'], 'cover')}\n${raw(c['rceptNo'], 'cfs')}',
                      ),
                    )
                    .toString(),
              ),
        ),
      );
    });
    DartFiling f() => DartFiling(
      rceptNo: c['rceptNo'],
      corpCode: c['corpCode'],
      reportName: c['reportName'],
      bsnsYear: c['bsnsYear'],
      reportCode: FinancialReportCode.annual,
      consolidatedStatus: FilingFetchStatus.failed,
      separateStatus: FilingFetchStatus.stored,
      attempts: 3,
      lastError: 'api-noData-annual-public:attempt=2',
      discoveredAt: DateTime.utc(2026),
    );
    test('finite CFS priority ${c['rceptNo']} with OFS untouched', () {
      final t = f();
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(t),
        true,
      );
      expect(t.attempts, 3);
      for (final wrong in [
        t.copyWith(corpCode: '00000000'),
        t.copyWith(bsnsYear: c['bsnsYear'] - 1),
        t.copyWith(reportName: '사업보고서 (${c['bsnsYear']}.06)'),
        t.copyWith(reportCode: FinancialReportCode.halfYear),
        t.copyWith(consolidatedStatus: FilingFetchStatus.stored),
        t.copyWith(lastError: 'api-noData-annual-public:attempt=3'),
      ]) {
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(wrong),
          false,
        );
      }
    });
  }
  for (final body in [
    '<body>2. 연결재무제표 당사는 해당사항 없습니다. 123</body>',
    '<body>2. 연결재무제표 <table><tr><td>당사는 해당사항 없습니다.</td></tr></table></body>',
    '<body>2. 연결재무제표 상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.</body>',
    '<body>2. 연결재무제표 당사는 현재 일반기업회계기준 결산법인으로 연결대상 종속회사가 없습니다. 세부사항은 재무제표 주석 21. 특수관계자거래를 참조하십시오.</body>',
    '<body>2. 연결재무제표 ※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.</body>',
    '<body>4. 재무제표 당사는 해당사항 없습니다.</body>',
  ]) {
    test(
      'none must not accept extra context $body',
      () => expectLater(
        actual(0, body: body),
        throwsA(
          isA<FormatException>().having(
            (e) => e is PublicFinancialHtmlBasisNotApplicable,
            'not typed absence',
            false,
          ),
        ),
      ),
    );
  }
  test(
    'wrong corp',
    () => expectLater(actual(0, corp: '01085188'), throwsFormatException),
  );
  test(
    'wrong period',
    () => expectLater(actual(0, year: 2023), throwsFormatException),
  );
  test(
    'wrong basis',
    () => expectLater(actual(0, consolidated: false), throwsFormatException),
  );
}
