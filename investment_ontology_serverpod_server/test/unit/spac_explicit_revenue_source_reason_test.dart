import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/imgt_explicit_revenue_missing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'public_financial_html_spac_missing_revenue_test.dart' as actual;

void main() {
  for (final receipt in ['20230315000997', '20230308000311']) {
    const basis = FsDiv.separate;
    final corp = actual.proof(receipt)['corpCode'] as String;
    test(
      'exact null fact and all six actual numeric source facts required $basis',
      () {
        final rows = actual.parse(receipt);
        expect(
          ImgtExplicitRevenueMissing.rowsProof(
            rows,
            corp,
            receipt,
            basis,
            ImgtExplicitRevenueMissing.sourceFor(receipt, basis),
          ),
          isTrue,
        );
        final converted = FinancialRows.toFacts(
          rows,
          reportId: 3,
          companyId: 4,
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          fsDiv: basis,
          sourceId: 5,
        );
        expect(converted.invalidAmounts, 0);
        final facts = [
          for (var i = 0; i < converted.facts.length; i++)
            converted.facts[i].copyWith(id: 10 + i),
        ];
        final line = FinancialAccounts.pick(facts)
            .singleWhere((l) => l.key == 'revenue');
        expect(line.amount, isNull);
        final report = FinancialReport(
          id: 3,
          companyId: 4,
          rceptNo: receipt,
          fsDiv: basis,
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (2022.12)',
          factCount: facts.length,
          sourceId: 5,
          fetchedAt: DateTime.utc(2026),
        );
        final digest = 'a' * 64;
        final source = Source(
          id: 5,
          kind: SourceKind.dartReport,
          reference: report.rceptNo,
          title: '${ImgtExplicitRevenueMissing.note} SHA256:$digest',
          url: ImgtExplicitRevenueMissing.sourceFor(receipt, basis).toString(),
          retrievedAt: DateTime.utc(2026),
        );
        final audit = Source(
          id: 6,
          kind: SourceKind.dartReport,
          reference:
              'financial-api-noData-source:${report.rceptNo}:${basis.name}',
          url: source.url,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode({
            'corpCode': corp,
            'sourceReceipt': report.rceptNo,
            'targetReceipt': report.rceptNo,
            'fsDiv': basis.name,
            'format': 'html',
            'sha256': digest,
            'coreRowProvenance': [
              for (final row in rows)
                {
                  if (row['thstrm_amount'] == null) ...{
                    'rcept_no': row['rcept_no'],
                    'corp_code': row['corp_code'],
                    'bsns_year': row['bsns_year'],
                    'reprt_code': row['reprt_code'],
                    'sj_div': row['sj_div'],
                  },
                  'account_nm': row['account_nm'],
                  'account_id': row['account_id'],
                  'thstrm_amount': row['thstrm_amount'],
                  'currency': row['currency'],
                  'html_provenance': row['html_provenance'],
                },
            ],
          }),
        );
        String? reason({
          Source? src,
          Source? evidence,
          List<FinancialFact>? ff,
          String? company,
        }) => ImgtExplicitRevenueMissing.reason(
          company: company ?? corp,
          report: report,
          source: src ?? source,
          audit: evidence ?? audit,
          facts: ff ?? facts,
          line: line,
        );
        expect(reason(), contains('미기재(-)'));
        expect(reason(company: '00000001'), isNull);
        expect(
          reason(src: source.copyWith(reference: '20260330001851')),
          isNull,
        );
        expect(reason(src: source.copyWith(title: 'missing digest')), isNull);
        expect(
          reason(evidence: audit.copyWith(reference: 'wrong-basis')),
          isNull,
        );
        expect(
          reason(ff: facts.where((f) => f.id != line.factId).toList()),
          isNull,
        );
        expect(
          reason(
            ff: [
              for (final f in facts)
                if (f.id == line.factId) f.copyWith(amount: BigInt.zero) else f,
            ],
          ),
          isNull,
        );
        expect(
          reason(
            ff: [
              for (final f in facts)
                if (f.amount != null)
                  f.copyWith(amount: f.amount! + BigInt.one)
                else
                  f,
            ],
          ),
          isNull,
        );
        expect(
          reason(ff: [for (final f in facts) f.copyWith(sourceId: 99)]),
          isNull,
        );
      },
    );
  }
}
