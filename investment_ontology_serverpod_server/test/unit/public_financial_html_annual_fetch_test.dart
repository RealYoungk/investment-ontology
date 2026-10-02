import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:test/test.dart';

void main() {
  String fixture(String receipt, String suffix) => File(
    'test/fixtures/financial_html/standard-annual/$receipt/$suffix',
  ).readAsStringSync();
  final requests = <http.Request>[];
  Future<PublicFinancialHtmlSource> fetch({
    String receipt = '20260330001188',
    String corp = '01565364',
    String company = '주식회사 폴레드',
    String? shell,
    String? cover,
    String? statement,
    String? reportName,
    DateTime? end,
    bool consolidated = true,
    bool foreignRedirect = false,
    bool sameHostWrongReceipt = false,
  }) {
    final date =
        end ??
        (receipt == '20260922000230'
            ? DateTime.utc(2026, 6, 30)
            : DateTime.utc(receipt == '20250324000440' ? 2024 : 2025, 12, 31));
    var viewers = 0;
    return PublicFinancialHtmlFetcher(
      MockClient((r) async {
        requests.add(r);
        expect(r.url.host, 'dart.fss.or.kr');
        expect(r.url.queryParameters.containsKey('crtfc_key'), isFalse);
        expect(r.url.queryParameters['rcpNo'], receipt);
        final body = r.url.path == '/dsaf001/main.do'
            ? shell ?? fixture(receipt, 'shell.html')
            : viewers++ == 0
            ? cover ?? fixture(receipt, 'cover.html')
            : statement ??
                  fixture(
                    receipt,
                    consolidated
                        ? 'consolidated-statement.html'
                        : 'separate-statement.html',
                  );
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
          request: foreignRedirect
              ? http.Request('GET', Uri.parse('https://example.org/foreign'))
              : sameHostWrongReceipt
              ? http.Request(
                  'GET',
                  Uri.parse(
                    'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260330001189',
                  ),
                )
              : r,
        );
      }),
    ).fetchAnnual(
      receipt,
      reportName:
          reportName ??
          '사업보고서 (${date.year}.${date.month.toString().padLeft(2, '0')})',
      corpCode: corp,
      companyName: company,
      bsnsYear: date.year,
      periodEnd: date,
      consolidated: consolidated,
    );
  }

  setUp(requests.clear);
  test(
    'exact annual transport accepts declared 92-day period without scaling',
    () async {
      const receipt = '20260330001188';
      String short(String raw) =>
          raw.replaceAll(RegExp(r'2025년\s*0?1월\s*0?1일'), '2025년10월01일');
      final original = await fetch();
      requests.clear();
      final result = await fetch(
        cover: short(fixture(receipt, 'cover.html')),
        statement: short(fixture(receipt, 'consolidated-statement.html')),
      );
      expect(result.periodStart, DateTime.utc(2025, 10, 1));
      expect(result.periodEnd, DateTime.utc(2025, 12, 31));
      expect(
        result.rows.map((r) => r['thstrm_amount']).toList(),
        original.rows.map((r) => r['thstrm_amount']).toList(),
      );
      expect(requests, hasLength(3));
    },
  );
  test(
    'short annual transport rejects body dates inconsistent with cover',
    () async {
      const receipt = '20260330001188';
      final cover = fixture(
        receipt,
        'cover.html',
      ).replaceAll(RegExp(r'2025년\s*0?1월\s*0?1일'), '2025년10월01일');
      await expectLater(fetch(cover: cover), throwsFormatException);
    },
  );

  for (final item in [
    ('20250324000440', '00112998', '서울보증보험주식회사', true),
    ('20250324000440', '00112998', '서울보증보험주식회사', false),
    ('20260330001188', '01565364', '주식회사 폴레드', true),
    ('20260330001188', '01565364', '주식회사 폴레드', false),
    ('20260922000230', '00910202', '대동고려삼(주)', false),
  ]) {
    test('exact actual annual ${item.$1} consolidated=${item.$4}', () async {
      final result = await fetch(
        receipt: item.$1,
        corp: item.$2,
        company: item.$3,
        consolidated: item.$4,
      );
      expect(result.sourceReceipt, item.$1);
      expect(result.correctionReceipt, isNull);
      expect(result.correctionSource, isNull);
      expect(result.rows, hasLength(8));
      expect(
        result.rows.every(
          (r) => r['account_id'] == null && r['rcept_no'] == item.$1,
        ),
        isTrue,
      );
      expect(requests, hasLength(3));
      expect(
        result.coverSource.queryParameters['dcmNo'],
        result.statementSource.queryParameters['dcmNo'],
      );
      if (item.$1 == '20260922000230') {
        expect(result.periodStart, DateTime.utc(2025, 7, 1));
      }
    });
  }
  test(
    'explicit CFS not applicable cannot become successful empty facts',
    () async {
      await expectLater(
        fetch(receipt: '20260922000230', corp: '00910202', company: '대동고려삼(주)'),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having(
                (e) => e.sourceReceipt,
                'source receipt',
                '20260922000230',
              )
              .having((e) => e.corpCode, 'company identity', '00910202')
              .having((e) => e.periodStart, 'start', DateTime.utc(2025, 7, 1))
              .having((e) => e.periodEnd, 'end', DateTime.utc(2026, 6, 30))
              .having((e) => e.consolidated, 'basis', true)
              .having((e) => e.correctionReceipt, 'no assumed original', isNull)
              .having(
                (e) => e.statementSource.queryParameters['rcpNo'],
                'statement receipt',
                '20260922000230',
              )
              .having(
                (e) => e.statementSource.queryParameters['dcmNo'],
                'document',
                '11588250',
              )
              .having(
                (e) => e.coverSource.queryParameters['dcmNo'],
                'cover same document',
                '11588250',
              )
              .having(
                (e) => e.evidence,
                'actual explicit evidence',
                '당사는 연결재무제표 작성법인이 아니므로 해당사항이 없습니다.',
              )
              .having(
                (e) => e.sourceDigest,
                'combined raw SHA',
                sha256
                    .convert(
                      utf8.encode(
                        '${fixture('20260922000230', 'cover.html')}\n${fixture('20260922000230', 'consolidated-statement.html')}',
                      ),
                    )
                    .toString(),
              ),
        ),
      );
    },
  );
  test('attachment annual is rejected before any GET', () async {
    await expectLater(
      fetch(reportName: '[첨부정정]사업보고서 (2025.12)'),
      throwsFormatException,
    );
    expect(requests, isEmpty);
  });
  test(
    'report label closing period mismatch is rejected before any GET',
    () async {
      await expectLater(
        fetch(reportName: '사업보고서 (2025.09)'),
        throwsFormatException,
      );
      expect(requests, isEmpty);
    },
  );
  test('foreign company shell cannot reach cover', () async {
    await expectLater(fetch(corp: '99999999'), throwsFormatException);
    expect(requests, hasLength(1));
  });
  test('foreign company cover cannot validate primary statements', () async {
    await expectLater(
      fetch(
        cover: fixture(
          '20260330001188',
          'cover.html',
        ).replaceAll('폴레드', '외국회사'),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(4));
    // Primary issuer captions and overview both fail; no numeric source is returned.
    expect(
      requests.last.url,
      Uri.parse(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260330001188&dcmNo=11196132&eleId=3&offset=6057&length=66304&dtd=dart4.xsd',
      ),
    );
  });
  test('actual cover end mismatch cannot reach statements', () async {
    await expectLater(
      fetch(end: DateTime.utc(2025, 11, 30)),
      throwsFormatException,
    );
    expect(requests, hasLength(2));
  });
  test(
    'annual cover invalid calendar date rejected without normalization',
    () async {
      await expectLater(
        fetch(
          cover: fixture(
            '20260330001188',
            'cover.html',
          ).replaceAll('12월 31일', '02월 31일'),
        ),
        throwsFormatException,
      );
      expect(requests, hasLength(2));
    },
  );
  test('official shell coordinate receipt tampering rejected', () async {
    await expectLater(
      fetch(
        shell: fixture(
          '20260330001188',
          'shell.html',
        ).replaceAll('20260330001188', '20260330001189'),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(1));
  });
  test('foreign redirected response rejected', () async {
    await expectLater(fetch(foreignRedirect: true), throwsFormatException);
    expect(requests, hasLength(1));
  });
  test(
    'same official host redirect to a different receipt is rejected',
    () async {
      await expectLater(
        fetch(sameHostWrongReceipt: true),
        throwsFormatException,
      );
      expect(requests, hasLength(1));
    },
  );
  final genericOnly = throwsA(
    predicate(
      (e) =>
          e is FormatException && e is! PublicFinancialHtmlBasisNotApplicable,
    ),
  );
  Future<PublicFinancialHtmlSource> explicitNone({
    String? body,
    String? cover,
    DateTime? end,
    bool consolidated = true,
  }) => fetch(
    receipt: '20260922000230',
    corp: '00910202',
    company: '대동고려삼(주)',
    statement: body,
    cover: cover,
    end: end,
    consolidated: consolidated,
  );
  test(
    'blank consolidated section is ordinary failure, not proven absence',
    () async {
      await expectLater(
        explicitNone(body: '<BODY>2. 연결재무제표</BODY>'),
        genericOnly,
      );
    },
  );
  test(
    'qualified not-applicable sentence cannot prove non-preparer status',
    () async {
      await expectLater(
        explicitNone(
          body:
              fixture(
                '20260922000230',
                'consolidated-statement.html',
              ).replaceAll(
                '당사는 연결재무제표 작성법인이 아니므로 해당사항이 없습니다.',
                '해당사항이 없습니다. 자세한 사항은 주석을 참조하십시오.',
              ),
        ),
        genericOnly,
      );
    },
  );
  test('explicit non-preparer plus a table cannot become noData', () async {
    await expectLater(
      explicitNone(
        body: fixture('20260922000230', 'consolidated-statement.html')
            .replaceFirst(
              '</BODY>',
              '<TABLE><TR><TD>자산총계</TD><TD>1</TD></TR></TABLE></BODY>',
            ),
      ),
      genericOnly,
    );
  });
  test('explicit sentence in requested OFS cannot become CFS noData', () async {
    await expectLater(
      explicitNone(
        body: fixture('20260922000230', 'consolidated-statement.html'),
        consolidated: false,
      ),
      genericOnly,
    );
  });
  test(
    'non-preparer evidence never overrides actual cover closing mismatch',
    () async {
      await expectLater(
        explicitNone(end: DateTime.utc(2026, 5, 31)),
        genericOnly,
      );
      expect(requests, hasLength(2));
    },
  );
  test(
    'non-preparer evidence never overrides cover company mismatch',
    () async {
      await expectLater(
        explicitNone(
          cover: fixture(
            '20260922000230',
            'cover.html',
          ).replaceAll('대동고려삼', '외국회사'),
        ),
        genericOnly,
      );
      expect(requests, hasLength(4));
      // A pure absence body cannot prove a different cover issuer.
      expect(
        requests.last.url,
        Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260922000230&dcmNo=11588250&eleId=3&offset=5925&length=100871&dtd=dart4.xsd',
        ),
      );
    },
  );
}
