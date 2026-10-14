import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_guide_panel.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/revenue_composition.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/substrate_guide.dart';

DocumentFact fact({
  int year = 2025,
  int document = 1,
  double value = 18309,
  String evidence = '제품매출 | AOI | 18,309 | 34.92% | 8,757 | 33.51%',
}) => DocumentFact(
  companyId: 1,
  documentId: document,
  bsnsYear: year,
  kind: DocumentFactKind.segmentRevenue,
  label: '제품매출',
  value: value,
  unit: '백만원',
  evidence: evidence,
  extractedBy: RelationOrigin.api,
  status: RelationStatus.verified,
  createdAt: DateTime.utc(2026),
);

void main() {
  test(
    'bare share values need verified revenue-rule provenance and a unique pair',
    () {
      final row = DocumentFact(
        companyId: 1,
        documentId: 1,
        bsnsYear: 2026,
        kind: DocumentFactKind.segmentRevenue,
        label: '네이버 플랫폼',
        value: 3741951,
        unit: '백만원',
        asOf: DateTime.utc(2026, 6, 30),
        evidence: '- 네이버 플랫폼 | 3,741,951 | 56.5 | 3,297,800 | 57.8',
        extractedBy: RelationOrigin.api,
        status: RelationStatus.verified,
        reviewedBy: '표 규칙 (비중 = 매출액 ÷ 합계 확인)',
        createdAt: DateTime.utc(2026),
      );
      expect(revenuePresentation(row).share, 56.5);
      expect(
        revenuePresentation(row.copyWith(reviewedBy: '다른 검증')).share,
        isNull,
      );
      expect(
        revenuePresentation(row.copyWith(status: RelationStatus.draft)).share,
        isNull,
      );
      expect(
        revenuePresentation(
          row.copyWith(
            evidence: '네이버 플랫폼 | 3,741,951 | 56.5 | 3,741,951 | 57.8',
          ),
        ).share,
        isNull,
      );
    },
  );

  test(
    'combined amount and ratio retains the disclosed single segment share',
    () {
      final combined = fact(
        value: 131895033,
        evidence: '반도체 부문 | 제품 외 | 131,895,033(100%)',
      );
      expect(revenuePresentation(combined).share, 100);
      expect(revenueCoverageNote([combined]), contains('제품별 매출 구분은 아닙니다'));
      expect(revenuePresentation(combined.copyWith(value: 1)).share, isNull);
    },
  );
  test(
    'partial and overlapping disclosures never imply a complete sales mix',
    () {
      expect(revenueCoverageNote([fact()]), contains('전체 매출 구성이 아닙니다'));
      expect(revenueCoverageNote([fact(value: 1)]), contains('확인되지 않았습니다'));
      expect(
        revenueCoverageNote(List.filled(4, fact())),
        contains('100%를 넘습니다'),
      );
    },
  );
  test('retains product label from merged cells without assigning another year share', () {
    expect(revenuePresentation(fact()).label, '제품매출 · AOI');
    expect(revenuePresentation(fact()).share, 34.92);
    expect(revenuePresentation(fact(value: 8757)).share, isNull);
    expect(
      revenuePresentation(fact(evidence: 'AOI | 18,309 | 110%')).share,
      isNull,
    );
  });
  test('never combines years or competing source documents', () {
    final latest = latestRevenueFacts([
      fact(year: 2024),
      fact(),
      fact(document: 2),
    ]);
    expect(latest.length, 1);
    expect(latest.single.documentId, 2);
  });
  test('latest revenue is one complete period, never a mixture of Q1 and half year', () {
    final q1 = fact(
      year: 2026,
      document: 8,
    ).copyWith(asOf: DateTime.utc(2026, 3, 31));
    final half = fact(
      year: 2026,
      document: 9,
    ).copyWith(asOf: DateTime.utc(2026, 6, 30));
    final lastAnnual = fact();
    expect(
      latestRevenueFacts([half, lastAnnual, q1]).map((f) => f.documentId),
      [9],
    );
  });
  test('기간이 확인된 오름차순 매출은 저장 금액의 비중을 찾는다', () {
    final row = fact(
      value: 17590074,
      evidence: '전장부품 | FF-PCB 등 | 28,638 | 0.0% | 5,408,956 | 6.3% | 17,590,074 | 22.0%',
    ).copyWith(asOf: DateTime.utc(2026, 6, 30));
    expect(revenuePresentation(row).share, 22);
    expect(revenuePresentation(row).label, '전장부품 · FF-PCB 등');
    final combined = row.copyWith(
      value: 17590074,
      evidence: '전장부품 | 28,638 (0%) | 5,408,956 (6.3%) | 17,590,074 (22%)\n(별도) (단위: 천원)',
    );
    expect(revenuePresentation(combined).share, 22);
    expect(revenueBasisNote(combined), contains('별도 기준'));
    expect(
      revenuePresentation(
        combined.copyWith(
          evidence: '전장부품 | 17,590,074 (5%) | 17,590,074 (22%)',
        ),
      ).share,
      isNull,
    );
  });
  for (final width in [320.0, 1280.0]) {
    testWidgets('lesson navigation and original diagrams at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: const Scaffold(
              body: SingleChildScrollView(child: SubstrateGuide()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('칩과 메인보드 사이에는 작은 회로판이 있습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('다음 →'));
      await tester.tap(find.text('다음 →'));
      await tester.pumpAndSettle();
      expect(find.text('칩을 올리기 전, 기판의 회로를 만드는 동안 씁니다.'), findsOneWidget);
      await tester.ensureVisible(find.text('다음 →'));
      await tester.tap(find.text('다음 →'));
      await tester.pumpAndSettle();
      expect(find.text('수리 전 · 구리 돌출'), findsOneWidget);
      expect(find.text('수리 후 · 돌출 제거'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [320.0, 1280.0]) {
    testWidgets('source disclosure and circuit card fit at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessProductCard(
                  product: BusinessProduct(
                    key: 'substrate_aor',
                    name: 'AOR',
                    role: '쇼트·돌기를 수리합니다.',
                    process: '기판 제조 · 수리',
                    benefit: '수리 가능한 기판의 폐기를 줄입니다.',
                    evidence: '기판의 쇼트를 수리합니다.',
                    explanationKind: 'reference_and_filing',
                  ),
                  rceptNo: '20260319000682',
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('이 회사의 제품인 근거'));
      await tester.pumpAndSettle();
      expect(find.text('기판의 쇼트를 수리합니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
