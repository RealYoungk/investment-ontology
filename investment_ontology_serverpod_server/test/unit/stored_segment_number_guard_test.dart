import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_segment_number_guard.dart';
import 'package:test/test.dart';

void main() {
  final cases = (jsonDecode(
    File('test/fixtures/stored_segment_number/six-actual-sources.json')
        .readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  for (final data in cases) {
    test(
      '${data['name']} legacy digits checked against own printed share and row sum',
      () {
        final fact = DocumentFact.fromJson(data['fact']);
        final doc = BusinessDocument(
          id: fact.documentId,
          reportId: 1,
          companyId: fact.companyId,
          bsnsYear: fact.bsnsYear,
          rceptNo: 'receipt',
          title: 'source',
          text: data['context'],
          charCount: (data['context'] as String).length,
        );
        final report = DisclosureReport(
          id: 1,
          companyId: fact.companyId,
          section: DartSection.businessContent,
          rceptNo: 'receipt',
          bsnsYear: fact.bsnsYear,
          reportCode: FinancialReportCode.annual,
          rowCount: 0,
          sourceId: fact.sourceId!,
          fetchedAt: DateTime.utc(2026),
        );
        final result = StoredSegmentNumberGuard.assess(fact, doc, report);
        expect(result.suspect, isTrue);
        expect(result.keep, fact.id != 311982, reason: result.reason);
        expect(fact.evidence, data['fact']['evidence']);
        expect(
          StoredSegmentNumberGuard.assess(
            fact,
            doc,
            report.copyWith(bsnsYear: 1999),
          ).keep,
          isFalse,
        );
        expect(
          StoredSegmentNumberGuard.isCandidate(
            fact.copyWith(extractedBy: RelationOrigin.ai),
          ),
          isFalse,
        );
      },
    );
  }
  test(
    'single 100% needs matching receipt/year/period/basis financial evidence',
    () {
      final fact = DocumentFact(
        id: 1,
        companyId: 1,
        documentId: 1,
        bsnsYear: 2025,
        kind: DocumentFactKind.segmentRevenue,
        label: 'A',
        value: 1234,
        unit: '원',
        asOf: DateTime.utc(2025, 12, 31),
        evidence: 'A | 1,234, | 100%',
        sourceId: 1,
        extractedBy: RelationOrigin.api,
        status: RelationStatus.verified,
        createdAt: DateTime.utc(2026),
      );
      final text = '별도 기준\n(단위: 원)\n부문 | 매출액 | 비중\n${fact.evidence}';
      final doc = BusinessDocument(
        id: 1,
        reportId: 1,
        companyId: 1,
        bsnsYear: 2025,
        rceptNo: 'receipt',
        title: 'source',
        text: text,
        charCount: text.length,
      );
      final report = DisclosureReport(
        id: 1,
        companyId: 1,
        section: DartSection.businessContent,
        rceptNo: 'receipt',
        bsnsYear: 2025,
        reportCode: FinancialReportCode.annual,
        rowCount: 0,
        sourceId: 1,
        fetchedAt: DateTime.utc(2026),
      );
      final reference = (
        companyId: 1,
        bsnsYear: 2025,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.separate,
        rceptNo: 'receipt',
        revenueWon: BigInt.from(1234),
      );
      expect(StoredSegmentNumberGuard.assess(fact, doc, report).keep, isFalse);
      expect(
        StoredSegmentNumberGuard.assess(
          fact,
          doc,
          report,
          financialRevenues: [reference],
        ).keep,
        isTrue,
      );
      expect(
        StoredSegmentNumberGuard.assess(
          fact.copyWith(value: 123),
          doc,
          report,
        ).suspect,
        isFalse,
      );
      final wrong = (
        companyId: 1,
        bsnsYear: 2024,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.separate,
        rceptNo: 'receipt',
        revenueWon: BigInt.from(1234),
      );
      expect(
        StoredSegmentNumberGuard.assess(
          fact,
          doc,
          report,
          financialRevenues: [wrong],
        ).keep,
        isFalse,
      );
    },
  );
}
