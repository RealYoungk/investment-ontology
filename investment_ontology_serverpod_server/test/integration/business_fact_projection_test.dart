import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:test/test.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('Public source-backed fact projections', (builder, _) {
    test('both reads correct signed currency and reject mismatched provenance without writes', () async {
      final session = builder.build();
      try {
        final now = DateTime.utc(2026, 10, 13);
        final company = await Company.db.insertRow(
          session,
          Company(corpCode: '00000001', name: 'fixture'),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: '20260320000001',
            title: '사업보고서',
            retrievedAt: now,
          ),
        );
        final other = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: '20260320000002',
            title: 'other source',
            retrievedAt: now,
          ),
        );
        final report = await DisclosureReport.db.insertRow(
          session,
          DisclosureReport(
            companyId: company.id!,
            section: DartSection.businessContent,
            rceptNo: source.reference!,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            rowCount: 0,
            sourceId: source.id!,
            fetchedAt: now,
          ),
        );
        const evidence =
            '합 계 | 18,331 | 79,022 | 18,445 | 79,300 | (114) | (278)';
        const text =
            '(단위 : 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n수량 | 금액 | 수량 | 금액 | 수량 | 금액\n$evidence';
        final document = await BusinessDocument.db.insertRow(
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
        final original = await DocumentFact.db.insertRow(
          session,
          DocumentFact(
            companyId: company.id!,
            documentId: document.id!,
            bsnsYear: 2025,
            kind: DocumentFactKind.orderBacklog,
            label: '합계',
            value: 114,
            unit: '백만원',
            asOf: DateTime.utc(2025, 12, 31),
            evidence: evidence,
            sourceId: source.id!,
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            createdAt: now,
          ),
        );
        await DocumentFact.db.insertRow(
          session,
          original.copyWith(
            id: null,
            label: 'wrong source',
            sourceId: other.id!,
          ),
        );
        await DocumentFact.db.insertRow(
          session,
          original.copyWith(id: null, label: 'wrong period', bsnsYear: 2024),
        );
        final endpoint = DisclosureEndpoint();
        for (final facts in [
          await endpoint.factTrends(session, company.corpCode),
          await endpoint.facts(session, company.corpCode),
        ]) {
          expect(facts, hasLength(1));
          expect(facts.single.value, -278);
          expect(facts.single.unit, '백만원');
          expect(facts.single.sourceId, source.id);
        }
        expect(await DocumentFact.db.count(session), 3);
        expect(
          (await DocumentFact.db.findById(session, original.id!))!.value,
          114,
        );
      } finally {
        await session.close();
      }
    });
  });
}
