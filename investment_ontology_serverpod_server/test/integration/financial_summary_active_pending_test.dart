import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';

import '../unit/financial_summary_active_pending_test.dart' show filing;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('summary active pending scope', (builder, endpoints) {
    test(
      'public summary excludes preserved old interim, year and correction',
      () async {
        final s = builder.build();
        final c = await Company.db.insertRow(
          s,
          Company(
            corpCode: '00115694',
            name: 'DB증권',
            stockCode: '016610',
            market: Market.kospi,
          ),
        );
        final rows = [
          for (var y = 2020; y <= 2025; y++)
            filing(y, y, FinancialReportCode.annual),
          filing(3000, 2024, FinancialReportCode.halfYear, month: 6),
          filing(3001, 2026, FinancialReportCode.q1, month: 3),
          filing(3002, 2026, FinancialReportCode.halfYear, month: 6),
          filing(
            4000,
            2023,
            FinancialReportCode.annual,
            status: FilingFetchStatus.stored,
          ),
        ];
        for (final row in rows) {
          await DartFiling.db.insertRow(
            s,
            row.copyWith(id: null, companyId: c.id),
          );
        }
        final before = await DartFiling.db.find(
          s,
          where: (t) => t.companyId.equals(c.id!),
        );
        final result = (await FinancialEndpoint().summary(s, c.corpCode))!;
        expect(result.filingCount, 10);
        expect(result.pendingFilingCount, 5);
        final after = await DartFiling.db.find(
          s,
          where: (t) => t.companyId.equals(c.id!),
        );
        expect(
          after.map((f) => f.toJson()).toList(),
          before.map((f) => f.toJson()).toList(),
        );
      },
    );
  });
}
