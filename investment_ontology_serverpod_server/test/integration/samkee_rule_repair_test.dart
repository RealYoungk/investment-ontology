import 'dart:io';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/ingest_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';

import '../support/storage_test_server.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_rnd_facts.dart';

void main() {
  withStorageServerpod('Samkee source repair', (builder, _) {
    test('admin replay retracts wrong years, preserves human facts, and validates interim R&D against separate revenue', () async {
      final session = builder.build();
      addTearDown(session.close);
      final admin = builder
          .copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              '00000000-0000-4000-8000-000000000001',
              {Scope.admin},
            ),
          )
          .build();
      addTearDown(admin.close);
      final company = await Company.db.insertRow(
        session,
        Company(corpCode: '01526806', name: '삼기에너지솔루션즈', market: Market.kosdaq),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: '20260813000643',
          title: '반기보고서 (2026.06)',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      final text = File('test/fixtures/business_tables/samkee-2026-half.txt')
          .readAsStringSync();
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.businessContent,
          rceptNo: '20260813000643',
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          settlementDate: DateTime.utc(2026, 6, 30),
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      final doc = await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: 2026,
          rceptNo: report.rceptNo,
          title: '사업의 내용',
          text: text,
          charCount: text.length,
        ),
      );
      final stale = DocumentFact(
        companyId: company.id!,
        documentId: doc.id!,
        bsnsYear: 2026,
        kind: DocumentFactKind.segmentRevenue,
        label: '기구부품',
        value: 60462926,
        unit: '천원',
        asOf: DateTime.utc(2026, 6, 30),
        evidence: 'legacy',
        extractedBy: RelationOrigin.api,
        extractorModel: '표 규칙',
        reviewedBy: '표 규칙 (비중 = 매출액 ÷ 합계 확인)',
        status: RelationStatus.verified,
        createdAt: DateTime.now().toUtc(),
      );
      await DocumentFact.db.insertRow(session, stale);
      final human = await DocumentFact.db.insertRow(
        session,
        stale.copyWith(
          kind: DocumentFactKind.orderBacklog,
          label: '보존할 사람 결정',
          value: 1,
          reviewedBy: null,
        ),
      );
      final financial = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: company.id!,
          rceptNo: report.rceptNo,
          fsDiv: FsDiv.separate,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          reportName: '반기보고서 (2026.06)',
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
          reportName: '반기보고서 (2026.06)',
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      await FinancialFact.db.insertRow(
        session,
        FinancialFact(
          reportId: financial.id!,
          companyId: company.id!,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          fsDiv: FsDiv.separate,
          statement: FinancialStatementKind.incomeStatement,
          accountId: 'ifrs-full_Revenue',
          accountName: '매출액',
          amount: BigInt.from(40000000000),
          cumulativeAmount: BigInt.from(79878008000),
          currency: 'KRW',
          sourceId: source.id!,
        ),
      );
      // Missing receipt provenance must not authorize a financial denominator.
      await Source.db.updateRow(
        session,
        source.copyWith(reference: 'wrong-receipt'),
      );
      expect(await StoredRndFacts.read(session, doc, report), isEmpty);
      await Source.db.updateRow(
        session,
        source.copyWith(reference: report.rceptNo),
      );
      expect(
        (await StoredRndFacts.read(
          session,
          doc,
          report,
        )).where((f) => f.kind == DocumentFactKind.rndExpense).single.value,
        1130222,
      );
      final endpoint = IngestEndpoint();
      await expectLater(
        endpoint.rebuildProductionFacts(session, corpCode: '01526806'),
        throwsA(isA<NotAuthorizedException>()),
      );
      await endpoint.rebuildProductionFacts(admin, corpCode: '01526806');
      expect(
        await BusinessProfile.db.count(
          session,
          where: (t) => t.documentId.equals(doc.id!),
        ),
        1,
      );
      final profile = await BusinessProfile.db.findFirstRow(
        session,
        where: (t) => t.documentId.equals(doc.id!),
      );
      expect(
        profile!.products.map((p) => p.name),
        containsAll(['End-Plate 등', 'FF-PCB 등']),
      );
      final first = await DocumentFact.db.find(
        session,
        where: (t) => t.documentId.equals(doc.id!),
      );
      expect(
        first
            .singleWhere(
              (f) =>
                  f.kind == DocumentFactKind.segmentRevenue &&
                  f.label == '기구부품',
            )
            .value,
        42055313,
      );
      expect(
        first.singleWhere((f) => f.kind == DocumentFactKind.capacity).label,
        '전장부품',
      );
      expect(
        first.where((f) => f.kind == DocumentFactKind.utilization).single.value,
        50,
      );
      expect(first.any((f) => f.value == 60462926), isFalse);
      expect(first.any((f) => f.id == human.id), isTrue);
      await endpoint.rebuildProductionFacts(admin, corpCode: '01526806');
      expect(
        await DocumentFact.db.count(
          session,
          where: (t) => t.documentId.equals(doc.id!),
        ),
        first.length,
      );
      final trends = await DisclosureEndpoint().factTrends(session, '01526806');
      expect(
        trends.singleWhere((f) => f.kind == DocumentFactKind.rndExpense).value,
        1130222,
      );
      expect(
        trends.singleWhere((f) => f.kind == DocumentFactKind.rndRatio).asOf,
        DateTime.utc(2026, 6, 30),
      );
      // A stored prior-year number is not promoted to the current period.
      expect(ProductionFacts.parse(text).single.capacity, 4268420);
    });
  });
}
