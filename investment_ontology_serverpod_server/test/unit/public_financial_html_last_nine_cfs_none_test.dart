import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

const directory = 'test/fixtures/financial_html/last-nine-cfs-none';
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
    periodEnd: DateTime.utc(year ?? c['bsnsYear'], 12, 31),
    consolidated: consolidated,
  );
}

void main() {
  final all = cases();
  for (var i = 0; i < all.length; i++) {
    final index = i, c = all[i];
    test('actual last nine pure CFS ${c['rceptNo']} sameperiod source-bound', () async {
      await expectLater(
        actual(index),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((e) => e.sourceReceipt, 'receipt', c['rceptNo'])
              .having((e) => e.corpCode, 'corp', c['corpCode'])
              .having(
                (e) => e.periodEnd,
                'end',
                DateTime.utc(c['bsnsYear'], 12, 31),
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
        t.copyWith(rceptNo: '20991231000000'),
        t.copyWith(reportName: '사업보고서 (${c['bsnsYear']}.06)'),
        t.copyWith(bsnsYear: c['bsnsYear'] - 1),
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
  const newLiterals = [
    '당사는 보고서 제출일 현재 해당 사항이 없습니다.',
    '-. 사업보고서 작성기준일 현재 해당사항 없습니다.',
  ];
  for (var index = 0; index < all.length; index++) {
    final target = index;
    final text = all[index]['exactSectionText'] as String;
    if (!newLiterals.any(text.endsWith)) continue;
    final literal = text.replaceFirst('2. 연결재무제표 ', '');
    for (final body in [
      '<body>2. 연결재무제표 $literal 123</body>',
      '<body>2. 연결재무제표 <table><tr><td>$literal</td></tr></table></body>',
      '<body>2. 연결재무제표 $literal 상기내역 참조</body>',
      '<body>2. 연결재무제표 $literal 법률 제1조의2</body>',
      '<body>4. 재무제표 $literal</body>',
    ]) {
      test(
        'new literal ${all[target]['rceptNo']} boundary $body',
        () => expectLater(
          actual(target, body: body),
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
      'new literal ${all[target]['rceptNo']} wrong corp',
      () =>
          expectLater(actual(target, corp: '00000000'), throwsFormatException),
    );
    test(
      'new literal ${all[target]['rceptNo']} wrong period',
      () => expectLater(
        actual(target, year: all[target]['bsnsYear'] - 1),
        throwsFormatException,
      ),
    );
    test(
      'new literal ${all[target]['rceptNo']} wrong basis',
      () => expectLater(
        actual(target, consolidated: false),
        throwsFormatException,
      ),
    );
  }
  for (final body in [
    '<body>2. 연결재무제표 당사는 해당사항 없습니다. 123</body>',
    '<body>2. 연결재무제표 <table><tr><td>당사는 해당사항 없습니다.</td></tr></table></body>',
    '<body>2. 연결재무제표 상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다. 상기내역 참조</body>',
    '<body>2. 연결재무제표 당사는 현재 일반기업회계기준 결산법인으로 연결대상 종속회사가 없습니다. 세부사항은 재무제표 주석 21. 특수관계자거래를 참조하십시오.</body>',
    '<body>2. 연결재무제표 ※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다. 123</body>',
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
  test('all official raw bytes retain independently reviewed SHA', () {
    for (final c in [
      ...cases(),
      ...List<Map<String, dynamic>>.from(
        jsonDecode(File('$directory/excluded.json').readAsStringSync()) as List,
      ),
    ]) {
      for (final source in c['sources'] as List) {
        expect(
          sha256
              .convert(
                File('$directory/${c['rceptNo']}/${source['label']}.html')
                    .readAsBytesSync(),
              )
              .toString(),
          source['sha256'],
        );
      }
    }
  });
  for (final receipt in ['20220321001162', '20220315000038']) {
    test(
      'actual full literal or conflicting numeric source $receipt',
      () async {
        final c = (jsonDecode(
          File('$directory/excluded.json').readAsStringSync(),
        ) as List).singleWhere((x) => x['rceptNo'] == receipt);
        var viewers = 0;
        await expectLater(
          PublicFinancialHtmlFetcher(
            MockClient(
              (r) async => http.Response.bytes(
                utf8.encode(
                  r.url.path == '/dsaf001/main.do'
                      ? raw(receipt, 'shell')
                      : viewers++ == 0
                      ? raw(receipt, 'cover')
                      : raw(receipt, 'cfs'),
                ),
                200,
                request: r,
              ),
            ),
          ).fetchAnnual(
            receipt,
            reportName: c['reportName'],
            corpCode: c['corpCode'],
            companyName: c['name'],
            bsnsYear: 2021,
            periodEnd: DateTime.utc(2021, 12, 31),
            consolidated: true,
          ),
          receipt == '20220321001162'
              ? throwsA(isA<PublicFinancialHtmlBasisNotApplicable>())
              : throwsA(
                  isA<FormatException>().having(
                    (e) => e is PublicFinancialHtmlBasisNotApplicable,
                    'not typed absence',
                    false,
                  ),
                ),
        );
      },
    );
  }
}
