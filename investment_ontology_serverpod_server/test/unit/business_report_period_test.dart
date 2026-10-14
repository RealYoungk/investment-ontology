import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_report_period.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:test/test.dart';

void main() {
  test(
    'fiscal 2027 first quarter is not a future calendar 2027 observation',
    () {
      final report = DisclosureReport(
        companyId: 1,
        section: DartSection.businessContent,
        rceptNo: 'source',
        bsnsYear: 2027,
        reportCode: FinancialReportCode.q1,
        settlementDate: DateTime.utc(2026, 6, 30),
        rowCount: 1,
        sourceId: 1,
        fetchedAt: DateTime.utc(2026, 10, 13),
      );
      final period = businessReportPeriod(report, 2027);
      expect(period, '2026.06 보고서 · 회계연도 2027 1분기');
      final tables = BusinessTableInsights.parse(
        '## 3. 생산\n(단위 : %)\n사업소 | 평균가동률\n공장 | 47.6%\n',
        reportPeriod: period,
      );
      final observations = tables.expand((t) => t.measures).toList();
      expect(observations, isNotEmpty);
      expect(observations.map((m) => m.period), everyElement(period));
      expect(observations.single.value, 47.6);
      expect(
        businessReportPeriod(
          report.copyWith(settlementDate: DateTime.utc(2026, 5, 31)),
          2027,
        ),
        '2026.05 보고서 · 회계연도 2027 1분기',
      );
    },
  );
}
