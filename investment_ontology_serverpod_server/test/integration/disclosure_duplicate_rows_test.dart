import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:test/test.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('duplicate disclosure rows', (builder, _) {
    test('exact rows collapse while distinct observations remain', () async {
      final session = builder.build();
      addTearDown(session.close);
      final company = await Company.db.insertRow(
        session,
        Company(corpCode: '00397289', name: '오텍'),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '사업보고서',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.dividend,
          rceptNo: '20260319001411',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          sourceId: source.id!,
          rowCount: 3,
          fetchedAt: DateTime.utc(2026),
        ),
      );
      for (final (ord, json) in [
        (0, '{"se":"현금배당","thstrm":"100"}'),
        (1, '{"thstrm":"100","se":"현금배당"}'),
        (2, '{"se":"현금배당","thstrm":"200"}'),
      ]) {
        await DisclosureRow.db.insertRow(
          session,
          DisclosureRow(
            reportId: report.id!,
            ord: ord,
            isTotal: false,
            rowJson: json,
          ),
        );
        await DividendEntry.db.insertRow(
          session,
          DividendEntry(
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: 2025,
            ord: ord,
            item: '현금배당',
            current: ord == 2 ? 200 : 100,
          ),
        );
      }
      final endpoint = DisclosureEndpoint();
      expect(
        (await endpoint.table(
          session,
          company.corpCode,
          DartSection.dividend,
        ))!.rows,
        hasLength(2),
      );
      expect(
        (await endpoint.shareholderReturn(
          session,
          company.corpCode,
        ))!.dividends.map((r) => r.current),
        [100, 200],
      );
      expect(
        await DisclosureRow.db.count(
          session,
          where: (t) => t.reportId.equals(report.id!),
        ),
        3,
      );
    });
  });
}
