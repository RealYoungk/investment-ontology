import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:test/test.dart';

void main() {
  String fixture(String name) =>
      File('test/fixtures/financial_html/$name').readAsStringSync();
  final target = fixture('20240702000525-shell.html'),
      source = fixture('20240701000635-shell.html');
  final cover = fixture('20240701000635-cover.html'),
      cfs = fixture('20240701000635-cfs.html'),
      ofs = fixture('20240701000635-ofs.html');
  final requests = <http.Request>[];
  Future<PublicFinancialHtmlSource> fetch({
    String? targetShell,
    String? sourceShell,
    String? coverHtml,
    bool consolidated = true,
    String reportName = '[첨부정정]사업보고서 (2024.03)',
    DateTime? end,
    String corpCode = '00677334',
  }) {
    var viewer = 0;
    return PublicFinancialHtmlFetcher(
      MockClient((r) async {
        requests.add(r);
        expect(r.url.host, 'dart.fss.or.kr');
        expect(r.url.scheme, 'https');
        expect(r.url.queryParameters.containsKey('crtfc_key'), isFalse);
        if (requests.length > 1) {
          expect(r.headers['Referer'], isNotNull);
          expect(r.headers['Cookie'], 'JSESSIONID=fixture');
        }
        String body;
        if (r.url.path == '/dsaf001/main.do') {
          body = r.url.queryParameters['rcpNo'] == '20240702000525'
              ? targetShell ?? target
              : sourceShell ?? source;
        } else {
          expect(r.url.path, '/report/viewer.do');
          expect(r.url.queryParameters['rcpNo'], '20240701000635');
          expect(r.url.queryParameters['dcmNo'], '10011158');
          body = viewer++ == 0
              ? coverHtml ?? cover
              : consolidated
              ? cfs
              : ofs;
        }
        return http.Response(
          body,
          200,
          headers: {
            'content-type': 'text/html; charset=utf-8',
            'set-cookie': 'JSESSIONID=fixture; Path=/',
          },
        );
      }),
    ).fetchAttachmentAnnual(
      '20240702000525',
      reportName: reportName,
      corpCode: corpCode,
      companyName: '(주)아하',
      bsnsYear: 2024,
      periodEnd: end ?? DateTime.utc(2024, 3, 31),
      consolidated: consolidated,
    );
  }

  setUp(requests.clear);
  for (final consolidated in [true, false]) {
    test(
      'actual basis $consolidated retains original identity and printed seven accounts',
      () async {
        final result = await fetch(consolidated: consolidated);
        expect(result.sourceReceipt, '20240701000635');
        expect(result.correctionReceipt, '20240702000525');
        expect(
          result.correctionSource.queryParameters['rcpNo'],
          '20240702000525',
        );
        expect(
          result.coverSource.queryParameters['rcpNo'],
          result.sourceReceipt,
        );
        expect(
          result.statementSource.queryParameters['rcpNo'],
          result.sourceReceipt,
        );
        expect(result.periodStart, DateTime.utc(2023, 4, 1));
        expect(result.periodEnd, DateTime.utc(2024, 3, 31));
        expect(result.rows, hasLength(7));
        expect(
          result.rows.every(
            (r) =>
                r['account_id'] == null &&
                r['rcept_no'] == result.sourceReceipt,
          ),
          isTrue,
        );
        expect(
          result.rows.singleWhere(
            (r) => r['account_nm'] == '자산총계',
          )['thstrm_amount'],
          consolidated ? '101131149053' : '101309722186',
        );
        expect(
          result.sourceDigest,
          sha256
              .convert(
                utf8.encode('${result.coverHtml}\n${result.statementHtml}'),
              )
              .toString(),
        );
        expect(requests, hasLength(4));
        expect(
          result.statementSource.queryParameters['eleId'],
          consolidated ? '19' : '21',
        );
      },
    );
  }
  test('nonattachment rejected before fetching', () async {
    await expectLater(fetch(reportName: '[기재정정]사업보고서'), throwsFormatException);
    expect(requests, isEmpty);
  });
  test('target and original shell company IDs each must match', () async {
    await expectLater(
      fetch(
        targetShell: target.replaceAll(
          "openCorpInfoNew('00677334'",
          "openCorpInfoNew('00000001'",
        ),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(1));
    requests.clear();
    await expectLater(
      fetch(
        sourceShell: source.replaceAll(
          "openCorpInfoNew('00677334'",
          "openCorpInfoNew('00000001'",
        ),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(2));
  });
  test('target shell own receipt must match', () async {
    await expectLater(
      fetch(
        targetShell: target.replaceAll(
          "openPdfDownload('20240702000525'",
          "openPdfDownload('20240702000526'",
        ),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(1));
  });
  test('ambiguous, nonprior and external original options rejected', () async {
    for (final option in [
      '<option value="rcpNo=20240701000635" title="사업보고서">duplicate</option>',
      '<option value="rcpNo=20240702000525" title="사업보고서">current</option>',
      '<option value="https://evil.test/rcpNo=20240701000635" title="사업보고서">foreign</option>',
    ]) {
      requests.clear();
      await expectLater(
        fetch(
          targetShell: target.replaceFirst('</select>', '$option</select>'),
        ),
        throwsFormatException,
      );
      expect(requests, hasLength(1));
    }
  });
  test('wrong financial document coordinate rejected before bodies', () async {
    await expectLater(
      fetch(
        sourceShell: source.replaceAll(
          "['dcmNo'] = \"10011158\"",
          "['dcmNo'] = \"99999999\"",
        ),
      ),
      throwsFormatException,
    );
    expect(requests, hasLength(2));
  });
  test('missing or duplicated exact statement node rejected', () async {
    await expectLater(
      fetch(sourceShell: source.replaceAll('2. 연결재무제표', '연결재무요약')),
      throwsFormatException,
    );
    expect(requests, hasLength(2));
    requests.clear();
    final node = RegExp(
      r'''node2\['text'\] = "2\. 연결재무제표";(.*?)(?=node2\['text'\])''',
      dotAll: true,
    ).firstMatch(source)!.group(0)!;
    await expectLater(
      fetch(sourceShell: '$source$node'),
      throwsFormatException,
    );
    expect(requests, hasLength(2));
  });
  test('cover period and company cannot be relabelled', () async {
    await expectLater(
      fetch(end: DateTime.utc(2024, 12, 31)),
      throwsFormatException,
    );
    expect(requests, hasLength(3));
    requests.clear();
    await expectLater(
      fetch(coverHtml: cover.replaceAll('(주)아하', '(주)다른회사')),
      throwsFormatException,
    );
    expect(requests, hasLength(4));
  });
}
