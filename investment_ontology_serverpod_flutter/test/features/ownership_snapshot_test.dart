import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/ownership_snapshot.dart';

ShareholderEntry holder(
  String name,
  double? ratio, {
  String kind = '보통주',
  bool total = false,
}) => ShareholderEntry(
  reportId: 1,
  companyId: 1,
  bsnsYear: 2025,
  ord: 1,
  holderName: name,
  ratioEnd: ratio,
  stockKind: kind,
  isTotal: total,
);
CompanyGovernance data(List<ShareholderEntry> holders) => CompanyGovernance(
  corpCode: 'test',
  bsnsYear: 2025,
  settlementDate: DateTime(2025, 12, 31),
  availableYears: [2025],
  shareholders: holders,
  executives: [],
  investments: [],
  investors: [],
  holdings: [],
  companies: [],
  persons: [],
  sources: [],
  minorityRatio: 63.3,
);

void main() {
  for (final width in [320.0, 1000.0]) {
    testWidgets('snapshot keeps date and common share basis at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: OwnershipSnapshotCard(
                data: data([
                  holder('최대주주회사', 20),
                  holder('관계인', 0.1),
                  holder('우선주보유자', 50, kind: '우선주'),
                  holder('합계', 20.1, total: true),
                ]),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('2025.12.31 기준'), findsOneWidget);
      expect(find.text('최대주주회사 외 관계인'), findsOneWidget);
      expect(find.text('우선주보유자'), findsNothing);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.201, 0.0001));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing ownership is not zero ownership', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(body: OwnershipSnapshotCard(data: data([]))),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('보통주 지분율을 확인할 자료가 부족해요.'), findsOneWidget);
  });
}
