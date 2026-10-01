import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_period_repair.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exact-source fiscal metadata repair', (builder, endpoints) {
    late Session session;
    late Company company;
    late Source source;
    late DartFiling filing;
    late FinancialReport current;
    late List<Map<String, dynamic>> rows;
    Future<FinancialReport> makeReport(
      String receipt,
      int year,
      String name,
    ) async {
      final report = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: company.id!,
          rceptNo: receipt,
          fsDiv: FsDiv.separate,
          bsnsYear: year,
          reportCode: FinancialReportCode.q1,
          reportName: name,
          factCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.utc(2026, 8, 13),
        ),
      );
      await FinancialFact.db.insert(
        session,
        FinancialRows.toFacts(
          rows,
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: year,
          reportCode: FinancialReportCode.q1,
          fsDiv: FsDiv.separate,
          sourceId: source.id!,
        ).facts,
      );
      return report;
    }

    setUp(() async {
      session = builder.asAdmin.build();
      company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00000001',
          name: '3월결산',
          stockCode: '000001',
          fiscalMonth: 3,
        ),
      );
      source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '원 API',
          reference: '20260813000001',
          retrievedAt: DateTime.utc(2026, 8, 13),
        ),
      );
      filing = await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: company.id,
          corpCode: company.corpCode,
          rceptNo: '20260813000001',
          bsnsYear: 2027,
          reportCode: FinancialReportCode.q1,
          reportName: '분기보고서 (2026.06)',
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.noData,
          discoveredAt: DateTime.utc(2026, 8, 13),
        ),
      );
      rows = [
        {
          'rcept_no': filing.rceptNo,
          'corp_code': company.corpCode,
          'bsns_year': '2026',
          'reprt_code': '11013',
          'sj_div': 'BS',
          'account_id': 'ifrs-full_Assets',
          'account_nm': '자산총계',
          'ord': '1',
          'thstrm_nm': '제27기 1분기말',
          'thstrm_amount': '100',
          'frmtrm_amount': '90',
          'currency': 'KRW',
        },
      ];
      current = await makeReport(filing.rceptNo, 2026, filing.reportName);
    });

    Future<bool> repair({List<Map<String, dynamic>>? values}) =>
        FinancialPeriodRepair.repair(
          session,
          existing: current,
          filing: filing,
          company: company,
          div: FsDiv.separate,
          freshRows: values ?? rows,
        );

    test(
      'all source values match before metadata changes and audit is stored',
      () async {
        expect(await repair(), isTrue);
        final updated = (await FinancialReport.db.findById(
          session,
          current.id!,
        ))!;
        final fact = (await FinancialFact.db.findFirstRow(
          session,
          where: (t) => t.reportId.equals(current.id!),
        ))!;
        expect(updated.bsnsYear, 2027);
        expect(updated.sourceId, source.id);
        expect(fact.bsnsYear, 2027);
        expect(fact.amount, BigInt.from(100));
        expect(fact.priorAmount, BigInt.from(90));
        expect(fact.sourceId, source.id);
        final audit = (await Source.db.find(session))
            .where(
              (s) =>
                  s.reference?.startsWith('financial-period-repair:') ?? false,
            )
            .single;
        expect(audit.title, contains('"previousFiscalYear":2026'));
        expect(audit.title, contains('"verifiedFiscalYear":2027'));
        expect(audit.url, contains(filing.rceptNo));
      },
    );
    test(
      'different amount, currency or receipt never relabels stored facts',
      () async {
        for (final change in [
          {'thstrm_amount': '101'},
          {'currency': 'GBP'},
          {'rcept_no': '20250813000001'},
        ]) {
          expect(
            await repair(
              values: [
                {...rows.single, ...change},
              ],
            ),
            isFalse,
          );
          expect(
            (await FinancialReport.db.findById(session, current.id!))!.bsnsYear,
            2026,
          );
          expect(
            (await FinancialFact.db.findFirstRow(
              session,
              where: (t) => t.reportId.equals(current.id!),
            ))!.amount,
            BigInt.from(100),
          );
        }
        expect(await Source.db.count(session), 1);
      },
    );
    test('restore cross-period prior and relink only the actual same-period correction', () async {
      final prior = await makeReport('20250813000001', 2026, '분기보고서 (2025.06)');
      final correction = await makeReport(
        '20260713000001',
        2027,
        '분기보고서 (2026.06)',
      );
      await FinancialReport.db.updateRow(
        session,
        prior.copyWith(supersededById: current.id),
      );
      final priorFact = (await FinancialFact.db.findFirstRow(
        session,
        where: (t) => t.reportId.equals(prior.id!),
      ))!;
      final currentFact = (await FinancialFact.db.findFirstRow(
        session,
        where: (t) => t.reportId.equals(current.id!),
      ))!;
      await FinancialFact.db.updateRow(
        session,
        priorFact.copyWith(supersededById: currentFact.id),
      );
      expect(await repair(), isTrue);
      expect(
        (await FinancialReport.db.findById(session, prior.id!))!.supersededById,
        isNull,
      );
      expect(
        (await FinancialFact.db.findById(
          session,
          priorFact.id!,
        ))!.supersededById,
        isNull,
      );
      expect(
        (await FinancialReport.db.findById(
          session,
          correction.id!,
        ))!.supersededById,
        current.id,
      );
      final correctionFact = (await FinancialFact.db.findFirstRow(
        session,
        where: (t) => t.reportId.equals(correction.id!),
      ))!;
      expect(correctionFact.supersededById, currentFact.id);
    });
  });
}
