import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

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
  testWidgets(
    'minor holders start folded and show shares and same-report change',
    (tester) async {
      final d = data([
        holder('주요 관계인', 1.2),
        holder(
          '소량 관계인',
          0,
        ).copyWith(sharesBegin: BigInt.from(100), sharesEnd: BigInt.from(180)),
      ]).copyWith(shareholderPeriodStart: DateTime(2025, 1, 1));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(body: OwnershipSnapshotCard(data: d)),
          ),
        ),
      );
      expect(find.text('주요 관계인'), findsOneWidget);
      expect(find.text('소량 관계인'), findsNothing);
      await tester.tap(find.text('소량 보유 관계인 1명'));
      await tester.pumpAndSettle();
      expect(find.text('180주'), findsOneWidget);
      expect(find.text('2025.01.01보다 80주 증가'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: OwnershipSnapshotCard(data: data(d.shareholders)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('180주'), findsOneWidget);
      expect(find.textContaining('주 증가'), findsNothing);
      expect(find.textContaining('기초 대비'), findsNothing);
      final missing = data([
        holder('소량 관계인', 0).copyWith(sharesEnd: BigInt.from(180)),
      ]);
      expect(
        snapshotQuantities(missing, snapshotHolders(missing).single).change,
        isNull,
      );
    },
  );
  test(
    'no top-five cutoff; retain rounded-zero and unknown common holders',
    () {
      final rows = [
        for (var i = 0; i < 7; i++) holder('관계인$i', 0.1),
        holder(
          '임원',
          0,
        ).copyWith(sharesEnd: BigInt.from(80), relationText: '계열회사 임원'),
        holder('미공시 관계인', null),
        holder('처분 완료', 0).copyWith(sharesEnd: BigInt.zero),
        holder('우선주만', 3, kind: '우선주'),
      ];
      final names = snapshotHolders(data(rows)).map((h) => h.name).toList();
      expect(names, hasLength(9));
      expect(names, containsAll(['관계인6', '임원', '미공시 관계인']));
      expect(names, isNot(contains('처분 완료')));
      expect(names, isNot(contains('우선주만')));
    },
  );
  for (final width in [320.0, 1000.0]) {
    testWidgets('snapshot keeps date and common share basis at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
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
        ),
      );
      expect(find.textContaining('2025.12.31 기준'), findsOneWidget);
      expect(find.text('최대주주회사'), findsOneWidget);
      expect(find.text('관계인'), findsOneWidget);
      expect(find.text('우선주보유자'), findsNothing);
      expect(find.text('그 외 주주 79.9%'), findsOneWidget);
      expect(find.text('최대주주회사 20.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing ownership is not zero ownership', (tester) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(body: OwnershipSnapshotCard(data: data([]))),
        ),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.byType(ShadProgress), findsNothing);
    expect(find.text('보통주 지분율을 확인할 자료가 부족해요.'), findsOneWidget);
  });
}
