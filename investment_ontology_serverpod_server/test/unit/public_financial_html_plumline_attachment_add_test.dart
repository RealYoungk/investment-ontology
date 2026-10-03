import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

Future<PublicFinancialHtmlSource> plumFetch({
  String receipt = '20260323000673',
  String corp = '01063237',
  String name = '[첨부추가]사업보고서 (2025.12)',
  int year = 2025,
}) {
  var viewers = 0;
  return PublicFinancialHtmlFetcher(
    MockClient((r) async {
      final file = r.url.path == '/dsaf001/main.do'
          ? 'shell.html'
          : viewers++ == 0
          ? 'cover.html'
          : 'ofs.html';
      return http.Response.bytes(
        utf8.encode(
          File('test/fixtures/financial_html/plumline-attachment-add/$file')
              .readAsStringSync(),
        ),
        200,
        request: r,
      );
    }),
  ).fetchAnnual(
    receipt,
    reportName: name,
    corpCode: corp,
    companyName: '(주)플럼라인생명과학',
    bsnsYear: year,
    periodEnd: DateTime.utc(year, 12, 31),
    consolidated: false,
  );
}

void main() {
  test('actual attachment-add own receipt OFS seven whole accounts', () async {
    final s = await plumFetch();
    expect(s.rows, hasLength(7));
    expect(s.sourceReceipt, '20260323000673');
    expect(s.correctionReceipt, isNull);
    expect(s.periodStart, DateTime.utc(2025));
    expect(
      s.rows.every((r) => r['currency'] == 'KRW' && r['account_id'] == null),
      isTrue,
    );
    expect(s.rows.first['thstrm_amount'], '2854354565');
  });
  for (final modifier in ['[첨부추가예정]', '[첨부정정]', '[기재추가]', '[첨부추가][기재정정]']) {
    test(
      'wrong modifier $modifier rejected',
      () => expectLater(
        plumFetch(name: '$modifier사업보고서 (2025.12)'),
        throwsFormatException,
      ),
    );
  }
  test(
    'wrong corp rejected',
    () => expectLater(plumFetch(corp: '01063238'), throwsFormatException),
  );
  test(
    'wrong receipt rejected',
    () => expectLater(
      plumFetch(receipt: '20260323000674'),
      throwsFormatException,
    ),
  );
  test(
    'wrong year rejected',
    () => expectLater(plumFetch(year: 2024), throwsFormatException),
  );
  DartFiling target() => DartFiling(
    rceptNo: '20260323000673',
    corpCode: '01063237',
    reportName: '[첨부추가]사업보고서 (2025.12)',
    bsnsYear: 2025,
    reportCode: FinancialReportCode.annual,
    consolidatedStatus: FilingFetchStatus.stored,
    separateStatus: FilingFetchStatus.failed,
    attempts: 3,
    lastError: 'api-noData-annual-public:attempt=2',
    discoveredAt: DateTime.utc(2026),
  );
  test('finite exact OFS priority preserves API attempts', () {
    final f = target();
    expect(FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f), true);
    expect(f.attempts, 3);
  });
  for (final f in [
    target().copyWith(corpCode: '00614089'),
    target().copyWith(bsnsYear: 2024),
    target().copyWith(reportCode: FinancialReportCode.halfYear),
    target().copyWith(reportName: '사업보고서 (2025.06)'),
    target().copyWith(lastError: 'api-noData-annual-public:attempt=3'),
    target().copyWith(separateStatus: FilingFetchStatus.stored),
  ]) {
    test(
      'priority rejects ${f.toJson()}',
      () => expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        false,
      ),
    );
  }
}
