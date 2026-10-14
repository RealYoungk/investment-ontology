import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';

import '../support/storage_test_server.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_rnd_facts.dart';

void main() {
  withStorageServerpod('Split R&D basis storage', (builder, _) {
    test(
      'NAVER consolidated expense validates against consolidated revenue',
      () async {
        final session = builder.build();
        addTearDown(session.close);
        final company = await Company.db.insertRow(
          session,
          Company(corpCode: '00266961', name: 'NAVER'),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: '20260316000001',
            title: 'NAVER annual table fixture',
            retrievedAt: DateTime.now().toUtc(),
          ),
        );
        final report = await DisclosureReport.db.insertRow(
          session,
          DisclosureReport(
            companyId: company.id!,
            section: DartSection.businessContent,
            rceptNo: '20260316000001',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            settlementDate: DateTime.utc(2025, 12, 31),
            rowCount: 1,
            sourceId: source.id!,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        const text = '''
(단위: 백만원)
과 목 | 연결 | 별도
제27기 | 제 26기 | 제27기 | 제 26기
연구개발비용 계 | 2,221,750 | 1,857,936 | 750,955 | 623,045
(정부보조금) | - | - | - | -
연구개발비/영업수익 비율* 연구개발비용계÷당기영업수익×100] | 18.5% | 17.3% | 10.7% | 10.1%
''';
        final doc = await BusinessDocument.db.insertRow(
          session,
          BusinessDocument(
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: 2025,
            rceptNo: report.rceptNo,
            title: '사업의 내용',
            text: text,
            charCount: text.length,
          ),
        );
        final financial = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: company.id!,
            rceptNo: report.rceptNo,
            fsDiv: FsDiv.consolidated,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            factCount: 1,
            sourceId: source.id!,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: report.rceptNo,
            corpCode: company.corpCode,
            companyId: company.id,
            reportName: '사업보고서 (2025.12)',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.noData,
            discoveredAt: DateTime.now().toUtc(),
          ),
        );
        await FinancialFact.db.insertRow(
          session,
          FinancialFact(
            reportId: financial.id!,
            companyId: company.id!,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.consolidated,
            statement: FinancialStatementKind.comprehensiveIncome,
            accountId: 'ifrs-full_Revenue',
            accountName: '영업수익',
            amount: BigInt.parse('12035007218975'),
            sourceId: source.id!,
          ),
        );
        final currentOnly = await StoredRndFacts.read(session, doc, report);
        expect(currentOnly, hasLength(2));
        expect(currentOnly.every((f) => f.asOf?.year == 2025), isTrue);
        // The printed comparative column needs its own year's eligible revenue,
        // not a denominator borrowed from the current report.
        final priorSource = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: '20250316000001',
            title: 'synthetic prior-year consolidated revenue fixture',
            retrievedAt: DateTime.now().toUtc(),
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: priorSource.reference!,
            corpCode: company.corpCode,
            companyId: company.id,
            reportName: '사업보고서 (2024.12)',
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.noData,
            discoveredAt: DateTime.now().toUtc(),
          ),
        );
        final priorReport = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: company.id!,
            rceptNo: priorSource.reference!,
            fsDiv: FsDiv.consolidated,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2024.12)',
            factCount: 1,
            sourceId: priorSource.id!,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        await FinancialFact.db.insertRow(
          session,
          FinancialFact(
            reportId: priorReport.id!,
            companyId: company.id!,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.consolidated,
            statement: FinancialStatementKind.comprehensiveIncome,
            accountId: 'ifrs-full_Revenue',
            accountName: 'synthetic revenue',
            amount: BigInt.parse('10740000000000'),
            currency: 'KRW',
            sourceId: priorSource.id!,
          ),
        );
        expect(await RndFacts.store(session, doc), 4);
        final facts = await DocumentFact.db.find(
          session,
          where: (t) => t.documentId.equals(doc.id!),
        );
        expect(
          facts
              .where((f) => f.kind == DocumentFactKind.rndExpense)
              .map((f) => f.value),
          containsAll([2221750.0, 1857936.0]),
        );
        expect(
          facts
              .where((f) => f.kind == DocumentFactKind.rndExpense)
              .every((f) => f.evidence.contains('750,955')),
          isTrue,
        );
      },
    );
  });
}
