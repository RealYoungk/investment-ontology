import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/revenue_trends.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';

import '../support/shad_test_host.dart';

DocumentFact fact(
  int year,
  double value, {
  int month = 12,
  String unit = '백만원',
}) => DocumentFact(
  companyId: 1,
  documentId: year,
  bsnsYear: year,
  kind: DocumentFactKind.segmentRevenue,
  label: '반도체',
  value: value,
  unit: unit,
  evidence: '반도체 | $value | 50%',
  asOf: DateTime.utc(year, month, month == 12 ? 31 : 30),
  extractedBy: RelationOrigin.api,
  status: RelationStatus.verified,
  createdAt: DateTime.utc(2026),
);
void main() {
  test('annual and interim periods stay separate and conflicting values remain missing', () {
    final a = fact(2024, 100),
        b = fact(2025, 200),
        half = fact(2026, 150, month: 6);
    final p = revenueTrendPeriods([a, b, half]);
    expect(p['12.31'], hasLength(2));
    expect(p['06.30'], hasLength(1));
    expect(revenueTrendValue([a, b], '반도체', 2023, share: false), isNull);
    expect(revenueTrendValue([a, b], '반도체', 2025, share: true), 50);
    expect(
      revenueTrendValue([a, b, fact(2025, 300)], '반도체', 2025, share: false),
      isNull,
    );
  });
  for (final width in [320.0, 1045.0]) {
    testWidgets(
      'revenue and printed shares switch without mixing half year at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1500));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(researchDeskBrand),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RevenueTrends(
                    facts: [
                      fact(2024, 100),
                      fact(2025, 200),
                      fact(2026, 150, month: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.textContaining('사업부문·제품별 매출 추이'), findsWidgets);
        await tester.tap(find.text('매출 비중 (%)'));
        await tester.pump();
        expect(find.text('매출 비중 (%)'), findsOneWidget);
        expect(find.textContaining('각 기간 전체 매출'), findsOneWidget);
        expect(find.text('상반기 (1~6월)'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
