import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';

import '../unit/financial_summary_active_pending_test.dart' show filing;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('summary active pending scope', (builder, endpoints) {
    test('exhausted and blocked failures remain outstanding without ledger mutation', () async {
      final s = builder.build();
      final c = await Company.db.insertRow(
        s,
        Company(
          corpCode: '00999999',
          name: 'Outstanding regression',
          stockCode: '999999',
          market: Market.kosdaq,
        ),
      );
      final rows = [
        filing(
          1,
          2020,
          FinancialReportCode.annual,
          status: FilingFetchStatus.failed,
          attempts: 9,
        ),
        filing(
          2,
          2021,
          FinancialReportCode.annual,
          status: FilingFetchStatus.failed,
          attempts: 3,
        ),
        filing(
          3,
          2022,
          FinancialReportCode.annual,
          status: FilingFetchStatus.failed,
          attempts: -1,
        ),
        filing(
          4,
          2023,
          FinancialReportCode.annual,
          status: FilingFetchStatus.stored,
        ),
        filing(
          5,
          2024,
          FinancialReportCode.annual,
          status: FilingFetchStatus.noData,
        ),
        filing(
          6,
          2025,
          FinancialReportCode.annual,
          status: FilingFetchStatus.stored,
        ),
        filing(
          7,
          2024,
          FinancialReportCode.halfYear,
          month: 6,
          status: FilingFetchStatus.failed,
          attempts: 8,
        ),
        filing(
          8,
          2026,
          FinancialReportCode.q1,
          month: 3,
          status: FilingFetchStatus.failed,
          attempts: -1,
        ),
        filing(
          9,
          2026,
          FinancialReportCode.halfYear,
          month: 6,
          status: FilingFetchStatus.failed,
          attempts: 4,
        ),
      ];
      for (final row in rows) {
        await DartFiling.db.insertRow(
          s,
          row.copyWith(id: null, companyId: c.id, corpCode: c.corpCode),
        );
      }
      final before = await DartFiling.db.find(
        s,
        where: (t) => t.companyId.equals(c.id!),
      );
      final result = (await FinancialEndpoint().summary(s, c.corpCode))!;
      expect(result.filingCount, 9);
      expect(result.pendingFilingCount, 3);
      final after = await DartFiling.db.find(
        s,
        where: (t) => t.companyId.equals(c.id!),
      );
      expect(
        after.map((f) => f.toJson()).toList(),
        before.map((f) => f.toJson()).toList(),
      );
    });
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
