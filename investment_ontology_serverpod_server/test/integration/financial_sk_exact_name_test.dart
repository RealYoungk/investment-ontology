import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import '../unit/public_financial_sk_exact_name_test.dart' show actualSk;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exact legal/commercial SK exact source storage', (
    builder,
    endpoints,
  ) {
    test('seven actual OFS values and printed identity survive Source/fact storage and summary pick', () async {
      final s = builder.build();
      try {
        final rows = actualSk();
        final c = await Company.db.insertRow(
          s,
          Company(corpCode: '01188730', name: 'SK시그넷(주)'),
        );
        final source = await Source.db.insertRow(
          s,
          Source(
            kind: SourceKind.dartReport,
            reference: '20250320001633',
            url: (rows.first['html_provenance'] as Map)['source'] as String,
            title: jsonEncode({
              'coreRowProvenance': rows
                  .map((r) => r['html_provenance'])
                  .toList(),
            }),
            retrievedAt: DateTime.utc(2026),
          ),
        );
        final report = await FinancialReport.db.insertRow(
          s,
          FinancialReport(
            companyId: c.id!,
            rceptNo: '20250320001633',
            fsDiv: FsDiv.separate,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2024.12)',
            factCount: 7,
            sourceId: source.id!,
            fetchedAt: DateTime.utc(2026),
          ),
        );
        final converted = FinancialRows.toFacts(
          rows,
          reportId: report.id!,
          companyId: c.id!,
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: source.id!,
        );
        await FinancialFact.db.insert(s, converted.facts);
        final stored = await FinancialFact.db.find(
          s,
          where: (t) => t.reportId.equals(report.id!),
        );
        final picked = FinancialAccounts.pick(stored);
        expect(
          picked
              .where(
                (v) => [
                  'assets',
                  'liabilities',
                  'equity',
                  'revenue',
                  'operatingIncome',
                  'netIncome',
                  'operatingCashFlow',
                ].contains(v.key),
              )
              .length,
          7,
        );
        for (final row in rows) {
          expect(
            stored
                .singleWhere((f) => f.accountName == row['account_nm'])
                .amount,
            BigInt.parse(row['thstrm_amount']),
          );
        }
        expect(
          (await Source.db.findById(s, source.id!))!.title,
          contains('에스케이시그넷주식회사'),
        );
        expect(
          stored.every(
            (f) =>
                f.sourceId == source.id &&
                f.fsDiv == FsDiv.separate &&
                f.accountId == null,
          ),
          isTrue,
        );
      } finally {
        await s.close();
      }
    });
  });
}
