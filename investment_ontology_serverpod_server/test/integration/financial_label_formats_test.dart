import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import '../unit/public_financial_html_label_formats_test.dart' show parseActual;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Actual printed annual labels Dart/SQL', (builder, endpoints) {
    test('whole current rows preserve names, values and identical null-ID mapping', () async {
      final session = builder.build();
      try {
        for (final receipt in ['20250326000042', '20230621000034']) {
          final rows = parseActual(receipt);
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'actual fixture source',
              reference: receipt,
              retrievedAt: DateTime.utc(2026),
            ),
          );
          final company = await Company.db.insertRow(
            session,
            Company(corpCode: rows.first['corp_code'], name: 'fixture'),
          );
          final facts = FinancialRows.toFacts(
            rows,
            reportId: 1,
            companyId: company.id!,
            bsnsYear: int.parse(rows.first['bsns_year']),
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.consolidated,
            sourceId: source.id!,
          ).facts;
          for (var i = 0; i < facts.length; i++) {
            facts[i].id = i + 1;
          }
          final picked = FinancialAccounts.pick(facts);
          expect(
            picked.singleWhere((l) => l.key == 'revenue').amount,
            BigInt.parse(
              receipt == '20250326000042' ? '155880764900' : '4315281301',
            ),
          );
          for (final fact in facts) {
            final result = await session.db.unsafeQuery(
              'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM jsonb_populate_record(NULL::financial_fact, @fact::jsonb) f',
              parameters: QueryParameters.named({
                'fact': jsonEncode(fact.toJson()),
              }),
            );
            final line = picked.where((l) => l.accountName == fact.accountName);
            if (line.isNotEmpty) {
              expect(
                result.single[0],
                FinancialAccounts.all
                    .singleWhere((a) => a.key == line.single.key)
                    .accountIds
                    .first,
              );
            }
          }
        }
      } finally {
        await session.close();
      }
    });
  });
}
