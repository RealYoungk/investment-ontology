import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  for (final c in [
    ('20250710000060', '00445869', '(주)유니포인트', '- 해당사항 없음'),
    ('20250321001022', '01023822', '(주)메디젠휴먼케어', '- 해당사항이 없습니다.'),
  ]) {
    String raw(String name) => File(
      'test/fixtures/financial_html/two-cfs-explicit-none/${c.$1}/$name.html',
    ).readAsStringSync();
    Future<PublicFinancialHtmlSource> fetch([String? body]) {
      var count = 0;
      return fastFinancialHtmlFetcher(
        MockClient((r) async {
          expect(r.url.queryParameters['rcpNo'], c.$1);
          expect(r.url.queryParameters.containsKey('crtfc_key'), false);
          final value = r.url.path == '/dsaf001/main.do'
              ? raw('shell')
              : count++ == 0
              ? raw('cover')
              : body ?? raw('cfs');
          return http.Response.bytes(utf8.encode(value), 200, request: r);
        }),
      ).fetchAnnual(
        c.$1,
        reportName: '사업보고서 (2024.12)',
        corpCode: c.$2,
        companyName: c.$3,
        bsnsYear: 2024,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: true,
      );
    }

    test(
      '${c.$1} actual CFS typed non-applicable without numeric success',
      () async {
        await expectLater(
          fetch(),
          throwsA(
            isA<PublicFinancialHtmlBasisNotApplicable>()
                .having((e) => e.evidence, 'evidence', c.$4)
                .having((e) => e.sourceReceipt, 'receipt', c.$1)
                .having((e) => e.corpCode, 'corp', c.$2)
                .having((e) => e.periodStart, 'start', DateTime.utc(2024))
                .having((e) => e.periodEnd, 'end', DateTime.utc(2024, 12, 31))
                .having((e) => e.statementHtml, 'raw unchanged', raw('cfs')),
          ),
        );
      },
    );
    for (final n in ['section', 'context', 'table', 'number', 'reference']) {
      test('${c.$1} rejects $n as non-applicable', () async {
        final b = switch (n) {
          'section' => raw('cfs').replaceAll('2. 연결재무제표', '4. 재무제표'),
          'context' => raw('cfs').replaceAll(c.$4, '${c.$4} 현재 적용 여부를 검토합니다.'),
          'table' => raw('cfs').replaceFirst(
            '</BODY>',
            '<table><tr><td>0</td></tr></table></BODY>',
          ),
          'number' => raw('cfs').replaceAll(c.$4, '${c.$4} 2024'),
          _ => raw('cfs').replaceAll(c.$4, '${c.$4} 주석을 참조하십시오.'),
        };
        await expectLater(
          fetch(b),
          throwsA(
            predicate(
              (e) =>
                  e is FormatException &&
                  e is! PublicFinancialHtmlBasisNotApplicable,
            ),
          ),
        );
      });
    }
    DartFiling filing() => DartFiling(
      rceptNo: c.$1,
      corpCode: c.$2,
      companyId: 1,
      reportName: '사업보고서 (2024.12)',
      bsnsYear: 2024,
      reportCode: FinancialReportCode.annual,
      consolidatedStatus: FilingFetchStatus.failed,
      separateStatus: FilingFetchStatus.stored,
      attempts: 3,
      lastError: 'api-noData-annual-public:attempt=2',
      discoveredAt: DateTime.utc(2025),
    );
    test('${c.$1} CFS priority preserves OFS and counters', () {
      final f = filing(), before = f.toJson();
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        true,
      );
      expect(f.toJson(), before);
    });
    test('${c.$1} rejects false priority', () {
      for (final f in [
        filing().copyWith(corpCode: '99999999'),
        filing().copyWith(reportName: '사업보고서 (2024.06)'),
        filing().copyWith(reportCode: FinancialReportCode.halfYear),
        filing().copyWith(lastError: 'api-noData-annual-public:attempt=3'),
        filing().copyWith(consolidatedStatus: FilingFetchStatus.noData),
        filing().copyWith(
          consolidatedStatus: FilingFetchStatus.stored,
          separateStatus: FilingFetchStatus.failed,
        ),
      ]) {
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
          false,
        );
      }
    });
  }
}
