import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import '../unit/public_issuer_legal_name_test.dart' show actualIssuerRows;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Official same-filing issuer legal name storage', (
    builder,
    endpoints,
  ) {
    test('seven actual OFS values and printed identity survive Source/fact storage and summary pick', () async {
      final s = builder.build();
      try {
        final rows = actualIssuerRows('20251124000372');
        final c = await Company.db.insertRow(
          s,
          Company(corpCode: '01669794', name: '(주)아이엘로보틱스'),
        );
        final source = await Source.db.insertRow(
          s,
          Source(
            kind: SourceKind.dartReport,
            reference: '20251124000372',
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
            rceptNo: '20251124000372',
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
          contains('주식회사 아이엘커누스'),
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
